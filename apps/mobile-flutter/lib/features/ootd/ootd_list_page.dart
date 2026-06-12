import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/character_model.dart';
import '../../shared/models/ootd_model.dart';
import '../../shared/widgets/grid_background.dart';
import '../../shared/widgets/onmu_date_picker.dart';
import '../../shared/widgets/pixel_character.dart';

class _BottomSheetScrollBehavior extends MaterialScrollBehavior {
  const _BottomSheetScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}

class OotdListPage extends StatefulWidget {
  final CharacterDraft userCharacter;
  final List<OotdRecord> customRecords;
  final Function(DateTime, OotdRecord?) onAddOotd;
  final void Function(DateTime, OotdRecord?) onAddDailyRecord;
  final Function(OotdRecord) onViewOotdDetail;
  final VoidCallback onNavigateToProfile;

  const OotdListPage({
    super.key,
    required this.userCharacter,
    required this.customRecords,
    required this.onAddOotd,
    required this.onAddDailyRecord,
    required this.onViewOotdDetail,
    required this.onNavigateToProfile,
  });

  @override
  State<OotdListPage> createState() => _OotdListPageState();
}

class _OotdListPageState extends State<OotdListPage> {
  late DateTime _currentMonth;
  late DateTime _selectedDay;
  final List<OotdRecord> _allRecords = [];

  final List<Color> _bgColors = [
    AppColors.calendarDatePinkBg,
    AppColors.calendarDatePurpleBg,
    AppColors.calendarDateGreenBg,
    AppColors.calendarDateYellowBg,
    AppColors.calendarDateBlueBg,
  ];

  // 달력 셀 테두리용 파스텔 컬러 팔레트
  final List<Color> _pastelBorders = [
    AppColors.accentBlue,
    AppColors.primaryPink,
    AppColors.accentOrange,
    AppColors.accentGreen,
    AppColors.primaryPurple,
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _currentMonth = DateTime(today.year, today.month, 1);
    _selectedDay = DateTime(today.year, today.month, today.day);
  }

  int get _firstWeekday =>
      DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
  int get _totalDaysInMonth =>
      DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

  // 기록 종류 선택 바텀시트 띄우기
  void _showRecordTypeSelectionSheet(BuildContext context, DateTime date) {
    DateTime localSelectedDate = date;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: AppColors.transparent,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final String weekdayName = _getWeekdayName(localSelectedDate);
            final String dateStr =
                '${localSelectedDate.year}.${localSelectedDate.month.toString().padLeft(2, '0')}.${localSelectedDate.day.toString().padLeft(2, '0')} ($weekdayName)';

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.bgDefault,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '어떤 기록을 남기시겠습니까?',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 16),

