import 'package:flutter/material.dart';
import '../theme/oneir_theme.dart';
import '../widgets/shared.dart';

/// NOTE: this is UI only -- there's no real payment processing wired up.
/// Actually charging money needs the Google Play Billing Library integrated
/// natively (a real products/subscriptions setup in the Play Console, a
/// BillingClient connection, purchase verification), which is a
/// significant separate piece of native work, not something addable from
/// Dart alone. Tapping Subscribe here doesn't charge anyone; it's a
/// placeholder for where that flow will plug in.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selected = 'yearly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneirColors.background,
      appBar: AppBar(
        backgroundColor: OneirColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: OneirColors.text), onPressed: () => Navigator.of(context).pop()),
        title: const Text('Subscription', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, color: OneirColors.text)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose your plan', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 22, color: OneirColors.text)),
            const SizedBox(height: 8),
            const Text('Support Oneir and unlock the full Co-Keeper experience.',
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: OneirColors.textFaint)),
            const SizedBox(height: 24),
            _PlanOption(
              label: 'Monthly',
              price: '\$4',
              period: '/ month',
              selected: _selected == 'monthly',
              onTap: () => setState(() => _selected = 'monthly'),
            ),
            const SizedBox(height: 12),
            _PlanOption(
              label: 'Yearly',
              price: '\$40',
              period: '/ year',
              badge: 'Save 17%',
              selected: _selected == 'yearly',
              onTap: () => setState(() => _selected = 'yearly'),
            ),
            const Spacer(),
            OneirPrimaryButton(
              label: 'Subscribe',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payments are not wired up yet -- this is a UI placeholder.', style: TextStyle(fontFamily: 'PlusJakartaSans'))),
                );
              },
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Cancel anytime in Google Play', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: OneirColors.textFaint)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String label;
  final String price;
  final String period;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.label,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAEAEA) : OneirColors.cardNeutral,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? OneirColors.text : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(label, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 15, color: OneirColors.text)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: OneirColors.accent, borderRadius: BorderRadius.circular(10)),
                          child: Text(badge!, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: price, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700, fontSize: 20, color: OneirColors.text)),
                        TextSpan(text: ' $period', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: OneirColors.textFaint)),
                      ]),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? OneirColors.text : OneirColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
