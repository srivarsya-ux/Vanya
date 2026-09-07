import 'package:flutter/material.dart';

import 'design_system/vanya_theme.dart';
import 'dev/design_system_showcase_screen.dart';

void main() {
  runApp(const VanyaApp());
}

/// PHASE 1–2 STATE: the real app shell (onboarding gate, navigation,
/// persistence) hasn't been ported yet — see MIGRATION.md at the repo
/// root. `home` points at the temporary design-system showcase so the
/// whole system can be judged on a real device first, per the build order
/// in the product brief. Swap this for the real root screen once Phase 3+
/// feature work begins.
class VanyaApp extends StatelessWidget {
  const VanyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vanya',
      debugShowCheckedModeBanner: false,
      theme: VanyaTheme.light(),
      darkTheme: VanyaTheme.dark(),
      home: const DesignSystemShowcaseScreen(),
    );
  }
}
