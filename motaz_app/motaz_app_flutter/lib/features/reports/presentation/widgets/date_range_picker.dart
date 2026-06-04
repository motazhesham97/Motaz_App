import 'package:flutter/material.dart';

import '../../../../core/utils/date_range.dart';

class DateRangePickerWidget extends StatefulWidget {
  final void Function(DateRange) onRangeChanged;

  const DateRangePickerWidget({super.key, required this.onRangeChanged});

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> {
  late DateRange _selectedRange;
  late DateTime _startDate;
  late DateTime _endDate;
  int? _selectedChipIndex;

  DateTime get _displayEnd => _endDate.subtract(const Duration(days: 1));

  static const _quickFilters = [
    ('اليوم', DateRangeType.today),
    ('هذا الأسبوع', DateRangeType.thisWeek),
    ('هذا الشهر', DateRangeType.thisMonth),
    ('هذا العام', DateRangeType.thisYear),
    ('الكل', DateRangeType.allTime),
  ];

  @override
  void initState() {
    super.initState();
    _selectedRange = DateRange.thisMonth();
    _startDate = _selectedRange.start;
    _endDate = _selectedRange.end;
    _selectedChipIndex = 2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_quickFilters.length, (i) {
              final selected = _selectedChipIndex == i;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(_quickFilters[i].$1),
                  selected: selected,
                  onSelected: (_) => _selectQuickFilter(i),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text(
                  '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: const Text('من', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.calendar_today, size: 18),
                contentPadding: EdgeInsets.zero,
                onTap: () => _pickDate(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ListTile(
                title: Text(
                  '${_displayEnd.year}-${_displayEnd.month.toString().padLeft(2, '0')}-${_displayEnd.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: const Text('إلى', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.calendar_today, size: 18),
                contentPadding: EdgeInsets.zero,
                onTap: () => _pickDate(isStart: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _selectQuickFilter(int index) {
    final type = _quickFilters[index].$2;
    final range = switch (type) {
      DateRangeType.today => DateRange.today(),
      DateRangeType.thisWeek => DateRange.thisWeek(),
      DateRangeType.thisMonth => DateRange.thisMonth(),
      DateRangeType.thisYear => DateRange.thisYear(),
      DateRangeType.allTime => DateRange.allTime(),
      DateRangeType.custom => DateRange.thisMonth(),
    };
    setState(() {
      _selectedRange = range;
      _startDate = range.start;
      _endDate = range.end;
      _selectedChipIndex = index;
    });
    widget.onRangeChanged(range);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final newStart = isStart
        ? DateTime(picked.year, picked.month, picked.day)
        : _startDate;
    final newEnd = isStart
        ? _endDate
        : DateTime(picked.year, picked.month, picked.day + 1);

    if (!newStart.isBefore(newEnd)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تاريخ البداية يجب أن يكون قبل تاريخ النهاية'),
          ),
        );
      }
      return;
    }

    setState(() {
      _startDate = newStart;
      _endDate = newEnd;
      _selectedChipIndex = null;
      _selectedRange = DateRange.custom(_startDate, _endDate);
    });
    widget.onRangeChanged(_selectedRange);
  }
}
