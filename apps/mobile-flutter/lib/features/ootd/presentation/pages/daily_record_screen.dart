import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../../../shared/widgets/pixel_character.dart';
import '../widgets/record_flow_navigation.dart';

String _dateLabel(DateTime date) {
  final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} (${weekdays[date.weekday - 1]})';
}

const int _photoCommentMaxLength = 25;

String _limitedPhotoComment(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= _photoCommentMaxLength) return trimmed;
  return trimmed.substring(0, _photoCommentMaxLength);
}

class DailyRecordScreen extends StatefulWidget {
  final CharacterDraft userCharacter;
  final DateTime recordDate;
  final OotdRecord? ootdRecord;
  final Future<OotdRecord> Function(OotdRecord) onSave;
  final Future<String> Function(Uint8List bytes, String fileName) onUploadMedia;
  final Future<OotdRecord?> Function() onCreateOotd;

  const DailyRecordScreen({
    super.key,
    required this.userCharacter,
    required this.recordDate,
    required this.onSave,
    required this.onUploadMedia,
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
  bool _isSaving = false;
  OotdRecord? _linkedOotdRecord;
  OotdRecord? _savedRecord;
  int _savedPhotoCount = 0;

  final _dayMemoController = TextEditingController();
  final _tagController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<_PhotoMemoDraft> _photoMemos = [_PhotoMemoDraft()];
  final List<String> _hashtags = ['#하루기록'];

  final _moods = const [
    _ChoiceData('행복', Icons.sentiment_very_satisfied, AppColors.primaryPink),
    _ChoiceData('평온', Icons.air, AppColors.accentGreen),
    _ChoiceData('신남', Icons.celebration, AppColors.accentOrange),
    _ChoiceData('피곤', Icons.mode_night, AppColors.primaryPurple),
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
    _linkedOotdRecord = widget.ootdRecord;
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
          if (r.imageUrls.length > _photoMemos.length) {
            draft.originalUrl = r.imageUrls[_photoMemos.length];
          }
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
    if (_isSaving) return;
    if (_currentStep == 7) {
      _closeResult();
      return;
    }
    if (_currentStep == 6) {
      _save();
      return;
    }
    if (_currentStep == 3 && _linkedOotdRecord == null) {
      setState(() {
        _includeCrew = false;
        _currentStep = 5;
      });
      return;
    }
    setState(() => _currentStep++);
  }

  void _back() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep == 0) {
      context.popOrGo(RoutePaths.records);
      return;
    }
    if (_currentStep == 5 && _linkedOotdRecord == null) {
      setState(() => _currentStep = 3);
      return;
    }
    setState(() => _currentStep--);
  }

