import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/character_model.dart';
import '../../shared/models/ootd_model.dart';
import '../../shared/widgets/grid_background.dart';
import '../../shared/widgets/onmu_date_picker.dart';
import '../../shared/widgets/pixel_character.dart';
import 'presentation/pages/daily_record_screen.dart';

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
  final Future<Object?> Function(OotdRecord) onEditRecord;
  final Future<void> Function(OotdRecord) onDeleteRecord;
  final VoidCallback onNavigateToProfile;

  const OotdListPage({
    super.key,
    required this.userCharacter,
    required this.customRecords,
    required this.onAddOotd,
    required this.onAddDailyRecord,
    required this.onViewOotdDetail,
    required this.onEditRecord,
    required this.onDeleteRecord,
    required this.onNavigateToProfile,
  });

  @override
  State<OotdListPage> createState() => _OotdListPageState();
}

class _OotdListPageState extends State<OotdListPage> {
  late DateTime _currentMonth;
  late DateTime _selectedDay;
  final List<OotdRecord> _allRecords = [];
  final Set<String> _locallyDeletedRecordIds = {};

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

    final dailyRecord = _getDailyRecordForDate(day);
    final ootdRecord = _getOotdRecordForDate(day);
    final record =
        dailyRecord ??
        ootdRecord ??
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
          dailyRecord: dailyRecord,
          ootdRecord: ootdRecord,
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
          onEditRecord: (editedRecord) async {
            final result = await widget.onEditRecord(editedRecord);
            if (!mounted) return result;
            if (result == 'deleted') {
              setState(() {
                _removeRecordImmediately(editedRecord);
              });
            } else if (result is OotdRecord) {
              setState(() {
                final idx = _allRecords.indexWhere(
                  (record) => record.id == result.id,
                );
                if (idx >= 0) {
                  _allRecords[idx] = result;
                }
              });
            }
            return result;
          },
          onDeleteRecord: (deletedRecord) async {
            await widget.onDeleteRecord(deletedRecord);
            if (!mounted) return;
            setState(() {
              _removeRecordImmediately(deletedRecord);
            });
          },
          onViewDetail: () {
            widget.onViewOotdDetail(record);
          },
        );
      },
    );
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

  OotdRecord? _getDailyRecordForDate(DateTime date) {
    try {
      return _allRecords.firstWhere(
        (r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day &&
            r.brands['recordType'] == 'daily',
      );
    } catch (_) {
      return null;
    }
  }

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


  void _removeRecordImmediately(OotdRecord deletedRecord) {
    final deletedId = deletedRecord.id;
    if (deletedId != null && deletedId.isNotEmpty) {
      _locallyDeletedRecordIds.add(deletedId);
    }
    _allRecords.removeWhere((record) {
      final sameId = deletedId != null &&
          deletedId.isNotEmpty &&
          record.id != null &&
          record.id!.isNotEmpty &&
          record.id == deletedId;
      final sameDay = record.date.year == deletedRecord.date.year &&
          record.date.month == deletedRecord.date.month &&
          record.date.day == deletedRecord.date.day;
      final sameType = record.brands['recordType'] == deletedRecord.brands['recordType'];
      return sameId || (sameDay && sameType);
    });
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
    final visibleCustomRecords = widget.customRecords.where((record) {
      final id = record.id;
      return id == null || id.isEmpty || !_locallyDeletedRecordIds.contains(id);
    }).toList(growable: false);
    final remoteIds = visibleCustomRecords
        .map((record) => record.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    _allRecords.removeWhere(
      (record) =>
          record.id != null &&
          record.id!.isNotEmpty &&
          !remoteIds.contains(record.id),
    );

    final Set<String> existingDates = _allRecords.map(_recordKey).toSet();
    for (final record in visibleCustomRecords) {
      final dateKey = _recordKey(record);
      final existingIndex = _allRecords.indexWhere(
        (item) => item.id != null && item.id!.isNotEmpty && item.id == record.id,
      );
      if (existingIndex >= 0) {
        _allRecords[existingIndex] = record;
      } else if (!existingDates.contains(dateKey)) {
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
    final cellHeight = availableCellWidth.clamp(68.0, 104.0).toDouble();

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
          final dailyRecord = _getDailyRecordForDate(cellDate);
          final ootdRecord = _getOotdRecordForDate(cellDate);
          final record = ootdRecord ?? dailyRecord;
          final weather = dailyRecord?.brands['weather'] ??
              dailyRecord?.weather ??
              ootdRecord?.brands['weather'] ??
              ootdRecord?.weather ??
              '';
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
                    if (weather.isNotEmpty)
                      Positioned(
                        top: 2,
                        right: 4,
                        child: Icon(
                          _weatherIcon(weather),
                          size: 10,
                          color: _weatherColor(weather),
                        ),
                      ),
                    if (ootdRecord != null)
                      Positioned(
                        bottom: 2,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: PixelCharacterWidget(
                            character: ootdRecord.character,
                            size: availableCellWidth
                                .clamp(26.0, 38.0)
                                .toDouble(),
                          ),
                        ),
                      ),
                    if (ootdRecord == null && dailyRecord != null)
                      Positioned(
                        bottom: 18,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Icon(
                            Icons.menu_book_outlined,
                            size: availableCellWidth
                                .clamp(18.0, 24.0)
                                .toDouble(),
                            color: AppColors.primaryPink,
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
  final OotdRecord? dailyRecord;
  final OotdRecord? ootdRecord;
  final CharacterDraft userCharacter;
  final Function(OotdRecord) onSaveRecord;
  final Function(DateTime, OotdRecord?) onAddDailyRecord;
  final Function(DateTime, OotdRecord?) onAddOotdRecord;
  final Future<Object?> Function(OotdRecord) onEditRecord;
  final Future<void> Function(OotdRecord) onDeleteRecord;
  final VoidCallback? onViewDetail;

  const _TimelineBottomSheetContent({
    required this.record,
    this.dailyRecord,
    this.ootdRecord,
    required this.userCharacter,
    required this.onSaveRecord,
    required this.onAddDailyRecord,
    required this.onAddOotdRecord,
    required this.onEditRecord,
    required this.onDeleteRecord,
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

  OotdRecord? get _dailyRecord {
    if (widget.dailyRecord != null) return widget.dailyRecord;
    return _localRecord.brands['recordType'] == 'daily' ? _localRecord : null;
  }

  OotdRecord? get _ootdRecord {
    if (widget.ootdRecord != null) return widget.ootdRecord;
    return _localRecord.brands['recordType'] == 'daily' ? null : _localRecord;
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
    final hasActiveRecord = _tabIndex == 0
        ? _dailyRecord != null && _dailyRecord!.timeline.isNotEmpty
        : _ootdRecord != null && _ootdRecord!.timeline.isNotEmpty;

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
          if (hasActiveRecord) ...[
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
    final dailyRecord = _dailyRecord ?? _localRecord;
    final photoItems = dailyRecord.timeline
        .where((item) => item.category == 'photo')
        .toList(growable: false);
    final isDiary = dailyRecord.brands['theme'] == 'diary';
    final result = DailyRecordResultScreen(
      record: dailyRecord,
      userCharacter: widget.userCharacter,
      includeCrew: _ootdRecord != null,
      photoCount: photoItems.length,
      onEdit: () {
        Navigator.pop(context);
        widget.onEditRecord(dailyRecord);
      },
    );

    if (!isDiary) return result;

    return Container(
      width: double.infinity,
      color: AppColors.bgWarm,
      child: GridBackground(child: result),
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
    final ootdRecord = _ootdRecord;
    if (ootdRecord == null) {
      return _buildEmptyOotdView();
    }

    final ootdItems = ootdRecord.timeline
        .where((item) => item.category == 'ootd')
        .toList(growable: false);
    final ootdMemo = ootdItems.isNotEmpty
        ? ootdItems.first.description
        : ootdRecord.brands['ootdMemo'] ??
            ootdRecord.brands['outfitMemo'] ??
            '오늘 코디를 기록했어요.';
    final ootdTitle = ootdItems.isNotEmpty ? ootdItems.first.placeName : '오늘 코디 기록';
    final tags = ootdRecord.moodTags.isEmpty
        ? const ['#OOTD']
        : ootdRecord.moodTags;
    final mood = ootdRecord.brands['mood'] ?? ootdRecord.mood;
    final weather = ootdRecord.brands['weather'] ?? ootdRecord.weather;
    final style = ootdRecord.brands['style'] ?? ootdRecord.brands['outfit'] ?? '오늘의 코디';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown, width: 1.2),
          ),
          child: Column(
            children: [
              Text(
                ootdTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tags.join(' '),
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 170,
                child: Center(
                  child: PixelCharacterWidget(
                    character: ootdRecord.character,
                    size: 130,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgWarm,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lineSoft),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ootdMemo,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSub,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMetaCol('MOOD', mood),
            _buildMetaCol('WEATHER', weather),
            _buildMetaCol('STYLE', style),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyOotdView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.checkroom_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            '아직 OOTD 기록이 없어요',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textMain,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '오늘 입은 코디를 기록하면\n이 탭에서 캐릭터와 코디 내용을 볼 수 있어요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSub,
              height: 1.4,
            ),
          ),
          SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onAddOotdRecord(_localRecord.date, _dailyRecord);
            },
            icon: const Icon(Icons.checkroom_outlined, size: 18),
            label: Text('오늘 코디 기록하기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryPink,
              side: const BorderSide(color: AppColors.primaryPink, width: 1.5),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtonRow() {
    final activeRecord = _tabIndex == 0
        ? (_dailyRecord ?? _localRecord)
        : (_ootdRecord ?? _localRecord);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              widget.onSaveRecord(activeRecord);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('이미지 저장 기능은 이후 연결 예정입니다.')),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: Text('이미지로 저장하기'),
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
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onEditRecord(activeRecord);
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
                onPressed: () async {
                  try {
                    await widget.onDeleteRecord(activeRecord);
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('기록을 삭제했어요.')),
                    );
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('기록을 삭제하지 못했어요. 잠시 후 다시 시도해 주세요.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text('삭제하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgDefault,
                  foregroundColor: AppColors.primaryPink,
                  side: const BorderSide(color: AppColors.linePink),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}




