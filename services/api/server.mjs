import http from "node:http";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";

import { createDevContractRouter } from "./dev-contract-routes.mjs";
import { createDevContractStore } from "./dev-contract-store.mjs";

try {
  process.loadEnvFile();
} catch {
  // The server can still run with process env only.
}

const host = process.env.API_HOST || process.env.HOST || "127.0.0.1";
const port = Number(process.env.API_PORT || process.env.PORT || 8080);
const accessLogEnabled = process.env.ACCESS_LOG_ENABLED !== "false";
const accessLogFile = process.env.ACCESS_LOG_FILE || path.join("logs", "api-access.log");
const accessLogPath = path.isAbsolute(accessLogFile)
  ? accessLogFile
  : path.resolve(process.cwd(), accessLogFile);
let accessLogDirReady = false;
const devContractRouter = createDevContractRouter(createDevContractStore());

function allowedCorsOrigin(req) {
  const origin = headerValue(req, "origin");
  if (!origin) {
    return "*";
  }

  if (
    origin === "https://dev-api.onmu.cloud" ||
    /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
  ) {
    return origin;
  }

  return "";
}

function responseHeaders(req, extra = {}) {
  const corsOrigin = allowedCorsOrigin(req);
  return {
    ...(corsOrigin ? { "access-control-allow-origin": corsOrigin } : {}),
    "access-control-allow-methods": "GET,POST,PATCH,DELETE,OPTIONS",
    "access-control-allow-headers": "content-type,authorization,x-onmu-dev-client",
    "access-control-max-age": "600",
    vary: "origin",
    ...extra,
  };
}

function json(req, res, statusCode, body) {
  const payload = JSON.stringify(body, null, 2);
  res.writeHead(statusCode, {
    ...responseHeaders(req),
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
  });
  res.end(payload);
}

function noContent(req, res) {
  res.writeHead(204, responseHeaders(req));
  res.end();
}

function headerValue(req, name) {
  const value = req.headers[name.toLowerCase()];
  if (Array.isArray(value)) {
    return value[0] || "";
  }
  return value || "";
}

function firstForwardedIp(value) {
  return String(value || "")
    .split(",")
    .map((part) => part.trim())
    .filter(Boolean)[0] || "";
}

function remoteIp(req) {
  const cfIp = headerValue(req, "cf-connecting-ip");
  const forwardedIp = firstForwardedIp(headerValue(req, "x-forwarded-for"));
  const realIp = headerValue(req, "x-real-ip");
  const socketIp = req.socket.remoteAddress || "";
  return (cfIp || forwardedIp || realIp || socketIp).replace(/^::ffff:/, "");
}

function trimField(value, maxLength = 180) {
  const text = String(value || "");
  return text.length > maxLength ? `${text.slice(0, maxLength - 3)}...` : text;
}

function writeAccessLog(entry) {
  if (!accessLogEnabled) {
    return;
  }

  const line = JSON.stringify(entry);
  console.info(line);

  try {
    if (!accessLogDirReady) {
      fs.mkdirSync(path.dirname(accessLogPath), { recursive: true });
      accessLogDirReady = true;
    }
    fs.appendFile(accessLogPath, `${line}\n`, (error) => {
      if (error) {
        console.warn(`access log write failed: ${error.message}`);
      }
    });
  } catch (error) {
    console.warn(`access log setup failed: ${error.message}`);
  }
}

function attachAccessLog(req, res, url, startTime) {
  res.once("finish", () => {
    const durationMs = Number(process.hrtime.bigint() - startTime) / 1_000_000;
    writeAccessLog({
      kind: "access",
      ts: new Date().toISOString(),
      method: req.method,
      path: url.pathname,
      status: res.statusCode,
      duration_ms: Math.round(durationMs),
      ip: remoteIp(req),
      cf_ray: trimField(headerValue(req, "cf-ray"), 80),
      cf_country: trimField(headerValue(req, "cf-ipcountry"), 16),
      user_agent: trimField(headerValue(req, "user-agent")),
      dev_client: trimField(headerValue(req, "x-onmu-dev-client") || url.searchParams.get("client"), 80),
    });
  });
}

function tcpCheck(name, hostName, portNumber, timeoutMs = 1500) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host: hostName, port: portNumber });
    const done = (status, detail) => {
      socket.destroy();
      resolve({ name, status, detail });
    };

    socket.setTimeout(timeoutMs);
    socket.once("connect", () => done("ok", `${hostName}:${portNumber}`));
    socket.once("timeout", () => done("error", `timeout ${hostName}:${portNumber}`));
    socket.once("error", (error) => done("error", error.message));
  });
}

function postgresTarget() {
  const fallback = { hostName: "localhost", portNumber: 15432 };

  if (!process.env.DATABASE_URL) {
    return fallback;
  }

  try {
    const url = new URL(process.env.DATABASE_URL);
    return {
      hostName: url.hostname || fallback.hostName,
      portNumber: Number(url.port || fallback.portNumber),
    };
  } catch {
    return fallback;
  }
}

function redisTarget() {
  const fallback = { hostName: "localhost", portNumber: 6379 };

  if (!process.env.REDIS_URL) {
    return fallback;
  }

  try {
    const url = new URL(process.env.REDIS_URL);
    return {
      hostName: url.hostname || fallback.hostName,
      portNumber: Number(url.port || fallback.portNumber),
    };
  } catch {
    return fallback;
  }
}

async function minioCheck() {
  const endpoint = process.env.OBJECT_STORAGE_ENDPOINT || "http://localhost:9000";
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 1500);

  try {
    const response = await fetch(`${endpoint.replace(/\/$/, "")}/minio/health/live`, {
      signal: controller.signal,
    });
    return {
      name: "minio",
      status: response.ok ? "ok" : "error",
      detail: `${response.status} ${response.statusText}`,
    };
  } catch (error) {
    return { name: "minio", status: "error", detail: error.message };
  } finally {
    clearTimeout(timer);
  }
}

async function readiness() {
  const postgres = postgresTarget();
  const redis = redisTarget();

  const checks = await Promise.all([
    tcpCheck("postgres", postgres.hostName, postgres.portNumber),
    tcpCheck("redis", redis.hostName, redis.portNumber),
    minioCheck(),
  ]);

  return {
    ok: checks.every((check) => check.status === "ok"),
    checks,
  };
}

const server = http.createServer(async (req, res) => {
  const startTime = process.hrtime.bigint();
  const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);
  attachAccessLog(req, res, url, startTime);

  if (req.method === "OPTIONS") {
    noContent(req, res);
    return;
  }

  if (req.method === "GET" && url.pathname === "/healthz") {
    json(req, res, 200, {
      ok: true,
      service: "onmu-api",
      env: process.env.ONMU_ENV || "local",
    });
    return;
  }

  if (req.method === "GET" && url.pathname === "/readyz") {
    const result = await readiness();
    json(req, res, result.ok ? 200 : 503, result);
    return;
  }

  const devContractResult = await devContractRouter(req, url);
  if (devContractResult.handled) {
    json(req, res, devContractResult.statusCode, devContractResult.body);
    return;
  }

  json(req, res, 404, {
    ok: false,
    error: "not_found",
  });
});

server.listen(port, host, () => {
  console.log(`onmu-api listening on http://${host}:${port}`);
  if (accessLogEnabled) {
    console.log(`access log writing to ${accessLogPath}`);
  }
});
