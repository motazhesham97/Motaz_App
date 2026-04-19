import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../clients/application/client_providers.dart';
import '../application/report_providers.dart';
import '../data/report_models.dart';
import '../pdf/pdf_generator.dart';
import '../pdf/pdf_styles.dart';
import '../pdf/pdf_templates/client_statement_pdf.dart';
import '../presentation/widgets/date_range_picker.dart';

class ClientStatementScreen extends ConsumerStatefulWidget {
  const ClientStatementScreen({super.key});

  @override
  ConsumerState<ClientStatementScreen> createState() =>
      _ClientStatementScreenState();
}

class _ClientStatementScreenState extends ConsumerState<ClientStatementScreen> {
  Client? _selectedClient;
  late DateRange _selectedRange;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedRange = DateRange.thisMonth();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);

    return AppDrawerScaffold(
      title: 'كشف حساب عميل',
      currentRoute: '/reports/client-statement',
      child: Scaffold(
        floatingActionButton: _selectedClient == null
            ? null
            : FloatingActionButton.extended(
                onPressed: _isExporting ? null : _exportPdf,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isExporting ? 'جاري...' : 'تصدير PDF'),
              ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  clientsAsync.when(
                    data: (clients) {
                      return DropdownButtonFormField<Client>(
                        initialValue: _selectedClient,
                        decoration: const InputDecoration(
                          labelText: 'اختر عميلاً',
                          border: OutlineInputBorder(),
                        ),
                        items: clients
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.displayName),
                                ))
                            .toList(),
                        onChanged: (client) {
                          setState(() => _selectedClient = client);
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('خطأ: $e'),
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
              child: _selectedClient == null
                  ? const Center(
                      child: Text(
                        'اختر عميلاً',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : _buildStatement(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatement() {
    final statementAsync = ref.watch(clientStatementProvider(
      (clientId: _selectedClient!.id, range: _selectedRange),
    ));

    return statementAsync.when(
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'رصيد افتتاحي',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatMoney(data.openingBalance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: data.openingBalance < 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (data.entries.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'لا توجد حركات في هذه الفترة',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...data.entries.map((entry) => Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                _typeLabel(entry.type),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.reference,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                formatMoney(entry.amount),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: entry.type ==
                                          StatementEntryType.invoice
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(
                                formatMoney(entry.runningBalance),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: entry.runningBalance < 0
                                      ? Colors.red
                                      : Colors.black,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.closingBalance >= 0 ? 'رصيد مدين' : 'رصيد دائن',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatMoney(data.closingBalance),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: data.closingBalance < 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
    );
  }

  String _typeLabel(StatementEntryType type) => switch (type) {
        StatementEntryType.invoice => 'فاتورة',
        StatementEntryType.receipt => 'سند قبض',
        StatementEntryType.returnItem => 'مرتجع',
      };

  Future<void> _exportPdf() async {
    if (_selectedClient == null) return;
    final statementAsync = ref.read(clientStatementProvider(
      (clientId: _selectedClient!.id, range: _selectedRange),
    ));
    final data = statementAsync.when(
      data: (d) => d,
      loading: () => null,
      error: (_, _) => null,
    );
    if (data == null) return;

    setState(() => _isExporting = true);
    try {
      final styles = await PdfStyles.load();
      final doc = ClientStatementPdf.generate(styles, data);
      final sanitized = data.clientName.replaceAll(RegExp(r'[^\w\s-]'), '');
      await PdfGenerator.shareOrPrint(doc, 'client_statement_$sanitized.pdf');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}