/**
 * Server-side proxy for Vanya's AI intervention decisions.
 *
 * Why this exists: lib/intervention/ai/anthropic_provider.dart (and its
 * Gemini/OpenAI siblings) call the model provider directly from the
 * Flutter client, which means the API key has to travel inside the
 * compiled app (via --dart-define) to make that call. That's fine for
 * local development but not safe to ship -- anyone can pull an API key
 * back out of an APK. This Cloud Function moves the actual model call
 * server-side: the app calls this function (no secret involved), and the
 * function calls Anthropic using a key that only exists in Firebase's
 * secret store.
 *
 * Deploy with:
 *   firebase functions:secrets:set ANTHROPIC_API_KEY
 *   cd functions && npm install && firebase deploy --only functions:decideIntervention
 *
 * The Dart-side counterpart is
 * lib/intervention/ai/cloud_function_provider.dart, selected via
 * AI_PROVIDER=cloud (see ai_provider_config.dart) -- that's now the
 * recommended provider setting for anything beyond local testing.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

// Mirrors lib/intervention/services/prompt_templates.dart exactly -- this
// duplication (Dart client-side providers vs. this Node proxy) is
// intentional rather than an oversight: the client-side providers stay
// functional for local dev/testing without deploying anything, while this
// is the one used for anything that ships. If Vanya's personality or the
// JSON contract changes, both copies need updating -- there wasn't a
// clean way to share source between a Dart package and a Cloud Function
// without adding a build step, and duplicating ~30 lines of prompt text
// seemed like the lesser evil.
const SYSTEM_PROMPT = `You are Vanya, a gentle, warm companion inside a phone app called Oneir that helps someone stay away from apps they've asked to be protected from.

A protected app was just opened. The user has explained why. Decide whether to allow it, ask a clarifying question, or gently redirect them.

Your personality: warm, patient, thoughtful, encouraging, calm, emotionally intelligent.
Never: shame, guilt-trip, lecture, manipulate, sound like a parent, sound like a therapist.

Instead of "No," prefer "Can you tell me a little more?"
Instead of "You shouldn't," prefer "I'm wondering whether opening this will help with what you want right now."

Classify the user's intent into exactly one of: messaging, homework, research, work, shopping, banking, navigation, photography, emergency, habitScrolling, entertainment, other.

If you are not confident what they mean (confidence below about 0.6) and fewer than 2 clarifying questions have been asked yet, ask exactly one short, non-interrogating follow-up question instead of deciding.

If you do decide, estimate an appropriate unlock duration in minutes using judgment, not a fixed table -- roughly: a single message needs very little time (2-3 min), a group reply a bit more (5-6 min), uploading homework more still (6-8 min), watching an assigned lecture significantly more (around 45 min), a specific shopping errand around 10 min. Add a small buffer. Never ask the user how long they need.

Respond with ONLY a single JSON object, no other text, matching exactly one of these shapes:

For an allow decision:
{"decision":"allow","confidence":0.94,"intent":"messaging","reason":"Replying to a teacher","estimatedMinutes":5,"reply":"I'll open this for about five minutes so you can send that message."}

For a redirect decision:
{"decision":"redirect","confidence":0.88,"intent":"habitScrolling","reason":"Habit scrolling","reply":"It sounds like you're looking for a quick distraction. Would you like to finish today's task first?"}

For a clarify decision:
{"decision":"clarify","confidence":0.4,"intent":"other","reason":"Unclear what they need","clarifyingQuestion":"What are you hoping to do in there?","reply":"What are you hoping to do in there?"}`;

function buildUserPrompt(appLabel, history) {
  const lines = (history || []).map(
    (turn) => `${turn.role === "user" ? "User" : "Vanya"}: ${turn.text}`
  );
  return `Protected app: ${appLabel}\nConversation so far:\n${lines.join("\n")}`;
}

// Same defensive extraction as lib/intervention/services/json_extraction.dart
// -- models occasionally wrap the JSON in a code fence or add stray prose
// despite the system prompt saying not to.
function extractJsonObject(raw) {
  let text = (raw || "").trim();
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) text = fenceMatch[1].trim();
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end === -1 || end < start) return null;
  try {
    return JSON.parse(text.slice(start, end + 1));
  } catch (_) {
    return null;
  }
}

function fallbackDecision(reason) {
  return {
    decision: "clarify",
    confidence: 0,
    reason,
    reply: "I'm having a little trouble thinking right now -- could you tell me again what you need?",
    clarifyingQuestion: "Could you tell me again what you need?",
  };
}

/**
 * Callable function: { appLabel: string, history: [{role, text}], clarificationTurnsUsed: number }
 * -> the same decision JSON shape InterventionDecision.fromJson expects.
 *
 * Every possible free-text reply the user speaks or types is handled here
 * -- there's no keyword list or fixed branch tree on either side of this
 * call, the model reads the whole conversation and decides fresh each
 * turn, same as the client-side providers it replaces.
 */
exports.decideIntervention = onCall(
  { secrets: [anthropicApiKey], timeoutSeconds: 20, cors: true },
  async (request) => {
    const { appLabel, history, clarificationTurnsUsed } = request.data || {};

    if (!appLabel || typeof appLabel !== "string") {
      throw new HttpsError("invalid-argument", "appLabel is required.");
    }
    if (!Array.isArray(history)) {
      throw new HttpsError("invalid-argument", "history must be an array.");
    }

    const apiKey = anthropicApiKey.value();
    if (!apiKey) {
      // Server misconfigured (secret not set) -- fail soft into the same
      // clarify fallback the Dart providers use, rather than a raw 500.
      return fallbackDecision("Server is not configured with an Anthropic API key yet.");
    }

    const userPrompt = buildUserPrompt(appLabel, history);

    let response;
    try {
      response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-3-5-haiku-20241022",
          max_tokens: 300,
          temperature: 0.4,
          system: SYSTEM_PROMPT,
          messages: [{ role: "user", content: userPrompt }],
        }),
        signal: AbortSignal.timeout(15000),
      });
    } catch (e) {
      return fallbackDecision(`Anthropic request error: ${e}`);
    }

    if (!response.ok) {
      return fallbackDecision(`Anthropic request failed (${response.status})`);
    }

    const body = await response.json();
    const text = body?.content?.[0]?.text;
    if (!text) return fallbackDecision("Empty Anthropic response");

    const parsed = extractJsonObject(text);
    if (!parsed) return fallbackDecision("Could not parse Anthropic response as JSON");

    return parsed;
  }
);
