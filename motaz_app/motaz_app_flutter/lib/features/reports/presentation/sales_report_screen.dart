import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/document_reference_formatter.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../attachments/application/document_attachment_reader.dart';
import '../application/report_providers.dart';
import '../data/report_models.dart';
import '../pdf/pdf_file_names.dart';
import '../pdf/pdf_generator.dart';
import '../pdf/pdf_styles.dart';
import '../pdf/pdf_templates/sales_report_pdf.dart';
import '../presentation/widgets/date_range_picker.dart';
import '../presentation/widgets/report_summary_row.dart';

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  late DateRange _selectedRange;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedRange = DateRange.thisMonth();
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(salesReportProvider(_selectedRange));

    return AppDrawerScaffold(
      title: 'تقرير المبيعات',
      currentRoute: '/reports/sales',
      leading: IconButton(
        tooltip: 'الرجوع للتقارير',
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/reports'),
      ),
      child: Scaffold(
        floatingActionButton: reportAsync.maybeWhen(
          data: (summary) => summary.rows.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: _isExporting ? null : () => _exportPdf(summary),
                  icon: _isExporting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(_isExporting ? 'جاري...' : 'تصدير PDF'),
                )
              : null,
          orElse: () => null,
        ),
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
                data: (summary) {
                  if (summary.rows.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد بيانات',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: summary.rows.length,
                          itemBuilder: (context, index) {
                            final row = summary.rows[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            invoiceDisplayRef(row.localRef),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            row.clientName,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '${row.invoiceDate.year}-${row.invoiceDate.month.toString().padLeft(2, '0')}-${row.invoiceDate.day.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          formatMoney(row.total),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (row.discount > 0)
                                          Text(
                                            '-${formatMoney(row.discount)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.shadow.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ReportSummaryRow(
                              label: 'إجمالي المبيعات',
                              amountMinorUnits: summary.grossSales,
                            ),
                            ReportSummaryRow(
                              label: 'الخصومات',
                              amountMinorUnits: -summary.totalDiscounts,
                            ),
                            ReportSummaryRow(
                              label: 'المرتجعات',
                              amountMinorUnits: -summary.totalReturns,
                            ),
                            const Divider(),
                            ReportSummaryRow(
                              label: 'صافي المبيعات',
                              amountMinorUnits: summary.netSales,
                              isGrandTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Future<void> _exportPdf(SalesReportSummary summary) async {
    setState(() => _isExporting = true);
    try {
      final exportSummary = await _attachInvoiceImages(summary);
      final styles = await PdfStyles.load();
      final doc = SalesReportPdf.generate(
        styles,
        exportSummary,
        _selectedRange,
      );
      final savedPath = await PdfGenerator.shareOrPrint(
        doc,
        PdfReportFileNames.dated('تقرير المبيعات'),
      );
      if (!mounted) return;
      PdfGenerator.showSavedSnackBar(context, savedPath);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<SalesReportSummary> _attachInvoiceImages(
    SalesReportSummary summary,
  ) async {
    final reader = ref.read(documentAttachmentReaderProvider);
    final rows = <SalesReportRow>[];
    for (final row in summary.rows) {
      rows.add(
        row.copyWith(
          attachmentImages: await reader.loadImages(
            parentEntityType: ParentEntityType.SALES_INVOICE,
            parentEntityId: row.invoiceId,
          ),
        ),
      );
    }

    return SalesReportSummary(
      rows: rows,
      grossSales: summary.grossSales,
      totalDiscounts: summary.totalDiscounts,
      totalReturns: summary.totalReturns,
      netSales: summary.netSales,
    );
  }
}
