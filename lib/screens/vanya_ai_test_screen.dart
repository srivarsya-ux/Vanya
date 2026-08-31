import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../local_ai/vanya_ai_service.dart';
import '../local_ai/vanya_ai_provider.dart';
import '../local_ai/model_info.dart';

/// Developer/test screen only -- proves the on-device pipeline works
/// (Flutter app -> local Gemma 4 E2B -> prompt -> generated response)
/// before any of it is wired into Vanya's actual intervention logic.
///
/// Reachable from Settings ("Vanya AI (on-device, dev)"), not part of
/// onboarding. Talks only to [VanyaAiService] -- knows nothing about
/// Gemma, flutter_gemma, or model file formats itself.
class VanyaAiTestScreen extends StatefulWidget {
  const VanyaAiTestScreen({super.key});

  @override
  State<VanyaAiTestScreen> createState() => _VanyaAiTestScreenState();
}

class _VanyaAiTestScreenState extends State<VanyaAiTestScreen> {
  static const _testPrompt =
      'Respond as Vanya, a calm and supportive phone-use companion. Keep your response under 40 words.';

  final _service = VanyaAiService.instance;
  final _promptController = TextEditingController(text: _testPrompt);

  bool _asking = false;
  String? _response;
  String? _askError;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    // Only detach this screen's listener -- deliberately NOT calling
    // _service.dispose(), which would unload the model. The whole point
    // of the shared VanyaAiService.instance singleton is that leaving
    // this screen and coming back doesn't reload (or re-download) the
    // model. See VanyaAiService's doc comment.
    _service.removeListener(_onServiceChanged);
    _promptController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadModel() async {
    await _service.loadModel();
  }

  Future<void> _ask() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _asking || !_service.isReady) return;
    setState(() {
      _asking = true;
      _askError = null;
      _response = null;
    });
    try {
      final reply = await _service.ask(prompt);
      if (!mounted) return;
      setState(() => _response = reply);
    } catch (e) {
      if (!mounted) return;
      setState(() => _askError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OneirColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Vanya AI (on-device, dev)',
          style: OneirText.title,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(OneirSpace.xl, OneirSpace.sm, OneirSpace.xl, OneirSpace.xxxl),
        children: [
          _statusCard(),
          const SizedBox(height: OneirSpace.lg),
          _specCard(),
          const SizedBox(height: OneirSpace.xl),
          Text(
            'Prompt',
            style: OneirText.bodyStrong.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: OneirSpace.sm),
          _promptField(),
          const SizedBox(height: OneirSpace.md + 2),
          OneirPrimaryButton(
            label: _asking ? 'Thinking...' : 'Ask Vanya',
            onPressed: (_service.isReady && !_asking) ? _ask : null,
          ),
          const SizedBox(height: OneirSpace.xl),
          _responseArea(),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final status = _service.status;
    late final String label;
    late final Color dot;
    switch (status) {
      case VanyaAiStatus.notLoaded:
        label = 'Model not loaded';
        dot = OneirColors.textFaint;
        break;
      case VanyaAiStatus.downloading:
        label = 'Downloading model -- ${(_service.downloadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%';
        dot = OneirColors.accent;
        break;
      case VanyaAiStatus.loadingIntoMemory:
        label = 'Loading model into memory...';
        dot = OneirColors.accent;
        break;
      case VanyaAiStatus.ready:
        label = 'Model loaded and ready (${_service.providerName})';
        dot = OneirColors.text;
        break;
      case VanyaAiStatus.error:
        label = 'Failed to load';
        dot = OneirColors.text;
        break;
    }

    return OneirCard(
      padding: const EdgeInsets.all(OneirSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: OneirSpace.sm + 2),
              Expanded(
                child: Text(
                  label,
                  style: OneirText.bodyStrong.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          if (_service.isBusy) ...[
            const SizedBox(height: OneirSpace.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status == VanyaAiStatus.downloading && _service.downloadProgress > 0 ? _service.downloadProgress : null,
                minHeight: 6,
                backgroundColor: OneirColors.inputFill,
                color: OneirColors.accent,
              ),
            ),
          ],
          if (status == VanyaAiStatus.error && _service.errorMessage != null) ...[
            const SizedBox(height: OneirSpace.sm + 2),
            Text(
              _service.errorMessage!,
              style: OneirText.bodySmall.copyWith(color: OneirColors.textMuted, height: 1.4),
            ),
          ],
          const SizedBox(height: OneirSpace.md + 2),
          SizedBox(
            width: double.infinity,
            child: OneirSecondaryButton(
              label: status == VanyaAiStatus.ready
                  ? 'Loaded'
                  : status == VanyaAiStatus.error
                      ? 'Retry loading model'
                      : _service.isBusy
                          ? 'Loading...'
                          : 'Load model',
              onPressed: (_service.isReady || _service.isBusy) ? null : _loadModel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _specCard() {
    return OneirCard(
      padding: const EdgeInsets.all(OneirSpace.lg),
      color: OneirColors.background,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this model',
            style: OneirText.bodyStrong.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: OneirSpace.sm - 2),
          Text(
            'Gemma 4 E2B, on-device via LiteRT-LM. ~${VanyaLocalModelInfo.approxDownloadBytes ~/ (1024 * 1024)}MB one-time '
            'download, no account or API key needed to fetch it. ${VanyaLocalModelInfo.recommendedDeviceSpec}',
            style: OneirText.caption.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _promptField() {
    return OneirTextField(
      controller: _promptController,
      maxLines: 4,
      hintText: 'Type a prompt for Vanya...',
    );
  }

  Widget _responseArea() {
    if (_asking) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: OneirSpace.xxl),
        child: Center(child: CircularProgressIndicator(color: OneirColors.accent)),
      );
    }
    if (_askError != null) {
      return OneirCard(
        padding: const EdgeInsets.all(OneirSpace.lg),
        child: Text(
          _askError!,
          style: OneirText.bodySmall.copyWith(color: OneirColors.textMuted, height: 1.4),
        ),
      );
    }
    if (_response != null) {
      return OneirCard(
        padding: const EdgeInsets.all(OneirSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vanya's response",
              style: OneirText.bodyStrong.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: OneirSpace.sm),
            Text(
              _response!,
              style: OneirText.body.copyWith(color: OneirColors.text, height: 1.5),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
