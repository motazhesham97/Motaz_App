import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_range.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/report_providers.dart';
import '../presentation/widgets/date_range_picker.dart';
import '../presentation/widgets/report_summary_row.dart';

class ProfitReportScreen extends ConsumerStatefulWidget {
  const ProfitReportScreen({super.key});

  @override
  ConsumerState<ProfitReportScreen> createState() => _ProfitReportScreenState();
}

class _ProfitReportScreenState extends ConsumerState<ProfitReportScreen> {
  late DateRange _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = DateRange.thisMonth();
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(profitReportProvider(_selectedRange));

    return AppDrawerScaffold(
      title: 'تقرير الأرباح',
      currentRoute: '/reports/profit',
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DateRangePickerWidget(
                onRangeChanged: (range) {
                  setState(() => _selectedRange = range);
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: reportAsync.when(
                data: (data) {
                  if (data.grossSales == 0 && data.netProfit == 0) {
                    return const Center(
                      child: Text(
                        'لا توجد بيانات',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ReportSummaryRow(
                                  label: 'إجمالي المبيعات',
                                  amountMinorUnits: data.grossSales,
                                ),
                                ReportSummaryRow(
                                  label: 'الخصومات',
                                  amountMinorUnits: -data.discounts,
                                ),
                                ReportSummaryRow(
                                  label: 'المرتجعات',
                                  amountMinorUnits: -data.returns,
                                ),
                                const Divider(),
                                ReportSummaryRow(
                                  label: 'صافي المبيعات',
                                  amountMinorUnits: data.netSales,
                                  isGrandTotal: true,
                                ),
                                const SizedBox(height: 8),
                                ReportSummaryRow(
                                  label: 'مصروفات تشغيلية',
                                  amountMinorUnits: -data.operationalExpenses,
                                ),
                                ReportSummaryRow(
                                  label: 'مصروفات إنتاج',
                                  amountMinorUnits: -data.productionExpenses,
                                ),
                                const Divider(),
                                ReportSummaryRow(
                                  label: 'صافي الربح',
                                  amountMinorUnits: data.netProfit,
                                  isGrandTotal: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (data.distribution != null) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'توزيع الأرباح',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ReportSummaryRow(
                                    label: 'حصة المالك',
                                    amountMinorUnits: data.distribution!.ownerShare,
                                  ),
                                  ReportSummaryRow(
                                    label: 'حصة الشريك',
                                    amountMinorUnits: data.distribution!.partnerShare,
                                  ),
                                  ReportSummaryRow(
                                    label: 'حصة الهامش',
                                    amountMinorUnits: data.distribution!.marginShare,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else if (_isNonMonthly(_selectedRange)) ...[
                          const SizedBox(height: 16),
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'فترة غير شهرية - عرض فقط',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isNonMonthly(DateRange range) {
    final s = range.start;
    final e = range.end;
    return !(s.year == e.year && s.month == e.month && s.day == 1 && e.day >= 28);
  }
}