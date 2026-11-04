import 'package:shamsi_date/shamsi_date.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String shamsiDate(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${j.year}/${_two(j.month)}/${_two(j.day)}';
}

String shamsiDateTime(DateTime d) =>
    '${shamsiDate(d)}  ${_two(d.hour)}:${_two(d.minute)}';
