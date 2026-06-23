import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../../../shared/widgets/pixel_character.dart';
import '../widgets/ootd_generated_image_view.dart';
import '../widgets/record_flow_navigation.dart';

part 'daily_record_result.dart';
part 'daily_record_sections.dart';

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
      errorBuilder: (context, error, stackTrace) => fallback,
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
  bool _isSavingResultImage = false;
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
  final _resultCaptureKey = GlobalKey();
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
    if (!_hasLinkedPlanContext && !_isEditingSavedDaily) {
      _crewCharacters = const <CharacterDraft>[];
      _crewAppearances = const <CrewOotdAppearance>[];
      _includeCrew = false;
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

  bool get _isEditingSavedDaily =>
      widget.ootdRecord?.brands['recordType'] == 'daily';

  bool get _hasLinkedPlanContext {
    final groupId = widget.groupId?.trim();
    final planId = widget.planId?.trim();
    return groupId != null &&
        groupId.isNotEmpty &&
        planId != null &&
        planId.isNotEmpty;
  }

  bool get _hasCrewSource =>
      _crewAppearances.isNotEmpty || _crewCharacters.isNotEmpty;

  bool get _hasCrew =>
      (_hasLinkedPlanContext || _isEditingSavedDaily) && _hasCrewSource;

  bool get _shouldSkipCrewStep =>
      (!_hasLinkedPlanContext && !_isEditingSavedDaily) ||
      (!_isLoadingCrewAppearances && !_hasCrewSource);

  Future<void> _loadCrewAppearances() async {
    final fetch = widget.onFetchCrewAppearances;
    final groupId = widget.groupId;
    final planId = widget.planId;
    if (fetch == null || groupId == null || planId == null) {
      if (!_isEditingSavedDaily) {
        _includeCrew = false;
      }
      return;
    }
    if (groupId.trim().isEmpty || planId.trim().isEmpty) {
      if (!_isEditingSavedDaily) {
        _includeCrew = false;
      }
      return;
    }

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
        if (!_hasCrewSource) _includeCrew = false;
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
      record.timeline.where((item) => item.category == 'place').map((item) {
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

  Future<Uint8List> _captureResultImageBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    var renderObject = _resultCaptureKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('daily_result_capture_boundary_missing');
    }
    if (renderObject.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
      renderObject = _resultCaptureKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('daily_result_capture_boundary_missing');
      }
    }

    final image = await renderObject.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('daily_result_capture_empty');
    }
    return bytes;
  }

  Future<void> _saveResultImage() async {
    final currentRecord = _savedRecord;
    if (currentRecord == null || _isSavingResultImage) return;

    setState(() => _isSavingResultImage = true);
    try {
      final bytes = await _captureResultImageBytes();
      final date = currentRecord.date;
      final fileName =
          "daily-record-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.png";
      final uploaded = await widget.onUploadMedia(bytes, fileName);
      final updatedRecord = currentRecord.copyWith(
        imageUrls: [...currentRecord.imageUrls, uploaded.publicUrl],
        media: [
          ...currentRecord.media,
          uploaded.copyWith(sortOrder: currentRecord.media.length),
        ],
        brands: {
          ...currentRecord.brands,
          'dailyCompositeImageUrl': uploaded.publicUrl,
          'dailyCompositeStorageKey': uploaded.storageKey,
        },
      );
      final saved = await widget.onSave(updatedRecord);
      if (!mounted) return;
      setState(() {
        _savedRecord = saved;
        _isSavingResultImage = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('하루 일과 결과 이미지를 저장했어요.')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingResultImage = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 저장에 실패했어요: $error')));
    }
  }

  Future<bool> _confirmMemoryForNoPlan() async {
    if (_memoryPlaceNames.isNotEmpty ||
        _hasLinkedPlanContext ||
        _askedMemoryForNoPlan) {
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
      setState(() {
        _askedMemoryForNoPlan = true;
        _memoryPlaceNames = const <String>[];
      });
      return true;
    }

    final memory = await _promptManualMemory();
    if (!mounted) return false;
    if (memory == null) return false;

    setState(() {
      _askedMemoryForNoPlan = true;
      _memoryPlaceNames = _normalizePlaceNames([..._memoryPlaceNames, memory]);
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
          decoration: const InputDecoration(hintText: '예: 을지로 카페에서 책 읽기'),
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
      crewCharacters: _selectedCrewCharacters,
      crewAppearances: _selectedCrewAppearances,
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
        crewCharacters: _selectedCrewCharacters,
        crewAppearances: _selectedCrewAppearances,
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

  void _updateState(VoidCallback action) {
    setState(action);
  }
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
