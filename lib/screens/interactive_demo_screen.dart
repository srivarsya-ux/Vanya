import 'dart:async';
import '../widgets/vanya_animation.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import '../native/oneir_protection.dart';

enum _Stage { idle, hopping, speaking, buttons }

const _hopDuration = Duration(milliseconds: 900);

const _reasonPhrases = {
  'Reduce scrolling': 'cut back on scrolling',
  'Study focus': 'focus while studying',
  'Sleep better': 'sleep better',
  'Something else': 'do what matters most',
};

class InteractiveDemoScreen extends StatefulWidget {
  final VoidCallback onNext;
  const InteractiveDemoScreen({super.key, required this.onNext});

  @override
  State<InteractiveDemoScreen> createState() => _InteractiveDemoScreenState();
}

class _InteractiveDemoScreenState extends State<InteractiveDemoScreen> {
  _Stage _stage = _Stage.idle;
  int _lineIndex = -1;
  final List<Timer> _timers = [];
  String _name = '';
  String _reasonPhrase = 'do what matters most';

  List<String> get _demoLines => [
        _name.isEmpty ? 'Hey there.' : 'Hey $_name.',
        'You said you wanted to $_reasonPhrase.',
        'Still want Instagram?',
      ];

  @override
  void initState() {
    super.initState();
    _loadPersonalization();
  }

  Future<void> _loadPersonalization() async {
    final name = await OneirProtection.loadUserName();
    final reason = await OneirProtection.loadUserReason();
    if (!mounted) return;
    setState(() {
      _name = name;
      if (_reasonPhrases.containsKey(reason)) _reasonPhrase = _reasonPhrases[reason]!;
    });
  }

  void _clearTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _start() {
    if (_stage != _Stage.idle) return;
    _clearTimers();
    setState(() {
      _lineIndex = -1;
      _stage = _Stage.hopping;
    });
    _timers.add(Timer(_hopDuration, () => setState(() => _stage = _Stage.speaking)));
    for (var i = 0; i < _demoLines.length; i++) {
      _timers.add(Timer(_hopDuration + Duration(milliseconds: i * 1100), () => setState(() => _lineIndex = i)));
    }
    _timers.add(Timer(
      _hopDuration + Duration(milliseconds: _demoLines.length * 1100),
      () => setState(() => _stage = _Stage.buttons),
    ));
  }

  @override
  void dispose() {
    _clearTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interrupted = _stage != _Stage.idle;

    return OneirScaffold(
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: interrupted ? ImageFilter.blur(sigmaX: 6, sigmaY: 6) : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(OneirSpace.xl, OneirSpace.lg + 2, OneirSpace.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('10:30', style: OneirText.caption.copyWith(fontSize: 12, letterSpacing: 0, color: OneirColors.text)),
                      Text('80%', style: OneirText.caption.copyWith(fontSize: 12, letterSpacing: 0, color: OneirColors.text)),
                    ],
                  ),
                  const SizedBox(height: OneirSpace.lg + 2),
                  Text('Tue, 22 Jul', style: OneirText.caption.copyWith(fontSize: 12, letterSpacing: 0, color: OneirColors.textMuted)),
                  Text('18\u00B0', style: OneirText.caption.copyWith(fontSize: 12, letterSpacing: 0, color: OneirColors.textMuted)),
                  const SizedBox(height: OneirSpace.huge + 20),
                  Row(children: [
                    _AppIcon(label: 'Instagram', bg: const Color(0xFFDD2A7B), glyph: 'IG', onTap: _start),
                    const SizedBox(width: 28),
                    const _AppIcon(label: 'TikTok', bg: Color(0xFF111111), glyph: 'TT'),
                    const SizedBox(width: 28),
                    const _AppIcon(label: 'YouTube', bg: Color(0xFFFF0000), glyph: 'YT'),
                  ]),
                  if (!interrupted) ...[
                    const SizedBox(height: OneirSpace.huge + 60),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: OneirSpace.md),
                        child: Text(
                          _reasonPhrase == 'do what matters most'
                              ? 'Try opening Instagram'
                              : "Because you want to $_reasonPhrase, try opening Instagram",
                          textAlign: TextAlign.center,
                          style: OneirText.caption.copyWith(fontSize: 12, letterSpacing: 0, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_stage == _Stage.hopping)
            const Positioned(
              left: 25, bottom: 60, width: 300, height: 300,
              child: VanyaAnimation(width: 300, height: 300),
            ),
          if (_stage == _Stage.speaking || _stage == _Stage.buttons)
            const Positioned(
              left: -16, top: 35, width: 325, height: 382.8,
              child: VanyaAnimation(width: 325, height: 382.8),
            ),
          if (interrupted)
            Positioned(
              left: 0, right: 0, top: 440,
              child: SizedBox(
                height: 70,
                child: Center(
                  child: _lineIndex >= 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: OneirSpace.xxl),
                          child: Text(_demoLines[_lineIndex],
                              textAlign: TextAlign.center,
                              style: OneirText.heading.copyWith(fontSize: 20, fontWeight: FontWeight.w500)),
                        )
                      : null,
                ),
              ),
            ),
          if (_stage == _Stage.buttons)
            Positioned(
              left: 56, top: 540, width: 240,
              child: Column(children: [
                OneirPrimaryButton(label: 'Return to My Tasks', onPressed: widget.onNext),
                const SizedBox(height: OneirSpace.md - 2),
                OneirSecondaryButton(label: 'Request Co-Keeper Key', onPressed: widget.onNext),
              ]),
            ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String label;
  final Color bg;
  final String glyph;
  final VoidCallback? onTap;
  const _AppIcon({required this.label, required this.bg, required this.glyph, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(OneirRadius.sm), color: bg),
          alignment: Alignment.center,
          child: Text(glyph, style: OneirText.bodyStrong.copyWith(fontSize: 18, color: Colors.white)),
        ),
        const SizedBox(height: OneirSpace.sm - 2),
        Text(label, style: OneirText.caption.copyWith(fontSize: 10, letterSpacing: 0, color: OneirColors.textMuted)),
      ]),
    );
  }
}
