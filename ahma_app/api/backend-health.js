function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,X-API-Key');
}

module.exports = async function handler(req, res) {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({error: 'Method not allowed'});
    return;
  }

  const backendUrl = process.env.BACKEND_API_URL;
  if (!backendUrl) {
    res.status(500).json({error: 'Missing BACKEND_API_URL'});
    return;
  }

  const upstreamUrl = `${backendUrl.replace(/\/$/, '')}/health`;

  try {
    const response = await fetch(upstreamUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...(process.env.BACKEND_API_KEY
          ? {'X-API-Key': process.env.BACKEND_API_KEY}
          : {}),
      },
    });

    const text = await response.text();
    res.status(response.status);
    res.setHeader(
      'Content-Type',
      response.headers.get('content-type') || 'application/json',
    );
    res.send(text);
  } catch (error) {
    res.status(502).json({error: String(error)});
  }
};
