import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/pixel_character.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../widgets/record_flow_navigation.dart';

class OotdRecordScreen extends StatefulWidget {
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
  State<OotdRecordScreen> createState() => _OotdRecordScreenState();
}

class _OotdRecordScreenState extends State<OotdRecordScreen> {
  int _currentStep = 0;
  bool _isSaving = false;
  // 0: 진입 화면 (OotdEntryPage)
  // 1: 기록 방법 선택 (OotdMethodPage)
  // 2: 사진 업로드 또는 설명 입력 (OotdPhotoUploadPage / OotdDescriptionPage)
  // 3: 추가 정보 입력 (OotdExtraInfoPage)
  // 4: 스타일 옵션 (OotdStylePage)
  // 5: 소품 및 분위기 (OotdPropsMoodPage)
  // 6: AI 분석 중 (OotdAnalysisPage)
  // 7: 기록 완료 (OotdCompletePage)

  int _selectedMethod = 0; // 0: 사진으로 기록, 1: 설명으로 기록
  final List<String> _moodTags = ['#데일리룩'];
  final _tagController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  final _memoController = TextEditingController();

  String _selectedSeason = '가을'; // 봄, 여름, 가을, 겨울, 실내
  int _selectedBgColorIndex = 0;
  bool _changeStyle = false;
  int _customHairStyleIndex = 0;
  int _customHairColorIndex = 0;
  int _customEyeColorIndex = 0;
  double _rating = 5.0;

  // 시뮬레이션용 데이터
  final List<String> _seasons = ['봄', '여름', '가을', '겨울', '실내'];
  final List<Color> _bgColors = [
    AppColors.calendarDatePinkBg,
    AppColors.calendarDatePurpleBg,
    AppColors.calendarDateGreenBg,
    AppColors.calendarDateYellowBg,
    AppColors.calendarDateBlueBg,
  ];

  Color? get _selectedBackgroundColor {
    if (_selectedBgColorIndex < 0) return null;
    final safeIndex = _selectedBgColorIndex
        .clamp(0, _bgColors.length - 1)
        .toInt();
    return _bgColors[safeIndex];
  }

