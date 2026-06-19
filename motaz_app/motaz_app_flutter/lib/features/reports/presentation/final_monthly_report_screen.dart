import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_drawer.dart';
import '../application/report_providers.dart';
import '../pdf/pdf_file_names.dart';
import '../pdf/pdf_generator.dart';
import '../pdf/pdf_styles.dart';
import '../pdf/pdf_templates/final_monthly_report_pdf.dart';

class FinalMonthlyReportScreen extends ConsumerStatefulWidget {
  const FinalMonthlyReportScreen({super.key});

  @override
  ConsumerState<FinalMonthlyReportScreen> createState() =>
      _FinalMonthlyReportScreenState();
}

class _FinalMonthlyReportScreenState
    extends ConsumerState<FinalMonthlyReportScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = [
      for (var year = now.year - 8; year <= now.year + 1; year++) year,
    ];

    return AppDrawerScaffold(
      title: 'التقرير النهائي',
      currentRoute: '/reports/final',
      leading: IconButton(
        tooltip: 'الرجوع للتقارير',
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/reports'),
      ),
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'اختر الشهر والسنة',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'الشهر',
                        prefixIcon: Icon(Icons.calendar_month_rounded),
                      ),
                      items: [
                        for (var month = 1; month <= 12; month++)
                          DropdownMenuItem(
                            value: month,
                            child: Text(_monthName(month)),
                          ),
                      ],
                      onChanged: _isExporting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _selectedMonth = value);
                            },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'السنة',
                        prefixIcon: Icon(Icons.event_rounded),
                      ),
                      items: [
                        for (final year in years)
                          DropdownMenuItem(value: year, child: Text('$year')),
                      ],
                      onChanged: _isExporting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _selectedYear = value);
                            },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isExporting ? null : _exportPdf,
                      icon: _isExporting
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(_isExporting ? 'جاري التصدير...' : 'تطبيق'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final data = await ref
          .read(reportQueriesProvider)
          .getFinalMonthlyReport(year: _selectedYear, month: _selectedMonth);
      final styles = await PdfStyles.load();
      final doc = FinalMonthlyReportPdf.generate(styles, data);
      final savedPath = await PdfGenerator.shareOrPrint(
        doc,
        PdfReportFileNames.monthly(
          'التقرير الشهري النهائي',
          year: _selectedYear,
          month: _selectedMonth,
        ),
      );
      if (!mounted) return;
      PdfGenerator.showSavedSnackBar(context, savedPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تصدير التقرير: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _monthName(int month) {
    return switch (month) {
      1 => 'يناير',
      2 => 'فبراير',
      3 => 'مارس',
      4 => 'أبريل',
      5 => 'مايو',
      6 => 'يونيو',
      7 => 'يوليو',
      8 => 'أغسطس',
      9 => 'سبتمبر',
      10 => 'أكتوبر',
      11 => 'نوفمبر',
      _ => 'ديسمبر',
    };
  }
}
