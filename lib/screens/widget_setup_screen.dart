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
          padding: const EdgeInsets.fromLTRB(OneirSpace.screenMargin, OneirSpace.xl, OneirSpace.screenMargin, OneirSpace.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OneirProgressHeader(progress: 15 / 18, onBack: onBack),
              const SizedBox(height: OneirSpace.lg),
              Text('One last thing.', style: OneirText.heading.copyWith(fontSize: 26)),
              const SizedBox(height: OneirSpace.sm - 2),
              Text("Let's put me somewhere you'll actually see me.", style: OneirText.body),
              const SizedBox(height: OneirSpace.xl),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _WidgetPreview(
                        title: "Today's Focus",
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _widgetLabel('TODAY'),
                          const SizedBox(height: OneirSpace.sm),
                          // Placeholder rows, not invented specific tasks --
                          // this screen runs during onboarding, before the
                          // Tasks screen even exists to the user yet, so
                          // there's no real task to show. Naming fake ones
                          // ("Finish science assignment") read as if the app
                          // already knew something about them; a plain
                          // placeholder is honest about being a preview of
                          // the widget's *shape*, not its content.
                          _taskRow('Your first task will show up here'),
                          _taskRowPlaceholder(),
                          _taskRowPlaceholder(),
                        ]),
                      ),
                      const SizedBox(height: OneirSpace.md + 2),
                      _WidgetPreview(
                        title: 'Quick Focus',
                        child: Column(children: [
                          _widgetLabel('FOCUS'),
                          const SizedBox(height: OneirSpace.xs),
                          Text('25 min', style: OneirText.title.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      const SizedBox(height: OneirSpace.md + 2),
                      _WidgetPreview(
                        title: 'Vanya Daily Check-in',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Vanya', style: OneirText.title.copyWith(fontSize: 13)),
                          const SizedBox(height: OneirSpace.xs),
                          Text("What's one thing you want to get done today?", style: OneirText.bodySmall.copyWith(fontSize: 12)),
                          const SizedBox(height: OneirSpace.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: OneirSpace.md, vertical: OneirSpace.sm - 2),
                            decoration: BoxDecoration(color: OneirColors.accent, borderRadius: BorderRadius.circular(OneirRadius.md)),
                            child: Text('+ Add task', style: OneirText.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.white)),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: OneirSpace.lg),
              OneirPrimaryButton(label: 'Continue', onPressed: onNext),
            ],
          ),
        ),
      ),
    );
  }

  Widget _widgetLabel(String text) => Text(text, style: OneirText.eyebrow.copyWith(fontSize: 10, letterSpacing: 0.6));

  Widget _taskRow(String label) => Padding(
        padding: const EdgeInsets.only(bottom: OneirSpace.xs),
        child: Row(children: [
          Icon(Icons.circle_outlined, size: 12, color: OneirColors.border),
          const SizedBox(width: OneirSpace.sm - 2),
          Text(label, style: OneirText.caption.copyWith(fontSize: 12, fontStyle: FontStyle.italic)),
        ]),
      );

  /// An empty task row -- just the checkbox outline and a faint dashed
  /// line standing in for text, rather than a second invented task name.
  Widget _taskRowPlaceholder() => Padding(
        padding: const EdgeInsets.only(bottom: OneirSpace.xs),
        child: Row(children: [
          Icon(Icons.circle_outlined, size: 12, color: OneirColors.border),
          const SizedBox(width: OneirSpace.sm - 2),
          Container(width: 90, height: 10, decoration: BoxDecoration(color: OneirColors.border, borderRadius: BorderRadius.circular(4))),
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
        Text(title, style: OneirText.eyebrow.copyWith(fontSize: 12, letterSpacing: 0)),
        const SizedBox(height: OneirSpace.sm - 2),
        OneirCard(
          padding: const EdgeInsets.all(OneirSpace.md + 2),
          color: OneirColors.surfaceSunken,
          radius: OneirRadius.lg,
          bordered: false,
          elevated: false,
          child: child,
        ),
      ],
    );
  }
}
