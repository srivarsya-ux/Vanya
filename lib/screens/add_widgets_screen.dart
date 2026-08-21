import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';

/// NOTE: Android doesn't let an app programmatically place a widget on the
/// home screen -- that action is always user-initiated (long-press home
/// screen -> Widgets -> drag Oneir's widget on). This screen can only guide
/// the user through doing that themselves, and (once a real AppWidgetProvider
/// is implemented, which doesn't exist yet) deep-link to Android's widget
/// picker via requestPinAppWidget() on Android 8+. Right now this is UI only.
class AddWidgetsScreen extends StatelessWidget {
  const AddWidgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OneirColors.text), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Widgets', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, color: OneirColors.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Add Oneir's widgets to your home screen so today's tasks are visible before you even open the app.",
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: OneirColors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          const OneirStreakWidgetCard(title: "Today's Adventure", currentDay: 0, totalDays: 1),
          const SizedBox(height: 12),
          const OneirStreakWidgetCard(title: 'Focus Streak', currentDay: 3, totalDays: 30),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: OneirColors.cardNeutral, borderRadius: BorderRadius.circular(16)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to add a widget', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 14, color: OneirColors.text)),
                SizedBox(height: 8),
                Text(
                  '1. Long-press an empty area of your home screen\n'
                  '2. Tap Widgets\n'
                  '3. Find Oneir and drag your widget into place',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textMuted, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
