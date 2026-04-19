import 'package:flutter/material.dart';

import '../../../../core/utils/money_formatter.dart';

class ReportSummaryRow extends StatelessWidget {
  final String label;
  final int amountMinorUnits;
  final bool isGrandTotal;

  const ReportSummaryRow({
    super.key,
    required this.label,
    required this.amountMinorUnits,
    this.isGrandTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isGrandTotal
        ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        : const TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            formatMoney(amountMinorUnits),
            style: style.copyWith(
              color: amountMinorUnits < 0 ? Colors.red : Colors.green,
            ),
          ),
          Text(label, style: style),
        ],
      ),
    );
  }
}