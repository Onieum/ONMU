import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../../../shared/widgets/pixel_character.dart';
import '../../repository/record_repository.dart';
import '../widgets/record_flow_navigation.dart';

class OotdRecordScreen extends ConsumerStatefulWidget {
  final CharacterDraft userCharacter;
  final Future<OotdRecord> Function(OotdRecord) onSave;
  final DateTime? recordDate;
  final bool isDailyRecord;
  final OotdRecord? existingRecord;

  const OotdRecordScreen({
    super.key,
    required this.userCharacter,
    required this.onSave,
    this.recordDate,
    this.isDailyRecord = false,
    this.existingRecord,
  });

  @override
  ConsumerState<OotdRecordScreen> createState() => _OotdRecordScreenState();
}

class _OotdRecordScreenState extends ConsumerState<OotdRecordScreen> {
  static const _photoMode = 0;
  static const _textMode = 1;

  final _imagePicker = ImagePicker();
  final _descriptionController = TextEditingController();
  final _memoController = TextEditingController();
  final _tagController = TextEditingController();
  final _pointController = TextEditingController();
  final _nextSuggestionController = TextEditingController();

  int _step = 0;
  int _inputMode = _photoMode;
  bool _isSaving = false;
  Uint8List? _photoBytes;
  String? _photoFileName;
  OotdAvatarGenerationJob? _generationJob;
  late CharacterDraft _styleCharacter;
  late String _weather;
  late String _mood;
  late double _rating;
  late List<String> _tags;

  bool get _isPhotoMode => _inputMode == _photoMode;
  bool get _isTextMode => _inputMode == _textMode;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRecord;
    _styleCharacter = existing?.character ?? widget.userCharacter;
    _weather = existing?.weather.isNotEmpty == true ? existing!.weather : 'sunny';
    _mood = existing?.mood.isNotEmpty == true ? existing!.mood : 'happy';
    _rating = double.tryParse(existing?.brands['rating'] ?? '') ?? 4.0;
    _tags = existing?.moodTags.isNotEmpty == true
        ? List<String>.from(existing!.moodTags)
        : ['#OOTD'];

