import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../../../shared/widgets/pixel_character.dart';

class DailyRecordScreen extends StatefulWidget {
  final CharacterDraft userCharacter;
  final DateTime recordDate;
  final OotdRecord? ootdRecord;
  final ValueChanged<OotdRecord> onSave;
  final VoidCallback onCreateOotd;

  const DailyRecordScreen({
    super.key,
    required this.userCharacter,
    required this.recordDate,
    required this.onSave,
    required this.onCreateOotd,
    this.ootdRecord,
  });

  @override
  State<DailyRecordScreen> createState() => _DailyRecordScreenState();
}

class _DailyRecordScreenState extends State<DailyRecordScreen> {
  int _currentStep = 0;
  int _selectedMood = 0;
  int _selectedWeather = 0;
  int _selectedTheme = 0;
  bool _includeCrew = true;
  OotdRecord? _savedRecord;
  int _savedPhotoCount = 0;

  final _dayMemoController = TextEditingController();
  final _tagController = TextEditingController();
  final List<_PhotoMemoDraft> _photoMemos = [_PhotoMemoDraft()];
  final List<String> _hashtags = ['#하루기록'];

  final _moods = const [
    _ChoiceData('행복', Icons.sentiment_very_satisfied, AppColors.primaryPink),
    _ChoiceData('평온', Icons.spa_outlined, AppColors.accentGreen),
    _ChoiceData('신남', Icons.auto_awesome, AppColors.accentOrange),
    _ChoiceData('피곤', Icons.nights_stay_outlined, AppColors.primaryPurple),
  ];

