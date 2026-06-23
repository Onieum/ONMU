import 'package:flutter/material.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../widgets/ootd_generated_image_view.dart';

class OotdDetailScreen extends StatelessWidget {
  final OotdRecord record;

  const OotdDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        title: const Text('OOTD 기록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _Header(record: record),
                    const SizedBox(height: 18),
                    _ScrapbookBoard(record: record),
                    const SizedBox(height: 16),
                    _RatingAndSuggestion(record: record),
                    const SizedBox(height: 16),
                    _BottomActions(recordId: record.id),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final OotdRecord record;

  const _Header({required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatDate(record.date),
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSub),
        ),
        const SizedBox(height: 8),
        Text(
          _brand(record, 'title', fallback: 'OOTD 기록'),
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: record.moodTags
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPinkSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _ScrapbookBoard extends StatelessWidget {
  final OotdRecord record;

  const _ScrapbookBoard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.lineSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GridBackground(
        gridSize: 18,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final avatar = _AvatarCard(record: record);
            final look = _PaperNote(
              title: "Today's Look",
              titleStyle: _NoteTitleStyle.hand,
              body: _brand(
                record,
                'todayLook',
                fallback: '오늘의 코디를 분석하고 있어요. 생성이 완료되면 룩 설명이 여기에 표시돼요.',
              ),
            );
            final hair = _PaperNote(
              title: 'HAIR',
              body: _brand(
                record,
                'hairNote',
                fallback: '오늘만 선택한 헤어 스타일과 컬러를 반영했어요.',
              ),
              tapeColor: const Color(0xFFFFD6C8),
            );
            final weather = _MiniStatusCard(
              title: 'WEATHER',
              icon: _weatherIcon(record.weather),
              value: _weatherLabel(record.weather),
            );
            final mood = _MiniStatusCard(
              title: 'MOOD',
              icon: _moodIcon(record.mood),
              value: _moodLabel(record.mood),
            );
            final point = _PaperNote(
              title: 'POINT',
              body: _brand(record, 'point', fallback: '오늘 코디의 포인트를 기록해 보세요.'),
              tapeColor: AppColors.primaryPinkSoft,
            );
            final outfit = _OutfitInfoCard(record: record);

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  look,
                  const SizedBox(height: 18),
                  avatar,
                  const SizedBox(height: 18),
                  hair,
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: mood),
                      const SizedBox(width: 10),
                      Expanded(child: weather),
                    ],
                  ),
                  const SizedBox(height: 12),
                  point,
                  const SizedBox(height: 16),
                  outfit,
                  const SizedBox(height: 18),
                  _TagSection(tags: record.moodTags),
                ],
              );
            }

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 9, child: look),
                    const SizedBox(width: 18),
                    Expanded(flex: 8, child: hair),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 8, child: mood),
                    Expanded(flex: 10, child: avatar),
                    Expanded(flex: 8, child: weather),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: point),
                    const SizedBox(width: 18),
                    Expanded(flex: 10, child: outfit),
                  ],
                ),
                const SizedBox(height: 22),
                _TagSection(tags: record.moodTags),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  final OotdRecord record;

  const _AvatarCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.bgWarm.withOpacity(0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.lineSoft),
      ),
      alignment: Alignment.center,
      child: OotdGeneratedImageView(
        record: record,
        characterSize: 220,
        height: 260,
      ),
    );
  }
}

class _PaperNote extends StatelessWidget {
  final String title;
  final String body;
  final Color tapeColor;
  final _NoteTitleStyle titleStyle;

