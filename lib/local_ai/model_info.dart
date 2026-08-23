/// Everything about *which* on-device model Vanya's local AI brain
/// downloads and runs, kept in one place so swapping models later means
/// editing this file (plus [LocalGemmaProvider] if the runtime format
/// changes too) rather than hunting through the UI or service code.
///
/// This is a proof-of-concept model choice, not a final one -- see the
/// top-level doc comment in `vanya_ai_service.dart` for the architecture
/// that makes it swappable.
class VanyaLocalModelInfo {
  const VanyaLocalModelInfo._();

  /// litert-community's LiteRT-LM conversion of Google's Gemma 4 E2B
  /// (instruction-tuned, ~2B effective parameters, mixed 2/4/8-bit
  /// quantization). This mirror is not gated behind a Hugging Face
  /// click-through license acceptance the way the original
  /// `google/gemma-*` checkpoints are -- it downloads with a plain HTTPS
  /// GET, no Hugging Face account or token needed.
  ///
  /// IMPORTANT license note: the mirror repo's own metadata lists
  /// "apache-2.0", but that most plausibly covers the conversion
  /// tooling/wrapper, not a relicense of Google's underlying Gemma
  /// weights -- Google's Gemma Terms of Use govern the weights themselves
  /// regardless of who rehosts the converted file, and that license does
  /// not permit sublicensing under different terms. Treat this build as
  /// still bound by the Gemma Terms of Use. Read them yourself at
  /// https://ai.google.dev/gemma/terms before shipping anything beyond
  /// this dev/test screen -- this is not legal advice and this comment is
  /// not a substitute for reading the actual terms.
  ///
  /// Source: https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm
  static const String downloadUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';

  /// The general CPU/GPU build. The same repo also hosts NPU-specific
  /// variants (Tensor G5, Qualcomm, Intel) and a smaller "-web" build --
  /// deliberately not using those here since we can't know the target
  /// chipset ahead of time and want the widest-compatible file for a
  /// first proof-of-concept.
  static const String fileName = 'gemma-4-E2B-it.litertlm';

  /// Full-precision-on-disk download size. Actual resident memory while
  /// running is lower (see [approxRunningRamBytes]) because of the mixed
  /// low-bit quantization, but the file downloaded to disk is still this
  /// size.
  static const int approxDownloadBytes = 2583 * 1024 * 1024; // ~2.58 GB

  /// Rough CPU-backend resident memory figure from Google's published
  /// Gemma 4 benchmarks (mid-range Android reference device). Used only
  /// for the human-readable spec text shown in the test screen, not for
  /// any runtime enforcement -- Flutter has no reliable cross-device "how
  /// much RAM do I actually have" API without adding another native
  /// plugin, which felt like scope creep for a proof-of-concept screen.
  static const int approxRunningRamBytes = 1733 * 1024 * 1024; // ~1.7 GB

  /// libLiteRtLm.so (the native library flutter_gemma_litertlm depends on
  /// for .litertlm inference) requires Bionic syscalls that don't exist
  /// before Android 11 -- this is a hard floor, not a soft recommendation.
  /// android/app/build.gradle(.kts) is patched to enforce this by
  /// tool/wire_native.py; see wire_min_sdk() there.
  static const int minSdkVersion = 30; // Android 11

  /// Human-readable device guidance shown in the test screen. Deliberately
  /// conservative -- Google's own benchmark hardware (mid/high-end recent
  /// phones) ran comfortably, but this repo has no way to test against
  /// low-end devices, so "6GB+ RAM, arm64-v8a" is a reasonable floor
  /// rather than a verified one.
  static const String recommendedDeviceSpec =
      'Android 11 (API 30) or newer, 64-bit (arm64-v8a) CPU, 6GB+ total device RAM recommended. '
      'x86_64/32-bit devices and anything below Android 11 cannot run this model at all -- '
      'flutter_gemma_litertlm has no fallback path for them.';
}
