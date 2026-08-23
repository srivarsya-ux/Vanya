import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

/// Synthesizes text to an actual WAV file on disk instead of speaking it
/// live -- this is what makes real audio-based lip-sync possible at all.
/// `FlutterTts.speak()` plays through the OS's TTS engine directly with no
/// accessible audio buffer or position callback; `synthesizeToFile()` is a
/// separate, well-supported flutter_tts capability that renders to a real
/// file first, which [LipSyncAnalyzer] can then read and VanyaTalkingCharacter
/// can play back with a real position stream.
///
/// One file per call, written to the app's temp directory and named by a
/// timestamp so concurrent/rapid calls can't collide.
///
/// IMPLEMENTATION NOTE (fixed a real compile error here): the first version
/// of this class used `_tts.setSynthCompletionHandler(...)`, which doesn't
/// actually exist on this flutter_tts version -- a real "The method isn't
/// defined" compile error, not a guess that happened to be wrong in some
/// harmless way. Rather than guess at the "correct" callback name (same
/// failure mode, just delayed to the next build), this waits for the file
/// to actually appear on disk instead -- avoids depending on any specific
/// callback API surface, and also sidesteps a subtler risk: flutter_tts
/// may share one native instance across multiple `FlutterTts()` objects,
/// so this class and AndroidTtsProvider (used for live speech elsewhere)
/// registering their own completion handlers on what might be the same
/// underlying engine could otherwise clobber each other.
///
/// NOTE (honest platform caveat): flutter_tts's synthesizeToFile writes
/// into the app's own storage directory using the given file NAME, and
/// different Android/plugin versions have varied slightly in exactly
/// where that lands. This class checks the expected location and returns
/// null (rather than a wrong/guessed path) if the file never appears
/// there within the timeout -- callers must treat null as "no audio
/// available this turn" and degrade gracefully (e.g. show text only),
/// not crash.
class TtsFileSynthesizer {
  final FlutterTts _tts = FlutterTts();

  Future<String?> synthesizeToFile(String text, {required double rate, required double pitch}) async {
    if (text.trim().isEmpty) return null;

    try {
      await _tts.setSpeechRate(rate.clamp(0.1, 1.0).toDouble());
      await _tts.setPitch(pitch.clamp(0.5, 2.0).toDouble());

      final dir = await getTemporaryDirectory();
      final fileName = 'vanya_tts_${DateTime.now().microsecondsSinceEpoch}.wav';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      await _tts.synthesizeToFile(text, fileName);

      // Poll for the file actually existing and having stopped growing
      // (write finished) instead of depending on a completion callback --
      // checked every 150ms, up to a generous ceiling so a slow render on
      // an older device doesn't get cut off prematurely.
      const pollInterval = Duration(milliseconds: 150);
      const maxAttempts = 100; // ~15 seconds total
      int? lastSize;
      int stableCount = 0;

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        await Future.delayed(pollInterval);
        if (!await file.exists()) continue;

        final size = await file.length();
        if (size > 0 && size == lastSize) {
          stableCount++;
          // Two consecutive stable reads (300ms of no growth) is treated
          // as "the engine finished writing," since there's no explicit
          // completion signal to rely on here.
          if (stableCount >= 2) return filePath;
        } else {
          stableCount = 0;
        }
        lastSize = size;
      }

      // Timed out -- if a real (non-empty) file did appear, use it even
      // without confirming it fully stabilized, rather than throwing away
      // audio that likely did finish rendering.
      if (await file.exists() && await file.length() > 0) return filePath;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    // FlutterTts has no explicit dispose(); nothing to release here beyond
    // letting the instance be garbage collected.
  }
}
