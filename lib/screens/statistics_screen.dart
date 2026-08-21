import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../native/oneir_protection.dart';

/// Real numbers pulled from what's actually persisted -- not sample data.
/// Deliberately modest in scope: this reflects what the app genuinely
/// tracks right now (protected app count, task completion, saved reason).
/// A fuller history/trends view would need a real event log the app
/// doesn't keep yet -- that's a real future addition, not something to
/// fake here with invented numbers.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _loading = true;
  int _protectedAppCount = 0;
  int _tasksCompleted = 0;
  int _tasksTotal = 0;
  String _reason = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await OneirProtection.loadProtectedApps();
    final taskList = await OneirProtection.loadTaskList();
    final homeTaskState = await OneirProtection.loadTaskState();
    final reason = await OneirProtection.loadUserReason();

    final homeCompleted = homeTaskState?.where((t) => t).length ?? 0;
    final homeTotal = homeTaskState?.length ?? 0;
    final listCompleted = taskList.where((t) => t['done'] == true).length;

    if (!mounted) return;
    setState(() {
      _protectedAppCount = apps.length;
      _tasksCompleted = homeCompleted + listCompleted;
      _tasksTotal = homeTotal + taskList.length;
      _reason = reason;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OneirColors.text), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Statistics', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, color: OneirColors.text)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  Expanded(child: _StatCard(label: 'Tasks completed', value: '$_tasksCompleted / $_tasksTotal')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Protected apps', value: '$_protectedAppCount')),
                ]),
                const SizedBox(height: 12),
                if (_reason.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: OneirColors.cardNeutral, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Why you started', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 13, color: OneirColors.textFaint)),
                        const SizedBox(height: 6),
                        Text(_reason, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: OneirColors.text)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: OneirColors.cardNeutral, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700, fontSize: 22, color: OneirColors.text)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: OneirColors.textFaint)),
        ],
      ),
    );
  }
}
