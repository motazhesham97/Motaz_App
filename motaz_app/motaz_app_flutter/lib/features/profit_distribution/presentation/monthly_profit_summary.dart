import 'package:flutter/material.dart';
import '../../../core/utils/money_formatter.dart';
import '../domain/monthly_profit.dart';

class MonthlyProfitSummary extends StatelessWidget {
  const MonthlyProfitSummary({super.key, required this.profit});
  final MonthlyProfit profit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shares = profit.shares;
    final rows = <(String, int)>[
      ('صافي المبيعات', profit.netSales),
      ('المصروفات التشغيلية', profit.operationalExpenses),
      ('المصروفات الإنتاجية', profit.productionExpenses),
      ('نتيجة نشاط الشهر', profit.profitBeforeCarry),
      ('خسارة الشهر الحالي', profit.currentMonthLoss),
      ('الخسارة المرحلة السابقة', profit.carriedLossIn),
      ('صافي النتيجة بعد الترحيل', profit.netProfit),
      ('الخسارة المرحلة للشهر التالي', profit.carriedLossOut),
      ('الربح القابل للتوزيع', profit.distributableProfit),
      ('حصة امي', shares.ownerShare),
      ('حصة معتز', shares.partnerShare),
      ('حصة الهامش', shares.marginShare),
    ];
    return Column(
      children: [
        for (final (label, amount) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(label)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    formatMoney(amount),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: amount < 0 ? colors.error : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
