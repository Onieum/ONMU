import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/character_model.dart';
import '../../shared/widgets/pixel_character.dart';
import '../../shared/widgets/grid_background.dart';

class CharacterStartPage extends StatefulWidget {
  final Function(CharacterDraft) onCompleted;

  const CharacterStartPage({
    super.key,
    required this.onCompleted,
  });

  @override
  State<CharacterStartPage> createState() => _CharacterStartPageState();
}

class _CharacterStartPageState extends State<CharacterStartPage> {
  int _currentStep = 0; 
  // 0: 시작하기 (성별 선택 포함)
  // 1: 피부색 선택 (1~5단계)
  // 2: 눈 모양 선택 (1~5단계)
  // 3: 눈 색상 선택 (8가지)
  // 4: 헤어 스타일 선택 (1~8단계)
  // 5: 헤어 컬러 선택 (10가지)
  // 6: 의상 선택 (3벌 중 1벌)
  // 7: 캐릭터 미리보기
  // 8: 캐릭터 이름 설정
  // 9: 생성 완료

  CharacterDraft _draft = const CharacterDraft(gender: 'female', topStyleIndex: -1);
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _next() {
    setState(() {
      if (_currentStep < 9) {
        _currentStep++;
      } else {
        widget.onCompleted(_draft.copyWith(
          nickname: _nicknameController.text.trim().isEmpty ? '온뮤' : _nicknameController.text.trim(),
        ));
      }
    });
  }

  void _back() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  void _skipOnboarding() {
    widget.onCompleted(const CharacterDraft(
      gender: 'female',
      nickname: '온뮤',
      topStyleIndex: -1,
    ));
  }

