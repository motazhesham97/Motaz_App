import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/document_reference_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/audit_trail_sheet.dart';
import '../../clients/application/client_providers.dart';
import '../application/return_providers.dart';

enum _ReturnSearchMode { client, date }

class ReturnListScreen extends ConsumerStatefulWidget {
  const ReturnListScreen({super.key});

  @override
  ConsumerState<ReturnListScreen> createState() => _ReturnListScreenState();
}

class _ReturnListScreenState extends ConsumerState<ReturnListScreen> {
  final _clientSearchController = TextEditingController();
  final _clientSearchFocusNode = FocusNode();

  bool _showSearchPanel = false;
  _ReturnSearchMode _searchMode = _ReturnSearchMode.client;
  Client? _draftClient;
  DateTime? _draftDate;
  Client? _appliedClient;
  DateTime? _appliedDate;
  Map<String, String> _invoiceRefs = {};
  Map<String, String> _invoiceClientIds = {};
  Set<String> _loadedInvoiceIds = {};

  @override
  void dispose() {
    _clientSearchController.dispose();
    _clientSearchFocusNode.dispose();
    super.dispose();
  }

  void _applySearch() {
    setState(() {
      if (_searchMode == _ReturnSearchMode.client) {
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

  List<SalesReturn> _filterReturns(List<SalesReturn> returns) {
    final client = _appliedClient;
    final date = _appliedDate;

    if (client != null) {
      return returns
          .where((ret) => _invoiceClientIds[ret.invoiceId] == client.id)
          .toList();
    }

    if (date != null) {
      return returns.where((ret) => _sameDate(ret.returnDate, date)).toList();
    }

    return returns;
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatMoney(int minorUnits) {
    return '${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
  }

  Future<void> _loadInvoiceDetailsIfNeeded(List<SalesReturn> returns) async {
    final invoiceIds = returns.map((r) => r.invoiceId).toSet();
    if (invoiceIds.difference(_loadedInvoiceIds).isEmpty) {
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final invoiceIdList = invoiceIds.toList();
    final invoices = await (db.select(
      db.salesInvoices,
    )..where((t) => t.id.isIn(invoiceIdList))).get();

    if (mounted) {
      setState(() {
        _invoiceRefs = {
          for (final inv in invoices) inv.id: inv.officialNo ?? inv.localRef,
        };
        _invoiceClientIds = {for (final inv in invoices) inv.id: inv.clientId};
        _loadedInvoiceIds = invoiceIds;
      });
    }
  }

  Future<void> _showVoidDialog(SalesReturn ret) async {
    final reasonController = TextEditingController();
    String reasonText = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء المرتجع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من إلغاء هذا المرتجع؟'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء *',
                hintText: 'أدخل سبب الإلغاء',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () {
              final text = reasonController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سبب الإلغاء مطلوب')),
                );
                return;
              }
              reasonText = text;
              Navigator.of(context).pop(true);
            },
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
    reasonController.dispose();

    if (confirmed == true) {
      await _voidReturn(ret, reasonText);
    }
  }

  Future<void> _voidReturn(SalesReturn ret, String reason) async {
    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      final repo = ref.read(returnRepositoryProvider);
      await repo.voidReturn(ret.id, reason, device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء المرتجع')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(returnListProvider);
    final clientsAsync = ref.watch(clientListProvider);
    final clients = clientsAsync.maybeWhen(
      data: (clients) => clients,
      orElse: () => const <Client>[],
    );

    return AppDrawerScaffold(
      title: 'المرتجعات',
      currentRoute: '/returns',
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildActiveSearchSummary()),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'بحث',
                        onPressed: () {
                          setState(() => _showSearchPanel = !_showSearchPanel);
                        },
                        icon: Icon(
                          _showSearchPanel ? Icons.close : Icons.search,
                        ),
                      ),
                    ],
                  ),
                  if (_showSearchPanel) ...[
                    const SizedBox(height: 10),
                    _buildSearchPanel(clients),
                  ],
                ],
              ),
            ),
            Expanded(
              child: returnsAsync.when(
                data: (returns) {
                  _loadInvoiceDetailsIfNeeded(returns);

                  final filteredReturns = _filterReturns(returns);
                  if (filteredReturns.isEmpty) {
                    return Center(
                      child: Text(
                        _appliedClient != null || _appliedDate != null
                            ? 'لا توجد مرتجعات مطابقة للبحث'
                            : 'لا توجد مرتجعات',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: filteredReturns.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final ret = filteredReturns[index];
                      final isVoided = ret.status == RecordStatus.VOIDED;
                      final invoiceRef = _invoiceRefs[ret.invoiceId];
                      final returnRef = returnDisplayRef(
                        ret.localRef,
                        officialNo: ret.officialNo,
                      );

                      return Opacity(
                        opacity: isVoided ? 0.6 : 1.0,
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              // We can add navigation to return details later
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isCompact = constraints.maxWidth < 520;
                                  if (isCompact) {
                                    return _buildCompactReturnContent(
                                      context: context,
                                      ret: ret,
                                      isVoided: isVoided,
                                      returnRef: returnRef,
                                      invoiceRef: invoiceRef,
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isVoided
                                              ? Colors.red.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.keyboard_return_rounded,
                                          color: isVoided
                                              ? Colors.red
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      SizedBox(width: isCompact ? 10 : 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    returnRef,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                if (isVoided) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            Colors.red.shade200,
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'ملغى',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                  invoiceRef == null
                                                      ? 'على فاتورة غير معروفة'
                                                      : 'على ${invoiceDisplayRef(invoiceRef)}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  ' â€¢ ',
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            )
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                                ),
                                                Text(
                                                  _formatDate(ret.returnDate),
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            )
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                                ),
                                                if (ret.note != null &&
                                                    ret.note!.isNotEmpty) ...[
                                                  Text(
                                                    ' â€¢ ',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                  Text(
                                                    ret.note!,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: isCompact ? 96 : 140,
                                        ),
                                        child: Text(
                                          _formatMoney(ret.totalReturnedAmount),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: isCompact ? 8 : 16),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.history,
                                              size: 20,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                            tooltip: 'سجل التعديلات',
                                            onPressed: () {
                                              showAuditTrailSheet(
                                                context,
                                                ref,
                                                ParentEntityType.SALES_RETURN,
                                                ret.id,
                                              );
                                            },
                                          ),
                                          if (!isVoided)
                                            PopupMenuButton<String>(
                                              icon: Icon(
                                                Icons.more_vert,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              onSelected: (value) {
                                                if (value == 'void') {
                                                  _showVoidDialog(ret);
                                                }
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 'void',
                                                  child: Text('إلغاء المرتجع'),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('خطأ: $error')),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.go('/returns/create');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCompactReturnContent({
    required BuildContext context,
    required SalesReturn ret,
    required bool isVoided,
    required String returnRef,
    required String? invoiceRef,
  }) {
    return ReturnCompactCardContent(
      ret: ret,
      isVoided: isVoided,
      returnRef: returnRef,
      invoiceRef: invoiceRef,
      onShowAuditTrail: () {
        showAuditTrailSheet(
          context,
          ref,
          ParentEntityType.SALES_RETURN,
          ret.id,
        );
      },
      onVoid: () => _showVoidDialog(ret),
    );
  }

  Widget _buildActiveSearchSummary() {
    final client = _appliedClient;
    final date = _appliedDate;
    final label = client != null
        ? 'البحث: ${client.displayName}'
        : date != null
        ? 'البحث: ${_formatDate(date)}'
        : 'كل المرتجعات';

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerRight,
      child: Text(label, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildSearchPanel(List<Client> clients) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_ReturnSearchMode>(
              segments: const [
                ButtonSegment(
                  value: _ReturnSearchMode.client,
                  icon: Icon(Icons.person_search),
                  label: Text('اسم العميل'),
                ),
                ButtonSegment(
                  value: _ReturnSearchMode.date,
                  icon: Icon(Icons.calendar_month),
                  label: Text('تاريخ المرتجع'),
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
            if (_searchMode == _ReturnSearchMode.client)
              _buildClientSearchField(clients)
            else
              _buildDateSearchField(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        (_searchMode == _ReturnSearchMode.client &&
                                _draftClient == null) ||
                            (_searchMode == _ReturnSearchMode.date &&
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

  Widget _buildClientSearchField(List<Client> clients) {
    return RawAutocomplete<Client>(
      textEditingController: _clientSearchController,
      focusNode: _clientSearchFocusNode,
      displayStringForOption: (client) => client.displayName,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return const <Client>[];
        return clients.where(
          (client) => client.displayName.toLowerCase().startsWith(query),
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
        return Align(
          alignment: Alignment.topRight,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 420),
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
        _draftDate == null ? 'اختيار تاريخ المرتجع' : _formatDate(_draftDate!),
      ),
    );
  }
}

class ReturnCompactCardContent extends StatelessWidget {
  const ReturnCompactCardContent({
    super.key,
    required this.ret,
    required this.isVoided,
    required this.returnRef,
    required this.invoiceRef,
    required this.onShowAuditTrail,
    required this.onVoid,
  });

  final SalesReturn ret;
  final bool isVoided;
  final String returnRef;
  final String? invoiceRef;
  final VoidCallback onShowAuditTrail;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ref = invoiceRef;
    final invoiceLabel = ref == null
        ? 'على فاتورة غير معروفة'
        : 'على ${invoiceDisplayRef(ref)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isVoided
                    ? Colors.red.withValues(alpha: 0.1)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.keyboard_return_rounded,
                color: isVoided ? Colors.red : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        returnRef,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isVoided)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Text(
                            'ملغى',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    invoiceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatReturnCardDate(ret.returnDate),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (ret.note != null && ret.note!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            ret.note!.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _formatReturnCardMoney(ret.totalReturnedAmount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colorScheme.primary,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.history,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'سجل التعديلات',
              onPressed: onShowAuditTrail,
            ),
            if (!isVoided)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'void') onVoid();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'void',
                    child: Text('إلغاء المرتجع'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

String _formatReturnCardDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _formatReturnCardMoney(int minorUnits) {
  return '${(minorUnits / 100).toStringAsFixed(2)} ر.ي';
}
