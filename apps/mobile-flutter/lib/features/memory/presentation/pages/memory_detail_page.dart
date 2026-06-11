import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../../../shared/widgets/pixel_character.dart';
import '../../../ootd/repository/record_repository.dart';

class MemoryDetailPage extends ConsumerWidget {
  final String memoryId;

  const MemoryDetailPage({super.key, required this.memoryId});

  OotdRecord? _findRecord(WidgetRef ref, String key) {
    final records = ref.watch(ootdRecordsProvider).value ?? const <OotdRecord>[];

    try {
      return records.firstWhere((r) {
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
        appBar: AppBar(title: Text('기록을 찾을 수 없음')),
        body: Center(child: Text('해당하는 다이어리 기록이 존재하지 않습니다.')),
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
          onPressed: () => context.popOrGo(RoutePaths.records),
        ),
        title: Text(
          isDaily ? '하루 기억 상세' : 'OOTD 상세 기록',
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
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
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: record.moodTags
                    .map(
                      (tag) => Text(
                        tag,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSub,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

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
                    style: AppTextStyles.sticker.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.placeName,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        item.description,
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
          );
        }),
        SizedBox(height: 16),

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
                      SizedBox(height: 6),
                      Text(
                        '나',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  if (record.brands['crew'] == 'included') ...[
                    SizedBox(width: 26),
                    const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.accentRed,
                      size: 28,
                    ),
                    SizedBox(width: 26),
                    Column(
                      children: [
                        PixelCharacterWidget(
                          character: record.character.copyWith(
                            hairColorIndex: 4,
                            topStyleIndex: 1,
                          ),
                          size: 72,
                        ),
                        SizedBox(height: 6),
                        Text(
                          '크루원',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12),
              Text(
                '기분: ${record.mood} · 날씨: ${record.weather}',
                style: AppTextStyles.labelLarge.copyWith(
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
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽 정보
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Look',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primaryPink,
                          ),
                        ),
                        SizedBox(height: 8),
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
                            style: AppTextStyles.sticker.copyWith(
                              color: AppColors.textSub,
                              height: 1.35,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text('MOOD', style: AppTextStyles.micro),
                        SizedBox(height: 4),
                        Text('🥰 ${record.mood}', style: AppTextStyles.sticker),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),

                  // 가운데 캐릭터
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        PixelCharacterWidget(
                          character: record.character,
                          size: 110,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),

                  // 오른쪽 날씨
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WEATHER', style: AppTextStyles.micro),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.wb_sunny_outlined,
                              size: 12,
                              color: AppColors.accentOrange,
                            ),
                            SizedBox(width: 4),
                            Text(record.weather, style: AppTextStyles.tiny),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (record.brands['스타일 컨셉'] != null ||
                  record.brands['장소'] != null ||
                  record.brands['rating'] != null) ...[
                const Divider(height: 24, color: AppColors.lineSoft),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (record.brands['스타일 컨셉'] != null ||
                        record.brands['장소'] != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '스타일 컨셉 / TPO',
                              style: AppTextStyles.tiny.copyWith(
                                color: AppColors.textSub,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${record.brands['스타일 컨셉'] ?? record.brands['장소']}',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (record.brands['rating'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '별점',
                            style: AppTextStyles.tiny.copyWith(
                              color: AppColors.textSub,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  final ratingVal =
                                      double.tryParse(
                                        record.brands['rating'].toString(),
                                      ) ??
                                      5.0;
                                  return Icon(
                                    index < ratingVal.floor()
                                        ? Icons.star_rounded
                                        : (index < ratingVal
                                              ? Icons.star_half_rounded
                                              : Icons.star_outline_rounded),
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${record.brands['rating']}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16),

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
                style: AppTextStyles.sticker.copyWith(
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
                context.push(RoutePaths.recordDiaryTemplate(memoryId));
              },
              icon: const Icon(Icons.palette_outlined, size: 16),
              label: Text('다이어리 꾸미기'),
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
