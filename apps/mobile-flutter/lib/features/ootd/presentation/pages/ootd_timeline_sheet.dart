part of 'ootd_list_page.dart';

class _TimelineBottomSheetContent extends StatefulWidget {
  final OotdRecord record;
  final OotdRecord? dailyRecord;
  final OotdRecord? ootdRecord;
  final CharacterDraft userCharacter;
  final Function(OotdRecord) onSaveRecord;
  final SaveRecordImageCallback onSaveRecordImage;
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
    required this.onSaveRecordImage,
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
  final GlobalKey _recordImageCaptureKey = GlobalKey();
  double _currentExtent = _sheetDefaultSize; // 드래그 비율 상태 변수
  bool _isDailyRecordButtonHovered = false;
  bool _isOotdRecordButtonHovered = false;
  bool _isSavingRecordImage = false;

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
    final hasAnyRecord =
        (_dailyRecord != null && _dailyRecord!.timeline.isNotEmpty) ||
        (_ootdRecord != null && _ootdRecord!.timeline.isNotEmpty);
    final hasActiveRecord = _tabIndex == 0
        ? _dailyRecord != null && _dailyRecord!.timeline.isNotEmpty
        : _ootdRecord != null && _ootdRecord!.timeline.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasAnyRecord)
            _buildEmptyRecordView()
          else if (!hasActiveRecord && _tabIndex == 0)
            _buildEmptyDailyView()
          else if (!hasActiveRecord)
            _buildEmptyOotdView()
          else if (_tabIndex == 0)
            _buildCaptureSurface(_buildDailyTimelineView())
          else
            _buildCaptureSurface(_buildOotdDetailView()),
          SizedBox(height: 24),
          if (hasActiveRecord) ...[
            _buildBottomButtonRow(),
            SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildCaptureSurface(Widget child) {
    return RepaintBoundary(key: _recordImageCaptureKey, child: child);
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
  // [탭 1: 하루 일과 상세 구현] - 기록 데이터 기반 다이어리 레이아웃
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
    final ootdTitle = ootdItems.isNotEmpty
        ? ootdItems.first.placeName
        : '오늘 코디 기록';
    final tags = ootdRecord.moodTags.isEmpty
        ? const ['#OOTD']
        : ootdRecord.moodTags;
    final mood = ootdRecord.brands['mood'] ?? ootdRecord.mood;
    final weather = ootdRecord.brands['weather'] ?? ootdRecord.weather;
    final style =
        ootdRecord.brands['style'] ?? ootdRecord.brands['outfit'] ?? '오늘의 코디';

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
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMain),
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

  Widget _buildEmptyDailyView() {
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
            Icons.menu_book_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            '아직 하루 일과 기록이 없어요',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMain),
          ),
          SizedBox(height: 6),
          Text(
            '오늘 하루를 기록하면\n이 탭에서 사진과 메모를 볼 수 있어요.',
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
              widget.onAddDailyRecord(_localRecord.date, _ootdRecord);
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text('하루 일과 기록하기'),
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
            onPressed: _isSavingRecordImage
                ? null
                : () => _saveActiveRecordImage(activeRecord),
            icon: const Icon(Icons.download, size: 16),
            label: Text(_isSavingRecordImage ? '이미지 저장 중...' : '이미지로 저장하기'),
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('기록을 삭제했어요.')));
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

  Future<Uint8List> _captureRecordImageBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _recordImageCaptureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('저장할 결과 화면을 찾지 못했어요.');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('결과 이미지를 만들지 못했어요.');
    }
    return bytes;
  }

  Future<void> _saveActiveRecordImage(OotdRecord activeRecord) async {
    if (_isSavingRecordImage) return;
    setState(() => _isSavingRecordImage = true);

    try {
      final bytes = await _captureRecordImageBytes();
      final type = activeRecord.brands['recordType'] == 'daily'
          ? 'daily'
          : 'ootd';
      final date = activeRecord.date;
      final fileName =
          "$type-record-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.png";
      final savedRecord = await widget.onSaveRecordImage(
        record: activeRecord,
        bytes: bytes,
        fileName: fileName,
      );
      if (!mounted) return;
      setState(() {
        _localRecord = savedRecord;
        _isSavingRecordImage = false;
      });
      widget.onSaveRecord(savedRecord);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결과 이미지를 저장했어요.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingRecordImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 저장에 실패했어요: $error')),
      );
    }
  }
}
