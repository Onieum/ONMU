import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../view_model/daily_record_edit_controller.dart';

class DailyRecordEditScreen extends ConsumerStatefulWidget {
  final String memoryId;

  const DailyRecordEditScreen({super.key, required this.memoryId});

  @override
  ConsumerState<DailyRecordEditScreen> createState() =>
      _DailyRecordEditScreenState();
}

class _DailyRecordEditScreenState extends ConsumerState<DailyRecordEditScreen> {
  final _memoController = TextEditingController();
  final _tagController = TextEditingController();
  final _imagePicker = ImagePicker();
  OotdRecord? _record;
  List<String> _tags = [];
  final List<_EditablePhoto> _photos = [];
  String _mood = '평온';
  String _weather = '맑음';
  String _theme = 'diary';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _error;

  static const _moods = ['평온', '행복', '신남', '피곤'];
  static const _weathers = ['맑음', '흐림', '비', '눈'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _memoController.dispose();
    _tagController.dispose();
    for (final photo in _photos) {
      photo.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final state = await ref
          .read(dailyRecordEditControllerProvider)
          .load(widget.memoryId);

      _photos.clear();
      for (final photoState in state.photos) {
        final photo = _EditablePhoto(originalUrl: photoState.originalUrl);
        photo.controller.text = photoState.description;
        _photos.add(photo);
      }

      if (!mounted) return;
      setState(() {
        _record = state.record;
        _tags = state.tags;
        _memoController.text = state.memo;
        _mood = state.mood;
        _weather = state.weather;
        _theme = state.theme;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '기록을 불러오지 못했어요.';
        _isLoading = false;
      });
    }
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

  void _addPhoto() {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진은 최대 5장까지 추가할 수 있어요.')));
      return;
    }
    setState(() => _photos.add(_EditablePhoto()));
  }

  void _removePhoto(int index) {
    if (_photos.length == 1) {
      setState(() {
        _photos[index].clearImage();
        _photos[index].controller.clear();
      });
      return;
    }
    setState(() {
      final removed = _photos.removeAt(index);
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
        const SnackBar(content: Text('이미지가 아직 커요. 1MB 이하 사진으로 다시 선택해 주세요.')),
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
        const SnackBar(content: Text('jpg, png, webp 이미지만 선택할 수 있어요.')),
      );
      return;
    }
    setState(() {
      _photos[index].imageBytes = bytes;
      _photos[index].fileName = picked.name;
      _photos[index].originalUrl = null;
    });
  }

  Future<void> _pickChoice({
    required String title,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: values
                    .map(
                      (value) => ChoiceChip(
                        label: Text(value),
                        selected: selected == value,
                        onSelected: (_) => Navigator.of(context).pop(value),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onSelected(picked);
  }

  Future<void> _save() async {
    final record = _record;
    if (record == null || _isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(dailyRecordEditControllerProvider)
          .save(
            DailyRecordEditSaveInput(
              memoryId: widget.memoryId,
              record: record,
              tags: _tags,
              mood: _mood,
              weather: _weather,
              theme: _theme,
              memo: _memoController.text,
              photos: _photos
                  .map(
                    (photo) => DailyRecordEditPhotoInput(
                      originalUrl: photo.originalUrl,
                      imageBytes: photo.imageBytes,
                      fileName: photo.fileName,
                      description: photo.controller.text,
                    ),
                  )
                  .toList(growable: false),
            ),
          );
      if (!mounted) return;
      if (result.hasPhotoUploadFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 일부는 업로드되지 않았지만 수정 내용은 저장했어요.')),
        );
      }
      context.pop(result.record);
    } catch (error) {
      debugPrint('Daily record edit save failed: $error');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = '수정 내용을 저장하지 못했어요.';
      });
    }
  }

