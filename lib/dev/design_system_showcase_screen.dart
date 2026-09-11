import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_system/vanya_colors.dart';
import '../design_system/vanya_spacing.dart';
import '../design_system/vanya_typography.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../widgets/vanya_glass_button.dart';
import '../widgets/vanya_glass_card.dart';
import '../widgets/vanya_glass_chip.dart';
import '../widgets/vanya_glass_dialog.dart';
import '../widgets/vanya_glass_navigation.dart';
import '../widgets/vanya_glass_progress.dart';
import '../widgets/vanya_glass_sheet.dart';
import '../widgets/vanya_glass_toggle.dart';

/// TEMPORARY — Phase 2 deliverable only.
///
/// A single screen that puts every design-system token and every glass
/// component on screen at once, over a stand-in "illustrated environment"
/// (soft blurred color blobs, since no Vanya artwork assets exist yet), so
/// the whole system can be judged on a real device before any feature
/// screens are built on top of it. Delete this screen once Phase 3+ feature
/// screens make it redundant.
class DesignSystemShowcaseScreen extends StatefulWidget {
  const DesignSystemShowcaseScreen({super.key});

  @override
  State<DesignSystemShowcaseScreen> createState() => _DesignSystemShowcaseScreenState();
}

class _DesignSystemShowcaseScreenState extends State<DesignSystemShowcaseScreen> {
  final Set<String> _selectedChips = {'Focus'};
  bool _toggleValue = true;
  double _progress = 0.35;
  int _navIndex = 0;
  ThemeMode _themeMode = ThemeMode.light;

  static const _chipLabels = ['Focus', 'Sleep', 'School', 'Creativity', 'Being present'];
  static const _navItems = [
    VanyaNavItem(icon: Icons.home_rounded, label: 'Home'),
    VanyaNavItem(icon: Icons.timer_rounded, label: 'Focus'),
    VanyaNavItem(icon: Icons.auto_awesome_rounded, label: 'Moments'),
    VanyaNavItem(icon: Icons.pets_rounded, label: 'Vanya'),
    VanyaNavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return _ThemedShowcase(
      themeMode: _themeMode,
      onToggleTheme: () => setState(() {
        _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      }),
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.vanyaColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _IllustratedBackdrop(colors: colors),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                VanyaSpacing.lg,
                VanyaSpacing.lg,
                VanyaSpacing.lg,
                120,
              ),
              children: [
                _sectionLabel(context, 'Vanya design system'),
                Text(
                  'A little room for you.',
                  style: VanyaTypography.display.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: VanyaSpacing.xxs),
                Text(
                  'Every token and glass component on one screen, over a stand-in illustrated backdrop.',
                  style: VanyaTypography.secondary.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: VanyaSpacing.lg),
                VanyaGlassButton(
                  label: 'Preview: Onboarding flow',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingFlow()),
                  ),
                ),
                const SizedBox(height: VanyaSpacing.sm),
                VanyaGlassButton(
                  label: 'Preview: Home (functional core)',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                ),
                const SizedBox(height: VanyaSpacing.xxl),

