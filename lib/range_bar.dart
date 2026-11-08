import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'dates.dart';
import 'jalali_utils.dart';

enum RangeKind { today, week, month, lastMonth, all, custom }

const _labels = {
  RangeKind.today: 'امروز',
  RangeKind.week: '۷ روز اخیر',
  RangeKind.month: 'این ماه',
  RangeKind.lastMonth: 'ماه قبل',
  RangeKind.all: 'همه',
};

class RangeSelection {
  final RangeKind kind;
  final DateTime? from;
  final DateTime? to;

  const RangeSelection(this.kind, [this.from, this.to]);

  /// (شروع، پایان)؛ پایان خودش جزو بازه نیست
  (DateTime?, DateTime?) bounds() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (kind) {
      case RangeKind.today:
        return (today, null);
      case RangeKind.week:
        return (DateTime(today.year, today.month, today.day - 6), null);
      case RangeKind.month:
        {
          final j = Jalali.fromDateTime(now);
          return (jalaliStart(j.year, j.month, 1), null);
        }
      case RangeKind.lastMonth:
        {
          final j = Jalali.fromDateTime(now);
          var y = j.year;
          var m = j.month - 1;
          if (m == 0) {
            m = 12;
            y--;
          }
          return (jalaliStart(y, m, 1), jalaliStart(j.year, j.month, 1));
        }
      case RangeKind.all:
        return (null, null);
      case RangeKind.custom:
        {
          final f = from;
          final t = to;
          if (f == null || t == null) return (null, null);
          return (f, DateTime(t.year, t.month, t.day + 1));
        }
    }
  }

  bool contains(DateTime t) {
    final (s, e) = bounds();
    return (s == null || !t.isBefore(s)) && (e == null || t.isBefore(e));
  }

  String describe() {
    final (s, e) = bounds();
    if (s == null) return 'کل زمان';
    final end = e == null ? DateTime.now() : e.subtract(const Duration(days: 1));
    return 'از ${shamsiDate(s)} تا ${shamsiDate(end)}';
  }
}

class RangeChips extends StatelessWidget {
  final RangeSelection value;
  final ValueChanged<RangeSelection> onChanged;

  const RangeChips({super.key, required this.value, required this.onChanged});

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = await pickJalaliDate(
      context,
      initial: value.from ?? DateTime(today.year, today.month, today.day - 6),
      title: 'از تاریخ',
    );
    if (from == null || !context.mounted) return;
    final to = await pickJalaliDate(
      context,
      initial: value.to ?? today,
      title: 'تا تاریخ',
    );
    if (to == null) return;
    onChanged(
      to.isBefore(from)
          ? RangeSelection(RangeKind.custom, to, from)
          : RangeSelection(RangeKind.custom, from, to),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customLabel = (value.kind == RangeKind.custom &&
            value.from != null &&
            value.to != null)
        ? '${shamsiDate(value.from!)} تا ${shamsiDate(value.to!)}'
        : 'بازه دلخواه';
    return Wrap(
      spacing: 8,
      children: [
        for (final k in _labels.keys)
          ChoiceChip(
            label: Text(_labels[k]!),
            selected: value.kind == k,
            onSelected: (_) => onChanged(RangeSelection(k)),
          ),
        ChoiceChip(
          avatar: const Icon(Icons.date_range, size: 18),
          label: Text(customLabel),
          selected: value.kind == RangeKind.custom,
          onSelected: (_) => _pickCustom(context),
        ),
      ],
    );
  }
}
