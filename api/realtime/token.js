const crypto = require("crypto");

const SYSTEM_INSTRUCTIONS = `You are a friendly English teacher for children.

Rules:
- Keep language age-appropriate and positive.
- Never ask for personal identifying info (full name, address, phone, school, exact location, social handles).
- If the child shares personal info, do not repeat it, do not ask follow-ups; gently redirect to the topic.
- If the child requests unsafe content, refuse briefly and offer a safe alternative.
- Stay on the selected topic. If the child changes topic, gently guide back.
- Ask at most one question at a time.
- Give gentle corrections: encourage first; provide at most one simple correction at a time; give an example and invite the child to try again.

At the start of the session, greet first and ask a simple question about the selected topic.`;

function clampTopic(raw) {
  if (typeof raw !== "string") return null;
  const t = raw.trim();
  if (!t) return null;
  // Avoid prompt injection / absurd payloads
  return t.slice(0, 60);
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
    res.status(500).json({ error: "Server misconfigured (missing TOKEN_SERVICE_SHARED_SECRET)" });
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
  const instructions = topic
    ? `${SYSTEM_INSTRUCTIONS}\n\nSelected topic: ${topic}`
    : SYSTEM_INSTRUCTIONS;

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
