import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';

/// Step 08 -- widget setup, now showing the 3 REAL widget concepts
/// (android_native_files/widgets/) rather than an unrelated placeholder
/// card style. Same honest note as AddWidgetsScreen (Settings' version of
/// this): Android widgets are always user-placed, never programmatic --
/// this screen can only preview and guide, not install one directly.
class WidgetSetupScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const WidgetSetupScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OneirProgressHeader(progress: 15 / 18, onBack: onBack),
              const SizedBox(height: 16),
              Text('One last thing.',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 26, letterSpacing: -0.4, color: OneirColors.text)),
              const SizedBox(height: 6),
              Text("Let's put me somewhere you'll actually see me.",
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: OneirColors.textMuted)),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _WidgetPreview(
                        title: "Today's Focus",
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _widgetLabel('TODAY'),
                          const SizedBox(height: 8),
                          _taskRow('Finish science assignment'),
                          _taskRow('Practice piano'),
                          _taskRow('Read 10 pages'),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      _WidgetPreview(
                        title: 'Quick Focus',
                        child: Column(children: [
                          _widgetLabel('FOCUS'),
                          const SizedBox(height: 4),
                          Text('25 min', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700, fontSize: 18, color: OneirColors.text)),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      _WidgetPreview(
                        title: 'Vanya Daily Check-in',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Vanya', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 13, color: OneirColors.text)),
                          const SizedBox(height: 4),
                          Text("What's one thing you want to get done today?",
                              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: OneirColors.textMuted)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: OneirColors.accent, borderRadius: BorderRadius.circular(16)),
                            child: const Text('+ Add task', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 11, color: Colors.white)),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OneirPrimaryButton(label: 'Continue', onPressed: onNext),
            ],
          ),
        ),
      ),
    );
  }

  Widget _widgetLabel(String text) =>
      Text(text, style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.6, color: OneirColors.textFaint));

  Widget _taskRow(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(Icons.circle_outlined, size: 12, color: OneirColors.border),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: OneirColors.text)),
        ]),
      );
}

class _WidgetPreview extends StatelessWidget {
  final String title;
  final Widget child;
  const _WidgetPreview({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 12, color: OneirColors.textFaint)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: OneirColors.cardNeutral, borderRadius: BorderRadius.circular(18)),
          child: child,
        ),
      ],
    );
  }
}
