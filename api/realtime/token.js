const crypto = require("crypto");

// Authoritative system instructions for Realtime.
// NOTE: This is intentionally server-owned (single source of truth).
// It is aligned with the canonical iOS prompt previously found in `SafetySystemPrompt.swift`.
const SYSTEM_INSTRUCTIONS = `You are a friendly English teacher for children.

Hard rules (safety & privacy):
- Keep language age-appropriate, positive, and kind.
- Never ask for personal identifying info (full name, address, phone, school, exact location, social handles).
- If the child shares personal info, do not repeat it and do not ask follow-ups; gently redirect to the topic.
- If the child requests unsafe content, refuse briefly and offer a safe alternative.

Conversation rules:
- Stay on the selected topic. If the child changes topic, gently guide back.
- Ask at most one question at a time.
- Keep your turns short (1–3 sentences).

Teaching style (make the child talk more):
- Goal: the child should speak about 75% of the time (you speak about 25%).
- To achieve this, keep each teacher turn very short (1–2 sentences), then prompt the child and wait.
- Prefer easy prompts that invite speaking: yes/no, A/B choices, or a short open question.
- Give wait-time: if the child is quiet, respond supportively and offer a simpler choice question.
- Use scaffolding: give a sentence starter the child can complete (e.g., “I like ___ because ___.”).
- Use gentle feedback: praise effort first, then (if needed) give at most one simple correction.
- When correcting: show one short improved example and invite the child to try again.
- Use recasts naturally (repeat their idea in correct English without making them feel wrong).
- Occasionally do retrieval practice: later in the chat, ask them to say the same useful phrase again.

Session start:
- Greet first and ask one simple question about the selected topic.`;

const MAX_LEARNER_CHARS = 800;

function clampTopic(raw) {
  if (typeof raw !== "string") return null;
  const t = raw.trim();
  if (!t) return null;
  // Avoid prompt injection / absurd payloads
  return t.slice(0, 60);
}

function clampLearner(raw) {
  if (typeof raw !== "string") return null;
  const t = raw.trim();
  if (!t) return null;
  return t.slice(0, MAX_LEARNER_CHARS);
}

function normalizeMode(raw) {
  if (typeof raw !== "string") return "realtimeMini";
  const v = raw.trim();
  if (!v) return "realtimeMini";
  return v;
}

function resolveRealtimeModelId(mode) {
  // NOTE: Keep this mapping explicit and server-side so the client can only
  // choose among approved modes.
  const realtime = (process.env.REALTIME_MODEL_ID || "gpt-realtime").trim() || "gpt-realtime";
  const realtimeMini =
    (process.env.REALTIME_MINI_MODEL_ID || "gpt-realtime-mini").trim() || "gpt-realtime-mini";

  if (mode === "realtime") return realtime;
  return realtimeMini;
}

// Very small, dependency-free rate limiter.
// Note: On serverless, this is per-instance (best-effort), not a global guarantee.
const _rlState = {
  windowStartMs: 0,
  hitsByIp: new Map()
};

function timingSafeEqualStrings(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  const aBuf = Buffer.from(a);
  const bBuf = Buffer.from(b);
  if (aBuf.length !== bBuf.length) return false;
  return crypto.timingSafeEqual(aBuf, bBuf);
}

function getPresentedSharedSecret(req) {
  const headers = req.headers || {};

  const direct = headers["x-token-service-secret"] ?? headers["X-Token-Service-Secret"];
  if (typeof direct === "string" && direct.trim().length > 0) return direct.trim();

  const auth = headers["authorization"] ?? headers["Authorization"];
  if (typeof auth === "string") {
    const m = auth.match(/^Bearer\s+(.+)$/i);
    if (m && m[1] && m[1].trim().length > 0) return m[1].trim();
  }

  return null;
}

function getClientIp(req) {
  const xff = req.headers?.["x-forwarded-for"];
  if (typeof xff === "string" && xff.length > 0) {
    // first IP in the list
    return xff.split(",")[0].trim();
  }
  const realIp = req.headers?.["x-real-ip"];
  if (typeof realIp === "string" && realIp.length > 0) return realIp.trim();
  return "unknown";
}

function rateLimitOk(req) {
  const limitRaw = process.env.REALTIME_TOKEN_RPM;
  const limit = Number.isFinite(Number(limitRaw)) ? Number(limitRaw) : 30;
  const now = Date.now();
  const windowMs = 60_000;

  if (now - _rlState.windowStartMs >= windowMs) {
    _rlState.windowStartMs = now;
    _rlState.hitsByIp.clear();
  }

  const ip = getClientIp(req);
  const current = _rlState.hitsByIp.get(ip) ?? 0;
  if (current >= limit) return { ok: false, retryAfterSeconds: 60 };
  _rlState.hitsByIp.set(ip, current + 1);
  return { ok: true };
}

module.exports = async function handler(req, res) {
  res.setHeader("Cache-Control", "no-store");

  if (req.method !== "GET") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  const expectedSecret = (process.env.TOKEN_SERVICE_SHARED_SECRET || "").trim();
  if (!expectedSecret) {
    console.error("TOKEN_SERVICE_SHARED_SECRET is not configured; refusing to serve realtime token.");
    res.status(503).json({ error: "Service unavailable" });
    return;
  }

  const presentedSecret = getPresentedSharedSecret(req);
  if (!presentedSecret || !timingSafeEqualStrings(presentedSecret, expectedSecret)) {
    res.status(401).json({ error: "Unauthorized" });
    return;
  }

  const rl = rateLimitOk(req);
  if (!rl.ok) {
    res.setHeader("Retry-After", String(rl.retryAfterSeconds ?? 60));
    res.status(429).json({ error: "Rate limit exceeded" });
    return;
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: "Server misconfigured (missing OPENAI_API_KEY)" });
    return;
  }

  const ttlSecondsRaw = process.env.REALTIME_EPHEMERAL_TTL_SECONDS;
  const ttlSeconds = Number.isFinite(Number(ttlSecondsRaw)) ? Number(ttlSecondsRaw) : 600;

  const voice = (process.env.REALTIME_VOICE || "alloy").trim() || "alloy";

  const requestedMode = normalizeMode(req.query?.mode);
  const allowedModes = new Set(["realtimeMini", "realtime"]);
  if (!allowedModes.has(requestedMode)) {
    res.status(400).json({ error: "Invalid mode", allowed: Array.from(allowedModes) });
    return;
  }

  const modelId = resolveRealtimeModelId(requestedMode);

  const topic = clampTopic(req.query?.topic);
  const learner = clampLearner(req.query?.learner);

  let instructions = SYSTEM_INSTRUCTIONS;
  if (learner) instructions += `\n\n${learner}`;
  if (topic) instructions += `\n\nSelected topic: ${topic}`;

  const body = {
    expires_after: {
      anchor: "created_at",
      seconds: Math.max(60, Math.min(ttlSeconds, 3600))
    },
    session: {
      type: "realtime",
      model: modelId,
      instructions,
      audio: {
        output: {
          voice
        }
      }
    }
  };

  try {
    const r = await fetch("https://api.openai.com/v1/realtime/client_secrets", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    });

    const text = await r.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch {
      data = { raw: text };
    }

    if (!r.ok) {
      res.status(r.status).json({ error: "OpenAI error", details: data });
      return;
    }

    // Expected: { value: 'ek_...', expires_at: <unix>, session: {...} }
    res.status(200).json({
      value: data.value,
      expires_at: data.expires_at,
      session: data.session
    });
  } catch (err) {
    res.status(500).json({ error: "Failed to mint client secret" });
  }
}
