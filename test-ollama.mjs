import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { once } from 'node:events';
import { test } from 'node:test';
import loadProvider from './ollama.js';

test('only local chat models are offered to Pi; a stopped server is optional', async () => {
  const server = createServer((req, res) => {
    if (req.url !== '/api/tags') return res.writeHead(404).end();
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ models: [
      { name: 'local:3b', capabilities: ['completion'], details: { context_length: 32768 } },
      { name: 'cloud-copy:latest', remote_model: 'cloud-copy', capabilities: ['completion'] },
      { name: 'embed', capabilities: ['embedding'] },
    ] }));
  });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  process.env.PI_POWER_DEV_OLLAMA_URL = `http://127.0.0.1:${server.address().port}`;
  let registered;
  const pi = { registerProvider: (id, config) => { registered = { id, ...config }; } };
  try {
    await loadProvider(pi);
    assert.equal(registered.id, 'pi-ollama');
    assert.equal(registered.baseUrl, `${process.env.PI_POWER_DEV_OLLAMA_URL}/v1`);
    assert.deepEqual(registered.models.map(m => m.id), ['local:3b']);
  } finally {
    await new Promise(resolve => server.close(resolve));
  }
  registered = undefined;
  await loadProvider(pi);
  assert.equal(registered, undefined);
});
