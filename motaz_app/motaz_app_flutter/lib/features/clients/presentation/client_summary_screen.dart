import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../application/client_providers.dart';
import 'client_form_screen.dart';

class ClientSummaryScreen extends ConsumerStatefulWidget {
  const ClientSummaryScreen({super.key, required this.client});

  final Client client;

  @override
  ConsumerState<ClientSummaryScreen> createState() => _ClientSummaryScreenState();
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
      setState(() { _loading = true; });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_client.displayName),
        actions: [
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
                    color: _balance > 0 ? Colors.red[50] : Colors.green[50],
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
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: _balance > 0 ? Colors.red : Colors.green,
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
                    ..._transactions.map((tx) => Card(
                          child: ListTile(
                            title: Text(
                              tx['type'] == 'INVOICE'
                                  ? 'فاتورة'
                                  : 'سند قبض',
                            ),
                            subtitle: Text(
                              '${((tx['amount'] as int) / 100).toStringAsFixed(2)} ر.ي.',
                            ),
                            trailing: Text(
                              (tx['date'] as DateTime).toString().split(' ').first,
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