  // 상단 진행 상태 바 (이모지 및 구성 단순화)
  Widget _buildProgressBar(int stepGroup) {
    final labels = ['외형 설정', '미리보기', '이름 설정', '완료'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final stepNum = index + 1;
          final isActive = stepGroup == stepNum;
          final isPassed = stepGroup > stepNum;

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
                      stepNum.toString(),
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold,
                        color: isActive 
                            ? Colors.white 
                            : isPassed 
                                ? AppColors.primaryPink 
                                : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppColors.textMain : AppColors.textMuted,
                    ),
                  )
                ],
              ),
              if (index < 3)
                Container(
                  width: 40,
                  height: 1.5,
                  margin: const EdgeInsets.only(bottom: 12, left: 6, right: 6),
                  color: isPassed ? AppColors.primaryPink : AppColors.lineSoft,
                ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: _currentStep == 0
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain, size: 20),
                onPressed: _back,
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (_currentStep > 0 && _currentStep < 9)
              _buildProgressBar(
                _currentStep <= 6 
                    ? 1 
                    : _currentStep == 7 
                        ? 2 
                        : 3,
              ),
            Expanded(
              child: GridBackground(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        return _buildEyeShapePage();
      case 3:
        return _buildEyeColorPage();
      case 4:
        return _buildHairStylePage();
      case 5:
        return _buildHairColorPage();
      case 6:
        return _buildClothesPage();
      case 7:
        return _buildPreviewPage();
      case 8:
        return _buildNamePage();
      case 9:
        return _buildCompletePage();
      default:
        return const SizedBox();
    }
  }

  // 0. 시작하기 & 성별 선택
  Widget _buildStartPage() {
    final bool isFemale = _draft.gender == 'female';

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          '캐릭터 만들기',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textMain),
        ),
        const SizedBox(height: 6),
        const Text(
          '나를 닮은 귀여운 픽셀 캐릭터를 꾸며보세요!',
          style: TextStyle(fontSize: 13, color: AppColors.textSub),
        ),
        const SizedBox(height: 30),
        
        // 실시간 성별 프리뷰
        Center(
          child: PixelCharacterWidget(character: _draft, size: 160),
        ),
        const SizedBox(height: 30),
        
        // 성별 선택 카드 타일
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '성별을 선택해 주세요',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _draft = _draft.copyWith(gender: 'female')),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isFemale ? AppColors.primaryPinkSoft : AppColors.bgDefault,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFemale ? AppColors.primaryPink : AppColors.lineSoft,
                      width: isFemale ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        '여성',
                        style: TextStyle(
                          fontSize: 13, 
                          fontWeight: isFemale ? FontWeight.bold : FontWeight.normal,
                          color: isFemale ? AppColors.primaryPink : AppColors.textSub
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _draft = _draft.copyWith(gender: 'male')),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: !isFemale ? AppColors.primaryPurpleSoft : AppColors.bgDefault,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !isFemale ? AppColors.primaryPurple : AppColors.lineSoft,
                      width: !isFemale ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        '남성',
                        style: TextStyle(
                          fontSize: 13, 
                          fontWeight: !isFemale ? FontWeight.bold : FontWeight.normal,
                          color: !isFemale ? AppColors.primaryPurple : AppColors.textSub
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 1. 피부색 선택 (1~5단계)
  Widget _buildSkinTonePage() {
    return Column(
      children: [
        const Text('01 피부색을 선택해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 24),
        PixelCharacterWidget(character: _draft, size: 140),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final hexColor = CharacterDraft.skinTones[index];
            final color = Color(int.parse(hexColor.replaceAll('#', '0xFF')));
            final isSelected = _draft.skinToneIndex == index;

            return GestureDetector(
              onTap: () => setState(() => _draft = _draft.copyWith(skinToneIndex: index)),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primaryPink : AppColors.lineSoft,
                    width: isSelected ? 3.5 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primaryPink.withValues(alpha: 0.25), blurRadius: 6)]
                      : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: AppColors.textMain, size: 20) : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          '피부 단계: ${_draft.skinToneIndex + 1}단계',
          style: const TextStyle(fontSize: 13, color: AppColors.textSub, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // 2. 눈 모양 선택 (1~5단계)
  Widget _buildEyeShapePage() {
    return Column(
      children: [
        const Text('02 눈 모양을 선택해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 24),
        PixelCharacterWidget(character: _draft, size: 140),
        const SizedBox(height: 28),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            final isSelected = _draft.eyeShapeIndex == index;
            // 각 눈 모양 번호의 검은색 눈동자 버전을 미니 프리뷰 캐릭터로 렌더링
            final previewChar = _draft.copyWith(eyeShapeIndex: index, eyeColorIndex: 0);

            return GestureDetector(
              onTap: () => setState(() => _draft = _draft.copyWith(eyeShapeIndex: index)),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryPink : AppColors.lineSoft,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: OverflowBox(
                          minHeight: 80,
                          maxHeight: 110,
                          child: Transform.translate(
                            offset: const Offset(0, 5), // 얼굴 부위가 크롭되어 보이도록 위치 오프셋 조정
                            child: PixelCharacterWidget(character: previewChar, size: 65),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '${index + 1}번 눈',
                        style: TextStyle(
                          fontSize: 9, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.textMain : AppColors.textSub
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 3. 눈 색상 선택 (8가지)
  Widget _buildEyeColorPage() {
    return Column(
      children: [
        const Text('03 눈동자 색상을 선택해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 24),
        PixelCharacterWidget(character: _draft, size: 140),
        const SizedBox(height: 28),
        
        if (_draft.gender == 'female' && _draft.eyeShapeIndex == 2) ...[
          // 여자 눈 03번(인덱스 2)은 디자이너 공지에 따라 단일 색상(선화)만 존재
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgPaper,
              border: Border.all(color: AppColors.lineSoft),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '선택하신 3번 눈동자는 단일 색상 렌더링을 지원합니다. ✦\n(색상 선택 없음)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSub, height: 1.4),
            ),
          )
        ] else ...[
          // 그 외의 눈동자는 8가지 색상 선택 지원
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemCount: CharacterDraft.eyeColors.length,
            itemBuilder: (context, index) {
              final colorHex = CharacterDraft.eyeColors[index];
              final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
              final isSelected = _draft.eyeColorIndex == index;
              final label = CharacterDraft.eyeColorLabels[index];

              return GestureDetector(
                onTap: () => setState(() => _draft = _draft.copyWith(eyeColorIndex: index)),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgDefault,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryPink : AppColors.lineSoft,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: AppColors.textMain,
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // 4. 헤어 스타일 선택 (1~8단계)
  Widget _buildHairStylePage() {
    return Column(
      children: [
        const Text('04 헤어 스타일을 선택해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 24),
        PixelCharacterWidget(character: _draft, size: 140),
        const SizedBox(height: 28),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            final isSelected = _draft.hairStyleIndex == index;
            // 각각의 헤어 스타일이 적용된 캐릭터 프리뷰 렌더링
            final previewChar = _draft.copyWith(hairStyleIndex: index);

            return GestureDetector(
              onTap: () => setState(() => _draft = _draft.copyWith(hairStyleIndex: index)),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryPink : AppColors.lineSoft,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: OverflowBox(
                          minHeight: 80,
                          maxHeight: 110,
                          child: Transform.translate(
                            offset: const Offset(0, -10), // 머리 부위가 도드라져 보이도록 위치 오프셋 조정
                            child: PixelCharacterWidget(character: previewChar, size: 65),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '스타일 ${index + 1}',
                        style: TextStyle(
                          fontSize: 9, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.textMain : AppColors.textSub
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 5. 헤어 컬러 선택 (10가지)
  Widget _buildHairColorPage() {
    return Column(
      children: [
        const Text('05 머리 색상을 선택해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 24),
        PixelCharacterWidget(character: _draft, size: 140),
        const SizedBox(height: 28),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.2,
          ),
          itemCount: CharacterDraft.hairColors.length,
          itemBuilder: (context, index) {
            final colorHex = CharacterDraft.hairColors[index];
            final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
            final isSelected = _draft.hairColorIndex == index;
            final label = CharacterDraft.hairColorLabels[index];

            return GestureDetector(
              onTap: () => setState(() => _draft = _draft.copyWith(hairColorIndex: index)),
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
                        border: Border.all(color: Colors.black26, width: 0.8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(index + 1).toString().padLeft(2, '0')} $label',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: AppColors.textMain,
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 6. 의상 선택 (3벌 중 1벌)
  Widget _buildClothesPage() {
    return Column(
      children: [
        const Text('06 의상을 선택해주세요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 24),
        PixelCharacterWidget(character: _draft, size: 140),
        const SizedBox(height: 28),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: 3,
          itemBuilder: (context, index) {
            final isSelected = _draft.topStyleIndex == index;
            final previewChar = _draft.copyWith(topStyleIndex: index);

            return GestureDetector(
              onTap: () => setState(() => _draft = _draft.copyWith(topStyleIndex: index)),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryPink : AppColors.lineSoft,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: OverflowBox(
                          minHeight: 110,
                          maxHeight: 140,
                          child: Transform.translate(
                            offset: const Offset(0, 15), // 의상 부위 크롭을 위해 오프셋 조정
                            child: PixelCharacterWidget(character: previewChar, size: 85),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        '의상 ${index + 1}',
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.textMain : AppColors.textSub
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 7. 캐릭터 미리보기
  Widget _buildPreviewPage() {
    return Column(
      children: [
        const Text('캐릭터 미리보기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 24),
        Container(
          width: 220,
          height: 260,
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PixelCharacterWidget(character: _draft, size: 155),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_outline, size: 16, color: AppColors.primaryPink),
              SizedBox(width: 8),
              Text(
                '나만의 전용 픽셀 아바타가 준비되었습니다!',
                style: TextStyle(fontSize: 11, color: AppColors.textSub, fontWeight: FontWeight.w500),
              )
            ],
          ),
        )
      ],
    );
  }

  // 7. 캐릭터 이름 설정
  Widget _buildNamePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('캐릭터 이름을 정해주세요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 24),
        const Text('이름 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSub)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: '이름을 입력해 주세요'),
        ),
        const SizedBox(height: 18),
        const Text('닉네임 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSub)),
        const SizedBox(height: 6),
        TextField(
          controller: _nicknameController,
          decoration: const InputDecoration(hintText: '닉네임을 입력해 주세요'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // 8. 생성 완료
  Widget _buildCompletePage() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          '꾸미기 완료!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textMain),
        ),
        const SizedBox(height: 24),
        Container(
          width: 230,
          height: 310,
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PixelCharacterWidget(character: _draft, size: 165),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgWarm,
                  border: Border.all(color: AppColors.lineSoft),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _nicknameController.text.trim().isEmpty ? '내 캐릭터' : _nicknameController.text.trim(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryPinkSoft.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.linePink),
          ),
          child: const Text(
            '이제 OOTD 다이어리 기록을 시작해볼까요?\n캘린더 탭에서 나만의 코디를 수집해 보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.primaryPink, fontWeight: FontWeight.bold, height: 1.4),
          ),
        )
      ],
    );
  }

  Widget _buildBottomCta() {
    String label = '다음 ➔';
    if (_currentStep == 0 || _currentStep == 9) {
      label = '시작하기';
    } else if (_currentStep == 7) {
      label = '다음';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentStep > 0 && _currentStep < 9) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _back,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgDefault,
                      foregroundColor: AppColors.textMain,
                      side: const BorderSide(color: AppColors.lineSoft),
                    ),
                    child: const Text('이전'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_currentStep == 0 || _currentStep == 9) 
                        ? AppColors.primaryPink 
                        : AppColors.primaryPurple,
                  ),
                  child: Text(label),
                ),
              ),
            ],
          ),
          if (_currentStep == 0) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _skipOnboarding,
              child: const Text(
                '스킵하고 기본 캐릭터로 시작하기 ➔',
                style: TextStyle(color: AppColors.textSub, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
