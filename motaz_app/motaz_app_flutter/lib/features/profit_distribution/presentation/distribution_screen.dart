import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/profit_providers.dart';

class DistributionScreen extends ConsumerStatefulWidget {
  const DistributionScreen({super.key});

  @override
  ConsumerState<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends ConsumerState<DistributionScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month - 1;
  int? _netSales;
  int? _netProfit;
  ({int ownerShare, int partnerShare, int marginShare})? _shares;
  bool _computing = false;
  bool _distributing = false;

  static const _monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

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
      final netSales = await engine.computeMonthlyNetSales(
        _selectedYear,
        _selectedMonth,
      );
      final netProfit = await engine.computeMonthlyNetProfit(
        _selectedYear,
        _selectedMonth,
      );
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

  Future<void> _distribute() async {
    setState(() => _distributing = true);
    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      if (!mounted) return;

      final repo = ref.read(distributionRepositoryProvider);
      await repo.distribute(
        year: _selectedYear,
        month: _selectedMonth,
        deviceId: device.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل توزيع الأرباح')),
        );
        _refreshDistributionList();
        await _computePreview();
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
            const Text('سيبقى السجل محفوظا كملغى، وسيتم مزامنة الإلغاء.'),
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
          FilledButton(
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
            child: const Text('إلغاء التوزيع'),
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
    MonthlyDistribution dist,
    String reason,
  ) async {
    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      final repo = ref.read(distributionRepositoryProvider);
      await repo.voidDistribution(dist.id, reason, device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء التوزيع')),
        );
        _refreshDistributionList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  bool get _isPastMonth {
    final engine = ref.read(profitEngineProvider);
    return engine.isPastMonth(_selectedYear, _selectedMonth);
  }

  MonthlyDistribution? _selectedDistribution(
    List<MonthlyDistribution> distributions,
  ) {
    for (final distribution in distributions) {
      if (distribution.year == _selectedYear &&
          distribution.month == _selectedMonth &&
          distribution.status == RecordStatus.ACTIVE) {
        return distribution;
      }
    }
    return null;
  }

  void _refreshDistributionList() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(distributionListProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final distributionsAsync = ref.watch(distributionListProvider);

    return AppDrawerScaffold(
      title: 'توزيع الأرباح',
      currentRoute: '/distributions',
      child: Scaffold(
        body: distributionsAsync.when(
          data: (distributions) {
            final selectedDistribution = _selectedDistribution(distributions);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPolicyNote(),
                const SizedBox(height: 12),
                _buildMonthSelector(),
                const SizedBox(height: 12),
                _buildProfitPreview(),
                const SizedBox(height: 12),
                _buildDistributeButton(selectedDistribution),
                const SizedBox(height: 24),
                Text(
                  'سجل التوزيعات',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildDistributionHistory(distributions),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
        ),
      ),
    );
  }

  Widget _buildPolicyNote() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.event_repeat_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'يتم توزيع أرباح الشهر السابق تلقائيا عند أول مزامنة بعد بداية شهر جديد. الزر اليدوي مخصص للشهور السابقة غير المسجلة فقط.',
              ),
            ),
          ],
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
              final month = i + 1;
              return DropdownMenuItem(
                value: month,
                child: Text(_monthNames[i]),
              );
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
    final colorScheme = Theme.of(context).colorScheme;

    if (_computing) {
      return const Card(
        child: SizedBox(
          height: 148,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryLine(
              label: 'صافي المبيعات',
              value: _netSales != null ? formatMoney(_netSales!) : '---',
            ),
            const SizedBox(height: 8),
            _SummaryLine(
              label: 'صافي الربح',
              value: _netProfit != null ? formatMoney(_netProfit!) : '---',
              emphasized: true,
            ),
            if (_shares != null) ...[
              const Divider(height: 24),
              _SummaryLine(
                label: 'حصة امي',
                value: formatMoney(_shares!.ownerShare),
                valueColor: colorScheme.primary,
              ),
              const SizedBox(height: 6),
              _SummaryLine(
                label: 'حصة معتز',
                value: formatMoney(_shares!.partnerShare),
                valueColor: colorScheme.secondary,
              ),
              const SizedBox(height: 6),
              _SummaryLine(
                label: 'حصة الهامش',
                value: formatMoney(_shares!.marginShare),
                valueColor: colorScheme.tertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDistributeButton(MonthlyDistribution? selectedDistribution) {
    final alreadyDistributed = selectedDistribution != null;
    final enabled = _isPastMonth && !alreadyDistributed && !_distributing;
    final label = !_isPastMonth
        ? 'الشهر الحالي أو المستقبلي لا يوزع'
        : alreadyDistributed
        ? 'هذا الشهر مسجل بالفعل'
        : 'تسجيل توزيع يدوي';

    return FilledButton.icon(
      onPressed: enabled ? _distribute : null,
      icon: _distributing
          ? SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.surface,
              ),
            )
          : const Icon(Icons.pie_chart_rounded),
      label: Text(label),
    );
  }

  Widget _buildDistributionHistory(List<MonthlyDistribution> distributions) {
    if (distributions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('لا توجد توزيعات بعد')),
      );
    }
    return Column(
      children: [
        for (final dist in distributions) ...[
          _DistributionHistoryCard(
            distribution: dist,
            onVoid: () => _showVoidDialog(dist),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textStyle = emphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text(
          value,
          style: textStyle?.copyWith(
            color: valueColor,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DistributionHistoryCard extends StatelessWidget {
  const _DistributionHistoryCard({
    required this.distribution,
    required this.onVoid,
  });

  final MonthlyDistribution distribution;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVoided = distribution.status == RecordStatus.VOIDED;

    return Opacity(
      opacity: isVoided ? 0.62 : 1,
      child: Card(
        child: ListTile(
          title: Text(
            '${distribution.year}-${distribution.month.toString().padLeft(2, '0')}',
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('صافي الربح: ${formatMoney(distribution.netProfit)}'),
                Text(
                  'امي: ${formatMoney(distribution.ownerShare)} | معتز: ${formatMoney(distribution.partnerShare)} | هامش: ${formatMoney(distribution.marginShare)}',
                ),
              ],
            ),
          ),
          trailing: isVoided
              ? Chip(
                  label: const Text('ملغى'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.errorContainer,
                  labelStyle: TextStyle(color: colorScheme.onErrorContainer),
                )
              : PopupMenuButton<String>(
                  tooltip: 'خيارات التوزيع',
                  onSelected: (value) {
                    if (value == 'void') {
                      onVoid();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'void',
                      child: Text('إلغاء التوزيع'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