  Future<void> _delete() async {
    if (_isDeleting || _isSaving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록을 삭제할까요?'),
        content: const Text('삭제한 기록은 목록에서 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.primaryPink),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await ref.read(dailyRecordEditControllerProvider).delete(widget.memoryId);
      if (mounted) context.pop('deleted');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _error = '기록을 삭제하지 못했어요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        title: Text(
          '기록 수정',
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GridBackground(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _record == null
              ? Center(child: Text(_error ?? '기록을 불러오지 못했어요.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('하루 메모'),
                      TextField(
                        controller: _memoController,
                        maxLines: 5,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          hintText: '오늘 하루를 수정해 주세요.',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _choiceCard(
                              label: 'MOOD',
                              value: _mood,
                              icon: _dailyMoodIcon(_mood),
                              onTap: () => _pickChoice(
                                title: '오늘 기분 다시 선택',
                                values: _moods,
                                selected: _mood,
                                onSelected: (value) =>
                                    setState(() => _mood = value),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _choiceCard(
                              label: 'WEATHER',
                              value: _weather,
                              icon: _dailyWeatherIcon(_weather),
                              onTap: () => _pickChoice(
                                title: '날씨 다시 선택',
                                values: _weathers,
                                selected: _weather,
                                onSelected: (value) =>
                                    setState(() => _weather = value),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('보기 형식'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _themeCard(
                              label: '다이어리',
                              description: '꾸민 일기장 형식',
                              value: 'diary',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _themeCard(
                              label: '클린',
                              description: '깔끔한 목록 형식',
                              value: 'clean',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _sectionTitle('사진과 코멘트')),
                          TextButton.icon(
                            onPressed: _addPhoto,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: const Text('사진 추가'),
                          ),
                        ],
                      ),
                      ...List.generate(
                        _photos.length,
                        (index) => _photoCard(index),
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle('해시태그'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map(
                              (tag) => InputChip(
                                label: Text(tag),
                                onDeleted: () =>
                                    setState(() => _tags.remove(tag)),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                hintText: '해시태그 추가',
                              ),
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
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.primaryPink),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isDeleting || _isSaving
                                  ? null
                                  : _delete,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(_isDeleting ? '삭제 중...' : '삭제하기'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                foregroundColor: AppColors.primaryPink,
                                side: const BorderSide(
                                  color: AppColors.linePink,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving || _isDeleting
                                  ? null
                                  : _save,
                              icon: const Icon(Icons.check, size: 18),
                              label: Text(_isSaving ? '저장 중...' : '수정 저장하기'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                backgroundColor: AppColors.primaryPink,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
    );
  }

  Widget _choiceCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lineSoft),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryPink, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.tiny),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoCard(int index) {
    final photo = _photos[index];
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '사진 ${index + 1}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _pickPhoto(index),
                child: Text(photo.hasImage ? '변경' : '선택'),
              ),
              TextButton(
                onPressed: () => _removePhoto(index),
                child: const Text('삭제'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _pickPhoto(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 150,
                width: double.infinity,
                color: AppColors.bgPaper,
                child: photo.imageBytes != null
                    ? Image.memory(photo.imageBytes!, fit: BoxFit.cover)
                    : photo.originalUrl != null
                    ? Image.network(
                        photo.originalUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textMuted,
                              size: 34,
                            ),
                      )
                    : const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.textMuted,
                        size: 34,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: photo.controller,
            maxLines: 2,
            maxLength: 120,
            decoration: const InputDecoration(
              hintText: '사진 코멘트 수정',
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeCard({
    required String label,
    required String description,
    required String value,
  }) {
    final selected = _theme == value;
    return GestureDetector(
      onTap: () => setState(() => _theme = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryPink : AppColors.lineSoft,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? AppColors.primaryPink : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: selected
                        ? AppColors.primaryPink
                        : AppColors.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSub,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
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

class _EditablePhoto {
  Uint8List? imageBytes;
  String? fileName;
  String? originalUrl;
  final TextEditingController controller = TextEditingController();

  _EditablePhoto({this.originalUrl});

  bool get hasImage =>
      imageBytes != null || (originalUrl != null && originalUrl!.isNotEmpty);

  void clearImage() {
    imageBytes = null;
    fileName = null;
    originalUrl = null;
  }

  void dispose() {
    controller.dispose();
  }
}
