import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/return_providers.dart';

class ReturnListScreen extends ConsumerStatefulWidget {
  const ReturnListScreen({super.key});

  @override
  ConsumerState<ReturnListScreen> createState() => _ReturnListScreenState();
}

class _ReturnListScreenState extends ConsumerState<ReturnListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  Map<String, String> _invoiceRefs = {};
  Set<String> _loadedInvoiceIds = {};

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

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatMoney(int minorUnits) {
    return '${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
  }

  Future<void> _loadInvoiceRefsIfNeeded(List<SalesReturn> returns) async {
    final invoiceIds = returns.map((r) => r.invoiceId).toSet();
    if (invoiceIds.difference(_loadedInvoiceIds).isEmpty) {
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final invoiceIdList = invoiceIds.toList();
    final invoices = await (db.select(db.salesInvoices)
          ..where((t) => t.id.isIn(invoiceIdList)))
        .get();
    
    if (mounted) {
      setState(() {
        _invoiceRefs = {for (final inv in invoices) inv.id: inv.localRef};
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
      final device =
          await ref.read(deviceServiceProvider).ensureCurrentDevice();
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
    final returnsAsync = _searchQuery.isEmpty
        ? ref.watch(returnListProvider)
        : ref.watch(returnSearchProvider(_searchQuery));

    return AppDrawerScaffold(
      title: 'المرتجعات',
      currentRoute: '/returns',
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: returnsAsync.when(
                data: (returns) {
                  if (returns.isEmpty) {
                    return const Center(
                      child: Text('لا توجد مرتجعات'),
                    );
                  }

                  _loadInvoiceRefsIfNeeded(returns);

                  return ListView.builder(
                    itemCount: returns.length,
                    itemBuilder: (context, index) {
                      final ret = returns[index];
                      final isVoided = ret.status == RecordStatus.VOIDED;
                      final invoiceRef = _invoiceRefs[ret.invoiceId] ?? 'فاتورة';

                      return Opacity(
                        opacity: isVoided ? 0.6 : 1.0,
                        child: ListTile(
                          title: Text(invoiceRef),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_formatMoney(ret.totalReturnedAmount)} - ${_formatDate(ret.returnDate)}',
                              ),
                              if (ret.note != null && ret.note!.isNotEmpty)
                                Text(
                                  ret.note!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: isVoided
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ملغى',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                )
                              : PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    if (value == 'void') {
                                      _showVoidDialog(ret);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'void',
                                      child: Text('إلغاء المرتجع'),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('خطأ: $error')),
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
}