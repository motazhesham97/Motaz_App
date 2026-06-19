import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_range.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../free_samples/application/free_sample_providers.dart';
import '../../free_samples/data/free_sample_repository.dart';
import '../pdf/pdf_file_names.dart';
import '../pdf/pdf_generator.dart';
import '../pdf/pdf_styles.dart';
import '../pdf/pdf_templates/free_sample_report_pdf.dart';
import 'widgets/date_range_picker.dart';

class FreeSampleReportScreen extends ConsumerStatefulWidget {
  const FreeSampleReportScreen({super.key});

  @override
  ConsumerState<FreeSampleReportScreen> createState() =>
      _FreeSampleReportScreenState();
}

class _FreeSampleReportScreenState
    extends ConsumerState<FreeSampleReportScreen> {
  late DateRange _selectedRange;
  final _beneficiaryController = TextEditingController();
  String _beneficiaryQuery = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedRange = DateRange.thisMonth();
  }

  @override
  void dispose() {
    _beneficiaryController.dispose();
    super.dispose();
  }

  List<FreeSampleSummary> _filter(List<FreeSampleSummary> rows) {
    final query = _beneficiaryQuery.trim().toLowerCase();
    return rows.where((row) {
      final inRange =
          !row.sample.sampleDate.isBefore(_selectedRange.start) &&
          row.sample.sampleDate.isBefore(_selectedRange.end);
      final matchesBeneficiary =
          query.isEmpty || _matchesWordPrefix(row.beneficiaryName, query);
      return inRange && matchesBeneficiary;
    }).toList();
  }

  bool _matchesWordPrefix(String value, String query) {
    return value
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .any((word) => word.startsWith(query));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _filterLabel() {
    final end = _selectedRange.end.subtract(const Duration(days: 1));
    final range =
        'من ${_formatDate(_selectedRange.start)} إلى ${_formatDate(end)}';
    final beneficiary = _beneficiaryQuery.trim();
    if (beneficiary.isEmpty) return range;
    return '$range - المستفيد: $beneficiary';
  }

  Future<void> _exportPdf(List<FreeSampleSummary> rows) async {
    setState(() => _isExporting = true);
    try {
      final styles = await PdfStyles.load();
      final doc = FreeSampleReportPdf.generate(
        styles,
        rows: rows,
        filterLabel: _filterLabel(),
      );
      final subject = _beneficiaryQuery.trim();
      final savedPath = await PdfGenerator.shareOrPrint(
        doc,
        PdfReportFileNames.dated(
          'تقرير العينات المجانية',
          subject: subject.isEmpty ? null : subject,
        ),
      );
      if (!mounted) return;
      PdfGenerator.showSavedSnackBar(context, savedPath);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final samplesAsync = ref.watch(freeSampleReportProvider);

    return AppDrawerScaffold(
      title: 'تقرير العينات المجانية',
      currentRoute: '/reports/free-samples',
      leading: IconButton(
        tooltip: 'الرجوع للتقارير',
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/reports'),
      ),
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _beneficiaryController,
                    decoration: const InputDecoration(
                      labelText: 'بحث باسم المستفيد',
                      prefixIcon: Icon(Icons.person_search_rounded),
                    ),
                    onChanged: (value) {
                      setState(() => _beneficiaryQuery = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DateRangePickerWidget(
                    onRangeChanged: (range) {
                      setState(() => _selectedRange = range);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: samplesAsync.when(
                data: (rows) {
                  final filtered = _filter(rows);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('لا توجد عينات مجانية ضمن البحث'),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'النتائج: ${filtered.length} | إجمالي العدد: ${filtered.fold<int>(0, (sum, row) => sum + row.totalQuantity)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _isExporting
                                  ? null
                                  : () => _exportPdf(filtered),
                              icon: _isExporting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                    )
                                  : const Icon(Icons.picture_as_pdf),
                              label: Text(
                                _isExporting ? 'جاري...' : 'تصدير PDF',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final row = filtered[index];
                            final products = row.lines
                                .map(
                                  (line) =>
                                      '${line.productName}: ${line.quantity}',
                                )
                                .join('، ');
                            return Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(row.beneficiaryName),
                                subtitle: Text(
                                  '${_formatDate(row.sample.sampleDate)} - $products',
                                ),
                                trailing: Text('العدد: ${row.totalQuantity}'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
