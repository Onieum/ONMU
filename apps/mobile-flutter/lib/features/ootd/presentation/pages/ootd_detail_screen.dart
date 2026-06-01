// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/pixel_character.dart';
import '../../../../shared/widgets/grid_background.dart';

class OotdDetailScreen extends StatelessWidget {
  final OotdRecord record;

  const OotdDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    // 10월 3일 '서울 카페 투어' 레코드에 대한 특별 콜라주 레이아웃 활성화
    final isSpecialCollage =
        record.moodTags.contains('#서울카페투어') ||
        (record.date.month == 10 && record.date.day == 3);

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${record.date.year}.${record.date.month}.${record.date.day} 다이어리',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textMain),
            onPressed: () {},
          ),
        ],
      ),
      body: GridBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 헤더 영역 (기록 제목 & 날짜)
              _buildTitleHeader(),
              const SizedBox(height: 16),

              if (isSpecialCollage) ...[
                // 피그마 시안과 일치하는 스크랩북 콜라주 레이아웃
                _buildScrapbookCollage(),
              ] else ...[
                // 일반 OOTD 상세 레이아웃
                _buildStandardOotdDetail(),
              ],
              const SizedBox(height: 24),

              // 3. 동행인 정보 & 날씨 & 기분
              _buildMetaStatsCard(),
              const SizedBox(height: 24),

              // 4. 시간별 타임라인
              _buildTimelineListSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleHeader() {
    return Center(
      child: Column(
        children: [
          const Text(
            '📝 2026.10.03 (SAT) 💖',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryPink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '서울 카페 투어 ☕',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: record.moodTags.map((tag) {
              return Text(
                tag,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSub,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 10월 3일 전용: 피그마 시안의 '아기자기한 스크랩북' 콜라주 구현
  Widget _buildScrapbookCollage() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 상단: 케이크 폴라로이드 카드 (mRd Record)
            Expanded(
              flex: 5,
              child: _buildPolaroidPhoto(
                title: 'PLACE 01 - mRd Record',
                description: '케이크가 진짜 맛있었고 매장 분위기도 너무 좋았어! 🍰',
                imageColor: const Color(0xFFFCE4EC),
                emoji: '🍰',
              ),
            ),
            const SizedBox(width: 12),
            // 오른쪽 상단: 편집숍 폴라로이드 카드 (Archive Hannam)
            Expanded(
              flex: 5,
              child: _buildPolaroidPhoto(
                title: 'PLACE 02 - Archive Hannam',
                description: '편집숍 구경 넘 재밌었고 시향해본 향수 취향 저격!',
                imageColor: const Color(0xFFE8F5E9),
                emoji: '🛍️',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 중앙: '나 & 지훈' standing 픽셀 아바타 커플 렌더링!
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown.withOpacity(0.5)),
            image: const DecorationImage(
              image: AssetImage('assets/images/dots.png'), // 모눈 배경 스타일
              repeat: ImageRepeat.repeat,
              opacity: 0.05,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      PixelCharacterWidget(
                        character: record.character,
                        size: 70,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '나',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  const Icon(
                    Icons.favorite,
                    color: AppColors.accentRed,
                    size: 24,
                  ),
                  const SizedBox(width: 24),
                  Column(
                    children: [
                      // 동행 캐릭터 (지훈 - 남성 숏컷 프리셋)
                      PixelCharacterWidget(
                        character: CharacterDraft(
                          gender: 'male',
                          nickname: '지훈',
                          hairStyleIndex: 2,
                          hairColorIndex: 1,
                          skinToneIndex: 1,
                          topStyleIndex: 1,
                          bottomStyleIndex: 0,
                        ),
                        size: 70,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '지훈',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 하트 말풍선 데코
              const Text(
                '우리의 가을 시밀러 룩 데이트! 💕',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 하단: 커피 컵 폴라로이드 카드 (Ofr. seoul)
            Expanded(
              flex: 5,
              child: _buildPolaroidPhoto(
                title: 'PLACE 03 - Ofr. seoul',
                description: '성수동으로 넘어와서 먹은 고소한 플랫화이트 ☕',
                imageColor: const Color(0xFFEFFFFA),
                emoji: '☕',
              ),
            ),
            const SizedBox(width: 12),
            // 오른쪽 하단: 저녁 파스타 카드
            Expanded(
              flex: 5,
              child: _buildPolaroidPhoto(
                title: 'EVENING - 성수 맛집',
                description: '예약해 둔 저녁 파스타! 분위기 맛 다 완벽해 🍝',
                imageColor: const Color(0xFFFFFDE7),
                emoji: '🍝',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 일반적인 OOTD 화면
  Widget _buildStandardOotdDetail() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgPaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lineBrown, width: 1.5),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 옷장 사진 대체용 캐릭터 빅 렌더링
                PixelCharacterWidget(character: record.character, size: 140),
                // 마스킹 테이프 장식 데코
                Positioned(
                  top: 0,
                  child: Container(
                    width: 60,
                    height: 14,
                    color: AppColors.accentOrange.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 브랜드 리스트박스
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgDefault,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lineSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BRAND INFO 👕',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (record.brands.isEmpty)
                    const Text(
                      '의상 정보가 비어있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    )
                  else
                    ...record.brands.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              '${e.key}: ',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSub,
                              ),
                            ),
                            Text(
                              e.value,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 폴라로이드 사진 카드 생성 함수
  Widget _buildPolaroidPhoto({
    required String title,
    required String description,
    required Color imageColor,
    required String emoji,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lineSoft, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 스냅 사진 영역 (컬러 플레이스홀더)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: imageColor,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSub,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 동행
          Column(
            children: [
              const Text(
                'WITH',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryPinkSoft,
                    child: Text(
                      '나',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (record.moodTags.contains('#데이트'))
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primaryPurpleSoft,
                      child: Text(
                        '지훈',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // 기분
          Column(
            children: [
              const Text(
                'MOOD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                record.mood == 'happy'
                    ? '😊 신남'
                    : record.mood == 'excited'
                    ? '🥰 데이트'
                    : '☕ 차분',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          // 날씨
          Column(
            children: [
              const Text(
                'WEATHER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    record.weather == 'sunny'
                        ? Icons.wb_sunny
                        : Icons.wb_cloudy_outlined,
                    size: 14,
                    color: record.weather == 'sunny'
                        ? AppColors.accentOrange
                        : AppColors.accentBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.weather == 'sunny' ? '맑음 20°C' : '구름',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘 하루의 기록 상세 📍',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 14),
        if (record.timeline.isEmpty)
          const Text(
            '추가된 타임라인 경로가 없습니다.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: record.timeline.length,
            itemBuilder: (context, index) {
              final item = record.timeline[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurpleSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.time,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.placeName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSub,
                                height: 1.4,
                              ),
                            ),
                          ],
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
}
