import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/parent_entity_type.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/database/enums/receipt_type.dart';
import '../../../core/utils/document_reference_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/audit_trail_sheet.dart';
import '../application/receipt_providers.dart';
import 'receipt_form_screen.dart';

enum _ReceiptSearchMode { client, date }

class ReceiptListScreen extends ConsumerStatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  ConsumerState<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends ConsumerState<ReceiptListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  _ReceiptSearchMode _searchMode = _ReceiptSearchMode.client;
  DateTime? _searchDate;
  bool _searchOpen = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim();
        });
      }
    });
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

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickSearchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _searchDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _searchDate = picked);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _searchQuery = '';
      _searchDate = null;
    });
  }

  String _formatMoney(int minorUnits) {
    return '${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showVoidDialog(Receipt receipt) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء السند'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من إلغاء هذا السند؟'),
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
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سبب الإلغاء مطلوب')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed == true && reason.isNotEmpty) {
      await _voidReceipt(receipt, reason);
    }
  }

  Future<void> _voidReceipt(Receipt receipt, String reason) async {
    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      final repo = ref.read(receiptRepositoryProvider);
      await repo.voidReceipt(receipt.id, reason, device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء السند')),
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

  Future<void> _editReceipt(Receipt receipt) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptFormScreen(existingReceipt: receipt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(receiptListProvider);

    return AppDrawerScaffold(
      title: 'سندات القبض',
      currentRoute: '/receipts',
      child: Scaffold(
        body: Column(
          children: [
            _buildSearchPanel(),
            Expanded(
              child: receiptsAsync.when(
                data: (receipts) {
                  return FutureBuilder<Map<String, String>>(
                    future: ref
                        .read(receiptRepositoryProvider)
                        .getClientNamesByReceiptId(),
                    builder: (context, clientSnapshot) {
                      final clientMap = clientSnapshot.data ?? const {};
                      final visibleReceipts = receipts.where((receipt) {
                        if (!_searchOpen) return true;
                        if (_searchMode == _ReceiptSearchMode.date) {
                          final date = _searchDate;
                          return date == null ||
                              _sameDay(receipt.receiptDate, date);
                        }
                        final clientName = clientMap[receipt.id] ?? '';
                        return _matchesWordPrefix(clientName, _searchQuery);
                      }).toList();

                      if (visibleReceipts.isEmpty) {
                        return const Center(
                          child: Text('لا توجد سندات'),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        itemCount: visibleReceipts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final receipt = visibleReceipts[index];
                          final clientName =
                              clientMap[receipt.id] ?? 'عميل غير معروف';
                          final isVoided =
                              receipt.status == RecordStatus.VOIDED;
                          final isInvoiceLinked =
                              receipt.receiptType == ReceiptType.INVOICE_LINKED;

                          final receiptRef = receiptDisplayRef(
                            receipt.localRef,
                            officialNo: receipt.officialNo,
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
                                  if (!isVoided) _editReceipt(receipt);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
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
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    8,
                                                  ),
                                            ),
                                            child: Icon(
                                              Icons.payments_rounded,
                                              color: isVoided
                                                  ? Colors.red
                                                  : Theme.of(
                                                          context,
                                                        )
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        receiptRef,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Color(
                                                            0xFFFFFFFF,
                                                          ),
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
                                                          color: Colors
                                                              .red
                                                              .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors
                                                                .red
                                                                .shade200,
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
                                                      clientName,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Color(
                                                          0xFFFFFFFF,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      ' • ',
                                                      style: TextStyle(
                                                        color: const Color(
                                                          0xFFFFFFFF,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatDate(
                                                        receipt.receiptDate,
                                                      ),
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                    if (isInvoiceLinked) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'مرتبط بفاتورة',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 140,
                                            ),
                                            child: Text(
                                              _formatMoney(receipt.amount),
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
                                          const SizedBox(width: 16),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.history,
                                                  size: 20,
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          )
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                                tooltip: 'سجل التعديلات',
                                                onPressed: () {
                                                  showAuditTrailSheet(
                                                    context,
                                                    ref,
                                                    ParentEntityType.RECEIPT,
                                                    receipt.id,
                                                  );
                                                },
                                              ),
                                              if (!isVoided)
                                                PopupMenuButton<String>(
                                                  icon: Icon(
                                                    Icons.more_vert,
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            )
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  ),
                                                  onSelected: (value) {
                                                    if (value == 'edit') {
                                                      _editReceipt(receipt);
                                                    } else if (value ==
                                                        'void') {
                                                      _showVoidDialog(receipt);
                                                    }
                                                  },
                                                  itemBuilder: (context) =>
                                                      const [
                                                        PopupMenuItem(
                                                          value: 'edit',
                                                          child: Text(
                                                            'تعديل السند',
                                                          ),
                                                        ),
                                                        PopupMenuItem(
                                                          value: 'void',
                                                          child: Text(
                                                            'إلغاء السند',
                                                          ),
                                                        ),
                                                      ],
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
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('خطأ: $error'),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReceiptFormScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => setState(() => _searchOpen = !_searchOpen),
            icon: const Icon(Icons.search),
            label: Text(_searchOpen ? 'إخفاء البحث' : 'بحث'),
          ),
          if (_searchOpen) ...[
            const SizedBox(height: 10),
            SegmentedButton<_ReceiptSearchMode>(
              segments: const [
                ButtonSegment(
                  value: _ReceiptSearchMode.client,
                  icon: Icon(Icons.person_search),
                  label: Text('اسم العميل'),
                ),
                ButtonSegment(
                  value: _ReceiptSearchMode.date,
                  icon: Icon(Icons.calendar_month),
                  label: Text('التاريخ'),
                ),
              ],
              selected: {_searchMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _searchMode = selection.first;
                  _searchDate = null;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
            const SizedBox(height: 8),
            if (_searchMode == _ReceiptSearchMode.client)
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'اكتب بداية أي كلمة من اسم العميل...',
                  prefixIcon: const Icon(Icons.person_search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
              )
            else
              InkWell(
                onTap: _pickSearchDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ السند',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _searchDate == null
                        ? 'اختر التاريخ'
                        : '${_searchDate!.year}-${_searchDate!.month.toString().padLeft(2, '0')}-${_searchDate!.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
