import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'lip_sync_timeline.dart';

/// Analyzes a real synthesized WAV file's audio and produces a
/// [LipSyncTimeline] -- this is the "LIP-SYNC ANALYSIS" step the brief
/// asks for, done locally with pure Dart math (no Rhubarb binary, no
/// network call, no paid API).
///
/// How it works, honestly: this is NOT phoneme recognition (that needs a
/// real speech model). It's an amplitude-envelope analysis -- the audio is
/// split into short windows, each window's loudness (RMS) is measured, and
/// windows are classified into mouth shapes by relative loudness tier, with
/// enough variation between tiers that the mouth visibly moves through
/// different shapes rather than just opening/closing with volume. This is
/// exactly the kind of practical local fallback the brief's own "FALLBACK"
/// section explicitly permits when running Rhubarb's real binary on
/// Android isn't practical.
class LipSyncAnalyzer {
  LipSyncAnalyzer._();

  static const double _windowSeconds = 0.045;
  static const double _minCueSeconds = 0.075;

  static Future<LipSyncTimeline> analyze(String wavFilePath, {required double fallbackDuration}) async {
    try {
      final file = File(wavFilePath);
      if (!await file.exists()) return LipSyncTimeline.silent(fallbackDuration);

      final bytes = await file.readAsBytes();
      final wav = _parseWav(bytes);
      if (wav == null || wav.samples.isEmpty) return LipSyncTimeline.silent(fallbackDuration);

      return _buildTimeline(wav);
    } catch (_) {
      return LipSyncTimeline.silent(fallbackDuration);
    }
  }

  static _WavData? _parseWav(Uint8List bytes) {
    if (bytes.length < 44) return null;
    final byteData = ByteData.sublistView(bytes);

    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') return null;

    int channels = 1;
    int sampleRate = 16000;
    int bitsPerSample = 16;
    int dataOffset = -1;
    int dataLength = 0;

    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = byteData.getUint32(offset + 4, Endian.little);

      if (chunkId == 'fmt ') {
        channels = byteData.getUint16(offset + 10, Endian.little);
        sampleRate = byteData.getUint32(offset + 12, Endian.little);
        bitsPerSample = byteData.getUint16(offset + 22, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = offset + 8;
        dataLength = chunkSize;
      }
      offset += 8 + chunkSize + (chunkSize.isOdd ? 1 : 0);
      if (dataOffset != -1 && channels != 0) break;
    }

    if (dataOffset == -1 || bitsPerSample != 16) return null;
    final end = min(dataOffset + dataLength, bytes.length);
    final sampleCount = (end - dataOffset) ~/ 2;
    final samples = Int16List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      samples[i] = byteData.getInt16(dataOffset + i * 2, Endian.little);
    }

    return _WavData(samples: samples, sampleRate: sampleRate, channels: channels);
  }

  static LipSyncTimeline _buildTimeline(_WavData wav) {
    final samplesPerChannelWindow = ((_windowSeconds * wav.sampleRate).round()) * wav.channels;
    final totalDuration = wav.samples.length / wav.channels / wav.sampleRate;
    if (samplesPerChannelWindow <= 0 || totalDuration <= 0) {
      return LipSyncTimeline.silent(totalDuration <= 0 ? 0.5 : totalDuration);
    }

    final rmsValues = <double>[];
    for (var start = 0; start < wav.samples.length; start += samplesPerChannelWindow) {
      final end = min(start + samplesPerChannelWindow, wav.samples.length);
      double sumSquares = 0;
      for (var i = start; i < end; i++) {
        final normalized = wav.samples[i] / 32768.0;
        sumSquares += normalized * normalized;
      }
      final rms = sqrt(sumSquares / (end - start));
      rmsValues.add(rms);
    }
    if (rmsValues.isEmpty) return LipSyncTimeline.silent(totalDuration);

    final peak = rmsValues.reduce(max);
    final normalized = peak <= 0.0001 ? rmsValues.map((_) => 0.0).toList() : rmsValues.map((v) => (v / peak).clamp(0.0, 1.0)).toList();

    final rawShapes = <MouthCueShape>[];
    for (var i = 0; i < normalized.length; i++) {
      rawShapes.add(_classify(normalized[i], i));
    }

    final cues = <MouthCue>[];
    var cueStartWindow = 0;
    for (var i = 1; i <= rawShapes.length; i++) {
      final atEnd = i == rawShapes.length;
      if (atEnd || rawShapes[i] != rawShapes[cueStartWindow]) {
        final startTime = cueStartWindow * _windowSeconds;
        final endTime = min(i * _windowSeconds, totalDuration);
        cues.add(MouthCue(start: startTime, end: endTime, shape: rawShapes[cueStartWindow]));
        cueStartWindow = i;
      }
    }

    final smoothed = _enforceMinimumHold(cues, totalDuration);
    return LipSyncTimeline(cues: smoothed, totalDuration: totalDuration);
  }

  static MouthCueShape _classify(double loudness, int windowIndex) {
    if (loudness < 0.06) return MouthCueShape.closed;
    final variety = [MouthCueShape.b, MouthCueShape.c, MouthCueShape.a, MouthCueShape.d, MouthCueShape.ef];
    if (loudness < 0.18) return MouthCueShape.b;
    if (loudness < 0.35) return variety[windowIndex % 3];
    if (loudness < 0.6) return variety[(windowIndex % 3) + 1];
    return variety[2 + (windowIndex % 3)];
  }

  static List<MouthCue> _enforceMinimumHold(List<MouthCue> cues, double totalDuration) {
    if (cues.length <= 1) return cues;
    final result = <MouthCue>[];
    for (final cue in cues) {
      final duration = cue.end - cue.start;
      if (duration < _minCueSeconds && result.isNotEmpty) {
        final prev = result.removeLast();
        result.add(MouthCue(start: prev.start, end: cue.end, shape: prev.shape));
      } else {
        result.add(cue);
      }
    }
    return result;
  }
}

class _WavData {
  final Int16List samples;
  final int sampleRate;
  final int channels;
  const _WavData({required this.samples, required this.sampleRate, required this.channels});
}