    final brands = existing?.brands ?? const <String, String>{};
    _descriptionController.text = brands['outfitDescription'] ?? '';
    _memoController.text = existing?.timeline.isNotEmpty == true
        ? existing!.timeline.first.description
        : '';
    _pointController.text = brands['point'] ?? '';
    _nextSuggestionController.text = brands['nextSuggestion'] ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _memoController.dispose();
    _tagController.dispose();
    _pointController.dispose();
    _nextSuggestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        title: const Text('OOTD 기록'),
        leading: RecordFlowExitButton(onPressed: _handleBack),
      ),
      body: SafeArea(
        child: Column(
          children: [
            RecordFlowStepIndicator(
              labels: const ['방식', '입력', '스타일', '확인', '완료'],
              activeIndex: _step,
            ),
            Expanded(
              child: GridBackground(
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      sliver: SliverToBoxAdapter(child: _buildStepContent()),
                    ),
                  ],
                ),
              ),
            ),
            RecordFlowBottomBar(
              primaryLabel: _primaryLabel,
              showBackButton: _step > 0,
              onBackPressed: _previousStep,
              onPrimaryPressed: _isSaving ? () {} : _nextStep,
            ),
          ],
        ),
      ),
    );
  }

  String get _primaryLabel {
    if (_isSaving) return '저장 중...';
    return switch (_step) {
      0 => '다음',
      1 => '다음',
      2 => '다음',
      3 => '생성 요청하기',
      _ => '기록으로 가기',
    };
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _buildMethodPage(),
      1 => _buildInputPage(),
      2 => _buildStylePage(),
      3 => _buildConfirmPage(),
      _ => _buildCompletePage(),
    };
  }

  Widget _buildMethodPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'AI OOTD 생성 방식',
          subtitle: '사진 또는 텍스트 중 하나만 선택해서 오늘의 코디를 캐릭터에 입혀요.',
        ),
        const SizedBox(height: 20),
        _ModeCard(
          selected: _isPhotoMode,
          icon: Icons.photo_camera_outlined,
          title: '사진으로 생성',
          subtitle: '전체 코디가 보이는 사진 1장을 참고해 의상을 분석해요.',
          onTap: () => setState(() => _inputMode = _photoMode),
        ),
        const SizedBox(height: 12),
        _ModeCard(
          selected: _isTextMode,
          icon: Icons.edit_note_outlined,
          title: '텍스트 설명으로 생성',
          subtitle: '사진 없이 옷 설명만으로 OOTD 캐릭터를 만들어요.',
          onTap: () => setState(() => _inputMode = _textMode),
        ),
        const SizedBox(height: 18),
        _InfoBox(
          icon: Icons.info_outline,
          text: '사진과 텍스트 설명은 동시에 사용하지 않아요. 사진 모드는 Vision AI가 의상만 분석하고, 텍스트 모드는 입력한 설명을 그대로 사용합니다.',
        ),
      ],
    );
  }

  Widget _buildInputPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: _isPhotoMode ? 'OOTD 사진 선택' : '코디 설명 입력',
          subtitle: _isPhotoMode
              ? '상의, 하의, 신발, 소품이 최대한 한 장에 보이는 사진을 선택해 주세요.'
              : '색상, 소재, 핏, 소품을 자세히 적을수록 더 잘 반영돼요.',
        ),
        const SizedBox(height: 18),
        if (_isPhotoMode) _buildPhotoPicker() else _buildDescriptionField(),
        const SizedBox(height: 18),
        _buildMemoAndTags(),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          color: AppColors.bgDefault,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: _photoBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.primaryPink,
                    size: 44,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '전체 코디 사진 1장 선택하기',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '상의/하의/신발을 따로 올리기보다 한 장에 보이게 찍어주세요.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSub,
                      height: 1.4,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.memory(_photoBytes!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      key: const ValueKey('ootdDescriptionField'),
      controller: _descriptionController,
      minLines: 5,
      maxLines: 8,
      maxLength: 240,
      decoration: const InputDecoration(
        hintText: '예: 아이보리 니트, 블랙 롱 스커트, 버건디 숄더백, 화이트 삭스와 로퍼',
      ),
    );
  }

  Widget _buildMemoAndTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('한줄 메모', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _memoController,
          maxLength: 80,
          decoration: const InputDecoration(
            hintText: '오늘 코디에 대한 짧은 메모를 남겨보세요.',
          ),
        ),
        const SizedBox(height: 14),
        Text('태그', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(hintText: '#카페룩'),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 88,
              child: ElevatedButton(onPressed: _addTag, child: const Text('추가')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags
              .map(
                (tag) => InputChip(
                  label: Text(tag),
                  onDeleted: _tags.length == 1
                      ? null
                      : () => setState(() => _tags.remove(tag)),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildStylePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: '오늘만 스타일 조정',
          subtitle: '기본 캐릭터는 유지하되, 오늘의 머리/렌즈 느낌만 바꿔 AI에게 전달할 수 있어요.',
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: PixelCharacterWidget(
              character: _styleCharacter,
              size: 150,
              showClothes: false,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _OptionGroup(
          title: '머리스타일',
          children: List.generate(
            6,
            (index) => _ChoicePill(
              key: ValueKey('hairStyleOption-$index'),
              label: '헤어 ${index + 1}',
              selected: _styleCharacter.hairStyleIndex == index,
              onTap: () => setState(
                () => _styleCharacter = _styleCharacter.copyWith(
                  hairStyleIndex: index,
                ),
              ),
            ),
          ),
        ),
        _OptionGroup(
          title: '머리색',
          children: List.generate(
            CharacterDraft.hairColors.length,
            (index) => _ColorChoice(
              key: ValueKey('hairColorOption-$index'),
              colorHex: CharacterDraft.hairColors[index],
              selected: _styleCharacter.hairColorIndex == index,
              onTap: () => setState(
                () => _styleCharacter = _styleCharacter.copyWith(
                  hairColorIndex: index,
                ),
              ),
            ),
          ),
        ),
        _OptionGroup(
          title: '눈색/렌즈',
          children: List.generate(
            CharacterDraft.eyeColors.length,
            (index) => _ColorChoice(
              key: ValueKey('eyeColorOption-$index'),
              colorHex: CharacterDraft.eyeColors[index],
              selected: _styleCharacter.eyeColorIndex == index,
              onTap: () => setState(
                () => _styleCharacter = _styleCharacter.copyWith(
                  eyeColorIndex: index,
                ),
              ),
            ),
          ),
        ),
        _OptionGroup(
          title: '오늘의 날씨',
          children: _weatherOptions
              .map(
                (option) => _ChoicePill(
                  key: ValueKey('weather-${option.value}'),
                  label: '${option.icon} ${option.label}',
                  selected: _weather == option.value,
                  onTap: () => setState(() => _weather = option.value),
                ),
              )
              .toList(growable: false),
        ),
        _OptionGroup(
          title: '오늘의 무드',
          children: _moodOptions
              .map(
                (option) => _ChoicePill(
                  key: ValueKey('mood-${option.value}'),
                  label: '${option.icon} ${option.label}',
                  selected: _mood == option.value,
                  onTap: () => setState(() => _mood = option.value),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Text('오늘 코디 별점', style: AppTextStyles.labelSmall),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (index) => IconButton(
              key: ValueKey('rating-${index + 1}'),
              onPressed: () => setState(() => _rating = (index + 1).toDouble()),
              icon: Icon(
                index < _rating.round() ? Icons.star : Icons.star_border,
                color: const Color(0xFFFFB84D),
                size: 34,
              ),
            ),
          )..add(
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(_rating.toStringAsFixed(1), style: AppTextStyles.labelSmall),
              ),
            ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('pointField'),
          controller: _pointController,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'POINT',
            hintText: '예: 가방으로 포인트 주기',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('nextSuggestionField'),
          controller: _nextSuggestionController,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: '다음 코디 메모',
            hintText: '예: 다음엔 청바지랑 입어보기',
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPage() {
    final description = _outfitDescription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: '저장 전 확인',
          subtitle: '아래 정보로 OOTD 캐릭터 생성 요청을 보낼게요.',
        ),
        const SizedBox(height: 20),
        _SummaryCard(
          title: _isPhotoMode ? '사진 기반 생성' : '텍스트 기반 생성',
          lines: [
            if (description.isNotEmpty) description,
            '날씨: ${_weatherLabel(_weather)}',
            '무드: ${_moodLabel(_mood)}',
            '별점: ${_rating.toStringAsFixed(1)}',
            if (_pointController.text.trim().isNotEmpty)
              '포인트: ${_pointController.text.trim()}',
          ],
        ),
        const SizedBox(height: 16),
        _InfoBox(
          icon: Icons.auto_awesome,
          text: '저장 후 Vision AI가 의상 정보를 정리하고, Azure ML이 오늘만 조정한 캐릭터 스타일을 기준으로 OOTD 이미지를 생성합니다.',
        ),
      ],
    );
  }

  Widget _buildCompletePage() {
    final job = _generationJob;
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(
          job?.isFailed == true ? Icons.error_outline : Icons.check_circle_outline,
          color: job?.isFailed == true ? const Color(0xFFE75D6A) : const Color(0xFF8EBB7A),
          size: 64,
        ),
        const SizedBox(height: 18),
        Text(
          job?.isFailed == true ? '생성 요청을 다시 확인해 주세요' : 'OOTD 기록이 저장됐어요',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textMain),
        ),
        const SizedBox(height: 10),
        Text(
          job?.isCompleted == true
              ? '생성된 캐릭터 이미지는 기록 상세에서 확인할 수 있어요.'
              : 'AI 생성은 잠시 걸릴 수 있어요. 기록 화면에서 상태를 다시 확인해 주세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSub, height: 1.4),
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _photoFileName = picked.name;
      _descriptionController.clear();
    });
  }

  void _addTag() {
    final raw = _tagController.text.trim();
    if (raw.isEmpty) return;
    final normalized = raw.startsWith('#') ? raw : '#$raw';
    if (_tags.contains(normalized)) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(normalized);
      _tagController.clear();
    });
  }

  void _nextStep() {
    if (_step == 4) {
      context.go(RoutePaths.records);
      return;
    }
    if (_step == 1 && !_validateInput()) return;
    if (_step == 3) {
      _save();
      return;
    }
    setState(() => _step += 1);
  }

  void _previousStep() {
    if (_step == 0) return;
    setState(() => _step -= 1);
  }

  void _handleBack() {
    if (_step > 0) {
      _previousStep();
      return;
    }
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.records);
    }
  }

  bool _validateInput() {
    if (_isPhotoMode && _photoBytes == null) {
      _showMessage('전체 코디가 보이는 사진 1장을 선택해 주세요.');
      return false;
    }
    if (_isTextMode && _descriptionController.text.trim().isEmpty) {
      _showMessage('코디 설명을 입력해 주세요.');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(recordRepositoryProvider);
      UploadedMedia? uploaded;
      if (_isPhotoMode && _photoBytes != null) {
        uploaded = await repository.uploadMedia(
          _photoBytes!,
          _photoFileName ?? 'ootd-reference.jpg',
        );
      }

      final inputType = _isTextMode ? 'TEXT_PROMPT' : 'PHOTO_REFERENCE';
      final brands = _buildBrands(inputType, uploaded);
      final timeline = [
        TimelineItem(
          time: 'OOTD',
          placeName: '오늘의 코디',
          category: 'ootd',
          description: _memoController.text.trim().isEmpty
              ? _outfitDescription
              : _memoController.text.trim(),
          imageUrl: uploaded?.publicUrl,
          mediaStorageKey: uploaded?.storageKey,
        ),
      ];

      final record = OotdRecord(
        id: widget.existingRecord?.id,
        date: widget.recordDate ?? widget.existingRecord?.date ?? DateTime.now(),
        imagePath: uploaded?.publicUrl ?? widget.existingRecord?.imagePath,
        imageUrls: uploaded == null ? widget.existingRecord?.imageUrls ?? const [] : [uploaded.publicUrl],
        media: uploaded == null ? widget.existingRecord?.media ?? const [] : [uploaded],
        character: _styleCharacter,
        moodTags: _tags,
        brands: brands,
        weather: _weather,
        mood: _mood,
        timeline: timeline,
      );

      final saved = await widget.onSave(record);
      final savedId = saved.id;
      if (savedId == null || savedId.isEmpty) {
        throw StateError('ootd_record_id_missing');
      }

      final job = await repository.createAvatarGeneration(
        recordId: savedId,
        inputType: inputType,
        outfitPhotoMediaId: _isPhotoMode ? uploaded?.id ?? uploaded?.storageKey : null,
        outfitDescription: _isTextMode ? _descriptionController.text.trim() : null,
        characterOverrides: _styleCharacter,
      );
      final resolved = await _resolveJob(repository, job);
      if (!mounted) return;
      setState(() {
        _generationJob = resolved;
        _isSaving = false;
        _step = 4;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('OOTD 저장에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<OotdAvatarGenerationJob> _resolveJob(
    RecordRepository repository,
    OotdAvatarGenerationJob initial,
  ) async {
    var current = initial;
    for (var attempt = 0; attempt < 6 && current.isPending; attempt += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      current = await repository.fetchAvatarGeneration(current.jobId);
    }
    return current;
  }

  Map<String, String> _buildBrands(String inputType, UploadedMedia? uploaded) {
    final outfitDescription = _outfitDescription;
    final outfitInfo = _outfitInfo(outfitDescription);
    return {
      ...?widget.existingRecord?.brands,
      'recordType': 'ootd',
      'inputType': inputType,
      'aiStatus': 'PENDING',
      'title': 'OOTD 기록',
      'outfitDescription': outfitDescription,
      'todayLook': _todayLook(outfitDescription),
      'hairNote': _hairNote,
      'point': _pointController.text.trim().isEmpty
          ? _defaultPoint(outfitDescription)
          : _pointController.text.trim(),
      'nextSuggestion': _nextSuggestionController.text.trim().isEmpty
          ? _defaultNextSuggestion
          : _nextSuggestionController.text.trim(),
      'rating': _rating.toStringAsFixed(1),
      'styleHairStyle': 'hair_style_${_styleCharacter.hairStyleIndex}',
      'styleHairColor': 'hair_color_${_styleCharacter.hairColorIndex}',
      'styleEyeStyle': 'eye_style_${_styleCharacter.eyeShapeIndex}',
      'styleEyeColor': 'eye_color_${_styleCharacter.eyeColorIndex}',
      if (uploaded != null) 'outfitPhotoStorageKey': uploaded.storageKey,
      ...outfitInfo,
    };
  }

  Map<String, String> _outfitInfo(String description) {
    final fallback = description.isEmpty ? 'AI 분석 대기 중' : description;
    return {
      'outfitInfoOuter': 'AI 분석 대기 중',
      'outfitInfoTop': fallback,
      'outfitInfoBottom': 'AI 분석 대기 중',
      'outfitInfoBag': 'AI 분석 대기 중',
      'outfitInfoShoes': 'AI 분석 대기 중',
    };
  }

  String get _outfitDescription => _isTextMode
      ? _descriptionController.text.trim()
      : '선택한 OOTD 사진에서 Vision AI가 의상 디테일을 분석합니다.';

  String _todayLook(String outfitDescription) {
    if (_isPhotoMode) {
      return '오늘 선택한 사진을 바탕으로 전체 코디의 색감, 소재, 소품 포인트를 분석하고 있어요.';
    }
    return '$outfitDescription 조합으로 오늘만의 분위기를 살린 OOTD예요.';
  }

  String get _hairNote {
    return '오늘은 헤어 ${_styleCharacter.hairStyleIndex + 1} 스타일과 선택한 컬러를 반영해 캐릭터 분위기를 조정했어요.';
  }

  String _defaultPoint(String outfitDescription) {
    if (outfitDescription.contains('가방')) return '가방으로 포인트 주기';
    if (outfitDescription.contains('신발') || outfitDescription.contains('로퍼')) {
      return '신발로 스타일 마무리하기';
    }
    return '전체 코디의 색감 맞추기';
  }

  String get _defaultNextSuggestion => '다음엔 다른 색감의 아이템과도 함께 매치해 보고 싶어요.';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _weatherLabel(String value) {
    return _weatherOptions
        .firstWhere((option) => option.value == value, orElse: () => _weatherOptions.first)
        .label;
  }

  static String _moodLabel(String value) {
    return _moodOptions
        .firstWhere((option) => option.value == value, orElse: () => _moodOptions.first)
        .label;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textMain)),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSub, height: 1.45)),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? AppColors.primaryPink : AppColors.lineSoft, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primaryPink : AppColors.textSub, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMain)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub, height: 1.35)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.primaryPink),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryPink, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub, height: 1.45))),
        ],
      ),
    );
  }
}

class _OptionGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _OptionGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMain)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoicePill({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryPinkSoft,
      side: BorderSide(color: selected ? AppColors.primaryPink : AppColors.lineSoft),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final String colorHex;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChoice({super.key, required this.colorHex, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? AppColors.primaryPink : AppColors.lineSoft, width: selected ? 3 : 1),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primaryPink.withOpacity(0.28), blurRadius: 8)]
              : null,
        ),
        child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _SummaryCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryPink)),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(line, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMain, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NamedOption {
  final String value;
  final String label;
  final String icon;

  const _NamedOption(this.value, this.label, this.icon);
}

const _weatherOptions = [
  _NamedOption('sunny', '맑음', '☀'),
  _NamedOption('cloudy', '흐림', '☁'),
  _NamedOption('rainy', '비', '💧'),
  _NamedOption('snowy', '눈', '❄'),
];

const _moodOptions = [
  _NamedOption('happy', '행복', '☺'),
  _NamedOption('calm', '평온', '〰'),
  _NamedOption('excited', '신남', '✦'),
  _NamedOption('tired', '피곤', '☾'),
];
