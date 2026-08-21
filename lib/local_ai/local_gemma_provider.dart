import 'package:flutter_gemma/flutter_gemma.dart';
// flutter_gemma split into a core package + opt-in engine packages (see
// its changelog's "modular package split" entry) -- LiteRtLmEngine (the
// .litertlm-format engine, as opposed to the MediaPipe .task engine) is
// exported from this opt-in package specifically, not from flutter_gemma
// itself, since a caller who only wants MediaPipe models shouldn't have
// to pull in LiteRT-LM at all.
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'model_info.dart';
import 'vanya_ai_provider.dart';

/// [VanyaAiProvider] implementation backed by Google's Gemma 4 E2B model
/// running fully on-device via the `flutter_gemma` / `flutter_gemma_litertlm`
/// packages (the current, maintained Flutter integration for Google's
/// LiteRT-LM on-device inference runtime as of this writing).
///
/// This is the ONE file that knows flutter_gemma's actual API surface --
/// every call into that package lives here, not scattered through the app.
/// That isolation is deliberate: flutter_gemma is a young, fast-moving
/// package (multiple breaking API rewrites in its recent changelog), and
/// its exact method signatures were pieced together from its current
/// pub.dev listing, changelog, and fluttergemma.dev docs rather than by
/// compiling against it directly -- there is no network path to pub.dev
/// from the sandbox this was written in, so `flutter pub get` has not
/// been run against this code. See the delivery notes for exactly what
/// that means and what to check first.
///
/// No cloud AI, no API key, nothing sent over the network at inference
/// time -- the only network call this class makes is the one-time model
/// *download* in [loadModel], which fetches the .litertlm weights file
/// (see [VanyaLocalModelInfo]) so it can be loaded and run locally
/// afterwards. Every [ask] call after that runs the model entirely on the
/// device's own CPU/GPU, no server involved.
class LocalGemmaProvider implements VanyaAiProvider {
  @override
  String get providerName => 'gemma-4-e2b-on-device';

  InferenceModel? _model;
  InferenceChat? _chat;
  bool _loading = false;

  @override
  bool get isReady => _model != null && _chat != null;

  @override
  Future<void> loadModel({void Function(double progress)? onProgress}) async {
    if (_loading) {
      throw StateError('loadModel() is already in progress');
    }
    if (isReady) return; // already loaded -- don't reload/redownload

    _loading = true;
    try {
      // One-time engine registration. Only the LiteRT-LM engine is
      // requested -- we don't need the MediaPipe (.task) engine, RAG, or
      // embeddings for this proof-of-concept, so those extra optional
      // packages/params are deliberately left out.
      await FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]);

      // fromNetwork() is expected to skip re-downloading if the file is
      // already cached from a previous run -- if that assumption turns
      // out to be wrong once this actually runs against the real
      // package, the fix is one line here, not a redesign.
      //
      // withProgress's callback reports an int 0-100 percentage (confirmed
      // against a real build: passing it straight through as a double
      // failed to compile with "argument type 'int' can't be assigned to
      // parameter type 'double'" at this exact line), not a 0.0-1.0
      // fraction -- VanyaAiService/the test screen both expect a 0.0-1.0
      // fraction throughout, hence the /100.0 here rather than in every
      // caller.
      await FlutterGemma.installModel(modelType: ModelType.gemma4)
          .fromNetwork(VanyaLocalModelInfo.downloadUrl)
          .withProgress((progress) => onProgress?.call(progress / 100.0))
          .install();

      final model = await FlutterGemma.getActiveModel(maxTokens: 512);
      final chat = await model.createChat();

      _model = model;
      _chat = chat;
    } catch (e) {
      // Make sure a half-finished load doesn't leave us in a state where
      // isReady is inconsistently true/false.
      _model = null;
      _chat = null;
      throw Exception(_describeLoadFailure(e));
    } finally {
      _loading = false;
    }
  }

  @override
  Future<String> ask(String prompt) async {
    final chat = _chat;
    if (chat == null) {
      throw StateError('ask() called before loadModel() completed');
    }
    try {
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await chat.generateChatResponse();
      final text = response.toString().trim();
      if (text.isEmpty) {
        throw Exception('Vanya\'s local model returned an empty response.');
      }
      return text;
    } catch (e) {
      throw Exception('Local inference failed: ${_shortMessage(e)}');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _model?.close();
    } catch (_) {
      // Best-effort cleanup -- nothing useful to do if native teardown
      // itself throws.
    } finally {
      _model = null;
      _chat = null;
    }
  }

  String _describeLoadFailure(Object e) {
    final msg = _shortMessage(e);
    final lower = msg.toLowerCase();
    if (lower.contains('memory') || lower.contains('oom')) {
      return "This device doesn't have enough free memory to load Gemma 4 E2B "
          '(needs roughly ${VanyaLocalModelInfo.approxRunningRamBytes ~/ (1024 * 1024)}MB free while running). '
          'Close other apps and try again, or test on a device with more RAM.';
    }
    if (lower.contains('network') || lower.contains('connection') || lower.contains('timeout')) {
      return 'Could not download the model -- check the network connection and try again. '
          "The download is roughly ${VanyaLocalModelInfo.approxDownloadBytes ~/ (1024 * 1024)}MB, "
          'so a slow or interrupted connection is the most likely cause.';
    }
    if (lower.contains('abi') || lower.contains('architecture') || lower.contains('unsupported')) {
      return 'This device or build is not compatible with on-device Gemma inference '
          '(${VanyaLocalModelInfo.recommendedDeviceSpec}).';
    }
    return "Vanya's local model failed to load: $msg";
  }

  String _shortMessage(Object e) {
    final s = e.toString();
    return s.length > 300 ? '${s.substring(0, 300)}...' : s;
  }
}
