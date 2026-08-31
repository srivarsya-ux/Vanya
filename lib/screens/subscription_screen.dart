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
        title: const Text('Subscription', style: OneirText.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(OneirSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose your plan', style: OneirText.heading),
            const SizedBox(height: OneirSpace.sm),
            Text('Support Oneir and unlock the full Co-Keeper experience.',
                style: OneirText.body.copyWith(color: OneirColors.textFaint)),
            const SizedBox(height: OneirSpace.xxl),
            _PlanOption(
              label: 'Monthly',
              price: '\$4',
              period: '/ month',
              selected: _selected == 'monthly',
              onTap: () => setState(() => _selected = 'monthly'),
            ),
            const SizedBox(height: OneirSpace.md),
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
                  SnackBar(content: Text('Payments are not wired up yet -- this is a UI placeholder.', style: OneirText.bodySmall.copyWith(color: Colors.white))),
                );
              },
            ),
            const SizedBox(height: OneirSpace.md),
            const Center(
              child: Text('Cancel anytime in Google Play', style: OneirText.caption),
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
      color: selected ? OneirColors.accentSoft : OneirColors.surface,
      borderRadius: BorderRadius.circular(OneirRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(OneirRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(OneirSpace.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OneirRadius.lg),
            border: Border.all(color: selected ? OneirColors.accent : OneirColors.border, width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(label, style: OneirText.bodyStrong.copyWith(fontWeight: FontWeight.w600)),
                      if (badge != null) ...[
                        const SizedBox(width: OneirSpace.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: OneirSpace.sm, vertical: 3),
                          decoration: BoxDecoration(color: OneirColors.accent, borderRadius: BorderRadius.circular(OneirRadius.pill)),
                          child: Text(badge!, style: OneirText.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: price, style: OneirText.title.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
                        TextSpan(text: ' $period', style: OneirText.bodySmall.copyWith(color: OneirColors.textFaint)),
                      ]),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? OneirColors.accent : OneirColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
