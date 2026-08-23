import 'package:flutter/material.dart';
import '../widgets/vanya_animation.dart';
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
              const SizedBox(height: 16),
              const Expanded(
                flex: 4,
                child: Center(
                  child: VanyaAnimation(width: 235, height: 287),
                ),
              ),
              const SizedBox(height: 16),
              Text("What's your name?", textAlign: TextAlign.center, style: OneirText.heading.copyWith(fontSize: 30, height: 1.2)),
              const SizedBox(height: 24),
              SizedBox(
                width: 224,
                height: 56,
                child: TextField(
                  controller: widget.nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, color: OneirColors.text),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: OneirColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: OneirColors.text, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
