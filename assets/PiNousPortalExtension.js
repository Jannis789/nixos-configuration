// Nous Portal — auto-discover models from the live Nous inference API.
// Deployed declaratively via home-manager into ~/.pi/agent/extensions/nous-portal/index.js
// (same pattern as the betterwright-driver skill). pi awaits this async factory
// before startup, so the full catalog shows in `pi --list-models`.
export default async function (pi) {
  const apiKey = process.env.NOUS_API_KEY;
  if (!apiKey) return; // not configured → skip, nothing to register

  let data = [];
  try {
    const res = await fetch("https://inference-api.nousresearch.com/v1/models", {
      headers: { Authorization: `Bearer ${apiKey}` },
    });
    if (!res.ok) return;
    const json = await res.json();
    data = Array.isArray(json?.data) ? json.data : [];
  } catch {
    return; // offline / network error → start without nous
  }

  pi.registerProvider("nous", {
    baseUrl: "https://inference-api.nousresearch.com/v1",
    apiKey: "$NOUS_API_KEY",
    api: "openai-completions",
    models: data.map((m) => ({
      id: m.id,
      name: m.name ?? m.id,
      reasoning: !!m.reasoning?.default_enabled,
      input: (m.architecture?.input_modalities ?? ["text"]).map((x) =>
        x === "image" ? "image" : "text"
      ),
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: m.context_length ?? 128000,
      maxTokens: m.top_provider?.max_completion_tokens ?? 16384,
    })),
  });
}