  const _PaperNote({
    required this.title,
    required this.body,
    this.tapeColor = AppColors.primaryPinkSoft,
    this.titleStyle = _NoteTitleStyle.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: titleStyle == _NoteTitleStyle.hand
                    ? AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primaryPink,
                      )
                    : AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMain,
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMain,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -10,
          right: 18,
          child: Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 72,
              height: 18,
              decoration: BoxDecoration(
                color: tapeColor.withOpacity(0.78),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _NoteTitleStyle { label, hand }

class _MiniStatusCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;

  const _MiniStatusCard({
    required this.title,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSub),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, color: AppColors.primaryPink, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutfitInfoCard extends StatelessWidget {
  final OotdRecord record;

  const _OutfitInfoCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final items = [
      _OutfitItem(
        Icons.checkroom_outlined,
        'outer',
        _brand(record, 'outfitInfoOuter', fallback: 'AI 분석 대기 중'),
      ),
      _OutfitItem(
        Icons.dry_cleaning_outlined,
        'top',
        _brand(record, 'outfitInfoTop', fallback: 'AI 분석 대기 중'),
      ),
      _OutfitItem(
        Icons.accessibility_new_outlined,
        'bottom',
        _brand(record, 'outfitInfoBottom', fallback: 'AI 분석 대기 중'),
      ),
      _OutfitItem(
        Icons.work_outline,
        'bag',
        _brand(record, 'outfitInfoBag', fallback: 'AI 분석 대기 중'),
      ),
      _OutfitItem(
        Icons.ice_skating_outlined,
        'shoes',
        _brand(record, 'outfitInfoShoes', fallback: 'AI 분석 대기 중'),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryPinkSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'OUTFIT INFO',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, size: 22, color: AppColors.textSub),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMain,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: '${item.label}\n',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textMain,
                            ),
                          ),
                          TextSpan(text: item.value),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitItem {
  final IconData icon;
  final String label;
  final String value;

  const _OutfitItem(this.icon, this.label, this.value);
}

class _TagSection extends StatelessWidget {
  final List<String> tags;

  const _TagSection({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.lineSoft, style: BorderStyle.solid),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S TAG",
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMain),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPinkSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tag,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _RatingAndSuggestion extends StatelessWidget {
  final OotdRecord record;

  const _RatingAndSuggestion({required this.record});

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(_brand(record, 'rating')) ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘 코디는 어땠나요?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < rating.round() ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFB84D),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _brand(record, 'nextSuggestion', fallback: '다음 코디 메모를 남겨보세요.'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMain,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final String? recordId;

  const _BottomActions({required this.recordId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              if (recordId != null && recordId!.isNotEmpty) {
                Navigator.of(
                  context,
                ).pushNamed('${RoutePaths.records}/$recordId/edit');
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('수정하기'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined),
            label: const Text('저장하기'),
          ),
        ),
      ],
    );
  }
}

String _brand(OotdRecord record, String key, {String fallback = ''}) {
  final value = record.brands[key]?.trim();
  return value == null || value.isEmpty ? fallback : value;
}

String _formatDate(DateTime date) {
  const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return '${date.year}.${_two(date.month)}.${_two(date.day)} (${weekdays[date.weekday - 1]})';
}

String _two(int value) => value.toString().padLeft(2, '0');

String _weatherLabel(String weather) {
  return switch (weather.toLowerCase()) {
    'sunny' => '맑음',
    'cloudy' => '흐림',
    'rainy' || 'rain' => '비',
    'snowy' || 'snow' => '눈',
    _ => '맑음',
  };
}

IconData _weatherIcon(String weather) {
  return switch (weather.toLowerCase()) {
    'cloudy' => Icons.cloud_outlined,
    'rainy' || 'rain' => Icons.water_drop_outlined,
    'snowy' || 'snow' => Icons.ac_unit,
    _ => Icons.wb_sunny_outlined,
  };
}

String _moodLabel(String mood) {
  return switch (mood.toLowerCase()) {
    'excited' => '신남',
    'calm' => '평온',
    'tired' => '피곤',
    _ => '행복',
  };
}

IconData _moodIcon(String mood) {
  return switch (mood.toLowerCase()) {
    'excited' => Icons.celebration_outlined,
    'calm' => Icons.air,
    'tired' => Icons.mode_night_outlined,
    _ => Icons.sentiment_satisfied_alt_outlined,
  };
}
