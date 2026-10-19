import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/device_service.dart';
import '../../../core/database/enums/record_status.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/profit_providers.dart';
import 'monthly_profit_summary.dart';

class DistributionScreen extends ConsumerStatefulWidget {
  const DistributionScreen({super.key});
  @override
  ConsumerState<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends ConsumerState<DistributionScreen> {
  late int _year;
  late int _month;
  bool _saving = false;
  static const _months = [
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
    final previous = DateTime(DateTime.now().year, DateTime.now().month - 1);
    _year = previous.year;
    _month = previous.month;
  }

  Future<void> _save(Future<void> Function(String deviceId) action) async {
    setState(() => _saving = true);
    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      if (!mounted) return;
      await action(device.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التسوية محليًا')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'تعذر حفظ التسوية. حاول مجددًا',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reapprove(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة اعتماد التسويات'),
        content: Text(
          'سيعاد حساب $count من الأشهر المتأثرة بالترتيب، ثم استدراك الأشهر المغلقة المفقودة. قد تتغير أرصدة الأطراف، وتبقى السحوبات السابقة محفوظة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إعادة الاعتماد'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _save(
      (id) => ref
          .read(distributionRepositoryProvider)
          .reapproveAffected(deviceId: id),
    );
  }

  Future<void> _void(MonthlyDistribution saved) async {
    final controller = TextEditingController();
    String? reason;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء التسوية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تحتاج الأشهر التالية إعادة اعتماد. خسارة نشاط الشهر لا تسقط بالإلغاء.',
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'سبب الإلغاء'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              reason = text;
              Navigator.pop(context);
            },
            child: const Text('إلغاء التسوية'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || reason == null) return;
    await _save(
      (id) => ref
          .read(distributionRepositoryProvider)
          .voidDistribution(saved.id, reason!, id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(
      monthlySettlementProvider((year: _year, month: _month)),
    );
    final history = ref.watch(distributionListProvider);
    final reviews = ref.watch(settlementReviewProvider).asData?.value ?? [];
    final isPast = ref.read(profitEngineProvider).isPastMonth(_year, _month);
    return AppDrawerScaffold(
      title: 'توزيع الأرباح',
      currentRoute: '/distributions',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (reviews.isNotEmpty) ...[
            Text(
              'تحتاج ${reviews.length} من الأشهر إعادة اعتماد',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.icon(
              onPressed: _saving ? null : () => _reapprove(reviews.length),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('مراجعة واعتماد الأشهر'),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(labelText: 'السنة'),
                  items: [
                    for (
                      var year = DateTime.now().year - 8;
                      year <= DateTime.now().year;
                      year++
                    )
                      DropdownMenuItem(value: year, child: Text('$year')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _year = value);
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _month,
                  decoration: const InputDecoration(labelText: 'الشهر'),
                  items: [
                    for (var month = 1; month <= 12; month++)
                      DropdownMenuItem(
                        value: month,
                        child: Text(_months[month - 1]),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _month = value);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          preview.when(
            data: (entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  entry.needsReview
                      ? 'معاينة جديدة؛ التسوية السابقة تحتاج إعادة اعتماد'
                      : entry.recorded?.status == RecordStatus.ACTIVE
                      ? 'تسوية معتمدة'
                      : 'معاينة غير معتمدة',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: MonthlyProfitSummary(profit: entry.profit),
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      _saving ||
                          !isPast ||
                          reviews.isNotEmpty ||
                          entry.recorded?.status == RecordStatus.ACTIVE
                      ? null
                      : () => _save((id) async {
                          await ref
                              .read(distributionRepositoryProvider)
                              .distribute(
                                year: _year,
                                month: _month,
                                deviceId: id,
                              );
                        }),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.pie_chart_rounded),
                  label: Text(
                    !isPast
                        ? 'الشهر الحالي أو المستقبلي للمعاينة'
                        : entry.recorded?.status == RecordStatus.ACTIVE
                        ? 'هذا الشهر معتمد'
                        : 'اعتماد تسوية الشهر',
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('تعذر قراءة حسابات الشهر'),
          ),
          const SizedBox(height: 24),
          Text('سجل التسويات', style: Theme.of(context).textTheme.titleLarge),
          history.when(
            data: (rows) => Column(
              children: [
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('لا توجد تسويات بعد'),
                  ),
                for (final row in rows)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${row.year}-${row.month.toString().padLeft(2, '0')}',
                      ),
                      subtitle: Text(
                        'النتيجة: ${formatMoney(row.netProfit)}\n'
                        'خسارة الشهر: ${formatMoney(row.currentMonthLoss)}\n'
                        'المرحلة للتالي: ${formatMoney(row.carriedLossOut)}\n'
                        'امي: ${formatMoney(row.ownerShare)}، معتز: ${formatMoney(row.partnerShare)}، الهامش: ${formatMoney(row.marginShare)}',
                      ),
                      trailing: row.status == RecordStatus.VOIDED
                          ? const Text('ملغى')
                          : IconButton(
                              tooltip: 'إلغاء التسوية',
                              icon: const Icon(Icons.block),
                              onPressed: _saving ? null : () => _void(row),
                            ),
                    ),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('تعذر قراءة سجل التسويات'),
          ),
        ],
      ),
    );
  }
}
