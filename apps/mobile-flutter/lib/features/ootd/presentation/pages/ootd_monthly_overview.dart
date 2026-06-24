part of 'ootd_list_page.dart';

class _MonthlyOverviewStats {
  const _MonthlyOverviewStats({
    required this.ootdRecordDays,
    required this.dailyRecordCount,
    required this.dailyPhotoCount,
    required this.ootdRate,
  });

  final int ootdRecordDays;
  final int dailyRecordCount;
  final int dailyPhotoCount;
  final double ootdRate;
}

extension _OotdListMonthlyOverview on _OotdListPageState {
  _MonthlyOverviewStats _monthlyOverviewStats() {
    final monthRecords = _allRecords.where(
      (record) =>
          record.date.year == _currentMonth.year &&
          record.date.month == _currentMonth.month,
    );

    final ootdDays = <int>{};
    var dailyRecordCount = 0;
    var dailyPhotoCount = 0;

    for (final record in monthRecords) {
      if (record.brands['recordType'] == 'daily') {
        dailyRecordCount += 1;
        dailyPhotoCount += _dailyPhotoCount(record);
      } else {
        ootdDays.add(record.date.day);
      }
    }

    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final ootdRate = daysInMonth == 0 ? 0.0 : ootdDays.length / daysInMonth;

    return _MonthlyOverviewStats(
      ootdRecordDays: ootdDays.length,
      dailyRecordCount: dailyRecordCount,
      dailyPhotoCount: dailyPhotoCount,
      ootdRate: ootdRate,
    );
  }

  int _dailyPhotoCount(OotdRecord record) {
    var count = record.imageUrls.length;

    final mediaCount = record.media.length;
    if (mediaCount > count) {
      count = mediaCount;
    }

    final timelinePhotoCount = record.timeline
        .where((item) => item.category.toLowerCase() == 'photo')
        .length;
    if (timelinePhotoCount > count) {
      count = timelinePhotoCount;
    }

    return count;
  }

  Widget _buildCalendarMonthSummary() {
    final stats = _monthlyOverviewStats();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '이번 달 한눈에 보기',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primaryPink,
                fontSize: 15,
              ),
            ),
          ),
          _buildMonthlyOverviewCard(stats),
          const SizedBox(height: 14),
          _buildTodayLineCard(stats),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverviewCard(_MonthlyOverviewStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMain.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMonthlyOverviewMetric(
              iconAsset: 'assets/images/diary_decorate/Clothes.png',
              label: '코디 기록',
              value: '${stats.ootdRecordDays}일',
              iconSize: 24,
            ),
          ),
          _buildMetricDivider(),
          Expanded(
            child: _buildMonthlyOverviewMetric(
              iconAsset: 'assets/images/diary_decorate/Diary.png',
              label: '하루 기록',
              value: '${stats.dailyRecordCount}건',
              iconSize: 24,
            ),
          ),
          _buildMetricDivider(),
          Expanded(
            child: _buildMonthlyOverviewMetric(
              iconAsset: 'assets/images/diary_decorate/Camera.png',
              label: '사진 등록',
              value: '${stats.dailyPhotoCount}장',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverviewMetric({
    required String iconAsset,
    required String label,
    required String value,
    double iconSize = 30,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPixelAsset(iconAsset, width: iconSize, height: iconSize),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSub,
                  fontSize: 11,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textMain,
                  fontSize: 14,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppColors.lineSoft,
    );
  }

  Widget _buildTodayLineCard(_MonthlyOverviewStats stats) {
    final characterAsset = widget.userCharacter.gender.toLowerCase() == 'male'
        ? 'assets/images/diary_decorate/boy.png'
        : 'assets/images/diary_decorate/girl.png';
    final message = stats.ootdRate >= 0.5
        ? '이번 달은 코디 기록이 꾸준히 쌓이고 있어요'
        : '작은 기록이 모여 \n나만의 스타일이 완성돼요';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘의 한 줄',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.primaryPink,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.bgDefault.withOpacity(0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineSoft, width: 1.2),
          ),
          child: Row(
            children: [
              _buildPixelAsset(characterAsset, width: 50, height: 50),
              const SizedBox(width: 10),
              Expanded(child: _buildTodayLineMessage(message)),
              const SizedBox(width: 8),
              _buildPixelAsset(
                'assets/images/diary_decorate/Flowerpot.png',
                width: 34,
                height: 34,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayLineMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMain,
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildPixelAsset(
    String assetPath, {
    required double width,
    required double height,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => SizedBox(width: width, height: height),
    );
  }
}
