String formatUnavailableDateForStorage(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}

String formatUnavailableDateForDisplay(String value) {
  final parsed = _parseStoredDate(value);
  if (parsed == null) {
    return value;
  }

  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final weekday = weekdays[parsed.weekday - 1];
  return '${parsed.month}/${parsed.day} ($weekday)';
}

List<String> visibleUnavailableDates(List<String> values, {DateTime? now}) {
  final todaySource = now ?? DateTime.now();
  final today = DateTime(todaySource.year, todaySource.month, todaySource.day);
  return values
      .where((value) {
        final parsed = _parseStoredDate(value);
        if (parsed == null) {
          return true;
        }
        return !parsed.isBefore(today);
      })
      .toList(growable: false);
}

DateTime? _parseStoredDate(String value) {
  final clean = value.trim();
  if (clean.isEmpty) {
    return null;
  }

  final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(clean);
  if (isoMatch != null) {
    return _dateFromParts(
      int.parse(isoMatch.group(1)!),
      int.parse(isoMatch.group(2)!),
      int.parse(isoMatch.group(3)!),
    );
  }

  final legacyMatch = RegExp(r'^(\d{1,2})/(\d{1,2})').firstMatch(clean);
  if (legacyMatch != null) {
    final now = DateTime.now();
    return _dateFromParts(
      now.year,
      int.parse(legacyMatch.group(1)!),
      int.parse(legacyMatch.group(2)!),
    );
  }

  return null;
}

DateTime? _dateFromParts(int year, int month, int day) {
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}