                  // 날짜 선택 영역 추가
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await OnmuDatePicker.pickDate(
                          context: context,
                          initialDate: localSelectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() {
                            localSelectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPinkSoft.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryPink.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: AppColors.primaryPink,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '기록할 날짜: $dateStr',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.edit_calendar,
                              color: AppColors.primaryPink,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  Row(
                    children: [
                      // 1. 하루 일과 기록하기
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onAddDailyRecord(
                                localSelectedDate,
                                _getOotdRecordForDate(localSelectedDate),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: AppColors.bgDefault,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.lineSoft),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 32,
                                    color: AppColors.primaryPink,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '하루 일과 기록',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '타임라인 및 일과 정보',
                                    style: AppTextStyles.sticker.copyWith(
                                      color: AppColors.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // 2. OOTD 기록하기
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onAddOotd(localSelectedDate, null);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: AppColors.bgDefault,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.lineSoft),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.checkroom,
                                    size: 32,
                                    color: AppColors.primaryPurple,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'OOTD 기록',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '의상 코디 및 외모 꾸미기',
                                    style: AppTextStyles.sticker.copyWith(
                                      color: AppColors.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 날짜 클릭 시 슬라이드 시트 띄우기
  void _onDayTap(DateTime day) {
    setState(() {
      _selectedDay = day;
    });

    final record =
        _getRecordForDate(day) ??
        OotdRecord(
          date: day,
          character: widget.userCharacter,
          moodTags: [],
          brands: {},
          weather: 'sunny',
          mood: 'happy',
          isPublic: false,
          timeline: [],
        );

    // 슬라이드 형식으로 아래에서 위로 바텀시트 호출 (isScrollControlled: true)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true, // 네이티브 바텀시트 드래그 활성화 (닫기 동작 위함)
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height,
        maxWidth: MediaQuery.of(context).size.width,
      ),
      builder: (context) {
        return _TimelineBottomSheetContent(
          record: record,
          userCharacter: widget.userCharacter,
          onSaveRecord: (updatedRecord) {
            setState(() {
              final idx = _allRecords.indexWhere(
                (r) =>
                    r.date.year == updatedRecord.date.year &&
                    r.date.month == updatedRecord.date.month &&
                    r.date.day == updatedRecord.date.day,
              );
              if (idx != -1) {
                _allRecords[idx] = updatedRecord;
              } else {
                _allRecords.add(updatedRecord);
              }
            });
          },
          onAddDailyRecord: (date, ootdRecord) {
            widget.onAddDailyRecord(date, ootdRecord);
          },
          onAddOotdRecord: (date, ootdRecord) {
            widget.onAddOotd(date, ootdRecord);
          },
          onViewDetail: () {
            widget.onViewOotdDetail(record);
          },
        );
      },
    );
  }

  OotdRecord? _getRecordForDate(DateTime date) {
    try {
      return _allRecords.firstWhere(
        (r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  OotdRecord? _getOotdRecordForDate(DateTime date) {
    try {
      return _allRecords.firstWhere(
        (r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day &&
            r.brands['recordType'] != 'daily',
      );
    } catch (_) {
      return null;
    }
  }

  String _getWeekdayName(DateTime date) {
    final list = ['일', '월', '화', '수', '목', '금', '토'];
    return list[date.weekday % 7];
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // customRecords 병합 동기화
    final Set<String> existingDates = _allRecords.map(_recordKey).toSet();
    for (final record in widget.customRecords) {
      final dateKey = _recordKey(record);
      if (!existingDates.contains(dateKey)) {
        _allRecords.add(record);
        existingDates.add(dateKey);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bgDefault, // DESIGN.md 기준 바탕색 하얀색(#FFFFFF)
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              // 1. 달력 상단 헤더
              _buildHeader(),

              // 2. 요일 헤더
              _buildWeekDaysHeader(),

              // 3. 달력 격자 뷰
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [_buildCalendarGrid(), SizedBox(height: 32)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordTypeSelectionSheet(context, _selectedDay),
        mouseCursor: SystemMouseCursors.click,
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  String _recordKey(OotdRecord record) {
    final type = record.brands['recordType'] ?? 'ootd';
    return '${record.date.year}-${record.date.month}-${record.date.day}-$type';
  }

  Widget _buildHeader() {
    final daysInCurrentMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final recordedDayCount = _allRecords
        .where(
          (record) =>
              record.date.year == _currentMonth.year &&
              record.date.month == _currentMonth.month,
        )
        .map((record) => record.date.day)
        .toSet()
        .length;
    final monthlyProgress = recordedDayCount / daysInCurrentMonth;
    final monthlyPercent = (monthlyProgress * 100).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        final progressBadgeWidth =
            (constraints.maxWidth * (isCompact ? 0.48 : 0.42))
                .clamp(132.0, 196.0)
                .toDouble();
        final headerTitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_currentMonth.year}. ${_currentMonth.month.toString().padLeft(2, '0')}',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: AppColors.textSub,
                  ),
                  onPressed: _prevMonth,
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSub,
                  ),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '오늘의 코디 기록 다이어리',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primaryPink,
              ),
            ),
          ],
        );
        final progressBadge = _buildMonthlyProgressBadge(
          recordedDayCount: recordedDayCount,
          monthlyProgress: monthlyProgress,
          monthlyPercent: monthlyPercent,
          isCompact: isCompact,
        );

        return Padding(
          padding: EdgeInsets.only(
            left: isCompact ? 16 : 20,
            right: isCompact ? 16 : 20,
            top: 16,
            bottom: 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: headerTitle),
              SizedBox(width: isCompact ? 8 : 12),
              SizedBox(width: progressBadgeWidth, child: progressBadge),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyProgressBadge({
    required int recordedDayCount,
    required double monthlyProgress,
    required int monthlyPercent,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryPinkSoft.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.linePink, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '이번 달 기록 $recordedDayCount일',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMain,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$monthlyPercent%',
                style: AppTextStyles.micro.copyWith(
                  color: AppColors.primaryPink,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: monthlyProgress,
              minHeight: 7,
              backgroundColor: AppColors.bgDefault.withValues(alpha: 0.9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryPink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaysHeader() {
    final weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: AppColors.bgDefault.withOpacity(0.5),
      child: Row(
        children: weekdays.map((day) {
          final isWeekend = day == 'SUN' || day == 'SAT';
          return Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: isWeekend
                    ? AppColors.accentRed.withOpacity(0.8)
                    : AppColors.textSub,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstWeekday = _firstWeekday;
    final totalDays = _totalDaysInMonth;
    final totalCells = firstWeekday + totalDays;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final horizontalPadding = isCompact ? 6.0 : 10.0;
    final crossSpacing = isCompact ? 3.0 : 5.0;
    final availableCellWidth =
        (screenWidth - (horizontalPadding * 2) - (crossSpacing * 6)) / 7;
    final cellHeight = availableCellWidth.clamp(58.0, 88.0).toDouble();

    return ClipRect(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 8,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisExtent: cellHeight,
          crossAxisSpacing: crossSpacing,
          mainAxisSpacing: isCompact ? 6 : 8,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          if (index < firstWeekday) {
            return const SizedBox();
          }

          final day = index - firstWeekday + 1;
          final cellDate = DateTime(
            _currentMonth.year,
            _currentMonth.month,
            day,
          );
          final isSelected =
              cellDate.year == _selectedDay.year &&
              cellDate.month == _selectedDay.month &&
              cellDate.day == _selectedDay.day;
          final record = _getRecordForDate(cellDate);
          final borderColor = _pastelBorders[day % _pastelBorders.length];

          final int? bgColorIndex = record != null
              ? int.tryParse(record.brands['bgColorIndex'] ?? '')
              : null;
          final Color cellBgColor = bgColorIndex != null
              ? _bgColors[bgColorIndex].withOpacity(0.4)
              : AppColors.bgDefault;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _onDayTap(cellDate),
              child: Container(
                decoration: BoxDecoration(
                  color: cellBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryPink
                        : record != null
                        ? borderColor
                        : AppColors.lineSoft.withOpacity(0.6),
                    width: isSelected ? 2.5 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryPink.withOpacity(0.15),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      left: 6,
                      child: Text(
                        day.toString(),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isSelected
                              ? AppColors.primaryPink
                              : AppColors.textMain,
                        ),
                      ),
                    ),
                    if (record != null)
                      Positioned(
                        top: 2,
                        right: 4,
                        child: Icon(
                          record.weather == 'sunny'
                              ? Icons.wb_sunny
                              : Icons.cloud_outlined,
                          size: 10,
                          color: record.weather == 'sunny'
                              ? AppColors.accentOrange
                              : AppColors.accentBlue,
                        ),
                      ),
                    if (record != null)
                      Positioned(
                        bottom: 2,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: PixelCharacterWidget(
                            character: record.character,
                            size: availableCellWidth
                                .clamp(26.0, 38.0)
                                .toDouble(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// [슬라이드식 바텀시트 콘텐츠 위젯]
// -----------------------------------------------------------------------------
class _TimelineBottomSheetContent extends StatefulWidget {
  final OotdRecord record;
  final CharacterDraft userCharacter;
  final Function(OotdRecord) onSaveRecord;
  final Function(DateTime, OotdRecord?) onAddDailyRecord;
  final Function(DateTime, OotdRecord?) onAddOotdRecord;
  final VoidCallback? onViewDetail;

  const _TimelineBottomSheetContent({
    required this.record,
    required this.userCharacter,
    required this.onSaveRecord,
    required this.onAddDailyRecord,
    required this.onAddOotdRecord,
    this.onViewDetail,
  });

  @override
  State<_TimelineBottomSheetContent> createState() =>
      _TimelineBottomSheetContentState();
}

class _TimelineBottomSheetContentState
    extends State<_TimelineBottomSheetContent> {
  static const double _sheetMinSize = 0.08;
  static const double _sheetDefaultSize = 0.68;
  static const double _sheetMaxSize = 1.0;

  int _tabIndex = 0; // 0: 하루 일과, 1: OOTD 기록
  late OotdRecord _localRecord;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  double _currentExtent = _sheetDefaultSize; // 드래그 비율 상태 변수
  bool _isDailyRecordButtonHovered = false;
  bool _isOotdRecordButtonHovered = false;

  @override
  void initState() {
    super.initState();
    _localRecord = widget.record;
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Widget _buildSheetDragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.lineSoft,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader(bool isFullScreen) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetDragHandle(),
          if (isFullScreen) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.bgDefault,
                border: Border(
                  bottom: BorderSide(color: AppColors.lineSoft, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.textMain,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _tabIndex == 0 ? '하루 일과' : 'OOTD 기록',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.edit_note,
                            color: AppColors.primaryPink,
                            size: 24,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_localRecord.date.year}.${_localRecord.date.month.toString().padLeft(2, '0')}.${_localRecord.date.day.toString().padLeft(2, '0')} (${_getWeekdayName(_localRecord.date)})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '오늘 하루의 소중한 기록을 채워보세요',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: AppColors.textSub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
          if (_localRecord.timeline.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton(0, '하루 일과'),
                SizedBox(width: 12),
                _buildTabButton(1, 'OOTD 기록'),
              ],
            ),
            SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildSheetScrollableBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_localRecord.timeline.isEmpty)
            _buildEmptyRecordView()
          else if (_tabIndex == 0)
            _buildDailyTimelineView()
          else
            _buildOotdDetailView(),
          SizedBox(height: 24),
          if (_localRecord.timeline.isNotEmpty) ...[
            _buildBottomButtonRow(),
            SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : AppColors.lineSoft,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: isSelected ? AppColors.primaryPink : AppColors.textSub,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        setState(() {
          _currentExtent = notification.extent;
        });
        if (notification.extent <= _sheetMinSize + 0.01) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
        return true;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _sheetDefaultSize,
        minChildSize: _sheetMinSize,
        maxChildSize: _sheetMaxSize,
        snap: true,
        snapSizes: const [_sheetMinSize, _sheetDefaultSize, _sheetMaxSize],
        expand: false,
        builder: (context, scrollController) {
          final isFullScreen = _currentExtent >= 0.90;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: isFullScreen
                  ? BorderRadius.zero
                  : const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textMain.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ScrollConfiguration(
              behavior: const _BottomSheetScrollBehavior(),
              child: ListView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottomInset),
                children: [
                  _buildSheetHeader(isFullScreen),
                  _buildSheetScrollableBody(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyRecordView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.note_add_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            '아직 기록된 내용이 없습니다',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMain),
          ),
          SizedBox(height: 6),
          Text(
            '오늘 하루 어떤 일들이 있었나요?\n소중한 순간들을 기록해 보세요!',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSub,
              height: 1.4,
            ),
          ),
          SizedBox(height: 24),
          Column(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) {
                  setState(() {
                    _isDailyRecordButtonHovered = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _isDailyRecordButtonHovered = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isDailyRecordButtonHovered
                        ? [
                            BoxShadow(
                              color: AppColors.primaryPink.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onAddDailyRecord(widget.record.date, null);
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text('하루 일과 기록하기'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink.withValues(
                        alpha: 0.14,
                      ),
                      foregroundColor: AppColors.primaryPink,
                      overlayColor: AppColors.primaryPink.withValues(
                        alpha: 0.04,
                      ),
                      side: const BorderSide(
                        color: AppColors.primaryPink,
                        width: 1.5,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) {
                  setState(() {
                    _isOotdRecordButtonHovered = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _isOotdRecordButtonHovered = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isOotdRecordButtonHovered
                        ? [
                            BoxShadow(
                              color: AppColors.primaryPurple.withValues(
                                alpha: 0.16,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onAddOotdRecord(widget.record.date, null);
                    },
                    icon: const Icon(Icons.checkroom, size: 16),
                    label: Text('오늘 코디 기록하기 (OOTD)'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.bgDefault,
                      foregroundColor: AppColors.primaryPurple,
                      overlayColor: AppColors.primaryPurple.withValues(
                        alpha: 0.08,
                      ),
                      side: const BorderSide(
                        color: AppColors.primaryPurple,
                        width: 1.5,
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWeekdayName(DateTime date) {
    final list = ['일', '월', '화', '수', '목', '금', '토'];
    return list[date.weekday % 7];
  }

  // ---------------------------------------------------------------------------
  // [탭 1: 하루 일과 상세 구현] - (Figma 서울 카페 투어 기준 고화질 다이어리 레이아웃)
  // ---------------------------------------------------------------------------
  Widget _buildDailyTimelineView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 메인 다이어리 제목 카드 (화이트 앤 소프트 브라운)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.textMain.withValues(alpha: 0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '서울 카페 투어',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '#카페 #한남동 #데이트',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSub,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // PLACE 01 카드 & TODAY'S MEMORY
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PLACE 01 (mRd Record)
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lineSoft),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 105,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.photoFrameRoseBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            color: AppColors.textSub,
                            size: 28,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'mRd Record',
                            style: AppTextStyles.sticker.copyWith(
                              color: AppColors.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'mRd Record',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textMain,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '케이크가 진짜 맛있었고 매장 분위기도 굿! 사진도 찰칵',
                      style: AppTextStyles.sticker.copyWith(
                        color: AppColors.textSub,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12),

            // TODAY'S MEMORY 체크리스트
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(14),
                height: 175,
                decoration: BoxDecoration(
                  color: AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lineBrown, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bookmark_outline_rounded,
                          color: AppColors.accentBrown,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'TODAY\'S MEMORY',
                          style: AppTextStyles.sticker.copyWith(
                            color: AppColors.accentBrown,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCheckRow(true, '한남동 산책'),
                          _buildCheckRow(true, 'mRd Record'),
                          _buildCheckRow(true, 'Archive 한남'),
                          _buildCheckRow(true, 'Ofr. seoul'),
                          _buildCheckRow(false, '저녁 맛집'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // 커플 아바타 standing 스크랩 (나 & 지훈)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown, width: 1.2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      PixelCharacterWidget(
                        character: _localRecord.character,
                        size: 72,
                      ),
                      SizedBox(height: 6),
                      Text(
                        '나',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 26),
                  const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.accentRed,
                    size: 28,
                  ),
                  SizedBox(width: 26),
                  Column(
                    children: [
                      PixelCharacterWidget(
                        character: const CharacterDraft(
                          gender: 'male',
                          nickname: '지훈',
                          hairStyleIndex: 2,
                          hairColorIndex: 1,
                          skinToneIndex: 1,
                          topStyleIndex: 1,
                          bottomStyleIndex: 0,
                        ),
                        size: 72,
                      ),
                      SizedBox(height: 6),
                      Text(
                        '지훈',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '우리의 가을 시밀러 룩 데이트!',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryPink,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // PLACE 02 & PLACE 03 이미지 프레임 카드
        Row(
          children: [
            Expanded(
              child: _buildScrapPhotoCard(
                'PLACE 02 - Archive Hannam',
                '편집숍 시향 최고!',
                AppColors.photoFrameGreenBg,
                Icons.shopping_bag_outlined,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildScrapPhotoCard(
                'PLACE 03 - Ofr. seoul',
                '달달한 플랫화이트',
                AppColors.photoFrameMintBg,
                Icons.coffee_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // EVENING (PLACE 04) 및 요약 정보
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    color: AppColors.primaryPink,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'EVENING - 성수 맛집',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                '저녁으로 예약해둔 파스타 맛집. 분위기 맛 다 최고였어!',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSub,
                  height: 1.3,
                ),
              ),
              const Divider(color: AppColors.lineSoft, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetaCol('WITH', '나 / 지훈'),
                  _buildMetaCol('MOOD', '😊 🥰 🎉'),
                  _buildMetaCol('WEATHER', '맑음 20°C'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckRow(bool checked, String text) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_box_outlined : Icons.check_box_outline_blank,
          size: 15,
          color: checked ? AppColors.primaryPink : AppColors.textMuted,
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.labelSmall.copyWith(
            color: checked ? AppColors.textMain : AppColors.textMuted,
            decoration: checked ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  Widget _buildScrapPhotoCard(
    String title,
    String desc,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: AppColors.textSub),
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: AppTextStyles.sticker.copyWith(color: AppColors.textMuted),
          ),
          SizedBox(height: 2),
          Text(
            desc,
            style: AppTextStyles.sticker.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCol(String label, String val) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted),
        ),
        SizedBox(height: 4),
        Text(
          val,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMain),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // [탭 2: OOTD 기록 상세 구현] - (Figma OOTD 기록 예시 반영 및 화이트 테마)
  // ---------------------------------------------------------------------------
  Widget _buildOotdDetailView() {
    const String lookMemoText =
        '베이지 + 블랙 조합은\n언제나 실패가 없어!\n단정하면서도\n포인트는 가방으로 툭 ♥';

    return Column(
      children: [
        // 메인 다이어리 영역
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown, width: 1.2),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // - 왼쪽: Today's Look 메모지 & MOOD 라디오
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s\nLook',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primaryPink,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            // 손글씨 폰트 느낌의 바디 텍스트
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.bgDefault,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.lineSoft.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                lookMemoText,
                                style: AppTextStyles.sticker.copyWith(
                                  color: AppColors.textSub,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),

                            // MOOD 라디오
                            _buildOotdPaperSection('MOOD', [
                              _buildOotdRadio(true, '😊 신나요!'),
                              _buildOotdRadio(false, '😐 평범해요'),
                              _buildOotdRadio(false, '😴 피곤해요'),
                            ]),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),

                      // 가운데: 캐릭터 크게 그리기
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            SizedBox(height: 16),
                            PixelCharacterWidget(
                              character: _localRecord.character,
                              size: 110,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),

                      // 오른쪽: HAIR 및 WEATHER 메모지
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildOotdPaperSection('HAIR', [
                              Text(
                                '오늘은 웨이브를\n살짝 넣어서\n분위기 있게 ♥',
                                style: AppTextStyles.tiny.copyWith(
                                  color: AppColors.textSub,
                                  height: 1.35,
                                ),
                              ),
                            ]),
                            SizedBox(height: 10),
                            _buildOotdPaperSection('WEATHER', [
                              Row(
                                children: [
                                  Icon(
                                    Icons.wb_sunny_outlined,
                                    size: 12,
                                    color: AppColors.accentOrange,
                                  ),
                                  SizedBox(width: 4),
                                  Text('20°C / 맑음', style: AppTextStyles.tiny),
                                ],
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // POINT 버건디백 카드
                      Expanded(
                        flex: 6,
                        child: _buildOotdPaperSection('POINT', [
                          Text('가방으로 포인트 주기!', style: AppTextStyles.tiny),
                          SizedBox(height: 6),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.bgDefault,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.lineSoft),
                              ),
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.accentRed,
                                size: 22,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      SizedBox(width: 12),

                      // OUTFIT INFO
                      Expanded(
                        flex: 6,
                        child: _buildOotdPaperSection('OUTFIT INFO', [
                          _buildOutfitRow(Icons.checkroom, 'outer', '베이지 하프코트'),
                          _buildOutfitRow(Icons.checkroom, 'top', '아이보리 니트'),
                          _buildOutfitRow(
                            Icons.checkroom,
                            'bottom',
                            '블랙 롱 스커트',
                          ),
                          _buildOutfitRow(
                            Icons.shopping_bag_outlined,
                            'bag',
                            '버건디 숄더백',
                          ),
                          _buildOutfitRow(
                            Icons.circle_outlined,
                            'shoes',
                            '화이트 삭스 + 로퍼',
                          ),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              // 마스킹 테이프 장식 데코
              Positioned(
                right: -8,
                top: -6,
                child: Transform.rotate(
                  angle: 0.15,
                  child: Container(
                    width: 48,
                    height: 12,
                    color: AppColors.accentOrange.withOpacity(0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // TODAY'S TAG (파스텔 칩)
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'TODAY\'S TAG',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _localRecord.moodTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPinkSoft.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.linePink.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  tag,
                  style: AppTextStyles.sticker.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 16),

        // 평가 피드백 카드
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '오늘 코디는 어땠나요?',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final double rating =
                          double.tryParse(
                            _localRecord.brands['rating'] ?? '5.0',
                          ) ??
                          5.0;
                      final int fullStars = rating.floor();
                      return Row(
                        children: [
                          ...List.generate(5, (index) {
                            if (index < fullStars) {
                              return const Icon(
                                Icons.star,
                                color: AppColors.accentOrange,
                                size: 14,
                              );
                            } else {
                              return const Icon(
                                Icons.star_border,
                                color: AppColors.accentOrange,
                                size: 14,
                              );
                            }
                          }),
                          SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textMain,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const Divider(color: AppColors.lineSoft, height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '다음에 입고 싶은 룩: ',
                    style: AppTextStyles.sticker.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '니트에 청바지 조합도 좋을 것 같아! ♡',
                      style: AppTextStyles.sticker.copyWith(
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOotdPaperSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.micro.copyWith(color: AppColors.textMuted),
          ),
          SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOotdRadio(bool selected, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 11,
            color: selected ? AppColors.primaryPink : AppColors.textMuted,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.tiny.copyWith(color: AppColors.textMain),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitRow(IconData icon, String part, String brand) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 9, color: AppColors.textMuted),
          SizedBox(width: 4),
          Text(
            '$part: ',
            style: AppTextStyles.micro.copyWith(color: AppColors.textSub),
          ),
          Expanded(
            child: Text(
              brand,
              style: AppTextStyles.micro.copyWith(color: AppColors.textMain),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [공통 하단 버튼바 및 기능]
  // ---------------------------------------------------------------------------
  Widget _buildBottomButtonRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close bottom sheet
              if (_localRecord.brands['recordType'] == 'daily') {
                widget.onAddDailyRecord(_localRecord.date, _localRecord);
              } else {
                widget.onAddOotdRecord(_localRecord.date, _localRecord);
              }
            },
            icon: const Icon(Icons.edit, size: 16),
            label: Text('수정하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bgDefault,
              foregroundColor: AppColors.textMain,
              side: const BorderSide(color: AppColors.lineSoft),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              widget.onSaveRecord(_localRecord);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('이미지가 핸드폰 갤러리에 저장되었습니다! 📸')),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: Text('저장하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
