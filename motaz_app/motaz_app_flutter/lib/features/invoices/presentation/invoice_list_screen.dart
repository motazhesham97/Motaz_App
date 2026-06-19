import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/document_reference_formatter.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/audit_trail_sheet.dart';
import '../../clients/application/client_providers.dart';
import '../application/invoice_providers.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';

enum _InvoiceSearchMode { client, date }

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final _clientSearchController = TextEditingController();
  final _clientSearchFocusNode = FocusNode();

  bool _showSearchPanel = false;
  _InvoiceSearchMode _searchMode = _InvoiceSearchMode.client;
  Client? _draftClient;
  DateTime? _draftDate;
  Client? _appliedClient;
  DateTime? _appliedDate;

  @override
  void dispose() {
    _clientSearchController.dispose();
    _clientSearchFocusNode.dispose();
    super.dispose();
  }

  void _applySearch() {
    setState(() {
      if (_searchMode == _InvoiceSearchMode.client) {
        _appliedClient = _draftClient;
        _appliedDate = null;
      } else {
        _appliedDate = _draftDate;
        _appliedClient = null;
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _draftClient = null;
      _draftDate = null;
      _appliedClient = null;
      _appliedDate = null;
      _clientSearchController.clear();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draftDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() => _draftDate = picked);
    }
  }

  List<SalesInvoice> _filterInvoices(List<SalesInvoice> invoices) {
    final client = _appliedClient;
    final date = _appliedDate;

    if (client != null) {
      return invoices
          .where((invoice) => invoice.clientId == client.id)
          .toList();
    }

    if (date != null) {
      return invoices
          .where((invoice) => _sameDate(invoice.invoiceDate, date))
          .toList();
    }

    return invoices;
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _matchesWordPrefix(String value, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return false;
    return value
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .any((word) => word.startsWith(normalizedQuery));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoiceListProvider);
    final clientsAsync = ref.watch(clientListProvider);
    final clients = clientsAsync.maybeWhen(
      data: (clients) => clients,
      orElse: () => const <Client>[],
    );

    return AppDrawerScaffold(
      title: 'الفواتير',
      currentRoute: '/invoices',
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InvoiceFormScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 640;
            final horizontalPadding = isCompact ? 16.0 : 24.0;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildActiveSearchSummary()),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'بحث',
                            onPressed: () {
                              setState(() {
                                _showSearchPanel = !_showSearchPanel;
                              });
                            },
                            icon: Icon(
                              _showSearchPanel ? Icons.close : Icons.search,
                            ),
                          ),
                        ],
                      ),
                      if (_showSearchPanel) ...[
                        const SizedBox(height: 10),
                        _buildSearchPanel(clients, isCompact),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: invoicesAsync.when(
                    data: (invoices) {
                      final filteredInvoices = _filterInvoices(invoices);
                      if (filteredInvoices.isEmpty) {
                        return Center(
                          child: Text(
                            _appliedClient != null || _appliedDate != null
                                ? 'لا توجد فواتير مطابقة للبحث'
                                : 'لا توجد فواتير',
                          ),
                        );
                      }

                      final clientMap = <String, Client>{
                        for (final client in clients) client.id: client,
                      };

                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          96,
                        ),
                        itemCount: filteredInvoices.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final invoice = filteredInvoices[index];
                          final clientName =
                              clientMap[invoice.clientId]?.displayName ??
                              'عميل محذوف';
                          return InvoiceCard(
                            invoice: invoice,
                            clientName: clientName,
                            formattedDate: _formatDate(invoice.invoiceDate),
                            isCompact: isCompact,
                            onOpen: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InvoiceDetailScreen(
                                    invoiceId: invoice.id,
                                  ),
                                ),
                              );
                            },
                            onAudit: () {
                              showAuditTrailSheet(
                                context,
                                ref,
                                ParentEntityType.SALES_INVOICE,
                                invoice.id,
                              );
                            },
                            onReturn: invoice.status == RecordStatus.ACTIVE
                                ? () {
                                    context.go(
                                      '/returns/create?invoiceId=${invoice.id}',
                                    );
                                  }
                                : null,
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          e.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveSearchSummary() {
    final client = _appliedClient;
    final date = _appliedDate;
    final label = client != null
        ? 'البحث: ${client.displayName}'
        : date != null
        ? 'البحث: ${_formatDate(date)}'
        : 'كل الفواتير';

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSearchPanel(List<Client> clients, bool isCompact) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_InvoiceSearchMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _InvoiceSearchMode.client,
                  icon: Icon(Icons.person_search),
                  label: Text('اسم العميل'),
                ),
                ButtonSegment(
                  value: _InvoiceSearchMode.date,
                  icon: Icon(Icons.calendar_month),
                  label: Text('تاريخ الفاتورة'),
                ),
              ],
              selected: {_searchMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _searchMode = selection.first;
                  _draftClient = null;
                  _draftDate = null;
                  _clientSearchController.clear();
                });
              },
            ),
            const SizedBox(height: 12),
            if (_searchMode == _InvoiceSearchMode.client)
              _buildClientSearchField(clients, isCompact)
            else
              _buildDateSearchField(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        (_searchMode == _InvoiceSearchMode.client &&
                                _draftClient == null) ||
                            (_searchMode == _InvoiceSearchMode.date &&
                                _draftDate == null)
                        ? null
                        : _applySearch,
                    icon: const Icon(Icons.search),
                    label: const Text('بحث'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                  label: const Text('مسح'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSearchField(List<Client> clients, bool isCompact) {
    return RawAutocomplete<Client>(
      textEditingController: _clientSearchController,
      focusNode: _clientSearchFocusNode,
      displayStringForOption: (client) => client.displayName,
      optionsBuilder: (value) {
        final query = value.text.trim();
        if (query.isEmpty) return const <Client>[];
        return clients.where(
          (client) => _matchesWordPrefix(client.displayName, query),
        );
      },
      onSelected: (client) {
        setState(() => _draftClient = client);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'اسم العميل',
            hintText: 'اكتب أول حروف اسم العميل',
            prefixIcon: const Icon(Icons.person_search),
            suffixIcon: _draftClient != null
                ? IconButton(
                    tooltip: 'مسح العميل',
                    onPressed: () {
                      setState(() {
                        _draftClient = null;
                        controller.clear();
                      });
                    },
                    icon: const Icon(Icons.close),
                  )
                : null,
          ),
          onChanged: (_) {
            if (_draftClient != null) {
              setState(() => _draftClient = null);
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final width = MediaQuery.sizeOf(context).width - 32;
        return Align(
          alignment: Alignment.topRight,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 240,
                maxWidth: isCompact ? width : 420,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final client = options.elementAt(index);
                  return ListTile(
                    title: Text(client.displayName),
                    subtitle: client.phone == null ? null : Text(client.phone!),
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

  Widget _buildDateSearchField() {
    return OutlinedButton.icon(
      onPressed: _pickDate,
      icon: const Icon(Icons.calendar_month),
      label: Text(
        _draftDate == null ? 'اختيار تاريخ الفاتورة' : _formatDate(_draftDate!),
      ),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.clientName,
    required this.formattedDate,
    required this.isCompact,
    required this.onOpen,
    required this.onAudit,
    required this.onReturn,
  });

  final SalesInvoice invoice;
  final String clientName;
  final String formattedDate;
  final bool isCompact;
  final VoidCallback onOpen;
  final VoidCallback onAudit;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVoided = invoice.status == RecordStatus.VOIDED;
    final reference = invoiceDisplayRef(
      invoice.localRef,
      officialNo: invoice.officialNo,
    );

    if (isCompact) {
      return Opacity(
        opacity: isVoided ? 0.62 : 1,
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isVoided
                              ? Colors.red.withValues(alpha: 0.12)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: isVoided ? Colors.red : colorScheme.secondary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isVoided)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'ملغية',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (isVoided) const SizedBox(height: 8),
                  Text(
                    clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatMoney(invoice.total),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'سجل التعديلات',
                        onPressed: onAudit,
                        icon: const Icon(Icons.history),
                      ),
                      if (onReturn != null)
                        PopupMenuButton<String>(
                          tooltip: 'خيارات',
                          onSelected: (value) {
                            if (value == 'return') onReturn?.call();
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'return',
                              child: Text('إنشاء مرتجع'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: isVoided ? 0.62 : 1,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onOpen,
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isVoided
                            ? Colors.red.withValues(alpha: 0.12)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: isVoided ? Colors.red : colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                reference,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isCompact ? 18 : 20,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (isVoided)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: const Text(
                                    'ملغية',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatMoney(invoice.total),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: isCompact ? 20 : 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'سجل التعديلات',
                      onPressed: onAudit,
                      icon: const Icon(Icons.history),
                    ),
                    if (onReturn != null)
                      PopupMenuButton<String>(
                        tooltip: 'خيارات',
                        onSelected: (value) {
                          if (value == 'return') onReturn?.call();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'return',
                            child: Text('إنشاء مرتجع'),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
