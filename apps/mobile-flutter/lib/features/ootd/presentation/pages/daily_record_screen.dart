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

part 'daily_record_result.dart';

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

Widget _crewAppearanceAvatar(
  CrewOotdAppearance appearance, {
  required double size,
}) {
  final character = appearance.character;
  final imageUrl = appearance.ootdImageUrl;
  final fallback = character == null
      ? Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: const Icon(Icons.person_outline, color: AppColors.textMuted),
        )
      : PixelCharacterWidget(character: character, size: size);

  if (imageUrl == null || imageUrl.trim().isEmpty) return fallback;

  return ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback,
    ),
  );
}

class DailyRecordScreen extends StatefulWidget {
  final CharacterDraft userCharacter;
  final DateTime recordDate;
  final OotdRecord? ootdRecord;
  final List<String> memoryPlaceNames;
  final List<CharacterDraft> crewCharacters;
  final List<CrewOotdAppearance> crewAppearances;
  final String? groupId;
  final String? planId;
  final Future<List<CrewOotdAppearance>> Function({
    required String groupId,
    required String planId,
    required DateTime date,
  })?
  onFetchCrewAppearances;
  final Future<OotdRecord> Function(OotdRecord) onSave;
  final Future<UploadedMedia> Function(Uint8List bytes, String fileName)
  onUploadMedia;
  final Future<OotdRecord?> Function() onCreateOotd;

