import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/profit_providers.dart';
import '../data/profit_engine.dart';

class SettlementReviewNotice extends ConsumerStatefulWidget {
  const SettlementReviewNotice({
    super.key,
    required this.child,
    this.suppressed = false,
  });

  final Widget child;
  final bool suppressed;

  @override
  ConsumerState<SettlementReviewNotice> createState() =>
      _SettlementReviewNoticeState();
}

class _SettlementReviewNoticeState extends ConsumerState<SettlementReviewNotice>
    with WidgetsBindingObserver {
  static const _displayDuration = Duration(seconds: 8);
  static const _reminderInterval = Duration(minutes: 15);
  List<MonthSettlement> _reviews = [];
  String _signature = '';
  bool _visible = false;
  Timer? _hideTimer;
  Timer? _reminderTimer;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(settlementReviewProvider, (_, next) {
      final rows = next.asData?.value;
      if (rows == null) return;
      final reviews = [...rows]
        ..sort((a, b) {
          final year = a.profit.year.compareTo(b.profit.year);
          return year != 0 ? year : a.profit.month.compareTo(b.profit.month);
        });
      final signature = reviews
          .map((entry) {
            final profit = entry.profit;
            return '${profit.year}-${profit.month}:${profit.netSales}:'
                '${profit.operationalExpenses}:${profit.productionExpenses}:'
                '${profit.carriedLossIn}';
          })
          .join('|');
      if (_signature == signature) return;
      _signature = signature;
      _reviews = reviews;
      _reminderTimer?.cancel();
      if (reviews.isEmpty) {
        _dismiss();
      } else {
        _show();
        // Remind from cached review state without querying the database again.
        _reminderTimer = Timer.periodic(_reminderInterval, (_) => _show());
      }
    }, fireImmediately: true);
  }

  void _show() {
    if (!mounted ||
        widget.suppressed ||
        _reviews.isEmpty ||
        _lifecycle != AppLifecycleState.resumed) {
      return;
    }
    _hideTimer?.cancel();
    setState(() => _visible = true);
    _hideTimer = Timer(_displayDuration, _dismiss);
  }

  void _dismiss() {
    _hideTimer?.cancel();
    if (mounted && _visible) setState(() => _visible = false);
  }

  @override
  void didUpdateWidget(SettlementReviewNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suppressed) _dismiss();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previous = _lifecycle;
    _lifecycle = state;
    if (state == AppLifecycleState.resumed && previous != state) {
      _show();
    } else if (state != AppLifecycleState.resumed) {
      _dismiss();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _reminderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final first = _reviews.firstOrNull?.profit;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible && !widget.suppressed && first != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Semantics(
                      liveRegion: true,
                      child: Material(
                        key: const Key('settlement-review-notification'),
                        color: colors.surfaceContainerHigh,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 12,
                            bottom: 4,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      color: colors.error,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        'تحتاج تسويات ${_reviews.length} من الأشهر إعادة اعتماد، بدءًا من '
                                        '${first.month.toString().padLeft(2, '0')}/${first.year}.',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'إغلاق التنبيه',
                                    onPressed: _dismiss,
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton.icon(
                                  onPressed: () {
                                    _dismiss();
                                    context.go(
                                      '/distributions?year=${first.year}&month=${first.month}',
                                    );
                                  },
                                  icon: const Icon(Icons.fact_check_outlined),
                                  label: const Text('مراجعة التسويات'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
