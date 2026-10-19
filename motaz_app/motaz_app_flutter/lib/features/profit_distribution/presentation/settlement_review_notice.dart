import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/profit_providers.dart';

class SettlementReviewNotice extends ConsumerWidget {
  const SettlementReviewNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(settlementReviewProvider).asData?.value;
    if (reviews == null || reviews.isEmpty) return const SizedBox.shrink();
    final first = reviews.first.profit;
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'تغيرت حسابات الأشهر من ${first.year}-${first.month}. تحتاج إعادة اعتماد.',
            ),
            TextButton.icon(
              onPressed: () => context.go('/distributions'),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('مراجعة التسويات'),
            ),
          ],
        ),
      ),
    );
  }
}
