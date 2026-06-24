part of 'ootd_list_page.dart';

extension _OotdListCalendarHelpers on _OotdListPageState {
  IconData _weatherIcon(String weather) {
    final normalized = weather.toLowerCase();
    if (normalized.contains('rain') || weather.contains('비')) {
      return Icons.umbrella_outlined;
    }
    if (normalized.contains('snow') || weather.contains('눈')) {
      return Icons.ac_unit;
    }
    if (normalized.contains('cloud') || weather.contains('흐')) {
      return Icons.cloud_outlined;
    }
    return Icons.wb_sunny_outlined;
  }

  Color _weatherColor(String weather) {
    final normalized = weather.toLowerCase();
    if (normalized.contains('rain') || weather.contains('비')) {
      return AppColors.accentBlue;
    }
    if (normalized.contains('snow') || weather.contains('눈')) {
      return AppColors.primaryPurple;
    }
    if (normalized.contains('cloud') || weather.contains('흐')) {
      return AppColors.textMuted;
    }
    return AppColors.accentOrange;
  }
}