  const DailyRecordScreen({
    super.key,
    required this.userCharacter,
    required this.recordDate,
    required this.onSave,
    required this.onUploadMedia,
    required this.onCreateOotd,
    this.ootdRecord,
    this.memoryPlaceNames = const [],
    this.crewCharacters = const [],
    this.crewAppearances = const [],
    this.groupId,
    this.planId,
    this.onFetchCrewAppearances,
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
  bool _askedMemoryForNoPlan = false;
  late List<String> _memoryPlaceNames;
  late List<CharacterDraft> _crewCharacters;
  late List<CrewOotdAppearance> _crewAppearances;
  bool _isLoadingCrewAppearances = false;

  final _dayMemoController = TextEditingController();
  final _tagController = TextEditingController();
  final _memoryController = TextEditingController();
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
    _memoryPlaceNames = _normalizePlaceNames(widget.memoryPlaceNames);
    _crewCharacters = List<CharacterDraft>.unmodifiable(widget.crewCharacters);
    _crewAppearances = List<CrewOotdAppearance>.unmodifiable(
      widget.crewAppearances,
    );
    _linkedOotdRecord = widget.ootdRecord;
    if (widget.ootdRecord != null &&
        widget.ootdRecord!.brands['recordType'] == 'daily') {
      final r = widget.ootdRecord!;
      final savedPlaces = _memoryPlaceNamesFromRecord(r);
      if (savedPlaces.isNotEmpty) {
        _memoryPlaceNames = savedPlaces;
      }
      if (r.crewAppearances.isNotEmpty) {
        _crewAppearances = List<CrewOotdAppearance>.unmodifiable(
          r.crewAppearances,
        );
        _crewCharacters = List<CharacterDraft>.unmodifiable(
          r.crewAppearances
              .map((appearance) => appearance.character)
              .whereType<CharacterDraft>(),
        );
      } else if (r.crewCharacters.isNotEmpty) {
        _crewCharacters = List<CharacterDraft>.unmodifiable(r.crewCharacters);
      }
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
          final photoIndex = _photoMemos.length;
          if (r.imageUrls.length > photoIndex) {
            draft.originalUrl = r.imageUrls[photoIndex];
          }
          if (r.media.length > photoIndex) {
            draft.originalStorageKey = r.media[photoIndex].storageKey;
          }
          _photoMemos.add(draft);
        }
      }
    }
    _loadCrewAppearances();
  }

  @override
  void dispose() {
    for (final photo in _photoMemos) {
      photo.dispose();
    }
    _dayMemoController.dispose();
    _tagController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  List<CharacterDraft> get _selectedCrewCharacters =>
      _includeCrew ? _crewCharacters : const <CharacterDraft>[];

  List<CrewOotdAppearance> get _selectedCrewAppearances =>
      _includeCrew ? _crewAppearances : const <CrewOotdAppearance>[];

  bool get _hasCrew =>
      _crewAppearances.isNotEmpty || _crewCharacters.isNotEmpty;

  bool get _shouldSkipCrewStep => !_hasCrew;

  Future<void> _loadCrewAppearances() async {
    final fetch = widget.onFetchCrewAppearances;
    final groupId = widget.groupId;
    final planId = widget.planId;
    if (fetch == null || groupId == null || planId == null) return;
    if (groupId.trim().isEmpty || planId.trim().isEmpty) return;

    setState(() => _isLoadingCrewAppearances = true);
    try {
      final appearances = await fetch(
        groupId: groupId,
        planId: planId,
        date: widget.recordDate,
      );
      if (!mounted) return;
      setState(() {
        _crewAppearances = List<CrewOotdAppearance>.unmodifiable(appearances);
        _crewCharacters = List<CharacterDraft>.unmodifiable(
          appearances
              .map((appearance) => appearance.character)
              .whereType<CharacterDraft>(),
        );
        _isLoadingCrewAppearances = false;
        if (!_hasCrew) _includeCrew = false;
      });
    } catch (error) {
      debugPrint('Daily record crew appearance load failed: $error');
      if (!mounted) return;
      setState(() => _isLoadingCrewAppearances = false);
    }
  }

  List<String> _normalizePlaceNames(Iterable<String> source) {
    final seen = <String>{};
    final places = <String>[];
    for (final value in source) {
      final place = value.trim();
      if (place.isEmpty) continue;
      if (seen.add(place)) places.add(place);
    }
    return List<String>.unmodifiable(places);
  }

  List<String> _memoryPlaceNamesFromRecord(OotdRecord record) {
    return _normalizePlaceNames(
      record.timeline
          .where((item) => item.category == 'place')
          .map((item) {
            final place = item.placeName.trim();
            return place.isNotEmpty ? place : item.description;
          }),
    );
  }

  void _next() {
    if (_isSaving) return;
    if (_currentStep == 7) {
      _closeResult();
      return;
    }
    if (_currentStep == 6) {
      _handleSaveStep();
      return;
    }
    if (_currentStep == 3 && _shouldSkipCrewStep) {
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
    if (_currentStep == 5 && _shouldSkipCrewStep) {
      setState(() => _currentStep = 3);
      return;
    }
    setState(() => _currentStep--);
  }

  Future<void> _handleSaveStep() async {
    final canSave = await _confirmMemoryForNoPlan();
    if (!canSave || !mounted) return;
    await _save();
  }

  Future<bool> _confirmMemoryForNoPlan() async {
    if (_memoryPlaceNames.isNotEmpty || _askedMemoryForNoPlan) {
      return true;
    }

    final wantsMemory = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오늘의 약속이 없습니다.'),
        content: const Text("TODAY'S MEMORY를 작성하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니오'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (!mounted) return false;

    if (wantsMemory != true) {
      setState(() => _askedMemoryForNoPlan = true);
      return true;
    }

    final memory = await _promptManualMemory();
    if (!mounted) return false;
    if (memory == null) return false;

    setState(() {
      _askedMemoryForNoPlan = true;
      _memoryPlaceNames = _normalizePlaceNames([
        ..._memoryPlaceNames,
        memory,
      ]);
    });
    return true;
  }

  Future<String?> _promptManualMemory() {
    _memoryController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("TODAY'S MEMORY"),
        content: TextField(
          controller: _memoryController,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: '예: 혼자 카페에서 책 읽기',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_memoryController.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진은 최대 5장까지 추가할 수 있어요.')));
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
        const SnackBar(content: Text('이미지 용량이 너무 커요. 1MB 이하 사진을 선택해 주세요.')),
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
        const SnackBar(content: Text('jpg, png, webp 형식의 사진만 선택할 수 있어요.')),
      );
      return;
    }
    setState(() {
      _photoMemos[index].imageBytes = bytes;
      _photoMemos[index].fileName = picked.name;
      _photoMemos[index].originalUrl = null;
      _photoMemos[index].originalStorageKey = null;
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
    final uploadedMedia = <UploadedMedia>[];

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
      crewCharacters: _includeCrew ? _crewCharacters : const [],
      crewAppearances: _includeCrew ? _crewAppearances : const [],
    );

    setState(() => _isSaving = true);
    try {
      final photoTimeline = <TimelineItem>[];
      var hasPhotoUploadFailure = false;
      for (var i = 0; i < _photoMemos.length; i++) {
        final photo = _photoMemos[i];
        if (!photo.hasPhoto && photo.controller.text.trim().isEmpty) continue;
        String? imageUrl;
        String? storageKey;
        if (photo.imageBytes != null) {
          try {
            final uploaded = await widget.onUploadMedia(
              photo.imageBytes!,
              photo.fileName ?? 'daily-record.jpg',
            );
            imageUrl = uploaded.publicUrl;
            storageKey = uploaded.storageKey;
            uploadedMedia.add(
              uploaded.copyWith(sortOrder: uploadedMedia.length),
            );
          } catch (error) {
            hasPhotoUploadFailure = true;
            debugPrint('Daily record photo upload failed: $error');
          }
        } else if (photo.originalUrl != null) {
          imageUrl = photo.originalUrl!;
          storageKey = photo.originalStorageKey;
          if (storageKey != null && storageKey.isNotEmpty) {
            uploadedMedia.add(
              UploadedMedia(
                storageKey: storageKey,
                publicUrl: imageUrl,
                sortOrder: uploadedMedia.length,
              ),
            );
          }
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
            mediaStorageKey: storageKey,
          ),
        );
      }
      final placeTimeline = _memoryPlaceNames
          .map(
            (place) => TimelineItem(
              time: 'Place',
              placeName: place,
              category: 'place',
              description: place,
            ),
          )
          .toList(growable: false);
      final timelineWithImages = [
        ...photoTimeline,
        ...placeTimeline,
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
        media: uploadedMedia,
        timeline: timelineWithImages,
        crewCharacters: _includeCrew ? _crewCharacters : const [],
        crewAppearances: _includeCrew ? _crewAppearances : const [],
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
          const SnackBar(content: Text('사진 일부를 업로드하지 못했지만 기록은 저장했어요.')),
        );
      }
      return;
    } catch (error) {
      debugPrint('Daily record save failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록을 저장하지 못했어요. 다시 시도해 주세요.')),
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
      resizeToAvoidBottomInset: true,
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
                textInputAction: TextInputAction.done,
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
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: '사진에 대한 코멘트',
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
        _sectionTitle('오늘의 OOTD', '오늘 입은 코디도 함께 기록할 수 있어요. 건너뛰면 하루 일과만 저장됩니다.'),
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
                  'OOTD 기록이 연결되었어요',
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
                  'OOTD를 기록하면 오늘의 일과에 함께 남길 수 있어요.',
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
          child: _isLoadingCrewAppearances
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: CircularProgressIndicator(),
                )
              : Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    PixelCharacterWidget(
                      character: widget.userCharacter,
                      size: 86,
                    ),
                    if (_includeCrew && _crewAppearances.isNotEmpty)
                      ..._crewAppearances.map(
                        (appearance) =>
                            _crewAppearanceAvatar(appearance, size: 76),
                      )
                    else if (_includeCrew)
                      ..._crewCharacters.map(
                        (character) => PixelCharacterWidget(
                          character: character,
                          size: 76,
                        ),
                      ),
                  ],
                ),
        ),
        if (_includeCrew && !_isLoadingCrewAppearances && !_hasCrew) ...[
          SizedBox(height: 18),
          Text(
            'No crew character was found for plans on this date.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
          ),
        ],
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
          '하루 일과 기록이 저장됐어요',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: 8),
        Text(
          isDiary ? '다이어리 형식으로 하루를 꾸며 저장했어요.' : '클린 형식으로 하루를 정리해 저장했어요.',
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
              if (_linkedOotdRecord != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PixelCharacterWidget(
                      character: widget.userCharacter,
                      size: 78,
                    ),
                    if (_selectedCrewAppearances.isNotEmpty)
                      ..._selectedCrewAppearances.take(3).map(
                            (appearance) => Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: _crewAppearanceAvatar(
                                appearance,
                                size: 66,
                              ),
                            ),
                          )
                    else if (_selectedCrewCharacters.isNotEmpty)
                      ..._selectedCrewCharacters.take(3).map(
                            (character) => Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: PixelCharacterWidget(
                                character: character,
                                size: 66,
                              ),
                            ),
                          ),
                  ],
                ),
                SizedBox(height: 14),
              ],
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
  String? originalStorageKey;
  final TextEditingController controller = TextEditingController();

  bool get hasPhoto => imageBytes != null || originalUrl != null;

  void dispose() {
    controller.dispose();
  }
}
