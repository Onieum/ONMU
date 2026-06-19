String formatOnmuPlanDate(DateTime date) {
  final localDate = date.toLocal();
  final weekday = const [
    '월',
    '화',
    '수',
    '목',
    '금',
    '토',
    '일',
  ][localDate.weekday - 1];
  return '${localDate.month}월 ${localDate.day}일 ($weekday)';
}

String formatOnmuPlanTime(DateTime date) {
  final localDate = date.toLocal();
  final hour = localDate.hour.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatOnmuPlanDateTimeRange(DateTime startsAt, DateTime endsAt) {
  final localStart = startsAt.toLocal();
  final localEnd = endsAt.toLocal();
  final startLabel =
      '${formatOnmuPlanDate(localStart)} · ${formatOnmuPlanTime(localStart)}';
  if (localStart.year == localEnd.year &&
      localStart.month == localEnd.month &&
      localStart.day == localEnd.day) {
    return '$startLabel ~ ${formatOnmuPlanTime(localEnd)}';
  }
  return '$startLabel ~ ${formatOnmuPlanDate(localEnd)} ${formatOnmuPlanTime(localEnd)}';
}
