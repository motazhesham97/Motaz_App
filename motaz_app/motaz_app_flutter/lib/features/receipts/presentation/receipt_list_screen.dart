import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/database/enums/receipt_type.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../clients/application/client_providers.dart';
import '../application/receipt_providers.dart';
import 'receipt_form_screen.dart';

class ReceiptListScreen extends ConsumerStatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  ConsumerState<ReceiptListScreen> createState() =>
      _ReceiptListScreenState();
}

class _ReceiptListScreenState extends ConsumerState<ReceiptListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

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

  String _formatMoney(int minorUnits) {
    return '${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
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
      final device = await ref.read(deviceServiceProvider).ensureCurrentDevice();
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

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = _searchQuery.isEmpty
        ? ref.watch(receiptListProvider)
        : ref.watch(receiptSearchProvider(_searchQuery));

    return AppDrawerScaffold(
      title: 'سندات القبض',
      currentRoute: '/receipts',
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
            child: receiptsAsync.when(
              data: (receipts) {
                if (receipts.isEmpty) {
                  return const Center(
                    child: Text('لا توجد سندات'),
                  );
                }
                return FutureBuilder<List<Client>>(
                  future: ref.read(clientListProvider.future),
                  builder: (context, clientSnapshot) {
                    final clientMap = {
                      for (final c in clientSnapshot.data ?? []) c.id: c.displayName,
                    };
                    return ListView.builder(
                      itemCount: receipts.length,
                      itemBuilder: (context, index) {
                        final receipt = receipts[index];
                        final clientName = clientMap[receipt.clientId] ?? 'عميل غير معروف';
                        final isVoided = receipt.status == RecordStatus.VOIDED;
                        final isInvoiceLinked = receipt.receiptType == ReceiptType.INVOICE_LINKED;
                        
                        return Opacity(
                          opacity: isVoided ? 0.6 : 1.0,
                          child: ListTile(
                            title: Text(clientName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_formatMoney(receipt.amount)} - ${receipt.receiptDate.year}-${receipt.receiptDate.month.toString().padLeft(2, '0')}-${receipt.receiptDate.day.toString().padLeft(2, '0')}'),
                                Text(
                                  isInvoiceLinked ? 'مرتبط بفاتورة' : 'دفعة عامة',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isVoided)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ملغى',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  )
                                else
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      if (value == 'void') {
                                        _showVoidDialog(receipt);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'void',
                                        child: Text('إلغاء السند'),
                                      ),
                                    ],
                                  ),
                              ],
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
}
