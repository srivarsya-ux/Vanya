import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';
import '../native/oneir_apps.dart';
import '../intervention/voice/voice_queue_controller.dart';

/// Fallback list used only when the native "oneir/apps" channel returns
/// nothing (e.g. running via `flutter run -d web-server` / desktop preview,
/// where there's no PackageManager to ask) -- on a real Android device this
/// is never used; the real installed-app list takes over instead.
const _fallbackApps = [
  InstalledApp(label: 'Instagram', packageName: 'com.instagram.android'),
  InstalledApp(label: 'TikTok', packageName: 'com.zhiliaoapp.musically'),
  InstalledApp(label: 'YouTube', packageName: 'com.google.android.youtube'),
  InstalledApp(label: 'Snapchat', packageName: 'com.snapchat.android'),
  InstalledApp(label: 'X', packageName: 'com.twitter.android'),
  InstalledApp(label: 'Reddit', packageName: 'com.reddit.frontpage'),
];

class ProtectedAppsScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final bool isStandalone;
  const ProtectedAppsScreen({super.key, required this.onNext, this.onBack, this.isStandalone = false});

  @override
  ConsumerState<ProtectedAppsScreen> createState() => _ProtectedAppsScreenState();
}

class _ProtectedAppsScreenState extends ConsumerState<ProtectedAppsScreen> {
  List<InstalledApp> _apps = [];
  bool _loading = true;
  bool _saving = false;
  final Set<String> _selected = {}; // package names

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await OneirApps.getInstalledApps();
    final previouslyProtected = await OneirProtection.loadProtectedApps();
    if (!mounted) return;
    setState(() {
      _apps = apps.isNotEmpty ? apps : _fallbackApps;
      _selected.addAll(previouslyProtected.isNotEmpty
          ? previouslyProtected
          : _apps.take(2).map((a) => a.packageName)); // sensible default: pre-select the first couple
      _loading = false;
    });
  }

  void _toggle(String packageName) {
    setState(() {
      if (_selected.contains(packageName)) {
        _selected.remove(packageName);
      } else {
        _selected.add(packageName);
      }
    });
  }

  Future<void> _handleContinue() async {
    setState(() => _saving = true);
    await OneirProtection.saveProtectedApps(_selected.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    ref.read(voiceQueueControllerProvider.notifier).speakWithLipSync(
          "Got them. I'll help you create some distance between you and them.",
        );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isStandalone) ...[
                  Text('Which apps pull you in?',
                      style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: 26, letterSpacing: -0.5, height: 1.25, color: OneirColors.text)),
                  const SizedBox(height: 8),
                  Text('Choose the apps you want Vanya to help you protect. You can change this anytime.',
                      style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, height: 1.5, color: OneirColors.textFaint)),
                  const SizedBox(height: 24),
                ],
                for (final app in _apps) ...[
                  _AppRow(app: app, isOn: _selected.contains(app.packageName), onTap: () => _toggle(app.packageName)),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );

    final footer = Column(
      children: [
        Text('${_selected.length} app${_selected.length == 1 ? '' : 's'} protected',
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textFaint)),
        const SizedBox(height: 12),
        OneirPrimaryButton(
          label: _saving ? 'Saving...' : (widget.isStandalone ? 'Save' : "Let's protect these"),
          onPressed: (_selected.isEmpty || _saving || _loading) ? null : _handleContinue,
        ),
      ],
    );

    if (widget.isStandalone) {
      return Scaffold(
        backgroundColor: OneirColors.background,
        appBar: AppBar(
          backgroundColor: OneirColors.background,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: OneirColors.text), onPressed: () => Navigator.of(context).pop()),
          title: const Text('Protected Apps', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, color: OneirColors.text)),
        ),
        body: Column(
          children: [
            Expanded(child: content),
            Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), child: footer),
          ],
        ),
      );
    }

    // SafeArea + a normal Column, matching every sibling onboarding screen --
    // this used to be a Stack of hardcoded Positioned offsets (top: 20,
    // bottom: 108/40) instead, which ignores the device's actual status
    // bar/gesture-nav insets. On a phone whose safe-area insets differ from
    // whatever this was eyeballed against, that meant the progress header
    // could sit closer to (or under) the status bar than every other step
    // in the same onboarding flow -- exactly the kind of screen-to-screen
    // misalignment this was fixed for.
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              OneirProgressHeader(progress: 6 / 18, onBack: widget.onBack),
              const SizedBox(height: 16),
              Expanded(child: content),
              const SizedBox(height: 16),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  final InstalledApp app;
  final bool isOn;
  final VoidCallback onTap;
  const _AppRow({required this.app, required this.isOn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isOn ? OneirColors.text : const Color(0xFFE5E5E5), width: isOn ? 1.5 : 1),
          color: isOn ? const Color(0xFFF7F6FC) : const Color(0xFFFAFAFA),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: app.iconBytes != null
                    ? Image.memory(app.iconBytes!, width: 36, height: 36, fit: BoxFit.cover)
                    : Container(
                        width: 36, height: 36,
                        color: OneirColors.text,
                        alignment: Alignment.center,
                        child: Text(
                          app.label.isNotEmpty ? app.label[0].toUpperCase() : '?',
                          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Text(app.label, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w500, color: OneirColors.text)),
            ]),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 24,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isOn ? OneirColors.text : const Color(0xFFDADADA)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18, height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
