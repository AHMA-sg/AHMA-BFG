function getBody(req) {
  if (req.method === 'GET' || req.method === 'DELETE') {
    return undefined;
  }

  if (req.body == null) {
    return undefined;
  }

  return typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
}

function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,X-API-Key');
}

export default async function handler(req, res) {
  setCorsHeaders(res);

  console.log(`[Ultravox Proxy] ${req.method} ${req.url}`);

  if (req.method === 'OPTIONS') {
    console.log('[Ultravox Proxy] CORS preflight');
    res.status(204).end();
    return;
  }

  const apiKey = process.env.ULTRAVOX_API_KEY;
  if (!apiKey) {
    console.error('[Ultravox Proxy] Missing ULTRAVOX_API_KEY');
    res.status(500).json({error: 'Missing ULTRAVOX_API_KEY'});
    return;
  }

  const baseUrl = process.env.ULTRAVOX_BASE_URL || 'https://api.ultravox.ai/api';
  const path = Array.isArray(req.query.path) ? req.query.path.join('/') : req.query.path;
  const search = req.url.includes('?') ? `?${req.url.split('?')[1]}` : '';
  const upstreamUrl = `${baseUrl.replace(/\/$/, '')}/${path}${search}`;

  try {
    console.log(`[Ultravox Proxy] Forwarding to ${upstreamUrl}`);
    const response = await fetch(upstreamUrl, {
      method: req.method,
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      },
      body: getBody(req),
    });

    const text = await response.text();
    console.log(`[Ultravox Proxy] Ultravox responded ${response.status}`);
    res.status(response.status);
    res.setHeader('Content-Type', response.headers.get('content-type') || 'application/json');
    res.send(text);
  } catch (error) {
    console.error('[Ultravox Proxy] Upstream error', error);
    res.status(502).json({error: String(error)});
  }
}
