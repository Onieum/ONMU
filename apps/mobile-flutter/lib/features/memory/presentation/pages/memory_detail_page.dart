// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../../../shared/widgets/pixel_character.dart';
import '../../../../shared/providers/state_providers.dart';

class MemoryDetailPage extends ConsumerWidget {
  final String memoryId;

  const MemoryDetailPage({super.key, required this.memoryId});

  // Mock records generator helper (matching the ones in OotdListPage)
  List<OotdRecord> _getMockRecords(CharacterDraft baseChar) {
    return [
      OotdRecord(
        date: DateTime(2026, 10, 1),
        character: baseChar.copyWith(
          accessoryStyleIndex: 1,
          topStyleIndex: 1,
          bottomStyleIndex: 2,
        ),
        moodTags: ['#아메카지', '#캐주얼', '#가을코디'],
        brands: {'모자': '스투시', '상의': '칼하트 후드', '하의': '디키즈 874'},
        weather: 'cloudy',
        mood: 'calm',
        isPublic: false,
        timeline: [
          const TimelineItem(
            time: '12:00',
            placeName: '삼청동 손칼국수',
            category: 'restaurant',
            description: '가을 날씨에 딱 어울리는 뜨끈한 국물',
          ),
          const TimelineItem(
            time: '14:30',
            placeName: '국립현대미술관',
            category: 'museum',
            description: '전시회 구경. 역시 힐링되는 미술관 투어',
          ),
        ],
      ),
      OotdRecord(
        date: DateTime(2026, 10, 2),
        character: baseChar.copyWith(
          hairStyleIndex: 1,
          topStyleIndex: 0,
          bottomStyleIndex: 1,
        ),
        moodTags: ['#오피스룩', '#블라우스', '#출근룩'],
        brands: {'상의': '자라 블라우스', '하의': '슬랙스'},
        weather: 'sunny',
        mood: 'happy',
        isPublic: false,
        timeline: [
          const TimelineItem(
            time: '09:00',
            placeName: '온무 사무실',
            category: 'work',
            description: '업무 시작!',
          ),
          const TimelineItem(
            time: '12:30',
            placeName: '카페 아우어',
            category: 'cafe',
            description: '시그니처 빵 최고',
          ),
        ],
      ),
      OotdRecord(
        date: DateTime(2026, 10, 3),
        character: baseChar.copyWith(
          hairStyleIndex: 2,
          topStyleIndex: 1,
          bottomStyleIndex: 1,
          hairColorIndex: 1,
        ),
        moodTags: ['#카페투어', '#한남동', '#데이트룩', '#ootd', '#Archive한남'],
        brands: {
          'outer': '베이지 하프코트',
          'top': '아이보리 니트',
          'bottom': '블랙 롱 스커트',
          'bag': '버건디 숄더백',
          'shoes': '화이트 삭스 + 로퍼',
        },
        weather: 'sunny',
        mood: 'happy',
        isPublic: true,
        timeline: [
          const TimelineItem(
            time: '13:00',
            placeName: 'mRd Record',
            category: 'cafe',
            description: '케이크가 진짜 맛있었고 매장 분위기도 너무 좋았어! 사진도 많이 찍음 ㅎㅎ',
          ),
          const TimelineItem(
            time: '15:30',
            placeName: 'Archive Hannam',
            category: 'shopping',
            description: '편집숍 구경 넘 재밌었고 여기 향수 시향했는데 향이 너무 좋았음!',
          ),
          const TimelineItem(
            time: '18:00',
            placeName: 'Ofr. seoul',
            category: 'cafe',
            description: '성수동으로 넘어가서 오랜만에 구경하고 달달한 플랫화이트 한 잔의 여유',
          ),
          const TimelineItem(
            time: '20:00',
            placeName: '성수 맛집',
            category: 'restaurant',
            description: '저녁으로 예약해둔 파스타 맛집. 분위기도 음식도 진짜 최고였어!',
          ),
        ],
      ),
      OotdRecord(
        date: DateTime(2026, 10, 4),
        character: baseChar.copyWith(topStyleIndex: 2, bottomStyleIndex: 0),
        moodTags: ['#러블리', '#데이트룩', '#주말나들이'],
        brands: {'상의': '폴로 가디건', '하의': '청치마'},
        weather: 'sunny',
        mood: 'happy',
        isPublic: true,
        timeline: [
          const TimelineItem(
            time: '14:00',
            placeName: '서울숲 공원',
            category: 'walk',
            description: '서울숲 피크닉. 가을 바람이 시원함',
          ),
        ],
      ),
    ];
  }

