import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/profit_providers.dart';

class DistributionScreen extends ConsumerStatefulWidget {
  const DistributionScreen({super.key});

  @override
  ConsumerState<DistributionScreen> createState() =>
      _DistributionScreenState();
}

class _DistributionScreenState extends ConsumerState<DistributionScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month - 1;
  int? _netSales;
  int? _netProfit;
  ({int ownerShare, int partnerShare, int marginShare})? _shares;
  bool _computing = false;
  bool _distributing = false;

  @override
  void initState() {
    super.initState();
    if (_selectedMonth < 1) {
      _selectedMonth = 12;
      _selectedYear = DateTime.now().year - 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _computePreview();
    });
  }

  Future<void> _computePreview() async {
    setState(() => _computing = true);
    try {
      final engine = ref.read(profitEngineProvider);
      final netSales =
          await engine.computeMonthlyNetSales(_selectedYear, _selectedMonth);
      final netProfit =
          await engine.computeMonthlyNetProfit(_selectedYear, _selectedMonth);
      final shares = engine.computeDistribution(netProfit);
      if (mounted) {
        setState(() {
          _netSales = netSales;
          _netProfit = netProfit;
          _shares = shares;
          _computing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _computing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _formatMoney(int minorUnits) {
    return '\${(minorUnits / 100).toStringAsFixed(2)} ر.ي.';
  }

  Future<void> _distribute() async {
    setState(() => _distributing = true);
    try {
      final device =
          await ref.read(deviceServiceProvider).ensureCurrentDevice();
      if (!mounted) return;

      final repo = ref.read(distributionRepositoryProvider);
      await repo.distribute(
        year: _selectedYear,
        month: _selectedMonth,
        deviceId: device.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التوزيع بنجاح')),
        );
        ref.invalidate(distributionListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _distributing = false);
    }
  }

  Future<void> _showVoidDialog(MonthlyDistribution dist) async {
    final reasonController = TextEditingController();
    String reasonText = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء التوزيع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من إلغاء هذا التوزيع؟'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء *',
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
      await _voidDistribution(dist, reasonText);
    }
  }

  Future<void> _voidDistribution(
      MonthlyDistribution dist, String reason) async {
    try {
      final device =
          await ref.read(deviceServiceProvider).ensureCurrentDevice();
      final repo = ref.read(distributionRepositoryProvider);
      await repo.voidDistribution(dist.id, reason, device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء التوزيع')),
        );
        ref.invalidate(distributionListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  bool get _canDistribute {
    final engine = ref.read(profitEngineProvider);
    return engine.isPastMonth(_selectedYear, _selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final distributionsAsync = ref.watch(distributionListProvider);

    return AppDrawerScaffold(
      title: 'توزيع الأرباح',
      currentRoute: '/distributions',
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMonthSelector(),
              const SizedBox(height: 16),
              _buildProfitPreview(),
              const SizedBox(height: 16),
              _buildDistributeButton(),
              const SizedBox(height: 24),
              const Text(
                'سجل التوزيعات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDistributionHistory(distributionsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _selectedYear,
            decoration: const InputDecoration(labelText: 'السنة'),
            items: List.generate(5, (i) {
              final year = DateTime.now().year - i;
              return DropdownMenuItem(value: year, child: Text('$year'));
            }),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedYear = v);
                _computePreview();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _selectedMonth,
            decoration: const InputDecoration(labelText: 'الشهر'),
            items: List.generate(12, (i) {
              final m = i + 1;
              return DropdownMenuItem(value: m, child: Text('$m'));
            }),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedMonth = v);
                _computePreview();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfitPreview() {
    if (_computing) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'صافي المبيعات: ${_netSales != null ? _formatMoney(_netSales!) : '---'}',
            ),
            const SizedBox(height: 8),
            Text(
              'صافي الربح: ${_netProfit != null ? _formatMoney(_netProfit!) : '---'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_shares != null) ...[
              const Divider(),
              Text('حصة المالك: ${_formatMoney(_shares!.ownerShare)}'),
              Text('حصة الشريك: ${_formatMoney(_shares!.partnerShare)}'),
              Text('حصة الهامش: ${_formatMoney(_shares!.marginShare)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDistributeButton() {
    return FilledButton(
      onPressed: _canDistribute && !_distributing ? _distribute : null,
      child: _distributing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              _canDistribute ? 'توزيع' : 'لا يمكن توزيع الشهر الحالي أو المستقبلي',
            ),
    );
  }

  Widget _buildDistributionHistory(AsyncValue<List<MonthlyDistribution>> async) {
    return async.when(
      data: (distributions) {
        if (distributions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('لا توجد توزيعات'),
            ),
          );
        }
        return Column(
          children: distributions.map((dist) {
            final isVoided = dist.status == RecordStatus.VOIDED;
            return Opacity(
              opacity: isVoided ? 0.6 : 1.0,
              child: Card(
                child: ListTile(
                  title: Text('${dist.year}-${dist.month.toString().padLeft(2, '0')}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('صافي الربح: ${_formatMoney(dist.netProfit)}'),
                      Text('مالك: ${_formatMoney(dist.ownerShare)} | شريك: ${_formatMoney(dist.partnerShare)} | هامش: ${_formatMoney(dist.marginShare)}'),
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
                          onSelected: (value) {
                            if (value == 'void') {
                              _showVoidDialog(dist);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'void',
                              child: Text('إلغاء التوزيع'),
                            ),
                          ],
                        ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: \$e')),
    );
  }
}
