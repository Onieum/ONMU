import http from "node:http";
import net from "node:net";

try {
  process.loadEnvFile();
} catch {
  // The server can still run with process env only.
}

const host = process.env.API_HOST || process.env.HOST || "127.0.0.1";
const port = Number(process.env.API_PORT || process.env.PORT || 8080);

function json(res, statusCode, body) {
  const payload = JSON.stringify(body, null, 2);
  res.writeHead(statusCode, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
  });
  res.end(payload);
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
  const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);

  if (req.method === "GET" && url.pathname === "/healthz") {
    json(res, 200, {
      ok: true,
      service: "onmu-api",
      env: process.env.ONMU_ENV || "local",
    });
    return;
  }

  if (req.method === "GET" && url.pathname === "/readyz") {
    const result = await readiness();
    json(res, result.ok ? 200 : 503, result);
    return;
  }

  json(res, 404, {
    ok: false,
    error: "not_found",
  });
});

server.listen(port, host, () => {
  console.log(`onmu-api listening on http://${host}:${port}`);
});
