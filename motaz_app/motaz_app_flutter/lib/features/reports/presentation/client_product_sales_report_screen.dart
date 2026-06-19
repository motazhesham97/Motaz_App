import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../clients/application/client_providers.dart';
import '../application/report_providers.dart';
import '../pdf/pdf_file_names.dart';
import '../pdf/pdf_generator.dart';
import '../pdf/pdf_styles.dart';
import '../pdf/pdf_templates/client_product_sales_report_pdf.dart';

enum _ReportPeriod {
  today,
  last7Days,
  thisMonth,
  lastMonth,
  allTime,
  custom,
}

class ClientProductSalesReportScreen extends ConsumerStatefulWidget {
  const ClientProductSalesReportScreen({super.key});

  @override
  ConsumerState<ClientProductSalesReportScreen> createState() =>
      _ClientProductSalesReportScreenState();
}

class _ClientProductSalesReportScreenState
    extends ConsumerState<ClientProductSalesReportScreen> {
  final _productController = TextEditingController();
  _ReportPeriod _period = _ReportPeriod.thisMonth;
  late DateRange _range;
  Client? _selectedClient;
  String _productQuery = '';
  bool _isExporting = false;
  bool _didRequestClient = false;

  @override
  void initState() {
    super.initState();
    _range = DateRange.thisMonth();
  }

  @override
  void dispose() {
    _productController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);

    if (!_didRequestClient && _selectedClient == null) {
      clientsAsync.when(
        data: (clients) {
          _didRequestClient = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _chooseClient(clients);
          });
        },
        loading: () {},
        error: (_, _) {},
      );
    }

    final selectedClient = _selectedClient;
    final reportAsync = selectedClient == null
        ? null
        : ref.watch(
            clientProductSalesReportProvider(
              (
                clientId: selectedClient.id,
                clientName: selectedClient.displayName,
                range: _range,
                productQuery: _productQuery,
              ),
            ),
          );

    return AppDrawerScaffold(
      title: 'المنتجات المباعة لعميل',
      currentRoute: '/reports/client-products',
      leading: IconButton(
        tooltip: 'الرجوع',
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/reports/clients'),
      ),
      child: Scaffold(
        floatingActionButton: selectedClient == null
            ? null
            : FloatingActionButton.extended(
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
        body: selectedClient == null
            ? _buildClientEmptyState(clientsAsync)
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.person_rounded),
                            title: Text(selectedClient.displayName),
                            trailing: TextButton.icon(
                              onPressed: () {
                                final clients = clientsAsync.when(
                                  data: (value) => value,
                                  loading: () => null,
                                  error: (_, _) => null,
                                );
                                if (clients != null) _chooseClient(clients);
                              },
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: const Text('تغيير العميل'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _productController,
                          decoration: InputDecoration(
                            labelText: 'اسم المنتج',
                            hintText:
                                'اختياري - اكتب بداية أي كلمة من اسم المنتج',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _productQuery.trim().isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'مسح',
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _productController.clear();
                                        _productQuery = '';
                                      });
                                    },
                                  ),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() => _productQuery = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildPeriodPicker(),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: reportAsync!.when(
                      data: (data) {
                        if (data.rows.isEmpty) {
                          return const Center(
                            child: Text('لا توجد منتجات مباعة'),
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formatMoney(data.netSales),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'إجمالي المبيعات',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetricChip(
                                  label: 'إجمالي البيع',
                                  value: formatMoney(data.totalSales),
                                ),
                                _MetricChip(
                                  label: 'إجمالي المرتجع',
                                  value: formatMoney(data.totalReturns),
                                ),
                                _MetricChip(
                                  label: 'صافي الكمية',
                                  value: data.netQuantity.toString(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...data.rows.map(
                              (row) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ListTile(
                                      title: Text(
                                        row.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'الكمية: ${row.totalQuantitySold}',
                                      ),
                                      trailing: Text(
                                        formatMoney(row.netSales),
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        12,
                                      ),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _MetricChip(
                                            label: 'المرتجع',
                                            value: row.totalQuantityReturned
                                                .toString(),
                                          ),
                                          _MetricChip(
                                            label: 'صافي الكمية',
                                            value: row.netQuantity.toString(),
                                          ),
                                          _MetricChip(
                                            label: 'قيمة المرتجع',
                                            value: formatMoney(
                                              row.totalReturns,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text('خطأ: $error')),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildClientEmptyState(AsyncValue<List<Client>> clientsAsync) {
    return Center(
      child: clientsAsync.when(
        data: (clients) => FilledButton.icon(
          onPressed: () => _chooseClient(clients),
          icon: const Icon(Icons.person_search_rounded),
          label: const Text('اختيار عميل'),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (error, _) => Text('خطأ: $error'),
      ),
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

  Future<void> _chooseClient(List<Client> clients) async {
    final client = await showDialog<Client>(
      context: context,
      builder: (context) => _ClientPickerDialog(clients: clients),
    );
    if (client == null) return;
    setState(() {
      _selectedClient = client;
      _productController.clear();
      _productQuery = '';
    });
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

  Future<void> _exportPdf() async {
    final selectedClient = _selectedClient;
    if (selectedClient == null) return;

    final asyncData = ref.read(
      clientProductSalesReportProvider(
        (
          clientId: selectedClient.id,
          clientName: selectedClient.displayName,
          range: _range,
          productQuery: _productQuery,
        ),
      ),
    );
    final data = asyncData.when(
      data: (value) => value,
      loading: () => null,
      error: (_, _) => null,
    );
    if (data == null) return;

    setState(() => _isExporting = true);
    try {
      final styles = await PdfStyles.load();
      final doc = ClientProductSalesReportPdf.generate(styles, data);
      final savedPath = await PdfGenerator.shareOrPrint(
        doc,
        PdfReportFileNames.dated(
          'تقرير مبيعات منتجات العميل',
          subject: selectedClient.displayName,
        ),
      );
      if (!mounted) return;
      PdfGenerator.showSavedSnackBar(context, savedPath);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ClientPickerDialog extends StatefulWidget {
  const _ClientPickerDialog({required this.clients});

  final List<Client> clients;

  @override
  State<_ClientPickerDialog> createState() => _ClientPickerDialogState();
}

class _ClientPickerDialogState extends State<_ClientPickerDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Client? _selectedClient;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختر عميل'),
      content: SizedBox(
        width: 520,
        child: RawAutocomplete<Client>(
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: (client) => client.displayName,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim();
            if (query.isEmpty) return const Iterable<Client>.empty();
            final normalized = query.toLowerCase();
            return widget.clients.where((client) {
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
              _controller.text = client.displayName;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ادخل اسم العميل',
                prefixIcon: Icon(Icons.person_search_rounded),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final normalized = value.trim().toLowerCase();
                Client? exactMatch;
                for (final client in widget.clients) {
                  if (client.displayName.trim().toLowerCase() == normalized) {
                    exactMatch = client;
                    break;
                  }
                }
                setState(() => _selectedClient = exactMatch);
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
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                    maxWidth: 480,
                  ),
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('غلق'),
        ),
        FilledButton(
          onPressed: _selectedClient == null
              ? null
              : () => Navigator.of(context).pop(_selectedClient),
          child: const Text('اختيار'),
        ),
      ],
    );
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
}
