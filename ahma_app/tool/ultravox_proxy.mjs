#!/usr/bin/env node

import http from 'node:http';
import { readFileSync, existsSync } from 'node:fs';

const envPath = new URL('../.env', import.meta.url);

if (existsSync(envPath)) {
  const envText = readFileSync(envPath, 'utf8');
  for (const line of envText.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#') || !trimmed.includes('=')) continue;

    const index = trimmed.indexOf('=');
    const key = trimmed.slice(0, index).trim();
    const value = trimmed.slice(index + 1).trim().replace(/^['"]|['"]$/g, '');
    process.env[key] ||= value;
  }
}

const port = Number(process.env.PORT || 5001);
const ultravoxApiKey = process.env.ULTRAVOX_API_KEY;
const ultravoxBaseUrl = process.env.ULTRAVOX_BASE_URL || 'https://api.ultravox.ai/api';

if (!ultravoxApiKey) {
  console.error('Missing ULTRAVOX_API_KEY in .env');
  process.exit(1);
}

function sendCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,X-API-Key');
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString('utf8');
}

const server = http.createServer(async (req, res) => {
  sendCors(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const url = new URL(req.url || '/', `http://${req.headers.host}`);
  if (!url.pathname.startsWith('/api/ultravox/')) {
    res.writeHead(404, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({error: 'Not found'}));
    return;
  }

  const upstreamPath = url.pathname.replace('/api/ultravox/', '/api/');
  const upstreamUrl = new URL(upstreamPath + url.search, ultravoxBaseUrl.replace(/\/api\/?$/, ''));
  const body = req.method === 'GET' || req.method === 'DELETE' ? undefined : await readBody(req);

  try {
    console.log(`[Proxy] ${req.method} ${upstreamUrl}`);
    const response = await fetch(upstreamUrl, {
      method: req.method,
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': ultravoxApiKey,
      },
      body,
    });

    const text = await response.text();
    res.writeHead(response.status, {'Content-Type': response.headers.get('content-type') || 'application/json'});
    res.end(text);
  } catch (error) {
    console.error('[Proxy] Error:', error);
    res.writeHead(502, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({error: String(error)}));
  }
});

server.listen(port, () => {
  console.log(`[Proxy] Listening on http://localhost:${port}`);
  console.log(`[Proxy] Forwarding Ultravox requests to ${ultravoxBaseUrl}`);
});
