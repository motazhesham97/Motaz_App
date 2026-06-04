import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/device_service.dart';
import '../../../core/utils/document_reference_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../application/free_sample_providers.dart';
import '../data/free_sample_repository.dart';

enum _SampleSearchMode { beneficiary, date }

class FreeSampleListScreen extends ConsumerStatefulWidget {
  const FreeSampleListScreen({super.key});

  @override
  ConsumerState<FreeSampleListScreen> createState() =>
      _FreeSampleListScreenState();
}

class _FreeSampleListScreenState extends ConsumerState<FreeSampleListScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;
  _SampleSearchMode _searchMode = _SampleSearchMode.beneficiary;
  String _beneficiaryQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(_mirrorClients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _mirrorClients() async {
    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      await ref
          .read(beneficiaryRepositoryProvider)
          .ensureClientsMirrored(
            device.id,
          );
    } catch (_) {
      // Device identity may be initialized a moment later during app startup.
    }
  }

  Future<void> _deleteSample(FreeSampleSummary row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العينة المجانية'),
        content: Text('هل تريد حذف ${row.title}؟'),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) Navigator.pop(context, false);
              });
            },
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () {
              FocusScope.of(context).unfocus();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) Navigator.pop(context, true);
              });
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final device = await ref
          .read(deviceServiceProvider)
          .ensureCurrentDevice();
      await ref
          .read(freeSampleRepositoryProvider)
          .voidSample(
            sampleId: row.sample.id,
            deviceId: device.id,
            reason: 'حذف يدوي',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف العينة المجانية')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  List<FreeSampleSummary> _filter(List<FreeSampleSummary> rows) {
    if (!_showSearch) return rows.take(10).toList();
    if (_searchMode == _SampleSearchMode.date && _selectedDate != null) {
      return rows
          .where((row) => _sameDate(row.sample.sampleDate, _selectedDate!))
          .toList();
    }
    final query = _beneficiaryQuery.trim().toLowerCase();
    if (query.isEmpty) return rows.take(10).toList();
    return rows
        .where((row) => _matchesWordPrefix(row.beneficiaryName, query))
        .toList();
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _matchesWordPrefix(String value, String query) {
    return value
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .any((word) => word.startsWith(query));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final samplesAsync = ref.watch(freeSampleReportProvider);

    return AppDrawerScaffold(
      title: 'العينات المجانية',
      currentRoute: '/free-samples',
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.go('/free-samples/create'),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _showSearch
                              ? (_searchMode == _SampleSearchMode.date
                                    ? (_selectedDate == null
                                          ? 'بحث بالتاريخ'
                                          : 'التاريخ: ${_formatDate(_selectedDate!)}')
                                    : (_beneficiaryQuery.isEmpty
                                          ? 'بحث باسم المستفيد'
                                          : 'المستفيد: $_beneficiaryQuery'))
                              : 'آخر 10 عينات مجانية',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          setState(() => _showSearch = !_showSearch);
                        },
                        icon: Icon(_showSearch ? Icons.close : Icons.search),
                      ),
                    ],
                  ),
                  if (_showSearch) ...[
                    const SizedBox(height: 12),
                    SegmentedButton<_SampleSearchMode>(
                      segments: const [
                        ButtonSegment(
                          value: _SampleSearchMode.beneficiary,
                          label: Text('المستفيد'),
                          icon: Icon(Icons.person_search_rounded),
                        ),
                        ButtonSegment(
                          value: _SampleSearchMode.date,
                          label: Text('التاريخ'),
                          icon: Icon(Icons.calendar_month_rounded),
                        ),
                      ],
                      selected: {_searchMode},
                      onSelectionChanged: (value) {
                        setState(() => _searchMode = value.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_searchMode == _SampleSearchMode.beneficiary)
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'اكتب بداية أي كلمة من اسم المستفيد',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() => _beneficiaryQuery = value);
                        },
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: Text(
                          _selectedDate == null
                              ? 'اختر التاريخ'
                              : _formatDate(_selectedDate!),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: samplesAsync.when(
                data: (rows) {
                  final filtered = _filter(rows);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('لا توجد عينات مجانية'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final row = filtered[index];
                      return _SampleCard(
                        row: row,
                        date: _formatDate(row.sample.sampleDate),
                        onEdit: () =>
                            context.go('/free-samples/${row.sample.id}/edit'),
                        onDelete: () => _deleteSample(row),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({
    required this.row,
    required this.date,
    required this.onEdit,
    required this.onDelete,
  });

  final FreeSampleSummary row;
  final String date;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final products = row.lines
        .map((line) => '${line.productName} (${line.quantity})')
        .join(' - ');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.card_giftcard_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          freeSampleDisplayRef(
                            row.sample.localRef,
                            officialNo: row.sample.officialNo,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'العدد: ${row.totalQuantity}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    row.beneficiaryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    products,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  tooltip: 'تعديل',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                ),
                const SizedBox(height: 4),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
