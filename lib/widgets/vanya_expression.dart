import 'package:flutter/material.dart';
import 'shared.dart' show OneirIdleBreathe;

/// Vanya's emotional range -- named for what she's feeling in the moment,
/// not for which screen calls it, so the same "listening" pose belongs
/// wherever she's actually listening rather than being screen-specific.
///
/// Every value maps to a real, already-illustrated asset already sitting
/// unused in assets/images/poses/ or assets/images/*.webp -- this adds no
/// new art, it just gives the app a way to reach for the right existing
/// pose instead of always falling back to the one hello/wave loop
/// ([VanyaAnimation] used unconditionally everywhere until now).
///
/// A few of the brief's named beats (concerned, tired, slightly confused)
/// have no dedicated illustration yet. Those stay as real enum values --
/// so call sites can express the intent now -- but deliberately fall back
/// to [idle] in [_poses] rather than being mapped to a pose that doesn't
/// actually mean that. A wrong-but-present expression is worse than a
/// neutral one; see each fallback's comment below for the reasoning.
enum VanyaExpression {
  /// Default resting state -- the hand-drawn idle/hello loop.
  idle,

  /// Attentive, waiting on the user -- also the closest real match for
  /// the brief's "curious".
  listening,

  /// Weighing something or reading -- also the closest real match for
  /// the brief's "thinking" (vanya_book's down-turned, reflective
  /// posture). A dedicated thinking pose, if drawn later, should replace
  /// this mapping rather than add a new enum value.
  thinking,

  /// Quietly pleased -- deliberately smaller and calmer than [proud]; the
  /// brief is explicit that she "shouldn't constantly smile," so this is
  /// for a mild, passing moment, not a default state.
  happy,

  /// A real win worth marking -- a finished streak, a completed task list.
  proud,

  /// Steady, supportive presence during a task or focus session (closest
  /// real match: vanya_determined's grounded stance).
  encouraging,

  /// A protection-related moment -- enabling or reviewing protected apps.
  protecting,

  /// Something was just unlocked for the user.
  unlocking,

  /// The AI classified the reason as messaging-intent (see
  /// InterventionPromptTemplates) -- a moment about staying connected,
  /// not about being pulled away.
  messaging,

  /// Homework/reading-intent moments.
  reading,

  /// A lighter, more energetic beat. Uses the animated hop loop instead
  /// of a static pose, since playfulness reads better as motion.
  playful,

  /// A calm, settled presence -- not celebrating, not asking anything.
  /// This is the "sitting there with her little tea" moment the brief
  /// describes for the home screen; distinct from [idle] (the
  /// onboarding wave) because the two should not look like the same
  /// greeting repeated everywhere.
  content,

  /// No dedicated art yet -- falls back to [idle]. A worried/uncertain
  /// pose risks reading as Vanya being upset with the user, which cuts
  /// directly against "never shame" -- better to stay neutral until a
  /// pose is drawn that's unambiguously "concerned for you", not "at you".
  concerned,

  /// No dedicated art yet -- falls back to [idle].
  tired,

  /// No dedicated art yet -- falls back to [idle].
  confused,
}

const String _idlePath = 'assets/images/hello_vanya.webp';

const Map<VanyaExpression, String> _poses = {
  VanyaExpression.idle: _idlePath,
  VanyaExpression.listening: 'assets/images/poses/vanya_listening.png',
  VanyaExpression.thinking: 'assets/images/poses/vanya_book.png',
  VanyaExpression.happy: 'assets/images/poses/vanya_happy.png',
  VanyaExpression.proud: 'assets/images/poses/vanya_cheering.png',
  VanyaExpression.encouraging: 'assets/images/poses/vanya_determined.png',
  VanyaExpression.protecting: 'assets/images/poses/vanya_shield.png',
  VanyaExpression.unlocking: 'assets/images/poses/vanya_with_key.png',
  VanyaExpression.messaging: 'assets/images/poses/vanya_envelope.png',
  VanyaExpression.reading: 'assets/images/poses/vanya_book.png',
  VanyaExpression.playful: 'assets/images/hop_vanya.webp',
  VanyaExpression.content: 'assets/images/tea_vanya.webp',
  VanyaExpression.concerned: _idlePath,
  VanyaExpression.tired: _idlePath,
  VanyaExpression.confused: _idlePath,
};

/// Vanya, rendered in whatever [expression] the moment calls for.
///
/// Switching [expression] crossfades between poses (so changing her mood
/// reads as her actually changing it, not a hard cut), and the whole
/// thing sits inside the existing [OneirIdleBreathe] loop so she keeps
/// her subtle up/down breathing motion underneath every pose -- a static
/// illustration was never meant to mean "frozen."
///
/// This is the expression-aware replacement for the old
/// always-idle-only [VanyaAnimation]; that widget now delegates to this
/// one at [VanyaExpression.idle], so every existing call site keeps
/// working unchanged. Reach for [VanyaCharacter] directly at new call
/// sites that know what Vanya should be feeling in that moment.
class VanyaCharacter extends StatelessWidget {
  final VanyaExpression expression;
  final double width;
  final double height;

  const VanyaCharacter({
    super.key,
    required this.expression,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final path = _poses[expression] ?? _idlePath;
    return SizedBox(
      width: width,
      height: height,
      child: OneirIdleBreathe(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Image.asset(
            path,
            key: ValueKey(path),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
