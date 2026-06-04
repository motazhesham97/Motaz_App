import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../clients/application/client_providers.dart';
import '../application/report_providers.dart';
import '../data/report_models.dart';
import '../pdf/pdf_generator.dart';
import '../pdf/pdf_styles.dart';
import '../pdf/pdf_templates/client_receivables_report_pdf.dart';

enum _ReportPeriod {
  today,
  last7Days,
  thisMonth,
  lastMonth,
  allTime,
  custom,
}

class ClientReceivablesReportScreen extends ConsumerStatefulWidget {
  const ClientReceivablesReportScreen({super.key});

  @override
  ConsumerState<ClientReceivablesReportScreen> createState() =>
      _ClientReceivablesReportScreenState();
}

class _ClientReceivablesReportScreenState
    extends ConsumerState<ClientReceivablesReportScreen> {
  final _clientController = TextEditingController();
  final _clientFocusNode = FocusNode();
  _ReportPeriod _period = _ReportPeriod.thisMonth;
  late DateRange _range;
  Client? _selectedClient;
  String _clientQuery = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _range = DateRange.thisMonth();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _clientFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);
    final reportAsync = ref.watch(
      clientReceivablesReportProvider(
        (
          range: _range,
          clientId: _selectedClient?.id,
          clientName: _selectedClient?.displayName,
        ),
      ),
    );

    return AppDrawerScaffold(
      title: 'المبالغ المتبقية عند العملاء',
      currentRoute: '/reports/client-receivables',
      leading: IconButton(
        tooltip: 'الرجوع',
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/reports/clients'),
      ),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isExporting ? null : _exportPdf,
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
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  clientsAsync.when(
                    data: _buildClientSearch,
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text('خطأ: $error'),
                  ),
                  const SizedBox(height: 12),
                  _buildPeriodPicker(),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: reportAsync.when(
                data: _buildReport,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('خطأ: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSearch(List<Client> clients) {
    return RawAutocomplete<Client>(
      textEditingController: _clientController,
      focusNode: _clientFocusNode,
      displayStringForOption: (client) => client.displayName,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) return const Iterable<Client>.empty();
        final normalized = query.toLowerCase();
        return clients.where((client) {
          final phone = client.phone?.toLowerCase() ?? '';
          final code = client.clientCode?.toLowerCase() ?? '';
          return _matchesWordPrefix(client.displayName, query) ||
              phone.startsWith(normalized) ||
              code.startsWith(normalized);
        });
      },
      onSelected: (client) {
        setState(() {
          _selectedClient = client;
          _clientQuery = client.displayName;
          _clientController.text = client.displayName;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'اسم العميل',
            hintText: 'اكتب بداية أي كلمة من اسم العميل',
            prefixIcon: const Icon(Icons.person_search_rounded),
            suffixIcon: _clientQuery.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'مسح',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _clientController.clear();
                        _clientQuery = '';
                        _selectedClient = null;
                      });
                    },
                  ),
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            final normalized = value.trim().toLowerCase();
            Client? exactMatch;
            for (final client in clients) {
              if (client.displayName.trim().toLowerCase() == normalized) {
                exactMatch = client;
                break;
              }
            }
            setState(() {
              _clientQuery = value;
              _selectedClient = exactMatch;
            });
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 480),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final client = options.elementAt(index);
                  return ListTile(
                    title: Text(client.displayName),
                    subtitle: client.phone != null
                        ? Text(client.phone!)
                        : client.clientCode != null
                        ? Text(client.clientCode!)
                        : null,
                    onTap: () => onSelected(client),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodPicker() {
    return DropdownButtonFormField<_ReportPeriod>(
      initialValue: _period,
      decoration: const InputDecoration(
        labelText: 'المدة',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.date_range_rounded),
      ),
      items: const [
        DropdownMenuItem(value: _ReportPeriod.today, child: Text('اليوم')),
        DropdownMenuItem(
          value: _ReportPeriod.last7Days,
          child: Text('آخر 7 أيام'),
        ),
        DropdownMenuItem(
          value: _ReportPeriod.thisMonth,
          child: Text('هذا الشهر'),
        ),
        DropdownMenuItem(
          value: _ReportPeriod.lastMonth,
          child: Text('الشهر الماضي'),
        ),
        DropdownMenuItem(
          value: _ReportPeriod.allTime,
          child: Text('مدى العمل'),
        ),
        DropdownMenuItem(
          value: _ReportPeriod.custom,
          child: Text('تاريخ خاص'),
        ),
      ],
      onChanged: (period) {
        if (period == null) return;
        _selectPeriod(period);
      },
    );
  }

  Widget _buildReport(ClientReceivablesReportData data) {
    final rows = _filteredRows(data.rows);
    final totalRemaining = rows.fold(
      0,
      (sum, row) => sum + row.remainingBalance,
    );

    if (rows.isEmpty) {
      return const Center(child: Text('لا توجد مبالغ متبقية حسب الفلترة'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'إجمالي المتبقي',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  formatMoney(totalRemaining),
                  style: TextStyle(
                    color: totalRemaining < 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...rows.map(
          (row) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    row.clientName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _AmountChip('الفواتير', row.totalInvoiced),
                      _AmountChip('المدفوع', row.totalPaid),
                      _AmountChip('المرتجع', row.totalReturned),
                      _AmountChip(
                        'المتبقي',
                        row.remainingBalance,
                        prominent: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectPeriod(_ReportPeriod period) async {
    if (period == _ReportPeriod.custom) {
      final range = await _pickCustomRange();
      if (range == null) return;
      setState(() {
        _period = period;
        _range = range;
      });
      return;
    }

    setState(() {
      _period = period;
      _range = _rangeFor(period);
    });
  }

  Future<DateRange?> _pickCustomRange() async {
    final start = await showDatePicker(
      context: context,
      initialDate: _range.start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (start == null || !mounted) return null;

    final end = await showDatePicker(
      context: context,
      initialDate: _range.end.subtract(const Duration(days: 1)),
      firstDate: start,
      lastDate: DateTime(2100),
    );
    if (end == null) return null;

    return DateRange.custom(
      DateTime(start.year, start.month, start.day),
      DateTime(end.year, end.month, end.day + 1),
    );
  }

  DateRange _rangeFor(_ReportPeriod period) {
    final now = DateTime.now();
    return switch (period) {
      _ReportPeriod.today => DateRange.today(),
      _ReportPeriod.last7Days => DateRange.custom(
        DateTime(now.year, now.month, now.day - 6),
        DateTime(now.year, now.month, now.day + 1),
      ),
      _ReportPeriod.thisMonth => DateRange.thisMonth(),
      _ReportPeriod.lastMonth => DateRange.custom(
        DateTime(now.year, now.month - 1, 1),
        DateTime(now.year, now.month, 1),
      ),
      _ReportPeriod.allTime => DateRange.allTime(),
      _ReportPeriod.custom => _range,
    };
  }

  List<ReceivablesRow> _filteredRows(List<ReceivablesRow> rows) {
    final query = _clientQuery.trim();
    if (_selectedClient != null || query.isEmpty) return rows;
    return rows
        .where((row) => _matchesWordPrefix(row.clientName, query))
        .toList();
  }

  bool _matchesWordPrefix(String value, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    final terms = normalizedQuery.split(RegExp(r'\s+'));
    final words = value
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return terms.every((term) => words.any((word) => word.startsWith(term)));
  }

  Future<void> _exportPdf() async {
    final asyncData = ref.read(
      clientReceivablesReportProvider(
        (
          range: _range,
          clientId: _selectedClient?.id,
          clientName: _selectedClient?.displayName,
        ),
      ),
    );
    final data = asyncData.when(
      data: (value) => value,
      loading: () => null,
      error: (_, _) => null,
    );
    if (data == null) return;

    final rows = _filteredRows(data.rows);
    final exportData = ClientReceivablesReportData(
      dateRange: data.dateRange,
      filterLabel: _filterLabel(),
      rows: rows,
      totalInvoiced: rows.fold(0, (sum, row) => sum + row.totalInvoiced),
      totalPaid: rows.fold(0, (sum, row) => sum + row.totalPaid),
      totalReturned: rows.fold(0, (sum, row) => sum + row.totalReturned),
      totalRemaining: rows.fold(0, (sum, row) => sum + row.remainingBalance),
    );

    setState(() => _isExporting = true);
    try {
      final styles = await PdfStyles.load();
      final doc = ClientReceivablesReportPdf.generate(styles, exportData);
      await PdfGenerator.shareOrPrint(doc, 'client_receivables_report.pdf');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _filterLabel() {
    final client = _selectedClient?.displayName ?? _clientQuery.trim();
    final clientLabel = client.isEmpty ? 'كل العملاء' : client;
    return '$clientLabel - ${_periodLabel(_period)}';
  }

  String _periodLabel(_ReportPeriod period) {
    return switch (period) {
      _ReportPeriod.today => 'اليوم',
      _ReportPeriod.last7Days => 'آخر 7 أيام',
      _ReportPeriod.thisMonth => 'هذا الشهر',
      _ReportPeriod.lastMonth => 'الشهر الماضي',
      _ReportPeriod.allTime => 'مدى العمل',
      _ReportPeriod.custom => 'تاريخ خاص',
    };
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip(this.label, this.amount, {this.prominent = false});

  final String label;
  final int amount;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final color = amount < 0 ? Colors.red : Colors.green;
    return Chip(
      label: Text('$label: ${formatMoney(amount)}'),
      labelStyle: TextStyle(
        fontWeight: prominent ? FontWeight.bold : FontWeight.normal,
        color: prominent ? color : null,
      ),
    );
  }
}
