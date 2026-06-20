import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/routing/navigation_extensions.dart';
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
  final List<String> _tags = ['#OOTD'];

  int _step = 0;
  int _inputMode = _photoMode;
  bool _isSaving = false;
  Uint8List? _photoBytes;
  String? _photoFileName;
  OotdAvatarGenerationJob? _generationJob;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRecord;
    if (existing != null) {
      _tags
        ..clear()
        ..addAll(existing.moodTags.isEmpty ? ['#OOTD'] : existing.moodTags);
      _memoController.text = existing.timeline.isEmpty
          ? ''
          : existing.timeline.first.description;
      _descriptionController.text =
          existing.brands['outfitDescription'] ?? '';
      _inputMode = existing.brands['inputType'] == 'TEXT_PROMPT'
          ? _textMode
          : _photoMode;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _memoController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  bool get _isTextMode => _inputMode == _textMode;

  void _next() {
    if (_isSaving) return;
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (!_validateInput()) return;
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      _save();
    }
  }

  void _back() {
    if (_isSaving) return;
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  bool _validateInput() {
    if (_isTextMode && _descriptionController.text.trim().isEmpty) {
      _showSnack('코디 설명을 입력해 주세요.');
      return false;
    }
    if (!_isTextMode && _photoBytes == null) {
      _showSnack('상의, 하의, 신발이 보이는 전체 코디 사진 1장을 선택해 주세요.');
      return false;
    }
    return true;
  }

  Future<void> _pickPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _inputMode = _photoMode;
      _descriptionController.clear();
      _photoBytes = bytes;
      _photoFileName = picked.name.isEmpty ? 'ootd-reference.jpg' : picked.name;
    });
  }

  void _selectPhotoMode() {
    setState(() {
      _inputMode = _photoMode;
      _descriptionController.clear();
    });
  }

  void _selectTextMode() {
    setState(() {
      _inputMode = _textMode;
      _photoBytes = null;
      _photoFileName = null;
    });
  }

  void _addTag() {
    final raw = _tagController.text.trim();
    if (raw.isEmpty) return;
    final tag = raw.startsWith('#') ? raw : '#$raw';
    if (!_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
    _tagController.clear();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final repository = ref.read(recordRepositoryProvider);
    UploadedMedia? uploaded;

    try {
      if (!_isTextMode && _photoBytes != null) {
        uploaded = await repository.uploadMedia(
          _photoBytes!,
          _photoFileName ?? 'ootd-reference.jpg',
        );
      }

      final imageUrls = uploaded == null ? <String>[] : [uploaded.publicUrl];
      final media = uploaded == null ? <UploadedMedia>[] : [uploaded];
      final description = _descriptionController.text.trim();
      final memo = _memoController.text.trim();
      final inputType = _isTextMode ? 'TEXT_PROMPT' : 'PHOTO_REFERENCE';
      final date = widget.recordDate ?? DateTime.now();

      final record = OotdRecord(
        date: date,
        imagePath: imageUrls.isEmpty ? null : imageUrls.first,
        imageUrls: imageUrls,
        media: media,
        character: widget.userCharacter,
        moodTags: _tags,
        brands: {
          'recordType': 'ootd',
          'inputType': inputType,
          if (description.isNotEmpty) 'outfitDescription': description,
          'aiStatus': 'PENDING',
        },
        weather: 'sunny',
        mood: 'happy',
        isPublic: false,
        timeline: [
          TimelineItem(
            time: 'OOTD',
            placeName: _isTextMode ? '코디 설명' : '코디 사진',
            category: 'ootd',
            description: _isTextMode
                ? description
                : memo.isEmpty
                    ? '오늘의 OOTD를 기록했어요.'
                    : memo,
            imageUrl: imageUrls.isEmpty ? null : imageUrls.first,
            mediaStorageKey: uploaded?.storageKey,
          ),
        ],
      );

      final saved = await widget.onSave(record);
      final savedId = saved.id;
      if (savedId == null || savedId.isEmpty) {
        throw StateError('ootd_record_id_missing');
      }

      final savedPhotoMediaId = saved.media.isNotEmpty
          ? saved.media.first.id
          : null;
      if (!_isTextMode && (savedPhotoMediaId == null || savedPhotoMediaId.isEmpty)) {
        throw StateError('ootd_photo_media_id_missing');
      }

      final job = await repository.createAvatarGeneration(
        recordId: savedId,
        inputType: inputType,
        outfitPhotoMediaId: _isTextMode ? null : savedPhotoMediaId,
        outfitDescription: _isTextMode ? description : null,
        characterOverrides: saved.character,
      );
      final resolvedJob = await _resolveJob(repository, job);

      if (!mounted) return;
      setState(() {
        _generationJob = resolvedJob;
        _step = 3;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('OOTD 생성 요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  Future<OotdAvatarGenerationJob> _resolveJob(
    RecordRepository repository,
    OotdAvatarGenerationJob initial,
  ) async {
    var current = initial;
    for (var i = 0; i < 6; i++) {
      if (!current.isPending) return current;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      current = await repository.fetchAvatarGeneration(current.jobId);
    }
    return current;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: _step == 3
            ? const SizedBox.shrink()
            : RecordFlowExitButton(
                onPressed: () => context.popOrGo(RoutePaths.records),
              ),
        title: Text(
          'OOTD 기록',
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_step < 3) _buildStepIndicator(),
            Expanded(
              child: GridBackground(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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

  Widget _buildStepIndicator() {
    return RecordFlowStepIndicator(
      labels: const ['방식', '입력', '확인'],
      activeIndex: _step.clamp(0, 2),
    );
  }

  Widget _buildContent() {
    if (_step == 0) return _buildMethodPage();
    if (_step == 1) return _buildInputPage();
    if (_step == 2) return _buildConfirmPage();
    return _buildCompletePage();
  }

  Widget _buildMethodPage() {
    return Column(
      children: [
        _buildHeader(
          title: 'OOTD 생성 방식 선택',
          subtitle: '사진이나 텍스트 설명 중 하나를 선택해 오늘의 코디를 AI 캐릭터로 만들어 보세요.',
        ),
        const SizedBox(height: 20),
        _buildMethodCard(
          selected: !_isTextMode,
          icon: Icons.photo_camera_outlined,
          title: '사진으로 생성',
          subtitle: '상의, 하의, 신발이 모두 보이는 전체 코디 사진 1장을 사용해요.',
          onTap: _selectPhotoMode,
        ),
        const SizedBox(height: 14),
        _buildMethodCard(
          selected: _isTextMode,
          icon: Icons.edit_note_outlined,
          title: '텍스트 설명으로 생성',
          subtitle: '사진 없이 옷 설명을 직접 입력해서 OOTD 캐릭터를 만들어요.',
          onTap: _selectTextMode,
        ),
        const SizedBox(height: 24),
        PixelCharacterWidget(character: widget.userCharacter, size: 120),
      ],
    );
  }

  Widget _buildInputPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: _isTextMode ? '코디 설명 입력' : '코디 사진 선택',
          subtitle: _isTextMode
              ? '색상, 소재, 핏, 소품까지 최대한 자세히 적어 주세요.'
              : '상의, 하의, 신발이 보이는 전체 코디 사진 1장을 선택해 주세요.',
        ),
        const SizedBox(height: 20),
        if (_isTextMode) _buildDescriptionInput() else _buildPhotoInput(),
        const SizedBox(height: 24),
        _buildTagInput(),
        const SizedBox(height: 20),
        TextField(
          controller: _memoController,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: '메모',
            hintText: '오늘 코디에 대한 메모를 남겨보세요.',
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPage() {
    final description = _descriptionController.text.trim();
    return Column(
      children: [
        _buildHeader(
          title: 'AI OOTD 생성 확인',
          subtitle: '입력 내용을 확인하고 AI 생성 요청을 보낼게요.',
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow('입력 방식', _isTextMode ? '텍스트 설명' : '사진'),
              const SizedBox(height: 10),
              _summaryRow(
                '입력 내용',
                _isTextMode
                    ? description
                    : _photoFileName ?? '사진 선택 완료',
              ),
              const SizedBox(height: 10),
              _summaryRow('태그', _tags.join(' ')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PixelCharacterWidget(character: widget.userCharacter, size: 130),
      ],
    );
  }

  Widget _buildCompletePage() {
    final job = _generationJob;
    final isCompleted = job?.isCompleted ?? false;
    return Column(
      children: [
        const SizedBox(height: 16),
        Icon(
          isCompleted ? Icons.check_circle_outline : Icons.hourglass_bottom,
          color: isCompleted ? AppColors.accentGreen : AppColors.primaryPink,
          size: 42,
        ),
        const SizedBox(height: 12),
        Text(
          isCompleted ? 'OOTD 생성 요청 완료' : 'OOTD 생성 처리 중',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textMain,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isCompleted
              ? 'mock 생성 결과를 저장했어요. 실제 Azure ML 연결 후에는 생성 이미지가 기록에 반영됩니다.'
              : '생성 job을 처리 중이에요. 잠시 후 기록 화면에서 결과를 확인할 수 있어요.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              PixelCharacterWidget(character: widget.userCharacter, size: 140),
              const SizedBox(height: 12),
              Text(
                'jobId: ${job?.jobId ?? '-'}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'status: ${job?.status ?? 'UNKNOWN'}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primaryPink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required String title, required String subtitle}) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textMain),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSub,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryPink : AppColors.lineSoft,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primaryPink : AppColors.textMuted,
              size: 34,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: selected
                          ? AppColors.primaryPink
                          : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSub,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              activeColor: AppColors.primaryPink,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoInput() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: _cardDecoration(),
        child: _photoBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.primaryPink,
                    size: 42,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '사진 선택하기',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '상의, 하의, 신발이 보이는 사진 1장',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(_photoBytes!, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return TextField(
      controller: _descriptionController,
      maxLength: 500,
      maxLines: 7,
      decoration: const InputDecoration(
        labelText: '코디 설명',
        hintText: '예: 아이보리 니트, 데님 미니스커트, 흰 양말, 흰 운동화',
      ),
    );
  }

  Widget _buildTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '하루 태그',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMain),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(hintText: '#코디 #OOTD'),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _addTag,
              child: const Text('추가'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags
              .map(
                (tag) => Chip(
                  label: Text(tag),
                  onDeleted: _tags.length <= 1
                      ? null
                      : () => setState(() => _tags.remove(tag)),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSub,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textMain,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.bgDefault,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.lineSoft),
    );
  }

  Widget _buildBottomBar() {
    if (_step == 3) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (widget.isDailyRecord) {
                  context.pop();
                } else {
                  context.go(RoutePaths.records);
                }
              },
              child: Text(widget.isDailyRecord ? '하루 일과 작성으로 돌아가기' : '기록으로 가기'),
            ),
          ),
        ),
      );
    }

    String label = '다음';
    if (_step == 0) label = '다음';
    if (_step == 2) label = _isSaving ? '생성 요청 중...' : '생성 요청하기';

    return RecordFlowBottomBar(
      primaryLabel: label,
      onPrimaryPressed: _next,
      onBackPressed: _back,
      showBackButton: _step > 0,
    );
  }
}
