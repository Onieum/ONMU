import 'package:flutter/material.dart';
import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/pixel_character.dart';
import '../../../../shared/widgets/grid_background.dart';

class OotdDetailScreen extends StatelessWidget {
  final OotdRecord record;

  const OotdDetailScreen({super.key, required this.record});

  String get _recordTitle {
    final title = record.brands['title']?.trim();
    return title == null || title.isEmpty ? 'OOTD 기록' : title;
  }

  String _formatDateLabel(DateTime date) {
    final weekday = const ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
    return '${date.year}.${_twoDigits(date.month)}.${_twoDigits(date.day)} ($weekday)';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String get _moodLabel {
    return switch (record.mood.trim().toLowerCase()) {
      'happy' => '😊 신남',
      'excited' => '🥰 설렘',
      'calm' => '☕ 차분',
      'sad' => '🌧️ 차분',
      _ => '🙂 보통',
    };
  }

  String get _weatherLabel {
    return switch (record.weather.trim().toLowerCase()) {
      'sunny' => '맑음',
      'cloudy' => '구름',
      'rainy' || 'rain' => '비',
      'snowy' || 'snow' => '눈',
      _ => '날씨 미정',
    };
  }

  IconData get _weatherIcon {
    return switch (record.weather.trim().toLowerCase()) {
      'sunny' => Icons.wb_sunny,
      'rainy' || 'rain' => Icons.umbrella_outlined,
      'snowy' || 'snow' => Icons.ac_unit,
      _ => Icons.wb_cloudy_outlined,
    };
  }

  Color get _weatherColor {
    return switch (record.weather.trim().toLowerCase()) {
      'sunny' => AppColors.accentOrange,
      'rainy' || 'rain' => AppColors.accentBlue,
      'snowy' || 'snow' => AppColors.accentBlue,
      _ => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain),
          onPressed: () => context.popOrGo(RoutePaths.records),
        ),
        title: Text(
          '${record.date.year}.${record.date.month}.${record.date.day} 다이어리',
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
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
              SizedBox(height: 16),

              _buildStandardOotdDetail(),
              SizedBox(height: 24),

              // 3. 동행인 정보 & 날씨 & 기분
              _buildMetaStatsCard(),
              SizedBox(height: 24),

              // 4. 시간별 타임라인
              _buildTimelineListSection(),
              SizedBox(height: 40),
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
          Text(
            _formatDateLabel(record.date),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primaryPink,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _recordTitle,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textMain,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: record.moodTags.map((tag) {
              return Text(
                tag,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSub,
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
            SizedBox(height: 20),
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
                  Text(
                    'BRAND INFO 👕',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (record.brands.isEmpty)
                    Text(
                      '의상 정보가 비어있습니다.',
                      style: AppTextStyles.bodySmall.copyWith(
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
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSub,
                              ),
                            ),
                            Text(
                              e.value,
                              style: AppTextStyles.bodySmall.copyWith(
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
              Text(
                'WITH',
                style: AppTextStyles.sticker.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryPinkSoft,
                    child: Text(
                      '나',
                      style: AppTextStyles.sticker.copyWith(
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                ],
              ),
            ],
          ),
          // 기분
          Column(
            children: [
              Text(
                'MOOD',
                style: AppTextStyles.sticker.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _moodLabel,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          // 날씨
          Column(
            children: [
              Text(
                'WEATHER',
                style: AppTextStyles.sticker.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(_weatherIcon, size: 14, color: _weatherColor),
                  SizedBox(width: 4),
                  Text(
                    _weatherLabel,
                    style: AppTextStyles.labelMedium.copyWith(
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
        Text(
          '오늘 하루의 기록 상세 📍',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMain),
        ),
        SizedBox(height: 14),
        if (record.timeline.isEmpty)
          Text(
            '추가된 타임라인 경로가 없습니다.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
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
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                      SizedBox(width: 14),
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
                              style: AppTextStyles.bodySmall.copyWith(
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