                _sectionLabel(context, 'Typography'),
                VanyaGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Display · Fraunces', style: VanyaTypography.display.copyWith(color: colors.textPrimary)),
                      const SizedBox(height: VanyaSpacing.sm),
                      Text('Title · Fraunces', style: VanyaTypography.title.copyWith(color: colors.textPrimary)),
                      const SizedBox(height: VanyaSpacing.sm),
                      Text('Section title · Fraunces', style: VanyaTypography.sectionTitle.copyWith(color: colors.textPrimary)),
                      const SizedBox(height: VanyaSpacing.sm),
                      Text('Body · Inter — the quiet, readable voice Vanya uses most.', style: VanyaTypography.body.copyWith(color: colors.textPrimary)),
                      const SizedBox(height: VanyaSpacing.xs),
                      Text('Secondary · Inter', style: VanyaTypography.secondary.copyWith(color: colors.textSecondary)),
                      const SizedBox(height: VanyaSpacing.xs),
                      Text('CAPTION · INTER', style: VanyaTypography.caption.copyWith(color: colors.textTertiary)),
                    ],
                  ),
                ),
                const SizedBox(height: VanyaSpacing.xxl),

                _sectionLabel(context, 'Color'),
                VanyaGlassCard(
                  child: Wrap(
                    spacing: VanyaSpacing.sm,
                    runSpacing: VanyaSpacing.sm,
                    children: [
                      _swatch('Background', colors.background),
                      _swatch('Surface', colors.surface),
                      _swatch('Accent', colors.accent),
                      _swatch('Gentle', colors.gentle),
                      _swatch('Fur base', colors.furBase),
                      _swatch('Fur shadow', colors.furShadow),
                      _swatch('Ear inner', colors.furEarInner),
                    ],
                  ),
                ),
                const SizedBox(height: VanyaSpacing.xxl),

                _sectionLabel(context, 'Glass card + intensities'),
                VanyaGlassCard(
                  child: Text(
                    'This is a standard VanyaGlassCard. It should feel warm, softly lit from the top edge, and let the backdrop show through — never opaque, never cold.',
                    style: VanyaTypography.body.copyWith(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(height: VanyaSpacing.xxl),

                _sectionLabel(context, 'Buttons'),
                Wrap(
                  spacing: VanyaSpacing.md,
                  runSpacing: VanyaSpacing.md,
                  children: [
                    VanyaGlassButton(
                      label: 'Meet Vanya',
                      style: VanyaGlassButtonStyle.accent,
                      onPressed: () {},
                    ),
                    VanyaGlassButton(
                      label: 'Not now',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () {},
                    ),
                    const VanyaGlassButton(label: 'Disabled', onPressed: null),
                  ],
                ),
                const SizedBox(height: VanyaSpacing.xxl),

                _sectionLabel(context, 'Chips (multi-select)'),
                VanyaGlassCard(
                  child: Wrap(
                    spacing: VanyaSpacing.sm,
                    runSpacing: VanyaSpacing.sm,
                    children: [
                      for (final label in _chipLabels)
                        VanyaGlassChip(
                          label: label,
                          selected: _selectedChips.contains(label),
                          onTap: () => setState(() {
                            if (_selectedChips.contains(label)) {
                              _selectedChips.remove(label);
                            } else {
                              _selectedChips.add(label);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: VanyaSpacing.xxl),

                _sectionLabel(context, 'Toggle'),
                VanyaGlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vanya encouragements', style: VanyaTypography.body.copyWith(color: colors.textPrimary)),
                      VanyaGlassToggle(
                        value: _toggleValue,
                        onChanged: (v) => setState(() => _toggleValue = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VanyaSpacing.xxl),

                _sectionLabel(context, 'Progress'),
                VanyaGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Focus session', style: VanyaTypography.body.copyWith(color: colors.textPrimary)),
                      const SizedBox(height: VanyaSpacing.md),
                      VanyaGlassProgress(value: _progress),
                      const SizedBox(height: VanyaSpacing.sm),
                      Slider(
                        value: _progress,
                        onChanged: (v) => setState(() => _progress = v),
                        activeColor: colors.accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VanyaSpacing.xxl),

                _sectionLabel(context, 'Sheet & dialog'),
                Wrap(
                  spacing: VanyaSpacing.md,
                  runSpacing: VanyaSpacing.md,
                  children: [
                    VanyaGlassButton(
                      label: 'Show sheet',
                      onPressed: () => VanyaGlassSheet.show(
                        context: context,
                        builder: (context) => Padding(
                          padding: const EdgeInsets.only(top: VanyaSpacing.sm),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Change my moment', style: VanyaTypography.sectionTitle.copyWith(color: colors.textPrimary)),
                              const SizedBox(height: VanyaSpacing.sm),
                              Text(
                                'A VanyaGlassSheet — used for the intervention flow\'s "change my moment" action, and anywhere else a lightweight modal is needed.',
                                style: VanyaTypography.secondary.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    VanyaGlassButton(
                      label: 'Show dialog',
                      onPressed: () => VanyaGlassDialog.show(
                        context: context,
                        title: 'Reset onboarding?',
                        message: 'You\'ll see the welcome flow again next time you open Vanya.',
                        actions: [
                          VanyaDialogAction(label: 'Cancel', onPressed: () {}),
                          VanyaDialogAction(
                            label: 'Reset',
                            style: VanyaGlassButtonStyle.accent,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VanyaSpacing.xxxl),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VanyaGlassNavigation(
              items: _navItems,
              selectedIndex: _navIndex,
              onSelect: (i) => setState(() => _navIndex = i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final colors = context.vanyaColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: VanyaSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: VanyaTypography.caption.copyWith(
          color: colors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _swatch(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(height: VanyaSpacing.xs),
        Text(label, style: VanyaTypography.footnote),
      ],
    );
  }
}

/// Registers the app's real [VanyaColors] extension on a plain Material
/// [ThemeData] for the chosen brightness, and adds a small floating control
/// for flipping light/dark while inspecting the screen. `builder` (rather
/// than a plain `child`) ensures the showcase content is built with a
/// [BuildContext] that sits *below* this `Theme`, so `context.vanyaColors`
/// resolves correctly.
class _ThemedShowcase extends StatelessWidget {
  const _ThemedShowcase({
    required this.themeMode,
    required this.onToggleTheme,
    required this.builder,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final vanyaColors = themeMode == ThemeMode.dark ? VanyaColors.dark : VanyaColors.light;
    final base = themeMode == ThemeMode.dark ? ThemeData.dark() : ThemeData.light();

    return Theme(
      data: base.copyWith(extensions: [vanyaColors]),
      child: Builder(
        builder: (context) => Stack(
          children: [
            builder(context),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(VanyaSpacing.sm),
                  child: IconButton(
                    onPressed: onToggleTheme,
                    icon: Icon(
                      themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: vanyaColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A stand-in "illustrated environment": soft, heavily blurred color blobs
/// in Vanya's own palette, purely so the glass components have real texture
/// behind them to be judged against. Replace with actual illustration once
/// Vanya's artwork assets exist.
class _IllustratedBackdrop extends StatelessWidget {
  const _IllustratedBackdrop({required this.colors});

  final VanyaColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.background),
      child: SizedBox.expand(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: Stack(
            children: [
              Positioned(top: -60, left: -40, child: _blob(colors.furBase, 220)),
              Positioned(top: 120, right: -60, child: _blob(colors.accentMuted, 260)),
              Positioned(bottom: 40, left: -30, child: _blob(colors.gentleMuted, 240)),
              Positioned(bottom: -80, right: -40, child: _blob(colors.furEarInner, 200)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.55), shape: BoxShape.circle),
    );
  }
}
