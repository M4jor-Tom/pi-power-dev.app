// Pi awaits the extension at startup and on /reload, including in offline mode.
export default async function loadProvider(pi) {
  const url = process.env.PI_POWER_DEV_OLLAMA_URL;
  const response = await fetch(`${url}/api/tags`, {
    signal: AbortSignal.timeout(1500), redirect: 'error',
  }).catch(() => null); // The independently managed server need not be running.
  if (!response?.ok) return;
  const { models } = await response.json();
  const local = models.filter(m => !m.remote_model && !m.remote_host &&
    (!m.capabilities?.length || m.capabilities.includes('completion')));
  if (!local.length) return;
  pi.registerProvider('pi-ollama', {
    baseUrl: `${url}/v1`, api: 'openai-completions', apiKey: 'local',
    models: local.map(({ name, details, capabilities }) => ({
      id: name, name, reasoning: false,
      input: capabilities?.includes('vision') ? ['text', 'image'] : ['text'],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: details?.context_length || 4096,
      maxTokens: Math.min(details?.context_length || 4096, 4096),
    })),
  });
}
