import 'package:flutter/material.dart';
import '../widgets/vanya_expression.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';

class NameEntryScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final TextEditingController nameController;
  const NameEntryScreen({super.key, required this.onNext, required this.nameController, this.onBack});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _handleContinue() async {
    await OneirProtection.saveUserName(widget.nameController.text.trim());
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final trimmedName = widget.nameController.text.trim();
    final hasName = trimmedName.isNotEmpty;
    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            children: [
              OneirProgressHeader(progress: 4 / 18, onBack: widget.onBack),
              const SizedBox(height: OneirSpace.lg),
              // She's waiting on an answer -- the same attentive pose used
              // anywhere else Vanya is genuinely listening for a reply.
              const Expanded(
                flex: 4,
                child: Center(
                  child: VanyaCharacter(expression: VanyaExpression.listening, width: 235, height: 287),
                ),
              ),
              const SizedBox(height: OneirSpace.lg),
              Text("What's your name?", textAlign: TextAlign.center, style: OneirText.heading.copyWith(fontSize: 30, height: 1.2)),
              const SizedBox(height: OneirSpace.xxl),
              SizedBox(
                width: 224,
                height: 56,
                child: TextField(
                  controller: widget.nameController,
                  textAlign: TextAlign.center,
                  style: OneirText.bodyStrong.copyWith(fontSize: 16, color: OneirColors.text),
                  cursorColor: OneirColors.accent,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: OneirColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(OneirRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(OneirRadius.md),
                      borderSide: const BorderSide(color: OneirColors.accent, width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: OneirSpace.lg),
                  ),
                ),
              ),
              const Spacer(),
              OneirPrimaryButton(
                label: hasName ? 'Nice to meet you, $trimmedName' : 'Continue',
                onPressed: hasName ? _handleContinue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
