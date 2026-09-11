import 'package:flutter/material.dart';

import '../../models/vanya_decision.dart';
import 'intervention_controller.dart';

/// Placeholder for the future Vanya intervention experience — deliberately
/// plain Material UI, not the polished onboarding design system. Renders
/// entirely off [InterventionController]; it holds no business logic of
/// its own beyond the reason text field and the phase-driven layout below.
class InterventionScreen extends StatefulWidget {
  const InterventionScreen({super.key, required this.controller, this.onResolved});

  final InterventionController controller;

  /// Called once the user has acted on a decision (and, for temporary
  /// access, after the grant is created) — the moment this intervention is
  /// truly done. Defaults to `Navigator.pop(decision)` when null, which is
  /// what the manual/dev trigger path (a normal pushed route with
  /// something to pop back to) wants. The Android-launched path
  /// (`InterventionActivity`, nothing meaningful to pop to) passes its own
  /// callback that resolves the task-stack outcome natively instead.
  final Future<void> Function(VanyaDecision decision)? onResolved;

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen> {
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _reasonController.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  Future<void> _submit() async {
    widget.controller.updateReason(_reasonController.text);
    await widget.controller.submitReason();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final ctx = controller.context;

    return Scaffold(
      appBar: AppBar(title: const Text('Intervention (wireframe)')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Placeholder for future Vanya artwork.
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '[ Vanya artwork placeholder ]',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),
              if (ctx != null) ...[
                Text(
                  '${ctx.currentTime.hour.toString().padLeft(2, '0')}:${ctx.currentTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 8),
                _LabeledValue(label: 'PROTECTED APP', value: ctx.protectedApp.displayName),
                const SizedBox(height: 12),
                if (ctx.currentTask != null) ...[
                  _LabeledValue(label: 'CURRENT TASK', value: ctx.currentTask!.title),
                  const SizedBox(height: 4),
                  Text(
                    '${ctx.currentTask!.startTime.format(context)} – ${ctx.currentTask!.endTime.format(context)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ] else
                  const Text(
                    "You don't have anything planned right now.",
                    style: TextStyle(fontSize: 16),
                  ),
              ],
              const SizedBox(height: 24),
              switch (controller.phase) {
                InterventionPhase.awaitingReason => _ReasonForm(
                    controller: _reasonController,
                    hasCurrentTask: ctx?.currentTask != null,
                    appName: ctx?.protectedApp.displayName ?? 'this',
                    onSubmit: _submit,
                  ),
                InterventionPhase.reasoning => const _ThinkingState(),
                InterventionPhase.decided => _DecisionState(
                    decision: controller.decision!,
                    onFinish: (grantAccess) async {
                      if (grantAccess) await controller.confirmTemporaryAccess();
                      final decision = controller.decision!;
                      if (widget.onResolved != null) {
                        await widget.onResolved!(decision);
                      } else {
                        if (!context.mounted) return;
                        Navigator.of(context).pop(decision);
                      }
                    },
                  ),
                InterventionPhase.error => _ErrorState(
                    message: controller.errorMessage,
                    onRetry: controller.retry,
                    onBack: () async {
                      // Reasoning failed — never fall back to unlimited
                      // access. Same safe outcome as a REDIRECT either way
                      // this is resolved.
                      if (widget.onResolved != null) {
                        await widget.onResolved!(
                          const VanyaDecision(
                            type: VanyaDecisionType.redirect,
                            message: "Vanya couldn't make a decision right now.",
                          ),
                        );
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                InterventionPhase.idle => const SizedBox.shrink(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonForm extends StatelessWidget {
  const _ReasonForm({
    required this.controller,
    required this.hasCurrentTask,
    required this.appName,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool hasCurrentTask;
  final String appName;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          hasCurrentTask
              ? 'Why do you need to open this?'
              : 'Do you still want to open $appName?',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Why do you need to open this?',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onSubmit, child: const Text('Submit')),
      ],
    );
  }
}

class _ThinkingState extends StatelessWidget {
  const _ThinkingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Vanya is thinking...', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

/// [onFinish] receives whether temporary access should actually be granted
/// — only true when the user tapped "Continue" on an allowTemporaryAccess
/// decision, so the grant is created at that explicit moment, not the
/// instant the decision arrived.
class _DecisionState extends StatelessWidget {
  const _DecisionState({required this.decision, required this.onFinish});

  final VanyaDecision decision;
  final void Function(bool grantAccess) onFinish;

  @override
  Widget build(BuildContext context) {
    final isTemporaryAccess = decision.type == VanyaDecisionType.allowTemporaryAccess;
    final actionLabel = switch (decision.type) {
      VanyaDecisionType.redirect => 'Back to my task',
      VanyaDecisionType.deny => 'Back to my task',
      VanyaDecisionType.allowTemporaryAccess => 'Continue',
      VanyaDecisionType.allow => 'Continue',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VANYA',
                style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(decision.message, style: const TextStyle(fontSize: 16)),
              if (isTemporaryAccess) ...[
                const SizedBox(height: 8),
                Text(
                  '${decision.temporaryAccessDuration!.inMinutes} minutes',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => onFinish(isTemporaryAccess),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry, required this.onBack});

  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "Vanya couldn't make a decision right now.",
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Try again')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onBack, child: const Text('Back')),
      ],
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, letterSpacing: 1, color: Colors.black54, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
