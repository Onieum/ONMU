import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../../../shared/widgets/pixel_character.dart';

class CharacterStartPage extends StatefulWidget {
  final Function(CharacterDraft) onCompleted;
  final VoidCallback? onBackToOnboarding;
  final String returnButtonLabel;
  final String completionButtonLabel;
  final CharacterDraft? initialDraft;

  const CharacterStartPage({
    super.key,
    required this.onCompleted,
    this.onBackToOnboarding,
    this.returnButtonLabel = '첫 설정 페이지로 돌아가기',
    this.completionButtonLabel = '첫 설정 페이지로 돌아가기',
    this.initialDraft,
  });

  @override
  State<CharacterStartPage> createState() => _CharacterStartPageState();
}

class _CharacterStartPageState extends State<CharacterStartPage> {
  static const int _lastStep = 5;

  int _currentStep = 0;
  late CharacterDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.initialDraft ??
        const CharacterDraft(gender: 'female', topStyleIndex: -1);
  }

  void _next() {
    if (_currentStep < _lastStep) {
      setState(() => _currentStep++);
      return;
    }

    widget.onCompleted(_draft);
  }

  void _back() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
  }

  void _backToStart() {
    if (_currentStep == 0) return;
    setState(() => _currentStep = 0);
  }

  void _returnToOnboarding() {
    widget.onBackToOnboarding?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: _currentStep == 0
          ? null
          : AppBar(
              backgroundColor: AppColors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textMain,
                  size: 20,
                ),
                onPressed: _backToStart,
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (_currentStep > 0) _buildProgressBar(),
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
        return _buildStartPage();
      case 1:
        return _buildSkinTonePage();
      case 2:
        return _buildEyePage();
      case 3:
        return _buildHairPage();
      case 4:
        return _buildClothesPage();
      case 5:
        return _buildCompletePage();
      default:
        return const SizedBox();
    }
  }

  Widget _buildProgressBar() {
    final labels = ['피부', '눈', '헤어', '의상', '완료'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(labels.length, (index) {
          final step = index + 1;
          final isActive = _currentStep == step;
          final isPassed = _currentStep > step;

          return Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isActive
                        ? AppColors.primaryPink
                        : isPassed
                        ? AppColors.primaryPinkSoft
                        : AppColors.bgWarm,
                    child: Text(
                      step.toString(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isActive
                            ? AppColors.textInverse
                            : isPassed
                            ? AppColors.primaryPink
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    style: AppTextStyles.tiny.copyWith(
                      color: isActive
                          ? AppColors.textMain
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (index < labels.length - 1)
                Container(
                  width: 24,
                  height: 1.5,
                  margin: const EdgeInsets.only(bottom: 12, left: 5, right: 5),
                  color: isPassed ? AppColors.primaryPink : AppColors.lineSoft,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStartPage() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          '캐릭터 만들기',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '나를 닮은 온뮤 캐릭터를 꾸며보세요.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: 24),
        _buildPreview(size: 190),
        const SizedBox(height: 24),
        _buildSectionTitle('성별을 선택해 주세요'),
        Row(
          children: [
            Expanded(
              child: _buildGenderCard(
                label: '여성',
                gender: 'female',
                selectedColor: AppColors.primaryPink,
                selectedBg: AppColors.primaryPinkSoft,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderCard(
                label: '남성',
                gender: 'male',
                selectedColor: AppColors.primaryPurple,
                selectedBg: AppColors.primaryPurpleSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGenderCard({
    required String label,
    required String gender,
    required Color selectedColor,
    required Color selectedBg,
  }) {
    final isSelected = _draft.gender == gender;

    return GestureDetector(
      onTap: () => setState(() => _draft = _draft.copyWith(gender: gender)),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.lineSoft,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            height: 1,
            color: isSelected ? selectedColor : AppColors.textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildSkinTonePage() {
    return Column(
      children: [
        _buildTitle('01 피부색을 선택해 주세요'),
        const SizedBox(height: 20),
        _buildPreview(size: 190),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List.generate(CharacterDraft.skinTones.length, (index) {
            final color = _colorFromHex(CharacterDraft.skinTones[index]);
            final isSelected = _draft.skinToneIndex == index;

            return GestureDetector(
              onTap: () => setState(
                () => _draft = _draft.copyWith(skinToneIndex: index),
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryPink
                        : AppColors.lineSoft,
                    width: isSelected ? 3.5 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryPink.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: AppColors.textMain,
                        size: 20,
                      )
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          '피부 ${_draft.skinToneIndex + 1}',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
      ],
    );
  }

  Widget _buildEyePage() {
    return Column(
      children: [
        _buildTitle('02 눈 스타일과 색상을 선택해 주세요'),
        const SizedBox(height: 18),
        _buildPreview(size: 190),
        const SizedBox(height: 22),
        _buildSectionTitle('눈 스타일'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.95,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            final isSelected = _draft.eyeShapeIndex == index;
            final previewChar = _draft.copyWith(
              eyeShapeIndex: index,
              eyeColorIndex: 0,
            );

            return _buildPartCard(
              isSelected: isSelected,
              label: '${index + 1}',
              onTap: () => setState(
                () => _draft = _draft.copyWith(eyeShapeIndex: index),
              ),
              child: _buildEyeStylePreview(previewChar),
            );
          },
        ),
        const SizedBox(height: 22),
        if (!(_draft.gender == 'female' && _draft.eyeShapeIndex == 2)) ...[
          _buildSectionTitle('눈 색상'),
          _buildColorGrid(
            colors: CharacterDraft.eyeColors,
            labels: CharacterDraft.eyeColorLabels,
            selectedIndex: _draft.eyeColorIndex,
            onSelect: (index) =>
                setState(() => _draft = _draft.copyWith(eyeColorIndex: index)),
          ),
        ] else
          _buildNotice('선택한 눈 스타일은 단일 색상만 지원합니다.'),
      ],
    );
  }

  Widget _buildHairPage() {
    return Column(
      children: [
        _buildTitle('03 헤어 스타일과 색상을 선택해 주세요'),
        const SizedBox(height: 18),
        _buildPreview(size: 190),
        const SizedBox(height: 22),
        _buildSectionTitle('헤어 스타일'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            final isSelected = _draft.hairStyleIndex == index;
            final previewChar = _draft.copyWith(
              hairStyleIndex: index,
              hairColorIndex: 0,
            );

            return _buildPartCard(
              isSelected: isSelected,
              label: '${index + 1}',
              onTap: () => setState(
                () => _draft = _draft.copyWith(hairStyleIndex: index),
              ),
              child: _buildHairStylePreview(
                previewChar,
                topOffset: index == 4 || index == 5 ? -5 : -15,
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        _buildSectionTitle('헤어 색상'),
        _buildColorGrid(
          colors: CharacterDraft.hairColors,
          labels: CharacterDraft.hairColorLabels,
          selectedIndex: _draft.hairColorIndex,
          onSelect: (index) =>
              setState(() => _draft = _draft.copyWith(hairColorIndex: index)),
        ),
      ],
    );
  }

  Widget _buildClothesPage() {
    return Column(
      children: [
        _buildTitle('04 의상을 선택해 주세요'),
        const SizedBox(height: 20),
        _buildPreview(size: 190),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: 3,
          itemBuilder: (context, index) {
            final isSelected = _draft.topStyleIndex == index;
            final previewChar = _draft.copyWith(topStyleIndex: index);

            return _buildPartCard(
              isSelected: isSelected,
              label: '의상 ${index + 1}',
              onTap: () => setState(
                () => _draft = _draft.copyWith(topStyleIndex: index),
              ),
              child: PixelCharacterWidget(character: previewChar, size: 88),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompletePage() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          '꾸미기 완료!',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 20),
        _buildPreview(size: 220),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryPinkSoft.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.linePink),
          ),
          child: Text(
            '이제 ??? 기록을 시작해볼까요?\n캘린더에서 나만의 코디를 모아보세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryPink,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview({required double size}) {
    final maxWidth = MediaQuery.sizeOf(context).width - 40;
    final maxAllowed = maxWidth / 1.25;
    final safeSize =
        (maxAllowed < 120 ? maxAllowed : size.clamp(120.0, maxAllowed))
            .toDouble();

    return Container(
      width: safeSize * 1.25,
      height: safeSize * 1.45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineBrown, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMain.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Transform.translate(
        offset: Offset(0, -safeSize * 0.04),
        child: PixelCharacterWidget(character: _draft, size: safeSize),
      ),
    );
  }

  Widget _buildPartCard({
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : AppColors.lineSoft,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: OverflowBox(
                  minWidth: 0,
                  minHeight: 0,
                  maxWidth: 140,
                  maxHeight: 140,
                  child: child,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                label,
                style: AppTextStyles.tiny.copyWith(
                  color: isSelected ? AppColors.textMain : AppColors.textSub,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEyeStylePreview(CharacterDraft character) {
    return SizedBox(
      width: 72,
      height: 44,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -53,
              top: -40,
              child: PixelCharacterWidget(
                character: character,
                size: 180,
                showShadow: false,
                showBody: false,
                showClothes: false,
                showHair: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHairStylePreview(
    CharacterDraft character, {
    double topOffset = -15,
  }) {
    return SizedBox(
      width: 76,
      height: 56,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -12,
              top: topOffset,
              child: PixelCharacterWidget(
                character: character,
                size: 100,
                showShadow: false,
                showBody: false,
                showClothes: false,
                showEyes: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorGrid({
    required List<String> colors,
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.2,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = _colorFromHex(colors[index]);
        final isSelected = selectedIndex == index;

        return GestureDetector(
          onTap: () => onSelect(index),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primaryPink : AppColors.lineSoft,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textMain.withValues(alpha: 0.26),
                      width: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMain),
        ),
      ),
    );
  }

  Widget _buildNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        border: Border.all(color: AppColors.lineSoft),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
      ),
    );
  }

  Widget _buildBottomCta() {
    final isStart = _currentStep == 0;
    final isLast = _currentStep == _lastStep;
    final label = isLast ? widget.completionButtonLabel : '다음';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _back,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgDefault,
                      foregroundColor: AppColors.textMain,
                      side: const BorderSide(color: AppColors.lineSoft),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('이전', maxLines: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isStart || isLast
                        ? AppColors.primaryPink
                        : AppColors.primaryPurple,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(isStart ? '시작하기' : label, maxLines: 1),
                  ),
                ),
              ),
            ],
          ),
          if (_currentStep == 0) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _returnToOnboarding,
              child: Text(
                widget.returnButtonLabel,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSub,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _colorFromHex(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }
}