  OotdRecord? _findRecord(WidgetRef ref, String key) {
    final character = ref.read(userCharacterProvider) ?? const CharacterDraft();
    final customRecords = ref.read(customRecordsProvider);
    final mockRecords = _getMockRecords(character);

    final allRecords = [...mockRecords, ...customRecords];

    try {
      return allRecords.firstWhere((r) {
        final type = r.brands['recordType'] ?? 'ootd';
        final k = '${r.date.year}-${r.date.month}-${r.date.day}-$type';
        return k == key;
      });
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = _findRecord(ref, memoryId);

    if (record == null) {
      return Scaffold(
        backgroundColor: AppColors.bgWarm,
        appBar: AppBar(title: const Text('기록을 찾을 수 없음')),
        body: const Center(child: Text('해당하는 다이어리 기록이 존재하지 않습니다.')),
      );
    }

    final isDaily = record.brands['recordType'] == 'daily';

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textMain,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isDaily ? '하루 기억 상세' : 'OOTD 상세 기록',
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: isDaily
                      ? _buildDailyTimelineView(context, record)
                      : _buildOotdDetailView(record),
                ),
              ),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // 1. 하루 일과 상세 구현
  Widget _buildDailyTimelineView(BuildContext context, OotdRecord record) {
    final isDiaryTheme = record.brands['theme'] == 'diary';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 메인 다이어리 제목 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                isDiaryTheme ? '오늘의 소중한 다이어리' : '하루 일과 기록',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: record.moodTags
                    .map(
                      (tag) => Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSub,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 타임라인 리스트
        ...record.timeline.asMap().entries.map((entry) {
          final item = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPinkSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.placeName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 11,
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
        }),
        const SizedBox(height: 16),

        // 캐릭터 배치 영역
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown, width: 1.2),
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
                        size: 72,
                      ),
                      const SizedBox(height: 6),
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
                  if (record.brands['crew'] == 'included') ...[
                    const SizedBox(width: 26),
                    const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.accentRed,
                      size: 28,
                    ),
                    const SizedBox(width: 26),
                    Column(
                      children: [
                        PixelCharacterWidget(
                          character: record.character.copyWith(
                            hairColorIndex: 4,
                            topStyleIndex: 1,
                          ),
                          size: 72,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '크루원',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '기분: ${record.mood} · 날씨: ${record.weather}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. OOTD 상세 구현
  Widget _buildOotdDetailView(OotdRecord record) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineBrown, width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽 정보
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Look',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryPink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bgWarm,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.lineSoft),
                      ),
                      child: Text(
                        record.timeline.isNotEmpty
                            ? record.timeline.first.description
                            : '즐겁게 기록한 OOTD 스타일링!',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSub,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'MOOD',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🥰 ${record.mood}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 가운데 캐릭터
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    PixelCharacterWidget(
                      character: record.character,
                      size: 110,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 오른쪽 날씨
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WEATHER',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.wb_sunny_outlined,
                          size: 12,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.weather,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 해시태그 목록
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: record.moodTags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryPinkSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.linePink.withOpacity(0.4)),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPink,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.bgWarm,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/memories/$memoryId/template-diary');
              },
              icon: const Icon(Icons.palette_outlined, size: 16),
              label: const Text('다이어리 꾸미기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