  Color get _characterPreviewBackground {
    return _selectedBackgroundColor?.withOpacity(0.3) ?? AppColors.transparent;
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      final r = widget.existingRecord!;
      _selectedMethod = r.brands['스타일'] == '사진 OOTD' ? 0 : 1;
      _moodTags.clear();
      _moodTags.addAll(r.moodTags);
      _locationController.text = r.brands['스타일 컨셉'] ?? r.brands['장소'] ?? '';
      _selectedSeason = r.brands['날씨/계절'] ?? '가을';
      _selectedBgColorIndex =
          int.tryParse(r.brands['bgColorIndex'] ?? '0') ?? 0;
      _changeStyle = true;
      _customHairStyleIndex = r.character.hairStyleIndex;
      _customHairColorIndex = r.character.hairColorIndex;
      _customEyeColorIndex = r.character.eyeColorIndex;
      _rating = double.tryParse(r.brands['rating'] ?? '5.0') ?? 5.0;
      if (r.timeline.isNotEmpty) {
        _memoController.text = r.timeline.first.description;
      }
    } else {
      _customHairStyleIndex = widget.userCharacter.hairStyleIndex;
      _customHairColorIndex = widget.userCharacter.hairColorIndex;
      _customEyeColorIndex = widget.userCharacter.eyeColorIndex;
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isSaving) return;
    if (_currentStep == 4) {
      // 4단계 완료 시 AI 분석 중 페이지(5)로 보내고, 2초 후에 완료 페이지(6)로 자동 이동 시뮬레이션!
      setState(() => _currentStep = 5);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _currentStep = 6);
        }
      });
    } else if (_currentStep == 6) {
      // 최종 세이브
      _save();
    } else {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _back() {
    if (_currentStep > 0 && _currentStep != 5 && _currentStep != 6) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final ootdCharacter = widget.userCharacter.copyWith(
      hairStyleIndex: _changeStyle
          ? _customHairStyleIndex
          : widget.userCharacter.hairStyleIndex,
      hairColorIndex: _changeStyle
          ? _customHairColorIndex
          : widget.userCharacter.hairColorIndex,
      eyeColorIndex: _changeStyle
          ? _customEyeColorIndex
          : widget.userCharacter.eyeColorIndex,
      accessoryStyleIndex: 0, // 소품은 완전히 배제
    );

    final record = OotdRecord(
      date: widget.recordDate ?? DateTime.now(),
      character: ootdCharacter,
      moodTags: _moodTags,
      brands: {
        '스타일': _selectedMethod == 0 ? '사진 OOTD' : '텍스트 OOTD',
        '날씨/계절': _selectedSeason,
        '스타일 컨셉': _locationController.text.trim().isEmpty
            ? '미지정'
            : _locationController.text.trim(),
        'bgColorIndex': _selectedBgColorIndex.toString(),
        'rating': _rating.toString(),
      },
      weather: _selectedSeason == '실내' ? 'cloudy' : 'sunny',
      mood: 'happy',
      isPublic: false,
      timeline: [
        TimelineItem(
          time: '14:00',
          placeName: _locationController.text.trim().isEmpty
              ? '스타일 컨셉'
              : _locationController.text.trim(),
          category: 'place',
          description: _memoController.text.trim().isEmpty
              ? '즐거운 하루의 기록!'
              : _memoController.text.trim(),
        ),
      ],
    );
    setState(() => _isSaving = true);
    OotdRecord saved = record;
    try {
      saved = await widget.onSave(record);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OOTD 저장에 실패했어요. 다시 시도해 주세요.')),
      );
      return;
    }
    if (!mounted) return;
    if (widget.isDailyRecord) {
      context.pop(saved);
      return;
    }
    context.go(RoutePaths.records);
  }

  // OOTD 스텝 인디케이터
  Widget _buildStepIndicator() {
    final labels = ['방법', '입력', '정보', '스타일', '완료'];
    final active = _currentStep == 0 ? 0 : (_currentStep - 1).clamp(0, 4);

    return RecordFlowStepIndicator(labels: labels, activeIndex: active);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: _currentStep == 6
            ? const SizedBox()
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
            if (_currentStep > 0 && _currentStep < 6) _buildStepIndicator(),
            Expanded(
              child: GridBackground(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildContent(),
                ),
              ),
            ),
            _buildBottomCta(),
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
        return _buildMethodPage();
      case 2:
        return _selectedMethod == 0
            ? _buildPhotoUploadPage()
            : _buildDescriptionPage();
      case 3:
        return _buildExtraInfoPage();
      case 4:
        return _buildStylePage();
      case 5:
        return _buildAnalysisPage();
      case 6:
        return _buildCompletePage();
      default:
        return SizedBox();
    }
  }

  // 0. OotdEntryPage (새 OOTD 기록하기 시작)
  Widget _buildEntryPage() {
    return RecordEntryIntro(
      character: widget.userCharacter,
      title: '새 OOTD 기록하기',
      subtitle: '오늘 입은 코디를 기록하고\n나만의 캐릭터를 꾸며보세요!',
      bannerText: '사진을 올리거나 코디 설명을 입력하면\n캐릭터를 자동으로 꾸며드려요!',
      topLeftIcon: Icons.cloud_outlined,
      topLeftColor: AppColors.accentBlue,
      bottomRightIcon: Icons.camera_alt_outlined,
      bottomRightColor: AppColors.textMuted,
    );
  }

  // 1. OotdMethodPage (기록 방법 선택)
  Widget _buildMethodPage() {
    return Column(
      children: [
        SizedBox(height: 10),
        Text(
          '기록 방법을 선택해주세요',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textMain),
        ),
        SizedBox(height: 6),
        Text(
          '어떤 방법으로 코디를 기록할까요?',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 24),
        // 사진으로 기록하기 카드
        _buildMethodCard(
          index: 0,
          icon: Icons.photo_camera_outlined,
          title: '사진으로 기록하기',
          subtitle: '오늘 입은 코디 사진을 업로드하면\nAI가 자동으로 인식해요!',
        ),
        SizedBox(height: 16),
        // 설명으로 기록하기 카드
        _buildMethodCard(
          index: 1,
          icon: Icons.edit_note_outlined,
          title: '설명으로 기록하기',
          subtitle: '직접 코디 정보를 입력하면\n캐릭터를 꾸며드려요!',
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgDefault,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : AppColors.lineSoft,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textMain.withValues(alpha: 0.02),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? AppColors.primaryPink : AppColors.textMuted,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected
                          ? AppColors.primaryPink
                          : AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 4),
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
            Radio<int>(
              value: index,
              groupValue: _selectedMethod,
              activeColor: AppColors.primaryPink,
              onChanged: (val) {
                if (val != null) setState(() => _selectedMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 2A. OotdPhotoUploadPage (코디 사진 업로드)
  Widget _buildPhotoUploadPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '코디 사진을 업로드해주세요 📷',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMain,
            ),
          ),
        ),
        SizedBox(height: 4),
        Center(
          child: Text(
            '정면 사진이 가장 좋아요!',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSub),
          ),
        ),
        SizedBox(height: 20),
        // 파일 드롭존 모양 컨테이너
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.lineBrown,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 36,
                color: AppColors.primaryPink,
              ),
              SizedBox(height: 10),
              Text(
                '사진을 선택하거나\n여기로 드래그 해주세요\n(JPG, PNG / 최대 10장)',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSub,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        // 코디 예시 목록 가로 스크롤
        Text(
          '사진 예시',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppColors.lineSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lineSoft),
                ),
                alignment: Alignment.center,
                child: Text(
                  '예시 ${index + 1}',
                  style: AppTextStyles.sticker.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 2B. OotdDescriptionPage (코디 설명 입력)
  Widget _buildDescriptionPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '코디 설명 입력 📝',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMain,
            ),
          ),
        ),
        SizedBox(height: 4),
        Center(
          child: Text(
            '입은 옷과 소품에 대해 알려주세요!',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSub),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _descController,
          maxLines: 6,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText:
                '예시)\n- 아이보리 니트 가디건\n- 흰색 셔츠\n- 검정 미니 스커트\n- 흰색 양말\n- 검정 로퍼\n- 체인 숄더백',
          ),
        ),
        SizedBox(height: 16),
        // 팁 카드
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '💡 TIP: 구체적으로 작성할수록 더 정확하게 캐릭터가 완성돼요!',
                  style: AppTextStyles.sticker.copyWith(
                    color: AppColors.textSub,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. OotdExtraInfoPage (추가 정보 입력)
  Widget _buildExtraInfoPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '추가 정보 입력 (선택)',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMain,
            ),
          ),
        ),
        SizedBox(height: 4),
        Center(
          child: Text(
            '더 자세한 정보를 입력하면 정확도가 높아져요!',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSub),
          ),
        ),
        SizedBox(height: 20),
        // 태그 추가
        Text(
          '태그 추가',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: '태그 입력 (예: 스트릿, 모던)',
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(minimumSize: const Size(60, 50)),
              child: Text('추가'),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _moodTags
              .map(
                (t) => Chip(
                  label: Text(
                    t,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                  backgroundColor: AppColors.primaryPinkSoft,
                  onDeleted: () => setState(() => _moodTags.remove(t)),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 16),
        // 스타일 컨셉 / 상황 (TPO)
        Text(
          '스타일 컨셉 / 상황 (TPO)',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 6),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            hintText: '예) 데이트, 오피스룩, 캠퍼스룩, 격식있는 자리 등',
          ),
        ),
        SizedBox(height: 16),
        // 날씨 / 계절
        Text(
          '날씨 / 계절',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _seasons.map((season) {
            final isSel = _selectedSeason == season;
            return GestureDetector(
              onTap: () => setState(() => _selectedSeason = season),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSel
                      ? AppColors.primaryPinkSoft
                      : AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSel ? AppColors.primaryPink : AppColors.lineSoft,
                    width: isSel ? 1.8 : 1.0,
                  ),
                ),
                child: Text(
                  season,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSel ? AppColors.primaryPink : AppColors.textMain,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        // 코디 별점
        Text(
          '오늘의 코디 별점',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final starVal = index + 1.0;
            final isFull = _rating >= starVal;
            return GestureDetector(
              onTap: () => setState(() => _rating = starVal),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  isFull ? Icons.star : Icons.star_border,
                  color: AppColors.accentOrange,
                  size: 32,
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 20),
        // 메모
        Text(
          '메모 (선택)',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _memoController,
          maxLength: 200,
          decoration: const InputDecoration(hintText: '오늘의 코디 포인트나 느낌을 적어보세요!'),
        ),
      ],
    );
  }

  void _addTag() {
    final val = _tagController.text.trim();
    if (val.isNotEmpty) {
      final tag = val.startsWith('#') ? val : '#$val';
      if (!_moodTags.contains(tag)) {
        setState(() {
          _moodTags.add(tag);
          _tagController.clear();
        });
      }
    }
  }

  // 4. OotdStylePage (스타일 옵션)
  Widget _buildStylePage() {
    final previewCharacter = widget.userCharacter.copyWith(
      hairStyleIndex: _changeStyle
          ? _customHairStyleIndex
          : widget.userCharacter.hairStyleIndex,
      hairColorIndex: _changeStyle
          ? _customHairColorIndex
          : widget.userCharacter.hairColorIndex,
      eyeColorIndex: _changeStyle
          ? _customEyeColorIndex
          : widget.userCharacter.eyeColorIndex,
      accessoryStyleIndex: 0, // 소품 배제
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '스타일 옵션 (선택)',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMain,
            ),
          ),
        ),
        SizedBox(height: 4),
        Center(
          child: Text(
            '캐릭터 배경 색상과 외모를 다이어리 분위기에 맞게 꾸며보세요!',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSub),
          ),
        ),
        SizedBox(height: 20),

        // 캐릭터 실시간 미리보기
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _characterPreviewBackground,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lineSoft, width: 1.5),
            ),
            child: PixelCharacterWidget(character: previewCharacter, size: 100),
          ),
        ),
        SizedBox(height: 24),

        // 1. 배경 색상 선택
        Text(
          '배경 색상',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _bgColors.length + 1,
            itemBuilder: (context, index) {
              final colorIndex = index - 1;
              final isNoBackground = colorIndex < 0;
              final isSel = _selectedBgColorIndex == colorIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedBgColorIndex = colorIndex),
                child: Container(
                  width: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isNoBackground
                        ? AppColors.bgDefault
                        : _bgColors[colorIndex],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? AppColors.primaryPink : AppColors.lineSoft,
                      width: isSel ? 3.0 : 1.0,
                    ),
                  ),
                  child: isNoBackground
                      ? Icon(
                          Icons.close_rounded,
                          color: isSel
                              ? AppColors.primaryPink
                              : AppColors.textMuted,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24),

        // 2. 외모 변경 여부 질문
        Text(
          '헤어스타일이나 헤어/눈 컬러를 변경하시겠습니까?',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _changeStyle = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_changeStyle
                        ? AppColors.primaryPinkSoft
                        : AppColors.bgDefault,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !_changeStyle
                          ? AppColors.primaryPink
                          : AppColors.lineSoft,
                      width: !_changeStyle ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '변경 안 함',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: !_changeStyle
                          ? AppColors.primaryPink
                          : AppColors.textMain,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _changeStyle = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _changeStyle
                        ? AppColors.primaryPinkSoft
                        : AppColors.bgDefault,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _changeStyle
                          ? AppColors.primaryPink
                          : AppColors.lineSoft,
                      width: _changeStyle ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '변경하기',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: _changeStyle
                          ? AppColors.primaryPink
                          : AppColors.textMain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // 3. 외모 커스터마이징 영역 (변경하기를 눌렀을 때만 노출)
        if (_changeStyle) ...[
          SizedBox(height: 24),
          Text(
            '헤어스타일 종류',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(8, (index) {
              final isSel = _customHairStyleIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _customHairStyleIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppColors.primaryPurpleSoft
                        : AppColors.bgDefault,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel
                          ? AppColors.primaryPurple
                          : AppColors.lineSoft,
                      width: isSel ? 1.8 : 1.0,
                    ),
                  ),
                  child: Text(
                    '스타일 ${index + 1}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSel
                          ? AppColors.primaryPurple
                          : AppColors.textMain,
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 20),
          Text(
            '헤어 컬러',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: CharacterDraft.hairColors.length,
              itemBuilder: (context, index) {
                final colorHex = CharacterDraft.hairColors[index];
                final isSel = _customHairColorIndex == index;
                final colorVal = Color(
                  int.parse(colorHex.replaceFirst('#', 'FF'), radix: 16),
                );
                return GestureDetector(
                  onTap: () => setState(() => _customHairColorIndex = index),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colorVal,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel
                            ? AppColors.primaryPurple
                            : AppColors.lineSoft,
                        width: isSel ? 3.0 : 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Text(
            '눈 컬러',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: CharacterDraft.eyeColors.length,
              itemBuilder: (context, index) {
                final colorHex = CharacterDraft.eyeColors[index];
                final isSel = _customEyeColorIndex == index;
                final colorVal = Color(
                  int.parse(colorHex.replaceFirst('#', 'FF'), radix: 16),
                );
                return GestureDetector(
                  onTap: () => setState(() => _customEyeColorIndex = index),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colorVal,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel
                            ? AppColors.primaryPurple
                            : AppColors.lineSoft,
                        width: isSel ? 3.0 : 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // 5. OotdAnalysisPage (AI 코디 분석 중)
  Widget _buildAnalysisPage() {
    return Column(
      children: [
        SizedBox(height: 30),
        Center(
          child: Text(
            'AI가 코디 분석 중...',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMain,
            ),
          ),
        ),
        SizedBox(height: 4),
        Center(
          child: Text(
            '조금만 기다려주세요!\n캐릭터를 예쁘게 꾸미고 있어요 ✨',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSub,
              height: 1.4,
            ),
          ),
        ),
        SizedBox(height: 40),
        // 진행 체크리스트 애니메이션 모의
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Column(
            children: [
              _buildAnalysisRow('이미지 분석 중', true),
              const Divider(color: AppColors.lineSoft, height: 24),
              _buildAnalysisRow('코디 스타일 분석 중', true),
              const Divider(color: AppColors.lineSoft, height: 24),
              _buildAnalysisRow('캐릭터 스타일 적용 중', false),
              const Divider(color: AppColors.lineSoft, height: 24),
              _buildAnalysisRow('최종 결과 생성 중', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisRow(String title, bool isDone) {
    return Row(
      children: [
        isDone
            ? const Icon(
                Icons.check_circle,
                color: AppColors.accentGreen,
                size: 20,
              )
            : SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryPurple,
                ),
              ),
        SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: isDone ? AppColors.textMain : AppColors.textSub,
          ),
        ),
      ],
    );
  }

  // 6. OotdCompletePage (기록 완료)
  Widget _buildCompletePage() {
    final recordDate = widget.recordDate ?? DateTime.now();
    final finalCharacter = widget.userCharacter.copyWith(
      hairStyleIndex: _changeStyle
          ? _customHairStyleIndex
          : widget.userCharacter.hairStyleIndex,
      hairColorIndex: _changeStyle
          ? _customHairColorIndex
          : widget.userCharacter.hairColorIndex,
      eyeColorIndex: _changeStyle
          ? _customEyeColorIndex
          : widget.userCharacter.eyeColorIndex,
      accessoryStyleIndex: 0,
    );

    return Column(
      children: [
        SizedBox(height: 10),
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.accentGreen,
          size: 30,
        ),
        SizedBox(height: 8),
        Text(
          'OOTD 기록 완료!',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '오늘의 코디가 기록되었어요!',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 30),
        // 폴라로이드 감성 완료 카드
        Container(
          width: 220,
          height: 290,
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.textMain.withValues(alpha: 0.04),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _characterPreviewBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lineSoft, width: 1.0),
                ),
                child: PixelCharacterWidget(
                  character: finalCharacter,
                  size: 100,
                ),
              ),
              SizedBox(height: 16),
              // 날짜 손글씨 메모 라벨
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgWarm,
                  border: Border.all(color: AppColors.lineSoft),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _completeDateLabel(recordDate),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30),
        Text(
          '기록을 저장하고 다른 날의\nOOTD도 기록해볼까요?',
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSub,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  String _completeDateLabel(DateTime date) {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final weekday = weekdays[date.weekday - 1];
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day ($weekday)';
  }

  Widget _buildBottomCta() {
    if (_currentStep == 5) {
      // 분석 로딩창에서는 하단 버튼 없음
      return SizedBox(height: 30);
    }

    String label = '다음';
    if (_currentStep == 0) {
      label = '시작하기';
    } else if (_currentStep == 4) {
      label = '기록 분석 요청';
    } else if (_currentStep == 6) {
      label = widget.isDailyRecord ? '이어서 하루 일과 작성하기' : '홈으로 가기';
    }

    return RecordFlowBottomBar(
      primaryLabel: label,
      onPrimaryPressed: _next,
      onBackPressed: _back,
      showBackButton: _currentStep > 0 && _currentStep < 5,
    );
  }
}
