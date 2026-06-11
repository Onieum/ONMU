#!/usr/bin/env node

const http = require('http');
const https = require('https');
const { URL } = require('url');

const port = Number(process.env.ONMU_TILE_GATEWAY_PORT || '19100');
const minioEndpoint = process.env.OBJECT_STORAGE_ENDPOINT || process.env.MINIO_ENDPOINT || 'http://localhost:9000';
const bucket = process.env.ONMU_TILE_BUCKET || 'onmu-tiles';
const manifestObjectKey = process.env.ONMU_TILE_MANIFEST_OBJECT_KEY || 'tiles/manifest.json';
const allowedOrigins = new Set(
  (process.env.ONMU_TILE_ALLOWED_ORIGINS ||
    'http://localhost:5173,http://127.0.0.1:5173,https://dev-api.onmu.cloud,https://int-api.onmu.cloud')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
);

function addCorsHeaders(req, res) {
  const origin = req.headers.origin;
  if (origin && allowedOrigins.has(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'GET,HEAD,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Range,If-None-Match,If-Modified-Since,Content-Type');
  res.setHeader('Access-Control-Expose-Headers', 'Accept-Ranges,Content-Length,Content-Range,Content-Type,ETag,Last-Modified,Cache-Control');
}

function objectKeyForPath(pathname) {
  let decoded;
  try {
    decoded = decodeURIComponent(pathname);
  } catch {
    return null;
  }

  if (decoded.includes('..') || decoded.includes('\\')) {
    return null;
  }
  if (decoded === '/manifest.json') {
    return manifestObjectKey;
  }
  if (/^\/styles\/[A-Za-z0-9._/-]+\.json$/.test(decoded)) {
    return decoded.slice(1);
  }
  if (/^\/pmtiles\/[A-Za-z0-9._/-]+\.pmtiles$/.test(decoded)) {
    return decoded.slice(1);
  }
  return null;
}

function upstreamUrlForObject(objectKey) {
  const base = new URL(minioEndpoint);
  const normalizedBasePath = base.pathname.replace(/\/+$/, '');
  base.pathname = `${normalizedBasePath}/${bucket}/${objectKey}`
    .split('/')
    .map((part) => encodeURIComponent(part))
    .join('/')
    .replace(/^%2F/, '/');
  base.search = '';
  return base;
}

function proxyObject(req, res, objectKey) {
  const upstreamUrl = upstreamUrlForObject(objectKey);
  const client = upstreamUrl.protocol === 'https:' ? https : http;
  const headers = {};
  for (const name of ['range', 'if-none-match', 'if-modified-since']) {
    if (req.headers[name]) {
      headers[name] = req.headers[name];
    }
  }

  const upstreamReq = client.request(
    upstreamUrl,
    {
      method: req.method,
      headers,
    },
    (upstreamRes) => {
      res.statusCode = upstreamRes.statusCode || 502;
      for (const name of [
        'content-type',
        'content-length',
        'content-range',
        'accept-ranges',
        'etag',
        'last-modified',
        'cache-control',
      ]) {
        const value = upstreamRes.headers[name];
        if (value) {
          res.setHeader(name, value);
        }
      }
      addCorsHeaders(req, res);
      if (req.method === 'HEAD') {
        res.end();
      } else {
        upstreamRes.pipe(res);
      }
    },
  );

  upstreamReq.on('error', () => {
    res.statusCode = 502;
    res.setHeader('content-type', 'application/json; charset=utf-8');
    addCorsHeaders(req, res);
    res.end(JSON.stringify({ ok: false, error: 'tile_upstream_unavailable' }));
  });
  upstreamReq.end();
}

const server = http.createServer((req, res) => {
  addCorsHeaders(req, res);
  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.end();
    return;
  }
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.statusCode = 405;
    res.setHeader('content-type', 'application/json; charset=utf-8');
    res.end(JSON.stringify({ ok: false, error: 'method_not_allowed' }));
    return;
  }

  const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  if (url.pathname === '/healthz') {
    res.statusCode = 200;
    res.setHeader('content-type', 'application/json; charset=utf-8');
    res.end(JSON.stringify({ ok: true, service: 'onmu-map-tiles-gateway' }));
    return;
  }

  const objectKey = objectKeyForPath(url.pathname);
  if (!objectKey) {
    res.statusCode = 404;
    res.setHeader('content-type', 'application/json; charset=utf-8');
    res.end(JSON.stringify({ ok: false, error: 'tile_object_not_found' }));
    return;
  }

  proxyObject(req, res, objectKey);
});

server.listen(port, '127.0.0.1', () => {
  console.log(`ONMU map tiles gateway listening on http://127.0.0.1:${port}`);
});
