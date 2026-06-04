import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/document_reference_formatter.dart';
import '../../invoices/presentation/invoice_detail_screen.dart';
import '../application/client_providers.dart';
import 'client_form_screen.dart';

class ClientSummaryScreen extends ConsumerStatefulWidget {
  const ClientSummaryScreen({super.key, required this.client});

  final Client client;

  @override
  ConsumerState<ClientSummaryScreen> createState() =>
      _ClientSummaryScreenState();
}

class _ClientSummaryScreenState extends ConsumerState<ClientSummaryScreen> {
  late Client _client;
  int _balance = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(clientRepositoryProvider);
    try {
      final freshClient = await repo.getById(_client.id);
      final balance = await repo.getOutstandingBalance(_client.id);
      final transactions = await repo.getRecentTransactions(_client.id);
      if (mounted) {
        setState(() {
          _client = freshClient;
          _balance = balance;
          _transactions = transactions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientFormScreen(
          existingClient: _client,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _loading = true;
      });
      await _loadData();
    }
  }

  Future<void> _toggleClientActive() async {
    final nextState = !_client.isActive;
    final clientName = _client.displayName;
    try {
      await ref.read(clientRepositoryProvider).setActive(_client.id, nextState);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextState ? 'تم تنشيط $clientName' : 'تم تعطيل $clientName',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث حالة العميل: $error')),
      );
    }
  }

  String _transactionTitle(Map<String, dynamic> transaction) {
    final localRef = transaction['localRef'] as String? ?? '';
    final officialNo = transaction['officialNo'] as String?;
    return transaction['type'] == 'INVOICE'
        ? invoiceDisplayRef(localRef, officialNo: officialNo)
        : receiptDisplayRef(localRef, officialNo: officialNo);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final balanceColor = _balance > 0
        ? const Color(0xFFFF6B5F)
        : const Color(0xFF6FCF7D);
    final balanceBackground = Color.alphaBlend(
      balanceColor.withValues(alpha: 0.18),
      colorScheme.surface,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_client.displayName),
        actions: [
          IconButton(
            tooltip: _client.isActive ? 'تعطيل العميل' : 'تنشيط العميل',
            icon: Icon(
              _client.isActive
                  ? Icons.block_rounded
                  : Icons.check_circle_rounded,
            ),
            onPressed: _toggleClientActive,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بيانات العميل',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Chip(
                            avatar: Icon(
                              _client.isActive
                                  ? Icons.check_circle_rounded
                                  : Icons.block_rounded,
                              size: 16,
                            ),
                            label: Text(_client.isActive ? 'نشط' : 'معطل'),
                          ),
                          const SizedBox(height: 12),
                          if (_client.phone != null) ...[
                            Text('الهاتف: ${_client.phone}'),
                            const SizedBox(height: 8),
                          ],
                          if (_client.email != null) ...[
                            Text('البريد: ${_client.email}'),
                            const SizedBox(height: 8),
                          ],
                          if (_client.address != null) ...[
                            Text('العنوان: ${_client.address}'),
                            const SizedBox(height: 8),
                          ],
                          if (_client.clientCode != null) ...[
                            Text('رمز العميل: ${_client.clientCode}'),
                            const SizedBox(height: 8),
                          ],
                          if (_client.note != null) ...[
                            Text('ملاحظة: ${_client.note}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: balanceBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: balanceColor.withValues(alpha: 0.75),
                        width: 1.4,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الرصيد المستحق',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _balance == 0
                                ? 'لا توجد مستحقات'
                                : '${(_balance / 100).toStringAsFixed(2)} ر.ي.',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: balanceColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'سجل المعاملات',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('لا توجد معاملات'),
                      ),
                    )
                  else
                    ..._transactions.map(
                      (tx) => Card(
                        child: ListTile(
                          title: Text(_transactionTitle(tx)),
                          subtitle: Text(
                            '${((tx['amount'] as int) / 100).toStringAsFixed(2)} ر.ي.',
                          ),
                          trailing: Text(
                            (tx['date'] as DateTime)
                                .toString()
                                .split(' ')
                                .first,
                          ),
                          onTap: tx['type'] == 'INVOICE'
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InvoiceDetailScreen(
                                        invoiceId: tx['id'] as String,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
