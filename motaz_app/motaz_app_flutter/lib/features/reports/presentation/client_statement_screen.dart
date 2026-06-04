import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../attachments/application/document_attachment_reader.dart';
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
  final _clientNameController = TextEditingController();
  final _clientFocusNode = FocusNode();
  late DateRange _selectedRange;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedRange = DateRange.thisMonth();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientFocusNode.dispose();
    super.dispose();
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
    return terms.every(
      (term) => words.any((word) => word.startsWith(term)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);

    return AppDrawerScaffold(
      title: 'كشف حساب عميل',
      currentRoute: '/reports/client-statement',
      leading: IconButton(
        tooltip: 'الرجوع للتقارير',
        icon: const BackButtonIcon(),
        onPressed: () => context.go('/reports/clients'),
      ),
      child: Scaffold(
        floatingActionButton: _selectedClient == null
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  clientsAsync.when(
                    data: (clients) => _buildClientSearch(clients),
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
                        'اختر عميلا',
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

  Widget _buildClientSearch(List<Client> clients) {
    return RawAutocomplete<Client>(
      textEditingController: _clientNameController,
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
          _clientNameController.text = client.displayName;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'اختر عميلا',
            hintText: 'اكتب بداية أي كلمة من اسم العميل',
            prefixIcon: Icon(Icons.person_search_rounded),
            border: OutlineInputBorder(),
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
            if (exactMatch != null) {
              setState(() => _selectedClient = exactMatch);
              return;
            }
            final selected = _selectedClient;
            if (selected != null &&
                selected.displayName.trim() != value.trim()) {
              setState(() => _selectedClient = null);
            }
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
              constraints: const BoxConstraints(maxHeight: 240),
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

  Widget _buildStatement() {
    final statementAsync = ref.watch(
      clientStatementProvider(
        (clientId: _selectedClient!.id, range: _selectedRange),
      ),
    );

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
                          color: data.openingBalance >= 0
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
                ...data.entries.map(
                  _buildStatementEntryCard,
                ),
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.closingBalance >= 0 ? 'رصيد عليه' : 'رصيد له',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: data.closingBalance >= 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      Text(
                        formatMoney(data.closingBalance.abs()),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: data.closingBalance >= 0
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

  Widget _buildStatementEntryCard(ClientStatementEntry entry) {
    final amountColor = entry.type == StatementEntryType.invoice
        ? Colors.red
        : Colors.green;
    final balanceColor = entry.runningBalance >= 0
        ? Colors.red
        : Colors.green;
    final date =
        '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _typeLabel(entry.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        date,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatMoney(entry.amount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: amountColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          formatMoney(entry.runningBalance),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: balanceColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    date,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 78,
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
                Flexible(
                  child: Text(
                    formatMoney(entry.amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: amountColor),
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    formatMoney(entry.runningBalance),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _typeLabel(StatementEntryType type) => switch (type) {
    StatementEntryType.invoice => 'فاتورة',
    StatementEntryType.receipt => 'سند قبض',
    StatementEntryType.returnItem => 'مرتجع',
  };

  Future<void> _exportPdf() async {
    if (_selectedClient == null) return;
    final statementAsync = ref.read(
      clientStatementProvider(
        (clientId: _selectedClient!.id, range: _selectedRange),
      ),
    );
    final data = statementAsync.when(
      data: (d) => d,
      loading: () => null,
      error: (_, _) => null,
    );
    if (data == null) return;

    setState(() => _isExporting = true);
    try {
      final exportData = await _attachStatementImages(data);
      final styles = await PdfStyles.load();
      final doc = ClientStatementPdf.generate(styles, exportData);
      final sanitized = data.clientName.replaceAll(RegExp(r'[^\w\s-]'), '');
      await PdfGenerator.shareOrPrint(doc, 'client_statement_$sanitized.pdf');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<ClientStatementData> _attachStatementImages(
    ClientStatementData data,
  ) async {
    final reader = ref.read(documentAttachmentReaderProvider);
    final entries = <ClientStatementEntry>[];
    for (final entry in data.entries) {
      entries.add(
        entry.copyWith(
          attachmentImages: await reader.loadImages(
            parentEntityType: entry.parentEntityType,
            parentEntityId: entry.entityId,
          ),
        ),
      );
    }

    return ClientStatementData(
      clientName: data.clientName,
      dateRange: data.dateRange,
      openingBalance: data.openingBalance,
      entries: entries,
      closingBalance: data.closingBalance,
    );
  }
}
