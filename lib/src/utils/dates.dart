import 'dart:math' as math;

const List<String> _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime oneCalendarMonthFrom(DateTime start) {
  final zeroBasedTargetMonth = start.month;
  final year = start.year + zeroBasedTargetMonth ~/ 12;
  final month = zeroBasedTargetMonth % 12 + 1;
  final day = math.min(start.day, DateTime(year, month + 1, 0).day);

  return DateTime(year, month, day);
}

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

int inclusiveDaysBetween(DateTime start, DateTime end) {
  final startDate = dateOnly(start);
  final endDate = dateOnly(end);
  final days = endDate.difference(startDate).inDays + 1;

  return math.max(days, 1);
}

bool isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String formatShortDate(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

String formatClockTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}
