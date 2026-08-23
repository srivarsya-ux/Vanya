# Universal Vanya Lip-Sync System

Implements the brief exactly: `DialogueGenerator -> VoiceGenerator ->
LipSyncAnalyzer -> LipSyncTimeline -> VanyaTalkingCharacter`, entirely
local, no paid API, works with any dialogue.

## Files

- `lip_sync_timeline.dart` -- `MouthCueShape` (Rhubarb's CLOSED/A/B/C/D/E-F
  naming, used exactly), `MouthCue`, `LipSyncTimeline`. The data model
  matches the brief's JSON example (`{"start":..,"end":..,"mouth":".."}`).
- `lip_sync_analyzer.dart` -- **this is the real analysis step**, not text
  guessing. Parses a WAV file's actual PCM samples (pure Dart, no native
  binary), computes an RMS loudness envelope in ~45ms windows, classifies
  each window into a mouth shape by loudness tier (with per-window
  variation so louder stretches don't all render as one repeated shape),
  merges cues, and enforces a minimum hold duration so short cues can't
  cause visible flicker. Honest scope note: this is amplitude-based, not
  phoneme recognition -- see the file's own doc comment for exactly why
  that's the right tradeoff here (Rhubarb's real binary needs native
  Android integration; this is the brief's own permitted fallback).
- `tts_file_synthesizer.dart` -- renders text to an actual WAV file via
  `flutter_tts`'s `synthesizeToFile`, instead of the old `.speak()` call
  that plays live with no accessible audio or position. This file existing
  is *why* real analysis and real position-sync are possible at all.
- `vanya_face_painter.dart` -- the shared vector rendering (ears, blinking
  eyes, mouth). The mouth is rendered from two continuous scalars
  (openness, roundness) rather than switching between hard-coded shapes,
  so it can be smoothly tweened between any two mouth states -- this is
  what makes the "no rapid flicking" requirement actually true rather than
  just documented.
- `vanya_talking_character.dart` -- **the main deliverable**,
  `VanyaTalkingCharacter(audio:, lipSyncData:, isSpeaking:)` exactly as
  specified. Owns its own `AudioPlayer`, plays the given file, and on every
  position tick looks up `lipSyncData.shapeAt(position)` and animates
  toward it over ~90ms. Exposes `idle`/`speaking`/`finished` via an
  optional `onStateChanged` callback. Body/head/position never move --
  only the mouth (and an independent idle blink) animate.

## Wired into the real app, not a demo

- `VoiceQueueController.speakWithLipSync()` (new method, alongside the
  original `speak()`) replaces the per-segment `.speak()` call with
  synthesize-to-file -> analyze -> expose `(audioPath, timeline)` in
  state. Sentence splitting, emotional pauses, and interruption-safety are
  all unchanged -- only *how* each sentence is voiced changed.
- `InterventionController`'s five speaking call sites (opener, clarify,
  decided reply, re-lock prompt, more-time request) all call
  `speakWithLipSync` now.
- `intervention_conversation_screen.dart` renders `VanyaTalkingCharacter`
  fed from `voiceState.currentAudioPath` / `currentLipSyncTimeline` /
  `isSpeaking`, replacing the old text-estimation `VanyaFaceWidget` there.

## What still uses the old text-estimation system

`animation/vanya_face_widget.dart` and `animation/viseme_timeline.dart`
(the earlier, cruder "guess mouth shape from word count" version) are
**left in place, unused, not deleted** -- nothing currently references
them after this change. Safe to delete once you've confirmed the new
system works on a real device; kept for now in case anything needs to
fall back to it.

## Honest gaps / what to verify on a real device

- **`synthesizeToFile`'s exact output path** varies slightly across
  flutter_tts/Android versions. `TtsFileSynthesizer` checks the expected
  temp-directory location and returns `null` (triggering a graceful
  fall-back to live speech for that one sentence, no lip-sync but audible)
  if the file isn't there -- this needs a real-device test to confirm the
  happy path actually finds the file where expected on your target
  Android versions.
- **Sequencing timing** (`speakWithLipSync`'s `Future.delayed` matching
  the analyzed clip's duration) is a close approximation of real playback
  duration, not a guaranteed exact match -- the mouth itself is
  frame-accurate (driven by the widget's own live position stream), but
  segment-to-segment sequencing could drift by tens of milliseconds if the
  TTS engine's actual playback speed doesn't exactly match the WAV's
  declared duration.
- **No architecture assumption was forced in** -- Riverpod was already
  present in `lib/intervention/` from an earlier round; this stays
  consistent with that rather than introducing it fresh or ripping it out.

## Testing checklist (per the brief's own "after implementation" list)

Manual, since there's no Flutter SDK in this environment to run these:
short sentence, long sentence, a dynamically-varied AI response, confirm
mouth returns to CLOSED after audio ends (`_stopAndReturnToClosed`,
called both on natural completion and on `interrupt()`), confirm no crash
on synthesis/playback failure (both wrapped in try/catch with graceful
fallback), confirm the character stays visually aligned (position/size
never change, only the painter's mouth parameters).
