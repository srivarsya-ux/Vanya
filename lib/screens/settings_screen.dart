import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';
import 'co_keeper_management_screen.dart';
import 'co_keeper_inbox_screen.dart';
import 'add_widgets_screen.dart';
import 'subscription_screen.dart';
import 'vanya_ai_test_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OneirColors.text), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Settings', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, color: OneirColors.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _SettingsRow(
            icon: Icons.diversity_1_outlined,
            title: 'Co-Keepers',
            subtitle: 'Manage who holds your key',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoKeeperManagementScreen())),
          ),
          _SettingsRow(
            icon: Icons.inbox_outlined,
            title: 'Co-Keeper Requests',
            subtitle: 'Approve or decline unlock requests you\'ve received',
            // This screen (CoKeeperInboxScreen) existed in the codebase but
            // had no way to reach it from anywhere in the app -- it only
            // matters on whichever device is acting as someone else's
            // Co-Keeper, but there was previously no entry point at all,
            // not even for that device's own owner.
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoKeeperInboxScreen())),
          ),
          _SettingsRow(
            icon: Icons.widgets_outlined,
            title: 'Widgets',
            subtitle: 'Add Oneir to your home screen',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddWidgetsScreen())),
          ),
          _SettingsRow(
            icon: Icons.workspace_premium_outlined,
            title: 'Subscription',
            subtitle: 'Manage your plan',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
          ),
          _SettingsRow(
            icon: Icons.memory_outlined,
            title: 'Vanya AI (on-device, dev)',
            subtitle: 'Proof-of-concept: local Gemma 4 E2B, no cloud',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VanyaAiTestScreen())),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: OneirColors.cardNeutral,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: OneirColors.background, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: OneirColors.text),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 15, color: OneirColors.text)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: OneirColors.textFaint)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: OneirColors.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
