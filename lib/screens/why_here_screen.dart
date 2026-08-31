import 'package:flutter/material.dart';
import '../widgets/vanya_expression.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';

class _ReasonOption {
  final String label;
  final IconData icon;
  const _ReasonOption(this.label, this.icon);
}

const _reasons = [
  _ReasonOption('I want to focus on school', Icons.school_outlined),
  _ReasonOption('I spend too much time on certain apps', Icons.hourglass_bottom),
  _ReasonOption('I want better control of my attention', Icons.center_focus_strong_outlined),
  _ReasonOption('I keep opening apps without thinking', Icons.touch_app_outlined),
  _ReasonOption('I have something important I want to focus on', Icons.flag_outlined),
  _ReasonOption('Something else', Icons.help_outline),
];

/// Step 4 of the 12-step flow -- "Why Are You Here?" A single-select reason
/// picker, styled to match the reference onboarding (progress header +
/// icon/label selection rows + pill button with circular accent).
class WhyHereScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const WhyHereScreen({super.key, required this.onNext, this.onBack});

  @override
  State<WhyHereScreen> createState() => _WhyHereScreenState();
}

class _WhyHereScreenState extends State<WhyHereScreen> {
  String? _selected;

  Future<void> _handleContinue() async {
    if (_selected == null) return;
    await OneirProtection.saveUserReason(_selected!);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OneirProgressHeader(progress: 5 / 18, onBack: widget.onBack),
              const SizedBox(height: OneirSpace.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: OneirSpace.md),
                      // She's genuinely asking and waiting on the answer
                      // that follows -- the same listening pose used
                      // anywhere else Vanya poses a real question.
                      Center(
                        child: VanyaCharacter(expression: VanyaExpression.listening, width: 168, height: 142),
                      ),
                      const SizedBox(height: OneirSpace.lg),
                      Text('What brought you here?',
                          style: OneirText.heading.copyWith(fontSize: 26, letterSpacing: -0.5, height: 1.25)),
                      const SizedBox(height: OneirSpace.sm),
                      Text('This helps Vanya know what to focus on with you.',
                          style: OneirText.caption.copyWith(fontSize: 13, letterSpacing: 0)),
                      const SizedBox(height: OneirSpace.xxl),
                      for (final reason in _reasons) ...[
                        OneirSelectionRow(
                          leading: Icon(reason.icon, size: 20, color: _selected == reason.label ? OneirColors.accent : OneirColors.textMuted),
                          label: reason.label,
                          selected: _selected == reason.label,
                          onTap: () => setState(() => _selected = reason.label),
                        ),
                        const SizedBox(height: OneirSpace.md - 2),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: OneirSpace.lg),
              OneirPrimaryButton(label: "That's it, exactly", onPressed: _selected == null ? null : _handleContinue),
            ],
          ),
        ),
      ),
    );
  }
}
