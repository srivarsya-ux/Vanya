import 'package:flutter/material.dart';

import '../../../design_system/vanya_colors.dart';
import '../../../design_system/vanya_spacing.dart';
import '../../../design_system/vanya_typography.dart';
import '../../../widgets/vanya_glass_button.dart';
import '../../../widgets/vanya_glass_card.dart';
import '../widgets/onboarding_scaffold.dart';

/// Screen — User's name. Asked early and in one plain sentence, per the
/// spec: not a labeled "Name" form field, just Vanya asking a question.
class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({
    super.key,
    required this.initialName,
    required this.onContinue,
    required this.onBack,
    required this.progressIndicator,
  });

  final String? initialName;
  final ValueChanged<String> onContinue;
  final VoidCallback onBack;
  final Widget progressIndicator;

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  late final TextEditingController _controller;
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialName ?? '';
    _controller = TextEditingController(text: _value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vanyaColors;
    final trimmed = _value.trim();

    return OnboardingScaffold(
      onBack: widget.onBack,
      progressIndicator: widget.progressIndicator,
      bottomAction: VanyaGlassButton(
        label: 'Continue',
        onPressed: trimmed.isEmpty ? null : () => widget.onContinue(trimmed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: VanyaSpacing.huge),
          VanyaGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before we start,\nwhat should I call you?',
                  style: VanyaTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: VanyaSpacing.xl),
                Container(
                  padding: const EdgeInsets.only(bottom: VanyaSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.separator, width: 1.5),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: trimmed.isEmpty
                        ? null
                        : (_) => widget.onContinue(trimmed),
                    onChanged: (value) => setState(() => _value = value),
                    style: VanyaTypography.display.copyWith(
                      color: colors.textPrimary,
                      fontSize: 28,
                    ),
                    cursorColor: colors.accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Your first name',
                      hintStyle: VanyaTypography.display.copyWith(
                        color: colors.textTertiary,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
