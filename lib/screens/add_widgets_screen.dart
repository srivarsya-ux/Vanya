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
        title: Text('Widgets', style: OneirText.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(OneirSpace.xl),
        children: [
          Text(
            "Add Oneir's widgets to your home screen so today's tasks are visible before you even open the app.",
            style: OneirText.body,
          ),
          const SizedBox(height: OneirSpace.xl),
          const OneirStreakWidgetCard(title: "Today's Adventure", currentDay: 0, totalDays: 1),
          const SizedBox(height: OneirSpace.md),
          const OneirStreakWidgetCard(title: 'Focus Streak', currentDay: 3, totalDays: 30),
          const SizedBox(height: OneirSpace.xxl),
          OneirCard(
            padding: const EdgeInsets.all(OneirSpace.lg),
            color: OneirColors.surfaceSunken,
            bordered: false,
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to add a widget', style: OneirText.bodyStrong.copyWith(fontSize: 14)),
                const SizedBox(height: OneirSpace.sm),
                Text(
                  '1. Long-press an empty area of your home screen\n'
                  '2. Tap Widgets\n'
                  '3. Find Oneir and drag your widget into place',
                  style: OneirText.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
