import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';

/// Scales the fixed 351.7x715.3 design canvas to fit the real device/window
/// size while preserving aspect ratio and staying fully on-screen.
///
/// Constraining by width alone (an earlier version of this) works fine on
/// an actual phone, where width is always the tight dimension -- but breaks
/// badly on a wide desktop browser window (e.g. `flutter run -d chrome`):
/// scaling to match a ~1300px-wide window blows the canvas up ~4x, and the
/// resulting height massively overflows the actual viewport, so only a
/// tiny, heavily zoomed-in slice of one screen is visible at all. Using the
/// smaller of the width-based and height-based scale factors (like
/// BoxFit.contain) fixes that on any aspect ratio, and centering the result
/// keeps it looking like a phone preview rather than a stretched page.
class OneirScaffold extends StatelessWidget {
  final Widget child;
  const OneirScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // FittedBox, NOT the previous hand-rolled SizedBox + Transform.scale.
    //
    // The old version had a double-scaling bug that broke EVERY screen at
    // once, which is why per-screen layout fixes never visibly changed
    // anything on a real device: the outer SizedBox(kDesignWidth * scale)
    // passes TIGHT constraints down, Transform forwards them unchanged,
    // and Flutter's constraint rules force the inner
    // SizedBox(width: kDesignWidth) to ignore its requested 351.7 width
    // and lay out at kDesignWidth * scale instead (a child cannot
    // override tight incoming constraints). Transform.scale then scaled
    // that already-scaled-up layout AGAIN at paint time, anchored
    // top-left -- so everything painted at scale^2: a few percent too
    // big on a typical phone, spilling off the right and bottom edges
    // (text clipped mid-word at the right edge, bottom buttons pushed
    // off-screen), while looking pixel-perfect at scale == 1.0 in a
    // desktop preview sized exactly to the design canvas.
    //
    // FittedBox does the intended thing in one step: the child lays out
    // at its natural size (the SizedBox below CAN be 351.7x715.3 here,
    // because FittedBox passes unconstrained layout to it), and the
    // single BoxFit.contain paint scale fits it on-screen, centered,
    // with the aspect ratio preserved -- on any screen or window shape.
    //
    // The MediaQuery override pins the system font-size setting to 1.0
    // inside the canvas: this is a fixed-design canvas whose text sizes
    // are already chosen for legibility at canvas scale, and letting a
    // device-level "Large font" setting inflate text inside a
    // fixed-pixel design is exactly how text bursts out of buttons and
    // rows that can't grow with it. (The canvas itself scales with the
    // screen, so text still gets physically larger on larger displays.)
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

/// The standard content wrapper for a screen: [OneirScaffold] + SafeArea +
/// the app's one consistent horizontal margin ([OneirSpace.screenMargin]).
/// New/migrated screens should reach for this instead of hand-rolling their
/// own Padding/SafeArea combination, so screen margins never drift between
/// screens again.
class OneirScreen extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final EdgeInsets? padding;

  const OneirScreen({super.key, required this.child, this.scrollable = false, this.padding});

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.fromLTRB(OneirSpace.screenMargin, OneirSpace.xl, OneirSpace.screenMargin, OneirSpace.xxl);
    return OneirScaffold(
      child: SafeArea(
        child: scrollable
            ? SingleChildScrollView(padding: effectivePadding, child: child)
            : Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}

/// The one reusable card surface for the whole app -- soft rounded
/// corners, a hairline border, a restrained warm-tinted shadow, comfortable
/// internal padding. Existing screens using a raw `Container` with their
/// own one-off `BoxDecoration` should migrate to this so every card in the
/// app reads as the same physical material.
class OneirCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final bool bordered;
  final bool elevated;

  const OneirCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OneirSpace.xl),
    this.color,
    this.radius = OneirRadius.lg,
    this.onTap,
    this.bordered = true,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? OneirColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: bordered ? Border.all(color: OneirColors.border) : null,
        boxShadow: elevated ? OneirElevation.card : null,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: content),
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
      height: 54,
      child: Material(
        color: disabled ? OneirColors.surfaceSunken : OneirColors.accent,
        borderRadius: BorderRadius.circular(OneirRadius.xl),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(OneirRadius.xl),
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
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: OneirColors.text,
          side: const BorderSide(color: OneirColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(OneirRadius.xl)),
        ),
        child: Text(label, style: OneirText.button.copyWith(color: OneirColors.text, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

/// A quiet, text-only tertiary action -- for things like "Skip" or "Not
/// now" that shouldn't compete visually with the primary/secondary
/// buttons above them.
class OneirTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const OneirTextButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: OneirColors.textMuted),
      child: Text(label, style: OneirText.bodySmall.copyWith(fontWeight: FontWeight.w600, color: OneirColors.textMuted)),
    );
  }
}