  Future<void> _closeResult() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    context.popOrGo(RoutePaths.records, result: _savedRecord);
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
    if (_photoMemos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('??彛?? 筌ㅼ뮆? 5?觀?댐쭪? ?곕떽???????됰선??')),
      );
      return;
    }
    setState(() => _photoMemos.add(_PhotoMemoDraft()));
  }

  void _removePhotoMemo(int index) {
    if (_photoMemos.length == 1) return;
    setState(() {
      final removed = _photoMemos.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickPhoto(int index) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 960,
      maxHeight: 960,
      imageQuality: 65,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 900 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('???筌왖揶쎛 ?袁⑹춦 ?뚣끉?? 1MB ??꾨릭 ??彛??곗쨮 ??쇰뻻 ?醫뤾문??雅뚯눘苑??')),
      );
      return;
    }
    final fileName = picked.name.toLowerCase();
    final allowed =
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.webp');
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('jpg, png, webp ???筌왖筌??醫뤾문??????됰선??')),
      );
      return;
    }
    setState(() {
      _photoMemos[index].imageBytes = bytes;
      _photoMemos[index].fileName = picked.name;
      _photoMemos[index].originalUrl = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final selectedMood = _moods[_selectedMood].label;
    final selectedWeather = _weathers[_selectedWeather].label;
    final memo = _dayMemoController.text.trim();
    final themeLabel = _selectedTheme == 0 ? 'diary' : 'clean';
    final uploadedUrls = <String>[];

    final record = OotdRecord(
      date: widget.recordDate,
      imagePath: null,
      character: widget.userCharacter,
      moodTags: _hashtags,
      brands: {
        'recordType': 'daily',
        'mood': selectedMood,
        'weather': selectedWeather,
        'theme': themeLabel,
        'crew': _includeCrew ? 'included' : 'userOnly',
        if (_linkedOotdRecord != null) 'linkedOotd': 'true',
      },
      weather: selectedWeather,
      mood: selectedMood,
      isPublic: false,
      timeline: const [],
    );

    setState(() => _isSaving = true);
    try {
      final photoTimeline = <TimelineItem>[];
      var hasPhotoUploadFailure = false;
      for (var i = 0; i < _photoMemos.length; i++) {
        final photo = _photoMemos[i];
        if (!photo.hasPhoto && photo.controller.text.trim().isEmpty) continue;
        String? imageUrl;
        if (photo.imageBytes != null) {
          try {
            imageUrl = await widget.onUploadMedia(
              photo.imageBytes!,
              photo.fileName ?? 'daily-record.jpg',
            );
          } catch (error) {
            hasPhotoUploadFailure = true;
            debugPrint('Daily record photo upload failed: $error');
          }
        } else if (photo.originalUrl != null) {
          imageUrl = photo.originalUrl!;
        }
        if (imageUrl != null) {
          uploadedUrls.add(imageUrl);
        }
        photoTimeline.add(
          TimelineItem(
            time: '사진 ',
            placeName: imageUrl == null ? '사진 없음' : '추가한 사진',
            category: 'photo',
            description: _limitedPhotoComment(photo.controller.text).isEmpty
                ? '사진에 대한 코멘트를 남기지 않았어요.'
                : _limitedPhotoComment(photo.controller.text),
            imageUrl: imageUrl,
          ),
        );
      }
      final timelineWithImages = [
        ...photoTimeline,
        TimelineItem(
          time: '메모',
          placeName: '하루 일과',
          category: 'daily',
          description: memo.isEmpty ? '오늘의 소중한 순간을 기록했어요.' : memo,
        ),
      ];
      final recordWithImages = record.copyWith(
        imagePath: uploadedUrls.isEmpty ? null : uploadedUrls.first,
        imageUrls: uploadedUrls,
        timeline: timelineWithImages,
      );
      final saved = await widget.onSave(recordWithImages);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _savedRecord = saved;
        _savedPhotoCount = photoTimeline.length;
        _currentStep = 7;
      });
      if (hasPhotoUploadFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진 일부를 업로드하지 못했지만 기록은 저장했어요.'),
          ),
        );
      }
      return;
    } catch (error) {
      debugPrint('Daily record save failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록을 저장하지 못했어요. 다시 시도해 주세요.')) ,
        );
      }
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  Widget _buildStepIndicator() {
    final labels = ['사진', '기분/날씨', 'OOTD', '크루', '테마', '완료'];
    final active = _currentStep == 0 ? 0 : (_currentStep - 1).clamp(0, 5);

    return RecordFlowStepIndicator(labels: labels, activeIndex: active);
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
            ? const SizedBox()
            : RecordFlowExitButton(
                onPressed: () => context.popOrGo(RoutePaths.records),
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
          ootdRecord: _linkedOotdRecord,
          includeCrew: _includeCrew,
          photoCount: _savedPhotoCount,
          onEdit: () {
            final id = savedRecord.id;
            if (id == null || id.isEmpty) return;
            context.go(RoutePaths.recordEdit(id));
          },
        );
      default:
        return SizedBox();
    }
  }

  Widget _buildEntryPage() {
    return RecordEntryIntro(
      character: widget.userCharacter,
      title: '오늘 하루 기록하기',
      subtitle: '\n하루를 한 장씩 남겨볼까요?',
      bannerText: '사진, 메모, 기분, 날씨, OOTD,\n함께한 크루까지 차례대로 기록해요.',
      topLeftIcon: Icons.auto_stories_outlined,
      topLeftColor: AppColors.primaryPink,
      bottomRightIcon: Icons.edit_note_outlined,
      bottomRightColor: AppColors.textMuted,
    );
  }

  Widget _buildPhotoMemoPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('사진과 코멘트', '사진을 추가하고 사진마다 짧은 코멘트를 남겨보세요.'),
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
          label: Text('사진 추가하기'),
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
        _sectionTitle('오늘의 기분과 날씨', '하루의 분위기와 날씨를 기록해 보세요.'),
        Text('오늘의 기분', style: _labelStyle),
        SizedBox(height: 8),
        _choiceGrid(
          _moods,
          _selectedMood,
          (index) => setState(() => _selectedMood = index),
        ),
        SizedBox(height: 20),
        Text('오늘의 날씨', style: _labelStyle),
        SizedBox(height: 8),
        _choiceGrid(
          _weathers,
          _selectedWeather,
          (index) => setState(() => _selectedWeather = index),
        ),
        SizedBox(height: 20),
        Text('하루 태그', style: _labelStyle),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(hintText: '# 카페 #산책 #기록'),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 92,
              child: ElevatedButton(
                onPressed: _addTag,
                child: const Text('?곕떽?', maxLines: 1, softWrap: false),
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
                  '??彛?${index + 1}',
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
            onTap: () => _pickPhoto(index),
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
              child: photo.imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        photo.imageBytes!,
                        width: double.infinity,
                        height: 126,
                        fit: BoxFit.cover,
                      ),
                    )
                  : photo.originalUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        photo.originalUrl!,
                        width: double.infinity,
                        height: 126,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
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
            maxLength: _photoCommentMaxLength,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            decoration: InputDecoration(
              hintText: '사진 에 대한 코멘트',
              counterStyle: AppTextStyles.tiny.copyWith(
                color: AppColors.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOotdPage() {
    final ootd = _linkedOotdRecord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('??삳뮎??OOTD', '揶쏆늿? ?醫롮?????ｋ┸ ?꾨뗀逾?疫꿸퀡以????롳펷 ??⑤궢 餓λ쵌而??獄쏄퀣???곸뒄.'),
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
                  '疫꿸퀡以??OOTD??筌≪뼚釉??곸뒄',
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
                  '건너뛰면 하루 일과만 저장됩니다.',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '??롳펷 疫꿸퀡以???꾨뗀逾????ｍ뜞 ??ｋ쭔繹먮슣??',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSub,
                  ),
                ),
                SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final saved = await widget.onCreateOotd();
                    if (!mounted || saved == null) return;
                    setState(() {
                      _linkedOotdRecord = saved;
                      _includeCrew = true;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text('OOTD 기록하고 돌아오기'),
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
        _sectionTitle('함께한 크루', '오늘을 함께한 크루를 선택해 주세요.'),
        Row(
          children: [
            Expanded(child: _toggleCard('크루와 함께', Icons.groups_outlined, true)),
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
        _sectionTitle('기록 스타일', '다이어리처럼 꾸미거나 깔끔한 카드로 남겨보세요.'),
        _themeCard(
          index: 0,
          title: '다이어리 형식',
          subtitle: '사진과 스티커가 어우러진 감성적인 스크랩북 스타일로 저장해요.',
          icon: Icons.interests_outlined,
          color: AppColors.primaryPink,
        ),
        SizedBox(height: 14),
        _themeCard(
          index: 1,
          title: '클린 형식',
          subtitle: '사진과 메모를 깔끔하게 정리한 카드 스타일로 저장해요.',
          icon: Icons.view_agenda_outlined,
          color: AppColors.primaryPurple,
        ),
        SizedBox(height: 20),
        TextField(
          controller: _dayMemoController,
          maxLines: 5,
          maxLength: 300,
          decoration: const InputDecoration(hintText: '오늘 하루를 자유롭게 적어보세요.'),
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
          '??롳펷 疫꿸퀡以??餓Β??쑬由??곸뒄',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: 8),
        Text(
          isDiary ? '??쇱뵠???곻㎗?롮쓥 熬곷챶흭?????館釉룟칰??뒄.' : '繹먮뗀嫄??疫꿸퀡以??곗쨮 ???館釉룟칰??뒄.',
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
              if (widget.ootdRecord != null) ...[
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
              ],
              Text(
                '${_weathers[_selectedWeather].label} 夷?${_moods[_selectedMood].label}',
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
    if (_currentStep == 7) {
      final saved = _savedRecord;
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.bgWarm,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: saved?.id == null
                    ? null
                    : () => context.go(RoutePaths.recordEdit(saved!.id!)),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const FittedBox(child: Text('수정하기')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPinkSoft,
                  foregroundColor: AppColors.primaryPink,
                  side: const BorderSide(color: AppColors.linePink),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _closeResult,
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const FittedBox(child: Text('기록으로 가기')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: AppColors.textInverse,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final label = _currentStep == 0
        ? '시작하기'
        : _currentStep == 6
        ? '저장하기'
        : '다음';

    return RecordFlowBottomBar(
      primaryLabel: label,
      onPrimaryPressed: _next,
      onBackPressed: _back,
      showBackButton: _currentStep > 0 && _currentStep < 7,
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
  Uint8List? imageBytes;
  String? fileName;
  String? originalUrl;
  final TextEditingController controller = TextEditingController();

  bool get hasPhoto => imageBytes != null || originalUrl != null;

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
  final VoidCallback onEdit;

  const DailyRecordResultScreen({
    super.key,
    required this.record,
    required this.userCharacter,
    required this.includeCrew,
    required this.photoCount,
    required this.onEdit,
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
    'assets/images/diary_decorate/background/IMG_1972.PNG',
    'assets/images/diary_decorate/background/IMG_1973.PNG',
    'assets/images/diary_decorate/background/IMG_1985.PNG',
    'assets/images/diary_decorate/background/IMG_1986.PNG',
  ];

  static final _scratchPapers = [
    'assets/images/diary_decorate/scratch_paper/1.png',
    'assets/images/diary_decorate/scratch_paper/2.png',
    'assets/images/diary_decorate/scratch_paper/3.png',
    'assets/images/diary_decorate/scratch_paper/4.png',
    'assets/images/diary_decorate/scratch_paper/IMG_1959.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1960.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1961.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1962.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1964.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1979.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1982.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1983.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1984.PNG',
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
    'assets/images/diary_decorate/masking_tape/IMG_1915.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1916.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1917.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1918.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1919.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1920.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1921.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1923.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1924.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1925.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1926.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1927.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1928.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1929.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1930.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1931.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1932.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1933.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1934.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1935.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1936.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1937.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1938.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1939.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1940.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1942.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1943.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1944.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1945.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1946.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1947.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1948.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1949.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1950.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1951.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1952.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1953.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1954.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1955.PNG',
  ];

  static final _stamps = [
    'assets/images/diary_decorate/stamp/IMG_1987.PNG',
    'assets/images/diary_decorate/stamp/IMG_1988.PNG',
    'assets/images/diary_decorate/stamp/IMG_1989.PNG',
    'assets/images/diary_decorate/stamp/IMG_1990.PNG',
    'assets/images/diary_decorate/stamp/IMG_1991.PNG',
    'assets/images/diary_decorate/stamp/IMG_1992.PNG',
    'assets/images/diary_decorate/stamp/IMG_1993.PNG',
    'assets/images/diary_decorate/stamp/IMG_1994.PNG',
    'assets/images/diary_decorate/stamp/IMG_1995.PNG',
    'assets/images/diary_decorate/stamp/IMG_1996.PNG',
    'assets/images/diary_decorate/stamp/IMG_1997.PNG',
    'assets/images/diary_decorate/stamp/IMG_1998.PNG',
    'assets/images/diary_decorate/stamp/IMG_1999.PNG',
  ];


  static final _stickers = [
    'assets/images/diary_decorate/sticker/camera_1.png',
    'assets/images/diary_decorate/sticker/camera_2.png',
    'assets/images/diary_decorate/sticker/coffee_1.png',
    'assets/images/diary_decorate/sticker/coffee_2.png',
    'assets/images/diary_decorate/sticker/coffee_3.png',
    'assets/images/diary_decorate/sticker/deco_1.png',
    'assets/images/diary_decorate/sticker/deco_2.png',
    'assets/images/diary_decorate/sticker/deco_3.png',
    'assets/images/diary_decorate/sticker/deco_4.png',
    'assets/images/diary_decorate/sticker/deco_5.png',
    'assets/images/diary_decorate/sticker/deco_6.png',
    'assets/images/diary_decorate/sticker/deco_7.png',
    'assets/images/diary_decorate/sticker/envelope_1.png',
    'assets/images/diary_decorate/sticker/envelope_2.png',
    'assets/images/diary_decorate/sticker/envelope_3.png',
    'assets/images/diary_decorate/sticker/envelope_4.png',
    'assets/images/diary_decorate/sticker/flower_1.png',
    'assets/images/diary_decorate/sticker/flower_2.png',
    'assets/images/diary_decorate/sticker/flower_3.png',
    'assets/images/diary_decorate/sticker/flower_4.png',
    'assets/images/diary_decorate/sticker/flower_5.png',
    'assets/images/diary_decorate/sticker/flower_6.png',
    'assets/images/diary_decorate/sticker/flower_7.png',
    'assets/images/diary_decorate/sticker/flower_8.png',
    'assets/images/diary_decorate/sticker/flower_9.png',
    'assets/images/diary_decorate/sticker/heart_1.png',
    'assets/images/diary_decorate/sticker/heart_2.png',
    'assets/images/diary_decorate/sticker/heart_3.png',
    'assets/images/diary_decorate/sticker/heart_4.png',
    'assets/images/diary_decorate/sticker/music note_1.png',
    'assets/images/diary_decorate/sticker/music note_2.png',
    'assets/images/diary_decorate/sticker/music note_3.png',
    'assets/images/diary_decorate/sticker/pin_1.png',
    'assets/images/diary_decorate/sticker/pin_2.png',
    'assets/images/diary_decorate/sticker/pin_3.png',
    'assets/images/diary_decorate/sticker/pin_4.png',
    'assets/images/diary_decorate/sticker/pin_5.png',
    'assets/images/diary_decorate/sticker/postal sticker_1.png',
    'assets/images/diary_decorate/sticker/postal sticker_2.png',
    'assets/images/diary_decorate/sticker/postal sticker_3.png',
    'assets/images/diary_decorate/sticker/postal sticker_4.png',
    'assets/images/diary_decorate/sticker/ribbon_1.png',
    'assets/images/diary_decorate/sticker/ribbon_2.png',
    'assets/images/diary_decorate/sticker/ribbon_3.png',
    'assets/images/diary_decorate/sticker/ribbon_4.png',
    'assets/images/diary_decorate/sticker/snack_1.png',
    'assets/images/diary_decorate/sticker/snack_2.png',
    'assets/images/diary_decorate/sticker/snack_3.png',
    'assets/images/diary_decorate/sticker/snack_4.png',
    'assets/images/diary_decorate/sticker/snack_5.png',
    'assets/images/diary_decorate/sticker/snack_7.png',
    'assets/images/diary_decorate/sticker/snack_8.png',
    'assets/images/diary_decorate/sticker/snack_9.png',
    'assets/images/diary_decorate/sticker/snack_10.png',
    'assets/images/diary_decorate/sticker/snack_11.png',
    'assets/images/diary_decorate/sticker/snack_12.png',
    'assets/images/diary_decorate/sticker/snack_13.png',
    'assets/images/diary_decorate/sticker/snack_14.png',
    'assets/images/diary_decorate/sticker/sparkle_1.png',
    'assets/images/diary_decorate/sticker/sparkle_2.png',
    'assets/images/diary_decorate/sticker/sparkle_3.png',
    'assets/images/diary_decorate/sticker/sparkle_4.png',
    'assets/images/diary_decorate/sticker/sparkle_5.png',
    'assets/images/diary_decorate/sticker/star_1.png',
    'assets/images/diary_decorate/sticker/star_2.png',
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
    final hasMappedPhotoUrls = photoItems.any((item) => item.imageUrl != null);
    final limitedPhotoItems = photoItems.take(5).toList(growable: false);
    final imageUrls = limitedPhotoItems.asMap().entries.map((entry) {
      return entry.value.imageUrl ??
          (!hasMappedPhotoUrls && entry.key < record.imageUrls.length
              ? record.imageUrls[entry.key]
              : null);
    }).toList(growable: false);

    return _DiaryResultLayout(
      record: record,
      photoItems: limitedPhotoItems,
      imageUrls: imageUrls,
      dailyMemo: dailyMemo ?? '??삳뮎?????㉦????볦퍢??疫꿸퀡以??됰선??',
      includeCrew: includeCrew,
      userCharacter: userCharacter,
      backgrounds: _backgrounds,
      scratchPapers: _scratchPapers,
      clips: _clips,
      tapes: _tapes,
      stamps: _stamps,
      stickers: _stickers,
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
          _dateLabel(record.date),
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
        SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Text(
            dailyMemo ?? '??삳뮎?????㉦????볦퍢??疫꿸퀡以??됰선??',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMain,
              height: 1.45,
            ),
          ),
        ),
        if (ootdRecord != null) ...[
          SizedBox(height: 20),
          Text(
            '??삳뮎??OOTD',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
          ),
          SizedBox(height: 12),
          _CleanOotdBlock(ootdRecord: ootdRecord!),
        ],
        if (ootdRecord != null) ...[
          SizedBox(height: 20),
          _CleanPeopleBlock(
            userCharacter: userCharacter,
            includeCrew: includeCrew,
          ),
        ],
      ],
    );
  }

}



class _DiaryResultLayout extends StatelessWidget {
  final OotdRecord record;
  final List<TimelineItem> photoItems;
  final List<String?> imageUrls;
  final String dailyMemo;
  final bool includeCrew;
  final CharacterDraft userCharacter;
  final List<String> backgrounds;
  final List<String> scratchPapers;
  final List<String> clips;
  final List<String> tapes;
  final List<String> stamps;
  final List<String> stickers;

  const _DiaryResultLayout({
    required this.record,
    required this.photoItems,
    required this.imageUrls,
    required this.dailyMemo,
    required this.includeCrew,
    required this.userCharacter,
    required this.backgrounds,
    required this.scratchPapers,
    required this.clips,
    required this.tapes,
    required this.stamps,
    required this.stickers,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random(record.date.millisecondsSinceEpoch);
    final photoEntries = photoItems.asMap().entries.toList(growable: false);
    final decoratedPhotos = photoEntries.map((entry) {
      final imageUrl = entry.key < imageUrls.length ? imageUrls[entry.key] : null;
      return _DiaryDecoratedPhoto(
        index: entry.key,
        item: entry.value,
        imageUrl: imageUrl,
        tapeAsset: _pick(tapes, random.nextInt(9999)),
        clipAsset: _pick(clips, random.nextInt(9999)),
        backgroundAsset: _pick(backgrounds, random.nextInt(9999)),
        scratchAsset: _pick(scratchPapers, random.nextInt(9999)),
      );
    }).toList(growable: false);

    return GridBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DiaryHeader(record: record),
            const SizedBox(height: 24),
            _DiaryCollageCanvas(
              record: record,
              photos: decoratedPhotos,
              dailyMemo: dailyMemo,
              includeCrew: includeCrew,
              userCharacter: userCharacter,
              stampAsset: _pick(stamps, random.nextInt(9999)),
              stickers: stickers,
              seed: record.date.millisecondsSinceEpoch + photoItems.length,
            ),
          ],
                ),
              ),
    );
  }

  static String _pick(List<String> assets, int seed) {
    if (assets.isEmpty) return '';
    return assets[Random(seed).nextInt(assets.length)];
  }
}

class _DiaryDecoratedPhoto {
  final int index;
  final TimelineItem item;
  final String? imageUrl;
  final String tapeAsset;
  final String clipAsset;
  final String backgroundAsset;
  final String scratchAsset;

  const _DiaryDecoratedPhoto({
    required this.index,
    required this.item,
    required this.imageUrl,
    required this.tapeAsset,
    required this.clipAsset,
    required this.backgroundAsset,
    required this.scratchAsset,
  });
}

class _DiaryCollageCanvas extends StatelessWidget {
  final OotdRecord record;
  final List<_DiaryDecoratedPhoto> photos;
  final String dailyMemo;
  final bool includeCrew;
  final CharacterDraft userCharacter;
  final String stampAsset;
  final List<String> stickers;
  final int seed;

  const _DiaryCollageCanvas({
    required this.record,
    required this.photos,
    required this.dailyMemo,
    required this.includeCrew,
    required this.userCharacter,
    required this.stampAsset,
    required this.stickers,
    required this.seed,
  });

  static const double _baseWidth = 344;

  @override
  Widget build(BuildContext context) {
    final count = photos.isEmpty ? 1 : photos.length.clamp(1, 5).toInt();
    final showCharacter =
        includeCrew ||
        record.brands['linkedOotd'] == 'true' ||
        record.brands['recordType'] != 'daily';
    final spec = _DiaryCollageSpec.resolve(count, showCharacter);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / _baseWidth;
        final canvasHeight = spec.contentHeight;
        return SizedBox(
          width: constraints.maxWidth,
          height: canvasHeight * scale,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _baseWidth,
              height: canvasHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ...photos.map((photo) {
                    final place = spec.memoPlaces[photo.index];
                    return _placed(
                      place,
                      _DiaryPhotoMemoCard(
                        index: photo.index,
                        text: photo.item.description,
                        scratchAsset: photo.scratchAsset,
                        useScratchPaper: photo.index.isEven,
                      ),
                    );
                  }),
                  if (photos.isEmpty)
                    _placed(
                      const _DiaryPlace(8, 8, 168, 142, -0.04),
                      _DiaryEmptyPhotoCard(),
                    )
                  else
                    ...photos.map((photo) {
                      final place = spec.photoPlaces[photo.index];
                      return _placed(
                        place,
                        _DiaryPhotoCard(
                          index: photo.index,
                          imageUrl: photo.imageUrl,
                          tapeAsset: photo.tapeAsset,
                          clipAsset: photo.clipAsset,
                          backgroundAsset: photo.backgroundAsset,
                          useBackgroundPaper: photo.index.isOdd,
                          useClip: photo.index.isEven && photo.index % 4 == 0,
                          rotation: place.rotation,
                        ),
                      );
                    }),
                  
                  if (showCharacter && spec.characterPlace != null)
                    _placed(
                      spec.characterPlace!,
                      _DiaryCharacterPair(
                        userCharacter: userCharacter,
                        includeCrew: includeCrew,
                      ),
                    ),
                  _placed(spec.memoryPlace, const _DiaryTodayMemoryBlock()),
                  _placed(spec.statusPlace, _DiaryTodayStatusBlock(record: record)),
                  _placed(
                    spec.memoFooterPlace,
                    _DiaryMemoFooter(memo: dailyMemo, stampAsset: stampAsset),
                  ),
                  _DiaryCanvasStickers(
                    stickers: stickers,
                    places: spec.stickerPlaces,
                    seed: seed,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placed(_DiaryPlace place, Widget child) {
    return Positioned(
      left: place.x,
      top: place.y,
      width: place.width,
      height: place.height,
      child: Transform.rotate(angle: place.rotation, child: child),
    );
  }
}

class _DiaryCollageSpec {
  final double height;
  final List<_DiaryPlace> photoPlaces;
  final List<_DiaryPlace> memoPlaces;
  final _DiaryPlace memoryPlace;
  final _DiaryPlace statusPlace;
  final _DiaryPlace memoFooterPlace;
  final _DiaryPlace? characterPlace;
  final List<_DiaryPlace> stickerPlaces;

  const _DiaryCollageSpec({
    required this.height,
    required this.photoPlaces,
    required this.memoPlaces,
    required this.memoryPlace,
    required this.statusPlace,
    required this.memoFooterPlace,
    required this.stickerPlaces,
    this.characterPlace,
  });

  static _DiaryCollageSpec resolve(int count, bool includeCrew) {
    if (includeCrew) return _withCharacter(count);
    return _withoutCharacter(count);
  }

  double get contentHeight {
    final places = <_DiaryPlace>[
      ...photoPlaces,
      ...memoPlaces,
      memoryPlace,
      statusPlace,
      memoFooterPlace,
      ?characterPlace,
      ...stickerPlaces,
    ];
    final bottom = places
        .map((place) => place.y + place.height)
        .fold<double>(height, max);
    return bottom + 24;
  }

  static _DiaryCollageSpec _withCharacter(int count) {
    switch (count) {
      case 1:
        return const _DiaryCollageSpec(
          height: 450,
          photoPlaces: [_DiaryPlace(10, 0, 166, 146, -0.025)],
          memoPlaces: [_DiaryPlace(188, 16, 140, 104, 0.01)],
          characterPlace: _DiaryPlace(112, 148, 120, 88, 0),
          memoryPlace: _DiaryPlace(10, 252, 178, 96, -0.005),
          statusPlace: _DiaryPlace(204, 264, 128, 84, 0.005),
          memoFooterPlace: _DiaryPlace(28, 368, 288, 62, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(24, 146, 24, 24, -0.18),
            _DiaryPlace(304, 358, 24, 24, -0.12),
          ],
        );
      case 2:
        return const _DiaryCollageSpec(
          height: 500,
          photoPlaces: [
            _DiaryPlace(10, 0, 150, 132, -0.025),
            _DiaryPlace(184, 132, 150, 132, 0.025),
          ],
          memoPlaces: [
            _DiaryPlace(174, 10, 154, 92, 0.01),
            _DiaryPlace(18, 148, 154, 92, -0.01),
          ],
          characterPlace: _DiaryPlace(112, 254, 120, 82, 0),
          memoryPlace: _DiaryPlace(10, 350, 178, 88, -0.005),
          statusPlace: _DiaryPlace(204, 358, 128, 80, 0.005),
          memoFooterPlace: _DiaryPlace(28, 450, 288, 42, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 246, 24, 24, 0.14),
            _DiaryPlace(18, 438, 24, 24, -0.14),
          ],
        );
      case 3:
        return const _DiaryCollageSpec(
          height: 610,
          photoPlaces: [
            _DiaryPlace(10, 0, 150, 132, -0.025),
            _DiaryPlace(184, 132, 150, 132, 0.025),
            _DiaryPlace(10, 264, 150, 132, -0.025),
          ],
          memoPlaces: [
            _DiaryPlace(174, 10, 154, 92, 0.01),
            _DiaryPlace(18, 148, 154, 92, -0.01),
            _DiaryPlace(174, 276, 154, 92, 0.01),
          ],
          characterPlace: _DiaryPlace(112, 372, 120, 78, 0),
          memoryPlace: _DiaryPlace(10, 456, 178, 98, -0.005),
          statusPlace: _DiaryPlace(204, 456, 128, 98, 0.005),
          memoFooterPlace: _DiaryPlace(28, 562, 288, 42, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 366, 24, 24, 0.14),
            _DiaryPlace(18, 548, 24, 24, -0.14),
          ],
        );
      case 4:
        return const _DiaryCollageSpec(
          height: 700,
          photoPlaces: [
            _DiaryPlace(10, 0, 126, 112, -0.025),
            _DiaryPlace(208, 104, 126, 112, 0.025),
            _DiaryPlace(10, 208, 126, 112, -0.025),
            _DiaryPlace(208, 312, 126, 112, 0.025),
          ],
          memoPlaces: [
            _DiaryPlace(150, 8, 176, 76, 0.01),
            _DiaryPlace(18, 118, 176, 76, -0.01),
            _DiaryPlace(150, 216, 176, 76, 0.01),
            _DiaryPlace(18, 326, 176, 76, -0.01),
          ],
          characterPlace: _DiaryPlace(112, 430, 120, 72, 0),
          memoryPlace: _DiaryPlace(10, 528, 178, 84, -0.005),
          statusPlace: _DiaryPlace(204, 528, 128, 84, 0.005),
          memoFooterPlace: _DiaryPlace(28, 634, 288, 52, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 420, 24, 24, 0.14),
            _DiaryPlace(18, 622, 24, 24, -0.14),
          ],
        );
      default:
        return const _DiaryCollageSpec(
          height: 790,
          photoPlaces: [
            _DiaryPlace(10, 0, 116, 104, -0.025),
            _DiaryPlace(218, 92, 116, 104, 0.025),
            _DiaryPlace(10, 184, 116, 104, -0.025),
            _DiaryPlace(218, 276, 116, 104, 0.025),
            _DiaryPlace(10, 368, 116, 104, -0.025),
          ],
          memoPlaces: [
            _DiaryPlace(140, 6, 188, 70, 0.01),
            _DiaryPlace(18, 106, 188, 70, -0.01),
            _DiaryPlace(140, 190, 188, 70, 0.01),
            _DiaryPlace(18, 290, 188, 70, -0.01),
            _DiaryPlace(140, 374, 188, 70, 0.01),
          ],
          characterPlace: _DiaryPlace(112, 490, 120, 70, 0),
          memoryPlace: _DiaryPlace(10, 584, 178, 84, -0.005),
          statusPlace: _DiaryPlace(204, 584, 128, 84, 0.005),
          memoFooterPlace: _DiaryPlace(28, 696, 288, 60, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 480, 24, 24, 0.14),
            _DiaryPlace(18, 684, 24, 24, -0.14),
          ],
        );
    }
  }

  static _DiaryCollageSpec _withoutCharacter(int count) {
    switch (count) {
      case 1:
        return const _DiaryCollageSpec(
          height: 360,
          photoPlaces: [_DiaryPlace(10, 0, 166, 146, -0.025)],
          memoPlaces: [_DiaryPlace(180, -10, 140, 150, 0.01)],
          memoryPlace: _DiaryPlace(10, 168, 178, 120, -0.005),
          statusPlace: _DiaryPlace(204, 174, 128, 86, 0.005),
          memoFooterPlace: _DiaryPlace(28, 300, 288, 62, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(20, 155, 24, 24, -0.18),
            _DiaryPlace(300, 272, 24, 24, -0.12),
          ],
        );
      case 2:
        return const _DiaryCollageSpec(
          height: 440,
          photoPlaces: [
            _DiaryPlace(10, 0, 150, 132, -0.025),
            _DiaryPlace(184, 132, 150, 132, 0.025),
          ],
          memoPlaces: [
            _DiaryPlace(174, 10, 154, 92, 0.01),
            _DiaryPlace(18, 148, 154, 92, -0.01),
          ],
          memoryPlace: _DiaryPlace(10, 266, 178, 120, -0.005),
          statusPlace: _DiaryPlace(204, 268, 128, 86, 0.005),
          memoFooterPlace: _DiaryPlace(28, 400, 288, 54, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 246, 24, 24, 0.14),
            _DiaryPlace(18, 362, 24, 24, -0.14),
          ],
        );
      case 3:
        return const _DiaryCollageSpec(
          height: 540,
          photoPlaces: [
            _DiaryPlace(10, 0, 150, 132, -0.025),
            _DiaryPlace(184, 132, 150, 132, 0.025),
            _DiaryPlace(10, 264, 150, 132, -0.025),
          ],
          memoPlaces: [
            _DiaryPlace(174, 10, 154, 92, 0.01),
            _DiaryPlace(18, 148, 154, 92, -0.01),
            _DiaryPlace(160, 276, 165, 100, 0.01),
          ],
          memoryPlace: _DiaryPlace(150, 382, 178, 120, -0.005),
          statusPlace: _DiaryPlace(10, 410, 128, 86, 0.005),
          memoFooterPlace: _DiaryPlace(28, 510, 288, 54, 0),
          stickerPlaces: [
            _DiaryPlace(306, 10, 24, 24, 0.18),
            _DiaryPlace(304, 375, 24, 24, 0.14),
            _DiaryPlace(18, 474, 24, 24, -0.14),
          ],
        );
      case 4:
        return const _DiaryCollageSpec(
          height: 640,
          photoPlaces: [
            _DiaryPlace(10, 0, 126, 112, -0.025),
            _DiaryPlace(208, 104, 126, 112, 0.025),
            _DiaryPlace(10, 208, 126, 112, -0.025),
            _DiaryPlace(185, 312, 140, 140, 0.025),
          ],
          memoPlaces: [
            _DiaryPlace(150, 8, 176, 92, 0.01),
            _DiaryPlace(50, 118, 150, 80, -0.01),
            _DiaryPlace(150, 216, 176, 92, 0.01),
            _DiaryPlace(30, 336, 150, 80, -0.01),
          ],
          memoryPlace: _DiaryPlace(10, 430, 178, 120, -0.005),
          statusPlace: _DiaryPlace(196, 460, 128, 86, 0.005),
          memoFooterPlace: _DiaryPlace(28, 560, 288, 56, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 430, 24, 24, 0.14),
            _DiaryPlace(18, 546, 24, 24, -0.14),
          ],
        );
      default:
        return const _DiaryCollageSpec(
          height: 710,
          photoPlaces: [
            _DiaryPlace(10, -5, 140, 130, -0.025),
            _DiaryPlace(218, 85, 116, 104, 0.025),
            _DiaryPlace(10, 180, 116, 104, -0.025),
            _DiaryPlace(170, 260, 140, 130, 0.025),
            _DiaryPlace(10, 368, 116, 104, -0.025),
          ],
          memoPlaces: [
            _DiaryPlace(140, 6, 188, 70, 0.01),
            _DiaryPlace(80, 110, 150, 80, -0.01),
            _DiaryPlace(120, 190, 188, 70, 0.01),
            _DiaryPlace(18, 290, 150, 80, -0.01),
            _DiaryPlace(130, 390, 188, 70, 0.01),
          ],
          memoryPlace: _DiaryPlace(10, 490, 178, 120, -0.005),
          statusPlace: _DiaryPlace(204, 490, 128, 86, 0.005),
          memoFooterPlace: _DiaryPlace(28, 625, 288, 60, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 482, 24, 24, 0.50),
            _DiaryPlace(18, 600, 24, 24, -0.14),
          ],
        );
    }
  }
}

class _DiaryPlace {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  const _DiaryPlace(
    this.x,
    this.y,
    this.width,
    this.height,
    this.rotation,
  );
}

class _DiaryCanvasStickers extends StatelessWidget {
  final List<String> stickers;
  final List<_DiaryPlace> places;
  final int seed;

  const _DiaryCanvasStickers({
    required this.stickers,
    required this.places,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    if (stickers.isEmpty) return const SizedBox.shrink();
    final random = Random(seed);
    return IgnorePointer(
      child: Stack(
        children: places.map((place) {
          final asset = stickers[random.nextInt(stickers.length)];
          return Positioned(
            left: place.x,
            top: place.y,
            width: place.width,
            height: place.height,
            child: Transform.rotate(
              angle: place.rotation,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DiaryCharacterPair extends StatelessWidget {
  final CharacterDraft userCharacter;
  final bool includeCrew;

  const _DiaryCharacterPair({
    required this.userCharacter,
    required this.includeCrew,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        PixelCharacterWidget(
          character: userCharacter,
          size: 52,
          showShadow: false,
        ),
        if (includeCrew) ...[
          const SizedBox(width: 2),
          PixelCharacterWidget(
            character: userCharacter.copyWith(hairColorIndex: 4),
            size: 48,
            showShadow: false,
          ),
        ],
      ],
    );
  }
}

class _DiaryHeader extends StatelessWidget {
  final OotdRecord record;

  const _DiaryHeader({required this.record});

  @override
  Widget build(BuildContext context) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
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

class _DiaryPhotoCard extends StatelessWidget {
  final int index;
  final String? imageUrl;
  final String tapeAsset;
  final String clipAsset;
  final String backgroundAsset;
  final bool useBackgroundPaper;
  final bool useClip;
  final double rotation;

  const _DiaryPhotoCard({
    required this.index,
    required this.imageUrl,
    required this.tapeAsset,
    required this.clipAsset,
    required this.backgroundAsset,
    required this.useBackgroundPaper,
    required this.useClip,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (useBackgroundPaper)
            Positioned.fill(
              child: Transform.rotate(
                angle: 0.08,
                child: Image.asset(
                  backgroundAsset,
                  fit: BoxFit.fill,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(useBackgroundPaper ? 10 : 0),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lineSoft),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A6B4A3D),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: imageUrl == null || imageUrl!.isEmpty
                      ? Container(
                          color: AppColors.bgPurpleSoft,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textSub,
                          ),
                        )
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.bgPurpleSoft,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textSub,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (useClip)
            Positioned(
              top: -14,
              left: -8,
              child: Image.asset(
                clipAsset,
                width: 42,
                height: 52,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            )
          else if (!useBackgroundPaper) ...[
            Positioned(
              top: -12,
              left: index.isEven ? 8 : null,
              right: index.isEven ? null : 8,
              child: Image.asset(
                tapeAsset,
                width: 66,
                height: 26,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            if (index.isEven)
              Positioned(
                bottom: -10,
                right: 2,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Image.asset(
                    tapeAsset,
                    width: 58,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DiaryPhotoMemoCard extends StatelessWidget {
  final int index;
  final String text;
  final String scratchAsset;
  final bool useScratchPaper;

  const _DiaryPhotoMemoCard({
    required this.index,
    required this.text,
    required this.scratchAsset,
    required this.useScratchPaper,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: BoxConstraints(minHeight: useScratchPaper ? 0 : 112),
      padding: EdgeInsets.fromLTRB(
        useScratchPaper ? 16 : 14,
        useScratchPaper ? 12 : 14,
        useScratchPaper ? 14 : 14,
        useScratchPaper ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: useScratchPaper
            ? Colors.transparent
            : AppColors.bgDefault.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: useScratchPaper ? null : Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PHOTO ${index + 1}',
            style: (useScratchPaper
                    ? AppTextStyles.tiny
                    : AppTextStyles.labelSmall)
                .copyWith(
              color: AppColors.accentBrown,
              fontSize: useScratchPaper ? 9 : 9,
            ),
          ),
          SizedBox(height: useScratchPaper ? 3 : 5),
          Text(
            text,
            maxLines: useScratchPaper ? 2 : 2,
            overflow: TextOverflow.ellipsis,
            style: (useScratchPaper
                    ? AppTextStyles.tiny
                    : AppTextStyles.bodySmall)
                .copyWith(
              color: AppColors.textMain,
              fontSize: useScratchPaper ? 10 : 10,
              height: useScratchPaper ? 1.18 : 1.18,
            ),
          ),
        ],
      ),
    );

    if (!useScratchPaper) return content;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            scratchAsset,
            fit: BoxFit.fill,
            errorBuilder: (_, _, _) => Container(
              decoration: BoxDecoration(
                color: AppColors.bgDefault.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lineSoft),
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }
}

class _DiaryEmptyPhotoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Text(
        '??彛???곸뵠 ??삳뮎 ??롳펷??筌롫뗀?덌쭕???ｊ펷??곸뒄.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSub,
          height: 1.45,
        ),
      ),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 62, 16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
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
          top: -16,
          child: Image.asset(
            stampAsset,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _DiaryTodayMemoryBlock extends StatelessWidget {
  const _DiaryTodayMemoryBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S MEMORY",
            style: AppTextStyles.tiny.copyWith(color: AppColors.textMain),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.textMuted),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.bgWarm,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryTodayStatusBlock extends StatelessWidget {
  final OotdRecord record;

  const _DiaryTodayStatusBlock({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S STATUS",
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          _statusLine('MOOD', _dailyMoodIcon(record.mood), record.mood),
          const SizedBox(height: 4),
          _statusLine(
            'WEATHER',
            _dailyWeatherIcon(record.weather),
            record.weather,
          ),
        ],
      ),
    );
  }

  Widget _statusLine(String label, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryPink),
        const SizedBox(width: 6),
        Text(
          '$label  $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.tiny.copyWith(color: AppColors.textMain),
        ),
      ],
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: index.isEven
                  ? AppColors.primaryPinkSoft
                  : AppColors.primaryPurpleSoft,
              borderRadius: BorderRadius.circular(10),
            ),
              child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? const Icon(Icons.photo_outlined, color: AppColors.textSub)
                  : Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textSub,
                      ),
                    ),
            ),
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
              '??ｍ뜞??筌?Ŧ??怨? ??釉????롳펷 疫꿸퀡以???類ｂ봺??됰선??',
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
        Expanded(
          child: _meta(
            'MOOD',
            mood,
            _dailyMoodIcon(mood),
          ),
        ),
        Expanded(
          child: _meta(
            'WEATHER',
            weather,
            _dailyWeatherIcon(weather),
          ),
        ),
        Expanded(
          child: _meta('PHOTO', '장', Icons.photo_library_outlined),
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
          style: AppTextStyles.tiny.copyWith(color: AppColors.accentBrown),
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

IconData _dailyMoodIcon(String mood) {
  switch (mood) {
    case '평온':
      return Icons.self_improvement;
    case '행복':
      return Icons.sentiment_very_satisfied;
    case '신남':
      return Icons.celebration;
    case '피곤':
      return Icons.mode_night;
    default:
      return Icons.sentiment_satisfied_alt;
  }
}

IconData _dailyWeatherIcon(String weather) {
  switch (weather) {
    case '맑음':
    case 'sunny':
      return Icons.wb_sunny;
    case '흐림':
    case 'cloudy':
      return Icons.cloud;
    case '비':
    case 'rain':
    case 'rainy':
      return Icons.water_drop;
    case '눈':
    case 'snow':
    case 'snowy':
      return Icons.ac_unit;
    default:
      return Icons.wb_sunny_outlined;
  }
}