  final _weathers = const [
    _ChoiceData('맑음', Icons.wb_sunny_outlined, AppColors.accentOrange),
    _ChoiceData('흐림', Icons.cloud_outlined, AppColors.accentBlue),
    _ChoiceData('비', Icons.water_drop_outlined, AppColors.primaryPurple),
    _ChoiceData('눈', Icons.ac_unit, AppColors.accentBlue),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ootdRecord != null &&
        widget.ootdRecord!.brands['recordType'] == 'daily') {
      final r = widget.ootdRecord!;
      _selectedMood = _moods.indexWhere((m) => m.label == r.brands['mood']);
      if (_selectedMood == -1) _selectedMood = 0;
      _selectedWeather = _weathers.indexWhere(
        (w) => w.label == r.brands['weather'],
      );
      if (_selectedWeather == -1) _selectedWeather = 0;
      _selectedTheme = r.brands['theme'] == 'diary' ? 0 : 1;
      _includeCrew = r.brands['crew'] == 'included';

      _hashtags.clear();
      _hashtags.addAll(r.moodTags);

      // Load daily memo
      final dailyItem = r.timeline.firstWhere(
        (item) => item.category == 'daily',
        orElse: () => const TimelineItem(
          time: '',
          placeName: '',
          category: '',
          description: '',
        ),
      );
      _dayMemoController.text = dailyItem.description;

      // Load photo memos
      final photoItems = r.timeline
          .where((item) => item.category == 'photo')
          .toList();
      _photoMemos.clear();
      if (photoItems.isEmpty) {
        _photoMemos.add(_PhotoMemoDraft());
      } else {
        for (final item in photoItems) {
          final draft = _PhotoMemoDraft();
          draft.controller.text = item.description;
          draft.hasPhoto = item.placeName == '추가한 사진';
          _photoMemos.add(draft);
        }
      }
    }
  }

  @override
  void dispose() {
    for (final photo in _photoMemos) {
      photo.dispose();
    }
    _dayMemoController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep == 7) {
      _closeResult();
      return;
    }
    if (_currentStep == 6) {
      _save();
      return;
    }
    setState(() => _currentStep++);
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _currentStep--);
  }

  Future<void> _closeResult() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    Navigator.of(context).pop(_savedRecord);
  }

  void _addTag() {
    final value = _tagController.text.trim();
    if (value.isEmpty) return;
    final tag = value.startsWith('#') ? value : '#$value';
    if (!_hashtags.contains(tag)) {
      setState(() {
        _hashtags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _addPhotoMemo() {
    setState(() => _photoMemos.add(_PhotoMemoDraft()));
  }

  void _removePhotoMemo(int index) {
    if (_photoMemos.length == 1) return;
    setState(() {
      final removed = _photoMemos.removeAt(index);
      removed.dispose();
    });
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    final selectedMood = _moods[_selectedMood].label;
    final selectedWeather = _weathers[_selectedWeather].label;
    final memo = _dayMemoController.text.trim();
    final themeLabel = _selectedTheme == 0 ? 'diary' : 'clean';
    final photoTimeline = <TimelineItem>[];

    for (var i = 0; i < _photoMemos.length; i++) {
      final photo = _photoMemos[i];
      if (!photo.hasPhoto && photo.controller.text.trim().isEmpty) continue;
      photoTimeline.add(
        TimelineItem(
          time: '사진 ${i + 1}',
          placeName: photo.hasPhoto ? '추가한 사진' : '사진 메모',
          category: 'photo',
          description: photo.controller.text.trim().isEmpty
              ? '사진에 대한 코멘트를 남기지 않았어요.'
              : photo.controller.text.trim(),
        ),
      );
    }

    final record = OotdRecord(
      date: widget.recordDate,
      imagePath: photoTimeline.isNotEmpty ? 'daily-photo-placeholder' : null,
      character: widget.userCharacter,
      moodTags: _hashtags,
      brands: {
        'recordType': 'daily',
        'mood': selectedMood,
        'weather': selectedWeather,
        'theme': themeLabel,
        'crew': _includeCrew ? 'included' : 'userOnly',
        if (widget.ootdRecord != null) 'linkedOotd': 'true',
      },
      weather: selectedWeather,
      mood: selectedMood,
      isPublic: false,
      timeline: [
        ...photoTimeline,
        TimelineItem(
          time: '오늘',
          placeName: '하루 일과',
          category: 'daily',
          description: memo.isEmpty ? '오늘의 소중한 순간을 기록했어요.' : memo,
        ),
      ],
    );

    setState(() {
      _savedRecord = record;
      _savedPhotoCount = photoTimeline.length;
      _currentStep = 7;
    });
  }

  Widget _buildStepIndicator() {
    final labels = ['사진', '해시태그', 'OOTD', '크루', '꾸미기', '완료'];
    final active = _currentStep == 0 ? 0 : (_currentStep - 1).clamp(0, 5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = active == index;
          final isDone = active > index;
          return Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryPink
                        : isDone
                        ? AppColors.primaryPinkSoft
                        : AppColors.bgPaper,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive || isDone
                          ? AppColors.primaryPink
                          : AppColors.lineSoft,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.sticker.copyWith(
                      color: isActive
                          ? AppColors.textInverse
                          : AppColors.textSub,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sticker.copyWith(
                    color: isActive ? AppColors.textMain : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: _currentStep == 7
            ? SizedBox()
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textMain,
                  size: 20,
                ),
                onPressed: _back,
              ),
        title: Text(
          '하루 일과 기록',
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_currentStep > 0 && _currentStep < 7) _buildStepIndicator(),
            Expanded(
              child: GridBackground(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: _buildContent(),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case 0:
        return _buildEntryPage();
      case 1:
        return _buildPhotoMemoPage();
      case 2:
        return _buildMoodWeatherPage();
      case 3:
        return _buildOotdPage();
      case 4:
        return _buildCrewPage();
      case 5:
        return _buildThemePage();
      case 6:
        return _buildCompletePage();
      case 7:
        final savedRecord = _savedRecord;
        if (savedRecord == null) return _buildCompletePage();
        return DailyRecordResultScreen(
          record: savedRecord,
          userCharacter: widget.userCharacter,
          ootdRecord: widget.ootdRecord,
          includeCrew: _includeCrew,
          photoCount: _savedPhotoCount,
        );
      default:
        return SizedBox();
    }
  }

  Widget _buildEntryPage() {
    return Column(
      children: [
        SizedBox(height: 12),
        const Icon(
          Icons.auto_stories_outlined,
          color: AppColors.primaryPink,
          size: 30,
        ),
        SizedBox(height: 10),
        Text(
          '오늘 하루를 한 장씩 남겨볼까요?',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _dateLabel(widget.recordDate),
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primaryPink,
          ),
        ),
        SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Column(
            children: [
              PixelCharacterWidget(character: widget.userCharacter, size: 112),
              SizedBox(height: 16),
              Text(
                '사진, 메모, 기분, 날씨, OOTD, 함께한 크루까지 차례대로 기록해요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSub,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoMemoPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('사진과 짧은 메모', '사진을 하나씩 추가하고, 각 사진마다 코멘트를 남겨주세요.'),
        ...List.generate(
          _photoMemos.length,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == _photoMemos.length - 1 ? 12 : 16,
            ),
            child: _buildPhotoMemoCard(index),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _addPhotoMemo,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text('사진 더 추가하기'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: AppColors.primaryPink,
            side: const BorderSide(color: AppColors.linePink),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodWeatherPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('오늘의 분위기', '하루 해시태그와 기분, 날씨를 골라주세요.'),
        Text('오늘 기분', style: _labelStyle),
        SizedBox(height: 8),
        _choiceGrid(
          _moods,
          _selectedMood,
          (index) => setState(() => _selectedMood = index),
        ),
        SizedBox(height: 20),
        Text('날씨', style: _labelStyle),
        SizedBox(height: 8),
        _choiceGrid(
          _weathers,
          _selectedWeather,
          (index) => setState(() => _selectedWeather = index),
        ),
        SizedBox(height: 20),
        Text('하루 해시태그', style: _labelStyle),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(hintText: '예: 카페투어, 생일파티'),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 92,
              child: ElevatedButton(
                onPressed: _addTag,
                child: const Text('추가', maxLines: 1, softWrap: false),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _hashtags
              .map(
                (tag) => Chip(
                  label: Text(tag, style: AppTextStyles.labelMedium),
                  backgroundColor: AppColors.primaryPinkSoft,
                  deleteIconColor: AppColors.primaryPink,
                  onDeleted: _hashtags.length == 1
                      ? null
                      : () => setState(() => _hashtags.remove(tag)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPhotoMemoCard(int index) {
    final photo = _photoMemos[index];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: photo.hasPhoto ? AppColors.primaryPink : AppColors.lineSoft,
          width: photo.hasPhoto ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMain.withValues(alpha: 0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryPinkSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '사진 ${index + 1}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
              ),
              if (_photoMemos.length > 1)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removePhotoMemo(index),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => photo.hasPhoto = !photo.hasPhoto),
            child: Container(
              width: double.infinity,
              height: 126,
              decoration: BoxDecoration(
                color: photo.hasPhoto
                    ? AppColors.primaryPinkSoft.withOpacity(0.52)
                    : AppColors.bgPaper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: photo.hasPhoto
                      ? AppColors.primaryPink
                      : AppColors.lineBrown,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    photo.hasPhoto
                        ? Icons.image_outlined
                        : Icons.add_a_photo_outlined,
                    color: photo.hasPhoto
                        ? AppColors.primaryPink
                        : AppColors.textMuted,
                    size: 11,
                  ),
                  SizedBox(height: 8),
                  Text(
                    photo.hasPhoto ? '사진 선택됨' : '사진 선택하기',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: photo.controller,
            maxLines: 2,
            maxLength: 120,
            decoration: InputDecoration(
              hintText: '사진 ${index + 1}에 대한 코멘트',
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOotdPage() {
    final ootd = widget.ootdRecord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('오늘의 OOTD', '같은 날짜에 남긴 코디 기록을 하루 일과 중간에 배치해요.'),
        if (ootd != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryPurple, width: 1.4),
            ),
            child: Column(
              children: [
                Text(
                  '기록된 OOTD를 찾았어요',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                SizedBox(height: 14),
                PixelCharacterWidget(character: ootd.character, size: 96),
                SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: ootd.moodTags
                      .take(4)
                      .map(
                        (tag) => Chip(
                          label: Text(tag, style: AppTextStyles.labelSmall),
                          backgroundColor: AppColors.primaryPurpleSoft,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgPaper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.checkroom_outlined,
                  size: 38,
                  color: AppColors.primaryPurple,
                ),
                SizedBox(height: 12),
                Text(
                  '이 날짜에는 OOTD 기록이 없어요',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '하루 기록에 코디도 함께 남길까요?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSub,
                  ),
                ),
                SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: widget.onCreateOotd,
                  icon: const Icon(Icons.add),
                  label: Text('OOTD 기록하러 가기'),
                ),
                SizedBox(height: 8),
                Text(
                  '건너뛰면 하루 일과만 저장됩니다.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCrewPage() {
    final crew = [
      widget.userCharacter.copyWith(hairColorIndex: 4, topStyleIndex: 1),
      widget.userCharacter.copyWith(hairColorIndex: 6, bottomStyleIndex: 2),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('함께한 크루', '약속에 함께 참여한 모임 크루 캐릭터를 같이 넣을지 선택해주세요.'),
        Row(
          children: [
            Expanded(child: _toggleCard('함께 넣기', Icons.groups_outlined, true)),
            SizedBox(width: 12),
            Expanded(child: _toggleCard('나만 넣기', Icons.person_outline, false)),
          ],
        ),
        SizedBox(height: 28),
        Center(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              PixelCharacterWidget(character: widget.userCharacter, size: 86),
              if (_includeCrew)
                ...crew.map(
                  (character) =>
                      PixelCharacterWidget(character: character, size: 76),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('기록 스타일', '다이어리 꾸미는 느낌과 깔끔한 느낌 중 하나를 골라주세요.'),
        _themeCard(
          index: 0,
          title: '다이어리 꾸미기',
          subtitle: '스티커, 색종이, 손글씨 느낌으로 아기자기하게 배치해요.',
          icon: Icons.interests_outlined,
          color: AppColors.primaryPink,
        ),
        SizedBox(height: 14),
        _themeCard(
          index: 1,
          title: '깔끔한 기록',
          subtitle: '사진과 텍스트가 또렷하게 보이도록 정돈된 레이아웃으로 남겨요.',
          icon: Icons.view_agenda_outlined,
          color: AppColors.primaryPurple,
        ),
        SizedBox(height: 20),
        TextField(
          controller: _dayMemoController,
          maxLines: 5,
          maxLength: 300,
          decoration: const InputDecoration(hintText: '오늘 하루를 마무리하는 메모를 적어주세요'),
        ),
      ],
    );
  }

  Widget _buildCompletePage() {
    final isDiary = _selectedTheme == 0;

    return Column(
      children: [
        SizedBox(height: 8),
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.accentGreen,
          size: 34,
        ),
        SizedBox(height: 10),
        Text(
          '하루 기록이 준비됐어요',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: 8),
        Text(
          isDiary ? '다이어리처럼 꾸며서 저장할게요.' : '깔끔한 기록으로 저장할게요.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDiary ? AppColors.bgPaper : AppColors.bgDefault,
            borderRadius: BorderRadius.circular(isDiary ? 16 : 10),
            border: Border.all(
              color: isDiary ? AppColors.lineBrown : AppColors.lineSoft,
              width: isDiary ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PixelCharacterWidget(
                    character: widget.userCharacter,
                    size: 78,
                  ),
                  if (_includeCrew) ...[
                    SizedBox(width: 10),
                    PixelCharacterWidget(
                      character: widget.userCharacter.copyWith(
                        hairColorIndex: 4,
                      ),
                      size: 66,
                    ),
                  ],
                ],
              ),
              SizedBox(height: 14),
              Text(
                '${_weathers[_selectedWeather].label} · ${_moods[_selectedMood].label}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textMain,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _hashtags
                    .map(
                      (tag) => Text(
                        tag,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryPink,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final label = _currentStep == 0
        ? '시작하기'
        : _currentStep == 7
        ? '홈으로 가기'
        : _currentStep == 6
        ? '저장하기'
        : '다음';

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.bgWarm,
      child: Row(
        children: [
          if (_currentStep > 0 && _currentStep < 7) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: _back,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgDefault,
                  foregroundColor: AppColors.textMain,
                  side: const BorderSide(color: AppColors.lineSoft),
                ),
                child: Text('이전'),
              ),
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: AppColors.textInverse,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.textMain),
          ),
          SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSub,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceGrid(
    List<_ChoiceData> choices,
    int selected,
    ValueChanged<int> onSelect,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: choices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.55,
      ),
      itemBuilder: (context, index) {
        final choice = choices[index];
        final isSelected = selected == index;
        return GestureDetector(
          onTap: () => onSelect(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? choice.color.withOpacity(0.16)
                  : AppColors.bgDefault,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? choice.color : AppColors.lineSoft,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(choice.icon, color: choice.color, size: 22),
                SizedBox(width: 8),
                Text(
                  choice.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toggleCard(String title, IconData icon, bool value) {
    final selected = _includeCrew == value;
    return GestureDetector(
      onTap: () => setState(() => _includeCrew = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryPink : AppColors.lineSoft,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primaryPink : AppColors.textMuted,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final selected = _selectedTheme == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.lineSoft,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSub,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} (${weekdays[date.weekday - 1]})';
  }

  static final _labelStyle = AppTextStyles.labelLarge.copyWith(
    color: AppColors.textSub,
  );
}

class _ChoiceData {
  final String label;
  final IconData icon;
  final Color color;

  const _ChoiceData(this.label, this.icon, this.color);
}

class _PhotoMemoDraft {
  bool hasPhoto = false;
  final TextEditingController controller = TextEditingController();

  void dispose() {
    controller.dispose();
  }
}

class DailyRecordResultScreen extends StatelessWidget {
  final OotdRecord record;
  final CharacterDraft userCharacter;
  final OotdRecord? ootdRecord;
  final bool includeCrew;
  final int photoCount;

  const DailyRecordResultScreen({
    super.key,
    required this.record,
    required this.userCharacter,
    required this.includeCrew,
    required this.photoCount,
    this.ootdRecord,
  });

  static final _backgrounds = [
    'assets/images/diary_decorate/background/IMG_1911.PNG',
    'assets/images/diary_decorate/background/IMG_1964.PNG',
    'assets/images/diary_decorate/background/IMG_1966.PNG',
    'assets/images/diary_decorate/background/IMG_1967.PNG',
    'assets/images/diary_decorate/background/IMG_1968.PNG',
    'assets/images/diary_decorate/background/IMG_1969.PNG',
    'assets/images/diary_decorate/background/IMG_1970.PNG',
    'assets/images/diary_decorate/background/IMG_1971.PNG',
  ];

  static final _clips = [
    'assets/images/diary_decorate/clip/IMG_1974.PNG',
    'assets/images/diary_decorate/clip/IMG_1975.PNG',
    'assets/images/diary_decorate/clip/IMG_1976.PNG',
    'assets/images/diary_decorate/clip/IMG_1977.PNG',
    'assets/images/diary_decorate/clip/IMG_1978.PNG',
  ];

  static final _tapes = [
    'assets/images/diary_decorate/masking_tape/IMG_1914.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1917.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1923.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1931.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1942.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1952.PNG',
  ];

  static final _scratchPapers = [
    'assets/images/diary_decorate/scratch_paper/IMG_1959.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1960.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1961.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1979.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1981.PNG',
  ];

  static final _stamps = [
    'assets/images/diary_decorate/stamp/IMG_1987.PNG',
    'assets/images/diary_decorate/stamp/IMG_1988.PNG',
    'assets/images/diary_decorate/stamp/IMG_1990.PNG',
    'assets/images/diary_decorate/stamp/row-1-column-1.png',
    'assets/images/diary_decorate/stamp/row-2-column-3.png',
    'assets/images/diary_decorate/stamp/row-5-column-5.png',
    'assets/images/diary_decorate/stamp/row-8-column-4.png',
  ];

  @override
  Widget build(BuildContext context) {
    final isDiary = record.brands['theme'] == 'diary';
    final photoItems = record.timeline
        .where((item) => item.category == 'photo')
        .toList(growable: false);
    final dailyItems = record.timeline
        .where((item) => item.category == 'daily')
        .toList(growable: false);
    final dailyMemo = dailyItems.isEmpty ? null : dailyItems.first.description;

    return isDiary
        ? _buildDiaryResult(context, photoItems, dailyMemo)
        : _buildCleanResult(context, photoItems, dailyMemo);
  }

  Widget _buildDiaryResult(
    BuildContext context,
    List<TimelineItem> photoItems,
    String? dailyMemo,
  ) {
    final middlePhotoIndex = photoItems.length > 1
        ? photoItems.length ~/ 2
        : -1;

    return Column(
      children: [
        _DiaryHeader(record: record),
        SizedBox(height: 20),
        if (photoItems.isEmpty)
          _DiaryEmptyPhotoCard(memo: dailyMemo)
        else
          ...photoItems.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == photoItems.length - 1 ? 4 : 22,
              ),
              child: _DiaryPhotoSpread(
                index: entry.key,
                item: entry.value,
                useBackground: entry.key == middlePhotoIndex,
                backgroundAsset: _pick(_backgrounds, entry.key),
                clipAsset: _pick(_clips, entry.key + record.date.day),
                tapeAsset: _pick(_tapes, entry.key + record.date.month),
                scratchAsset: _pick(
                  _scratchPapers,
                  entry.key + record.date.year,
                ),
                stampAsset: _pick(_stamps, entry.key + record.date.day),
              ),
            ),
          ),
        if (ootdRecord != null) ...[
          SizedBox(height: 14),
          _DiaryOotdBlock(ootdRecord: ootdRecord!),
        ],
        SizedBox(height: 18),
        _DiaryPeopleMoodBlock(
          record: record,
          userCharacter: userCharacter,
          includeCrew: includeCrew,
        ),
        SizedBox(height: 18),
        _DiaryMemoFooter(
          memo: dailyMemo ?? '오늘의 소중한 순간을 기록했어요.',
          stampAsset: _pick(_stamps, record.date.day + photoItems.length),
        ),
      ],
    );
  }

  Widget _buildCleanResult(
    BuildContext context,
    List<TimelineItem> photoItems,
    String? dailyMemo,
  ) {
    final photoCount = photoItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dailyMemo ?? '오늘의 소중한 순간을 기록했어요.',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textMain,
            height: 1.25,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: record.moodTags
              .map(
                (tag) => Chip(
                  label: Text(tag),
                  backgroundColor: AppColors.bgPurpleSoft,
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
        SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgWarm,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: _ResultMetaRow(
            mood: record.mood,
            weather: record.weather,
            photoCount: photoCount,
          ),
        ),
        SizedBox(height: 22),
        if (photoItems.isNotEmpty) ...[
          Text(
            '사진 기록',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
          ),
          SizedBox(height: 12),
          ...photoItems.asMap().entries.map(
            (entry) => _CleanPhotoCard(index: entry.key, item: entry.value),
          ),
        ],
        if (ootdRecord != null) ...[
          SizedBox(height: 20),
          Text(
            '오늘의 OOTD',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
          ),
          SizedBox(height: 12),
          _CleanOotdBlock(ootdRecord: ootdRecord!),
        ],
        SizedBox(height: 20),
        _CleanPeopleBlock(
          userCharacter: userCharacter,
          includeCrew: includeCrew,
        ),
      ],
    );
  }

  static String _pick(List<String> assets, int seed) {
    return assets[Random(seed).nextInt(assets.length)];
  }
}

class _DiaryHeader extends StatelessWidget {
  final OotdRecord record;

  const _DiaryHeader({required this.record});

  @override
  Widget build(BuildContext context) {
    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Column(
      children: [
        Text(
          '${record.date.year}.${record.date.month.toString().padLeft(2, '0')}.${record.date.day.toString().padLeft(2, '0')} (${weekdays[record.date.weekday - 1]})',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 4),
        Text(
          '하루 일과 기록',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: record.moodTags
              .map(
                (tag) => Text(
                  tag,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSub,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _DiaryAssetImage extends StatelessWidget {
  final String asset;
  final double? width;
  final BoxFit? fit;
  final Widget fallback;

  const _DiaryAssetImage({
    required this.asset,
    required this.fallback,
    this.width,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _DiaryPhotoSpread extends StatelessWidget {
  final int index;
  final TimelineItem item;
  final bool useBackground;
  final String backgroundAsset;
  final String clipAsset;
  final String tapeAsset;
  final String scratchAsset;
  final String stampAsset;

  const _DiaryPhotoSpread({
    required this.index,
    required this.item,
    required this.useBackground,
    required this.backgroundAsset,
    required this.clipAsset,
    required this.tapeAsset,
    required this.scratchAsset,
    required this.stampAsset,
  });

  @override
  Widget build(BuildContext context) {
    final photoFirst = index.isEven;
    final photo = Expanded(
      flex: 6,
      child: _DecoratedDiaryPhoto(
        index: index,
        useBackground: useBackground,
        backgroundAsset: backgroundAsset,
        clipAsset: clipAsset,
        tapeAsset: tapeAsset,
        stampAsset: stampAsset,
      ),
    );
    final memo = Expanded(
      flex: 5,
      child: _DiaryPhotoMemo(
        index: index,
        text: item.description,
        useScratchPaper: !useBackground,
        scratchAsset: scratchAsset,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: photoFirst
          ? [photo, SizedBox(width: 12), memo]
          : [memo, SizedBox(width: 12), photo],
    );
  }
}

class _DecoratedDiaryPhoto extends StatelessWidget {
  final int index;
  final bool useBackground;
  final String backgroundAsset;
  final String clipAsset;
  final String tapeAsset;
  final String stampAsset;

  const _DecoratedDiaryPhoto({
    required this.index,
    required this.useBackground,
    required this.backgroundAsset,
    required this.clipAsset,
    required this.tapeAsset,
    required this.stampAsset,
  });

  @override
  Widget build(BuildContext context) {
    final decorationMode = index % 3;
    return SizedBox(
      height: 188,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (useBackground)
            Positioned(
              left: -14,
              right: -8,
              top: -12,
              bottom: -10,
              child: Transform.rotate(
                angle: index.isEven ? -0.05 : 0.05,
                child: _DiaryAssetImage(
                  asset: backgroundAsset,
                  fit: BoxFit.cover,
                  fallback: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurpleSoft.withOpacity(0.34),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: Transform.rotate(
              angle: index.isEven ? -0.035 : 0.035,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.lineSoft),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textMain.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? AppColors.photoFrameRoseMutedBg
                        : AppColors.photoFrameGreenMutedBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.photo,
                    color: AppColors.textSub.withOpacity(0.42),
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
          if (decorationMode == 0 && !useBackground)
            Positioned(
              top: -12,
              left: 34,
              child: _DiaryAssetImage(
                asset: clipAsset,
                width: 14,
                fallback: const Icon(
                  Icons.attach_file,
                  color: AppColors.primaryPink,
                  size: 11,
                ),
              ),
            ),
          if (decorationMode == 1 || useBackground) ...[
            Positioned(
              top: -10,
              left: -8,
              child: Transform.rotate(
                angle: -0.18,
                child: _DiaryAssetImage(
                  asset: tapeAsset,
                  width: 76,
                  fallback: Container(
                    width: 76,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.34),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -8,
              bottom: 2,
              child: Transform.rotate(
                angle: 0.18,
                child: _DiaryAssetImage(
                  asset: tapeAsset,
                  width: 62,
                  fallback: Container(
                    width: 62,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.34),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (decorationMode == 2 && !useBackground)
            Positioned(
              right: -10,
              bottom: -8,
              child: _DiaryAssetImage(
                asset: stampAsset,
                width: 42,
                fallback: const Icon(
                  Icons.favorite,
                  color: AppColors.primaryPink,
                  size: 34,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiaryPhotoMemo extends StatelessWidget {
  final int index;
  final String text;
  final bool useScratchPaper;
  final String scratchAsset;

  const _DiaryPhotoMemo({
    required this.index,
    required this.text,
    required this.useScratchPaper,
    required this.scratchAsset,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PHOTO ${index + 1}',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.accentBrown,
          ),
        ),
        SizedBox(height: 8),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMain,
            height: 1.45,
          ),
        ),
      ],
    );

    if (!useScratchPaper) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgDefault.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: content,
      );
    }

    return SizedBox(
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _DiaryAssetImage(
            asset: scratchAsset,
            fit: BoxFit.fill,
            fallback: Container(
              decoration: BoxDecoration(
                color: AppColors.bgPaper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lineSoft),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(18), child: content),
        ],
      ),
    );
  }
}

class _DiaryOotdBlock extends StatelessWidget {
  final OotdRecord ootdRecord;

  const _DiaryOotdBlock({required this.ootdRecord});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineBrown),
      ),
      child: Row(
        children: [
          PixelCharacterWidget(character: ootdRecord.character, size: 80),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY OOTD',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryPurple,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  ootdRecord.moodTags.take(4).join(' '),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSub,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryPeopleMoodBlock extends StatelessWidget {
  final OotdRecord record;
  final CharacterDraft userCharacter;
  final bool includeCrew;

  const _DiaryPeopleMoodBlock({
    required this.record,
    required this.userCharacter,
    required this.includeCrew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: _diaryMeta(
              'WITH',
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PixelCharacterWidget(character: userCharacter, size: 42),
                  if (includeCrew) ...[
                    SizedBox(width: 6),
                    PixelCharacterWidget(
                      character: userCharacter.copyWith(hairColorIndex: 4),
                      size: 38,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: _diaryMeta(
              'MOOD',
              Text(
                record.mood,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textMain,
                ),
              ),
            ),
          ),
          Expanded(
            child: _diaryMeta(
              'WEATHER',
              Text(
                record.weather,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textMain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _diaryMeta(String label, Widget child) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.sticker.copyWith(color: AppColors.textMuted),
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DiaryMemoFooter extends StatelessWidget {
  final String memo;
  final String stampAsset;

  const _DiaryMemoFooter({required this.memo, required this.stampAsset});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Text(
            memo,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSub,
              height: 1.45,
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: -20,
          child: _DiaryAssetImage(
            asset: stampAsset,
            width: 46,
            fallback: const Icon(
              Icons.auto_awesome,
              color: AppColors.accentOrange,
              size: 38,
            ),
          ),
        ),
      ],
    );
  }
}

class _DiaryEmptyPhotoCard extends StatelessWidget {
  final String? memo;

  const _DiaryEmptyPhotoCard({this.memo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Text(
        memo ?? '사진 없이 오늘 하루의 메모만 남겼어요.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSub,
          height: 1.45,
        ),
      ),
    );
  }
}

class _CleanPhotoCard extends StatelessWidget {
  final int index;
  final TimelineItem item;

  const _CleanPhotoCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMain.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: index.isEven
                  ? AppColors.primaryPinkSoft
                  : AppColors.primaryPurpleSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.photo_outlined, color: AppColors.textSub),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  item.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSub,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanOotdBlock extends StatelessWidget {
  final OotdRecord ootdRecord;

  const _CleanOotdBlock({required this.ootdRecord});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPurpleSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          PixelCharacterWidget(character: ootdRecord.character, size: 62),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              ootdRecord.moodTags.take(4).join(' '),
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textMain,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanPeopleBlock extends StatelessWidget {
  final CharacterDraft userCharacter;
  final bool includeCrew;

  const _CleanPeopleBlock({
    required this.userCharacter,
    required this.includeCrew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        children: [
          PixelCharacterWidget(character: userCharacter, size: 58),
          if (includeCrew) ...[
            SizedBox(width: 10),
            PixelCharacterWidget(
              character: userCharacter.copyWith(hairColorIndex: 4),
              size: 52,
            ),
            SizedBox(width: 8),
            PixelCharacterWidget(
              character: userCharacter.copyWith(hairColorIndex: 6),
              size: 52,
            ),
          ],
          SizedBox(width: 14),
          Expanded(
            child: Text(
              '함께한 캐릭터를 포함해 하루 기록을 정리했어요.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSub,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetaRow extends StatelessWidget {
  final String mood;
  final String weather;
  final int photoCount;

  const _ResultMetaRow({
    required this.mood,
    required this.weather,
    required this.photoCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _meta('MOOD', mood, Icons.sentiment_satisfied_alt)),
        Expanded(child: _meta('WEATHER', weather, Icons.wb_sunny_outlined)),
        Expanded(
          child: _meta('PHOTO', '$photoCount장', Icons.photo_library_outlined),
        ),
      ],
    );
  }

  Widget _meta(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryPink, size: 18),
        SizedBox(height: 5),
        Text(
          label,
          style: AppTextStyles.tiny.copyWith(color: AppColors.textMuted),
        ),
        SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMain),
        ),
      ],
    );
  }
}
