# The Vanya Intervention Engine

This is the new AI-driven conversational intervention system, built as a
self-contained addition under `lib/intervention/` -- nothing in the rest of
the app (onboarding, home, settings, the existing graduated-tier
interruption screen) was modified to build this.

## What's real and complete in this round

- **Voice (Stage 2, this round)** -- real Android/iOS on-device TTS via
  `flutter_tts`, wrapped behind the same provider-abstraction pattern as
  the AI decision providers (`voice/voice_provider.dart` is the interface;
  `android_tts_provider.dart` the concrete on-device implementation, so a
  premium cloud voice can be added later as a second implementation
  without touching anything else). A real sentence queue
  (`voice_sentence_splitter.dart`) splits every reply into sentence-sized
  chunks with **emotional pauses** between them based on punctuation
  (longer after a question mark, longest after an ellipsis) -- this is what
  makes the brief's "Hi." <pause> "What are you hoping to do?" beat work;
  that specific opener passes an explicit extra pause rather than relying
  on punctuation alone. **Interruption** is handled with a generation
  counter so a superseded utterance can never keep talking after something
  newer starts speaking (the user typing an answer interrupts Vanya
  mid-sentence). **Replay** re-speaks the last full utterance. **Speaking
  rate is adjustable** via a small in-overlay control, persisted across
  sessions. **Caching** is scoped honestly -- see the doc comment in
  `voice_cache.dart` for why full audio-file caching doesn't make sense for
  on-device TTS (no real latency/cost to save) versus where it *would*
  matter (a future network-based premium voice provider).

- **AI decision pipeline** -- a real, working abstraction (`ai/`) with three
  actual API-backed providers (Gemini, OpenAI, Anthropic, each making real
  HTTP calls with the documented request/response shapes for that API) plus
  an **offline heuristic provider** that runs with zero network calls and no
  API key, so the system is never fully non-functional. The offline
  provider is deliberately conservative: keyword-based, defaults to asking
  a clarifying question rather than guessing, and never allows access
  without at least a plausible reason word matching.
- **Structured decisions only** -- `InterventionDecision` mirrors the exact
  JSON shapes from the brief. No provider's raw text is ever touched by the
  UI; a shared `extractJsonObject()` helper defensively strips markdown
  fences/stray text and falls back to a safe `clarify` decision if parsing
  fails for any reason, rather than crashing.
- **The state machine** (`providers/intervention_controller.dart`) -- a real
  Riverpod `Notifier` implementing the exact flow from the brief: detect ->
  speak -> await input -> think -> (clarify, max 2 turns) -> decide -> act
  (start a timed session, or just show the reply and close).
- **Unlock scheduler** (`services/unlock_scheduler.dart`) -- real session
  tracking with persistence (survives the app being killed) and a real
  `Timer` that fires a re-lock callback when a session expires, plus
  extension support for the "not quite done yet" re-lock flow.
- **The conversation UI** -- reuses the existing design system
  (`OneirColors`/`OneirPrimaryButton`/etc.) rather than inventing new visual
  language, per the brief's "do not redesign" instruction.
- **Riverpod added as a new dependency**, scoped to this subsystem only
  (`flutter_riverpod` in pubspec.yaml). The rest of the app still uses
  plain `StatefulWidget`/`setState` and was left untouched -- the brief's
  "assume Riverpod already exists" wasn't actually true of this codebase,
  so it's introduced additively rather than silently assumed or used to
  justify a wider rewrite.

## What's explicitly deferred to the next round (not half-built)

- **Real character animation (this round)** -- `animation/vanya_face_widget.dart`
  is a real, wired-in `CustomPainter` face (ears, blinking eyes, and a mouth
  that genuinely animates through 6 shapes) driven by live
  `VoiceQueueController` state, not a placeholder. Mouth timing is
  estimated (`viseme_timeline.dart`) from vowel-cluster count and a
  words-per-minute model of the current speaking rate, since flutter_tts
  doesn't expose real phoneme timing -- documented in that file's doc
  comment as an intentional approximation, not a bug. Once real Vanya
  artwork exists, this painter's shape-switching logic is exactly what a
  sprite-swap implementation would plug into (same external API:
  isSpeaking/spokenText/speakingRate), so this isn't throwaway work.