/// The app's one text-field style -- a soft warm-fill box, no visible
/// border until focused, focus ring in the accent colour. Screens
/// currently building their own `TextField`/`InputDecoration` inline
/// should migrate to this.
class OneirTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool autofocus;
  final int maxLines;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const OneirTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.autofocus = false,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      textAlign: textAlign,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: OneirText.bodyStrong,
      cursorColor: OneirColors.accent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: OneirText.body.copyWith(color: OneirColors.textFaint),
        filled: true,
        fillColor: OneirColors.inputFill,
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(OneirRadius.md), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OneirRadius.md),
          borderSide: const BorderSide(color: OneirColors.accent, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: OneirSpace.lg, vertical: OneirSpace.md + 2),
      ),
    );
  }
}

/// The app's one switch style -- wraps Material's Switch with Vanya's
/// accent colour so every toggle in the app (permissions, protected apps,
/// settings) looks the same, instead of Android's default green/blue.
class OneirSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const OneirSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: OneirColors.accent,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: OneirColors.borderStrong,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}

/// A tiny hand-drawn-feeling decorative mark -- a single soft dot in the
/// accent's lightest tone. Meant to be sprinkled VERY sparingly (one or
/// two per screen, near an illustration or a heading) to give the
/// interface a touch of crafted personality without ever competing with
/// content. Never a repeating pattern or a background texture.
class OneirDot extends StatelessWidget {
  final double size;
  final Color? color;
  const OneirDot({super.key, this.size = 6, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color ?? OneirColors.accentLine, shape: BoxShape.circle),
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
      color: selected ? OneirColors.accentSoft : OneirColors.surface,
      borderRadius: BorderRadius.circular(OneirRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OneirRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: OneirSpace.xl, vertical: OneirSpace.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OneirRadius.lg),
            border: Border.all(color: selected ? OneirColors.accent : OneirColors.border, width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: OneirSpace.md + 2)],
              Expanded(child: Text(label, style: OneirText.bodyStrong)),
              if (selected) const Icon(Icons.check_circle, size: 18, color: OneirColors.accent),
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
          child: Icon(Icons.arrow_back, size: 20, color: onBack == null ? Colors.transparent : OneirColors.text),
        ),
        const SizedBox(width: OneirSpace.md + 2),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: OneirColors.border,
              valueColor: const AlwaysStoppedAnimation(OneirColors.accent),
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(OneirRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(OneirRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(OneirSpace.lg),
          decoration: BoxDecoration(
            color: OneirColors.surface,
            borderRadius: BorderRadius.circular(OneirRadius.lg),
            border: Border.all(color: OneirColors.border),
            boxShadow: OneirElevation.subtle,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: OneirText.title.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: OneirSpace.sm - 2),
                  Text('$currentDay/$totalDays days', style: OneirText.caption),
                  const SizedBox(height: OneirSpace.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(value: progress, minHeight: 3, backgroundColor: OneirColors.border, valueColor: const AlwaysStoppedAnimation(OneirColors.accent)),
                  ),
                ],
              ),
              if (locked)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(OneirRadius.lg),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                      child: Container(
                        color: OneirColors.surface.withOpacity(0.55),
                        alignment: Alignment.center,
                        child: const Icon(Icons.lock_outline, size: 20, color: OneirColors.textMuted),
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
        color: OneirColors.surfaceSunken,
        borderRadius: borderRadius ?? BorderRadius.circular(OneirRadius.md),
        border: Border.all(color: OneirColors.border),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(OneirSpace.md),
        child: Text(description, textAlign: TextAlign.center, style: OneirText.caption),
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
