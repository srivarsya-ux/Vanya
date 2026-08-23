import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';

/// Scales the fixed 351.7x715.3 design canvas to fit the real device/window
/// size while preserving aspect ratio and staying fully on-screen.
class OneirScaffold extends StatelessWidget {
  final Widget child;
  const OneirScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // FittedBox, NOT a hand-rolled SizedBox + Transform.scale (that combo
    // double-scales: outer SizedBox(kDesignWidth * scale) forces tight
    // constraints down, so the inner SizedBox can't lay out at its
    // requested 351.7 width and instead lays out at kDesignWidth * scale,
    // then Transform.scale paints THAT again at scale -- everything ends
    // up scale^2, clipping text off the right edge and pushing buttons
    // off the bottom on a real phone).
    //
    // FittedBox does it in one step: the child lays out at its natural
    // 351.7x715.3 size, and a single BoxFit.contain paint scale fits it
    // on-screen, centered, aspect-ratio preserved, on any screen shape.
    //
    // The MediaQuery override pins system font-size scaling to 1.0 inside
    // the canvas -- this is a fixed-design canvas whose text sizes are
    // already chosen for legibility at canvas scale; letting a device
    // "Large font" setting inflate text here is how text bursts out of
    // buttons and rows that can't grow with it.
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: OneirColors.background,
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.noScaling),
            child: SizedBox(
              width: kDesignWidth,
              height: kDesignHeight,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class OneirPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const OneirPrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: disabled ? const Color(0xFFE0E0E0) : OneirColors.accent,
        borderRadius: BorderRadius.circular(28),
        elevation: disabled ? 0 : 3,
        shadowColor: OneirColors.accent.withOpacity(0.35),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OneirText.button.copyWith(color: disabled ? OneirColors.textFaint : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class OneirSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const OneirSecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: OneirColors.text,
          side: const BorderSide(color: OneirColors.border),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(label, style: OneirText.button.copyWith(color: OneirColors.text)),
      ),
    );
  }
}

/// Subtle idle breathing loop for static (non-animated) Vanya poses, matching
/// the locked React behavior for screens where no animated clip was
/// available. Respects the platform's reduce-motion setting.
class OneirIdleBreathe extends StatefulWidget {
  final Widget child;
  const OneirIdleBreathe({super.key, required this.child});

  @override
  State<OneirIdleBreathe> createState() => _OneirIdleBreatheState();
}

class _OneirIdleBreatheState extends State<OneirIdleBreathe> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dy = -4 * (1 - (2 * t - 1).abs());
        final scale = 1 + 0.015 * (1 - (2 * t - 1).abs());
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// A selectable row with a leading icon and label, matching the reference
/// style (e.g. "Male / Female / Other / Prefer not to say"). Used anywhere
/// the user picks one option from a short list -- reason pickers, contact
/// method, relationship, etc.
class OneirSelectionRow extends StatelessWidget {
  final Widget? leading;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const OneirSelectionRow({super.key, this.leading, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAEAEA) : const Color(0xFFF5F5F7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? OneirColors.text : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w500, color: OneirColors.text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top-of-screen progress bar + back button, matching the reference
/// onboarding style -- a thin filled line showing how far through the flow
/// the user is, with a back arrow to the left of it.
class OneirProgressHeader extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final VoidCallback? onBack;

  const OneirProgressHeader({super.key, required this.progress, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Icon(Icons.arrow_back, size: 22, color: onBack == null ? Colors.transparent : OneirColors.text),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFE5E5E5),
              valueColor: const AlwaysStoppedAnimation(OneirColors.text),
            ),
          ),
        ),
      ],
    );
  }
}

/// Matches the "Streaks"-style widget-gallery card from the reference: a
/// named streak/task with a day-count label, a progress bar, and (when
/// locked) a translucent overlay with a padlock -- used for the app's
/// actual home-screen widget gallery / Focus Time and Statistics previews.
class OneirStreakWidgetCard extends StatelessWidget {
  final String title;
  final int currentDay;
  final int totalDays;
  final bool locked;
  final VoidCallback? onTap;

  const OneirStreakWidgetCard({
    super.key,
    required this.title,
    required this.currentDay,
    required this.totalDays,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalDays == 0 ? 0.0 : currentDay / totalDays;
    return Material(
      color: const Color(0xFFF5F5F7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 13, color: OneirColors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text('$currentDay/$totalDays days', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, color: OneirColors.textFaint)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(value: progress, minHeight: 3, backgroundColor: const Color(0xFFE5E5E5), valueColor: const AlwaysStoppedAnimation(OneirColors.text)),
              ),
            ],
          ),
          if (locked)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(
                    color: Colors.white.withOpacity(0.4),
                    alignment: Alignment.center,
                    child: const Icon(Icons.lock, size: 20, color: Colors.black45),
                  ),
                ),
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }
}

/// Universal placeholder for any Vanya illustration/animation not yet
/// supplied -- a plain gray box labeled with what it's meant to show, so
/// nothing in the app displays real character art until assets are
/// provided.
class OneirAssetPlaceholder extends StatelessWidget {
  final String description;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const OneirAssetPlaceholder({
    super.key,
    required this.description,
    this.width = 160,
    this.height = 160,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0D0D0)),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, color: Color(0xFF9A9A9A)),
        ),
      ),
    );
  }
}

/// Pinned action area near the
/// bottom of every screen.
class OneirBottomBar extends StatelessWidget {
  final List<Widget> children;
  const OneirBottomBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 32,
      right: 32,
      bottom: 40,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}
