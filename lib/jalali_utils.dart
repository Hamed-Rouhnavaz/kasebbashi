import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

const jalaliMonthNames = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

DateTime jalaliStart(int y, int m, int d) => Jalali(y, m, d).toDateTime();

/// شروع ماه شمسی بعد از (y, m)
DateTime nextJalaliMonthStart(int y, int m) => m == 12
    ? Jalali(y + 1, 1, 1).toDateTime()
    : Jalali(y, m + 1, 1).toDateTime();

int jalaliMonthLength(int y, int m) {
  final diff = nextJalaliMonthStart(y, m).difference(jalaliStart(y, m, 1));
  return (diff.inHours / 24).round();
}

/// دیالوگ انتخاب تاریخ شمسی. اگر کاربر انصراف دهد null برمی‌گرداند.
Future<DateTime?> pickJalaliDate(
  BuildContext context, {
  required DateTime initial,
  required String title,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _JalaliPickerDialog(initial: initial, title: title),
  );
}

class _JalaliPickerDialog extends StatefulWidget {
  final DateTime initial;
  final String title;

  const _JalaliPickerDialog({required this.initial, required this.title});

  @override
  State<_JalaliPickerDialog> createState() => _JalaliPickerDialogState();
}

class _JalaliPickerDialogState extends State<_JalaliPickerDialog> {
  late int _y;
  late int _m;
  late int _d;
  late final int _nowYear;

  @override
  void initState() {
    super.initState();
    final j = Jalali.fromDateTime(widget.initial);
    _y = j.year;
    _m = j.month;
    _d = j.day;
    _nowYear = Jalali.fromDateTime(DateTime.now()).year;
  }

  void _clampDay() {
    final len = jalaliMonthLength(_y, _m);
    if (_d > len) _d = len;
  }

  @override
  Widget build(BuildContext context) {
    final len = jalaliMonthLength(_y, _m);
    final firstYear = math.min(_nowYear - 5, _y);
    final lastYear = math.max(_nowYear + 1, _y);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _y,
                items: [
                  for (var y = firstYear; y <= lastYear; y++)
                    DropdownMenuItem(value: y, child: Text('$y')),
                ],
                onChanged: (v) => setState(() {
                  _y = v!;
                  _clampDay();
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButton<int>(
                isExpanded: true,
                value: _m,
                items: [
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem(
                        value: m, child: Text(jalaliMonthNames[m - 1])),
                ],
                onChanged: (v) => setState(() {
                  _m = v!;
                  _clampDay();
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _d,
                items: [
                  for (var d = 1; d <= len; d++)
                    DropdownMenuItem(value: d, child: Text('$d')),
                ],
                onChanged: (v) => setState(() => _d = v!),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, jalaliStart(_y, _m, _d)),
          child: const Text('تأیید'),
        ),
      ],
    );
  }
}