- **Voice input (this round)** -- `voice/speech_input_controller.dart` adds
  real speech-to-text (the `speech_to_text` package) so a reply can
  actually be spoken, not just typed -- the brief's "text or voice replies"
  needed both directions; only TTS output existed before. Tapping the mic
  interrupts Vanya (same as typing does), listens, and auto-submits on
  stop. Needs `RECORD_AUDIO` in the manifest (see
  `android_native_files/AndroidManifest_additions.xml`) -- the runtime
  permission dialog itself is handled by the package's own
  `initialize()` call.

Per the brief's own "implement one subsystem completely before moving to
the next, do not leave placeholders" instruction, these are not started
rather than started-and-incomplete:

- **Voice (TTS)** -- async playback, interruption support, queue
  management, provider abstraction for swappable engines.
- **Character animation system** -- idle/blink/listen/think/speak/happy/
  concerned states, viseme-based lip-sync with amplitude fallback. Right
  now the conversation screen shows a plain `OneirAssetPlaceholder` (same
  placeholder convention used everywhere else in the app since real assets
  aren't wired into code yet by explicit earlier instruction).
- **Native wiring for this specific entrypoint** -- `smartInterventionMain`
  exists and is a real, complete Dart entrypoint, but (a) there's no
  `InterventionActivity`-equivalent native Activity routing to it yet
  (the existing `InterruptionActivity` still only launches the old
  `interruptionMain`), and (b) the `onDismiss`/`onLaunchApp` callbacks in
  the conversation screen are stubbed with comments explaining exactly
  what native platform-channel call needs to go there (the same
  `returnHome` / `returnToOpenedApp` pattern the existing
  `InterruptionActivity` already uses) -- not filled in with fake behavior,
  left as a clearly marked real gap.
- **Deciding which flow runs** -- there's no UI yet for choosing between the
  existing graduated-tier flow and this new AI conversation flow (e.g. a
  "Smart Mode" toggle in Settings). Both exist independently right now.

## Configuring a real AI provider

No API key is hardcoded anywhere (a compiled APK is not a safe place to
store one). Configure at build/run time:

```
flutter run --dart-define=AI_PROVIDER=anthropic --dart-define=AI_API_KEY=sk-ant-...
```

`AI_PROVIDER` is one of `gemini` / `openai` / `anthropic` / `offline`
(defaults to `offline` if unset). `AI_MODEL` can override the default model
per provider if needed. With no key configured, the app automatically falls
back to the offline heuristic provider rather than making a doomed request.

## Data-driven quick-reason system (this round)

Addresses a real gap: the AI conversation pipeline is data-driven via the
LLM, but the brief separately wants a fast LOCAL branch with its own four
specific reasons and rule-based (non-AI) responses, sitting alongside the
free-text conversation, not replacing it. See `quickreason/`:

- `quick_reason.dart` -- the four reasons + `InterventionAction` enum
- `intervention_context.dart` -- bundles goal/task/focus/Co-Keeper state so
  responses can be genuinely personalized
- `quick_reason_responses.dart` -- **the actual data-driven rules table**.
  Evolving Vanya's dialogue means editing this list, never touching UI code
- `quick_reason_action_handler.dart` -- every action does something real
  (native return-home/return-to-app calls, an actual snooze write, a real
  Co-Keeper request) -- nothing fakes success

Wired into `intervention_conversation_screen.dart`: chips appear above the
text field only on the initial ask (not on AI follow-up questions), tapping
one speaks the resolved dialogue through the same real lip-sync pipeline
and shows real action buttons.

**Honest gap**: `OneirProtection.startShortBreakSnooze()` writes a real
snooze flag, but `OneirAccessibilityService` (native Kotlin) doesn't read
it yet -- one small check needs adding there (read the same
SharedPreferences key before launching InterruptionActivity) before the
5-minute break is actually *enforced*, not just recorded. Flagged clearly
rather than claimed as done.
