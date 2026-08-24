import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../widgets/vanya_expression.dart';
import '../native/oneir_protection.dart';
import '../intervention/widgets/intervention_conversation_screen.dart';
import '../intervention/models/intervention_decision.dart';

/// Onboarding step that lets a new user actually talk to Vanya before
/// they finish setup, instead of watching a scripted mockup of what she'd
/// say.
///
/// This replaces the old InteractiveDemoScreen (lib/screens/
/// interactive_demo_screen.dart, still present but unused), which played
/// back three fixed lines with a canned "Still want Instagram?" question
/// no matter what the user would actually say. This screen instead opens
/// the same [InterventionConversationScreen] used for a real protected-app
/// interruption -- same AI decision pipeline (see
/// lib/intervention/providers/intervention_controller.dart), same voice
/// and lip-synced character, same free-text handling. Whatever the user
/// says here is genuinely sent through the AI provider configured via
/// AI_PROVIDER (see ai_provider_config.dart) and gets a real, specific
/// reply -- not a canned line matched against a keyword list.
///
/// A distinct demo package name ("com.oneir.onboarding_demo", not a real
/// installed app) keeps this fully isolated from the user's actual
/// protected-app list and any real unlock sessions.
class AiInterventionDemoScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const AiInterventionDemoScreen({super.key, required this.onNext, this.onBack});

  @override
  State<AiInterventionDemoScreen> createState() => _AiInterventionDemoScreenState();
}

class _AiInterventionDemoScreenState extends State<AiInterventionDemoScreen> {
  static const _demoPackageName = 'com.oneir.onboarding_demo';

  String _name = '';
  bool _tried = false;
  InterventionDecisionType? _lastOutcome;

  @override
  void initState() {
    super.initState();
    OneirProtection.loadUserName().then((name) {
      if (mounted) setState(() => _name = name);
    });
  }

  Future<void> _openDemo() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => InterventionConversationScreen(
          appLabel: 'Instagram',
          packageName: _demoPackageName,
          onDismiss: () => Navigator.of(context).pop(InterventionDecisionType.redirect),
          onLaunchApp: () => Navigator.of(context).pop(InterventionDecisionType.allow),
        ),
      ),
    ).then((outcome) {
      if (!mounted) return;
      setState(() {
        _tried = true;
        _lastOutcome = outcome as InterventionDecisionType?;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _name.isEmpty ? 'Try talking to Vanya' : 'Try talking to Vanya, $_name';

    return OneirScaffold(
      child: SafeArea(
        child: Padding(
          // Matches every other onboarding step's padding/header pattern
          // (ProtectedAppsScreen at 6/18, this step at 7/18, CoKeeperIntro
          // at 8/18) -- this screen previously used a one-off top inset and
          // a bespoke back button with no progress bar, which made it look
          // like a different screen dropped into the middle of the flow.
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OneirProgressHeader(progress: 7 / 18, onBack: widget.onBack),
              const SizedBox(height: 24),
              Text(
                greeting,
                style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 26, color: OneirColors.text),
              ),
              const SizedBox(height: 12),
              Text(
                "This is the real Vanya -- not a script. Tap below, pretend you just opened a protected app, and say whatever you'd actually say. She'll answer for real.",
                style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, height: 1.5, color: OneirColors.textMuted),
              ),
              const Spacer(),
              // A real, expression-aware Vanya instead of a generic
              // graphic_eq icon in a circle -- she's attentive/listening
              // before the demo runs, then reacts to how it actually went:
              // pleased if the AI allowed it, steady/encouraging if it
              // redirected. Neither reaction shames the user either way,
              // matching the "never a lecture" rule the demo copy itself
              // already promises below.
              Center(
                child: VanyaCharacter(
                  expression: !_tried
                      ? VanyaExpression.listening
                      : (_lastOutcome == InterventionDecisionType.allow
                          ? VanyaExpression.happy
                          : VanyaExpression.encouraging),
                  width: 140,
                  height: 140,
                ),
              ),
              const SizedBox(height: 24),
              if (_tried) ...[
                Center(
                  child: Text(
                    _lastOutcome == InterventionDecisionType.allow
                        ? "That's what it feels like when Vanya thinks you have a real reason -- quick and no lecture."
                        : "That's what it feels like when Vanya gently redirects you -- still no lecture.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textFaint, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              OneirPrimaryButton(label: _tried ? 'Talk to her again' : 'Try it now', onPressed: _openDemo),
              const SizedBox(height: 10),
              OneirSecondaryButton(label: _tried ? 'Continue' : 'Skip for now', onPressed: widget.onNext),
            ],
          ),
        ),
      ),
    );
  }
}
