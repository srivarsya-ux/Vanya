import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';

class _Principle {
  final String title;
  final String line;
  final IconData icon;
  const _Principle(this.title, this.line, this.icon);
}

const _principles = [
  _Principle('Co-Keeper', "You aren't relying entirely on willpower.", Icons.diversity_1_outlined),
  _Principle('Widgets', 'Your goals stay visible instead of disappearing behind your apps.', Icons.widgets_outlined),
  _Principle('Intervention', "When you try to open a protected app, I don't just throw up a wall.", Icons.pan_tool_outlined),
  _Principle('The Pause', 'I give you a moment to decide whether you actually want to continue.', Icons.hourglass_bottom),
];

/// Step 09 -- the "aha" screen: makes Oneir's actual mechanism (not just
/// its features) immediately understandable in four short lines.
class WhyVanyaWorksScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const WhyVanyaWorksScreen({super.key, required this.onNext, this.onBack});

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OneirProgressHeader(progress: 16 / 18, onBack: onBack),
              const SizedBox(height: 16),
              Text('Why Vanya works',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 26, letterSpacing: -0.4, color: OneirColors.text)),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in _principles) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(color: OneirColors.cardNeutral, borderRadius: BorderRadius.circular(10)),
                              alignment: Alignment.center,
                              child: Icon(p.icon, size: 18, color: OneirColors.text),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.title, style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 14.5, color: OneirColors.text)),
                                  const SizedBox(height: 3),
                                  Text(p.line, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, height: 1.4, color: OneirColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
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
}
