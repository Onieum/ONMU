import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class HomeRecentRecordsPage extends StatefulWidget {
  const HomeRecentRecordsPage({super.key});

  @override
  State<HomeRecentRecordsPage> createState() => _HomeRecentRecordsPageState();
}

class _HomeRecentRecordsPageState extends State<HomeRecentRecordsPage> {
  String _selectedFilter = '전체';

  List<_HomeRecord> get _records {
    final records = _createHomeRecords();
    if (_selectedFilter == '전체') {
      return records;
    }
    return records
        .where((record) => record.category == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;

    return OnmuScaffold(
      title: '최근 기록',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.home),
      action: IconButton(
        tooltip: '기록 필터',
        onPressed: () => _showSnack(context, '정렬과 검색은 다음 단계에서 연결할게요.'),
        icon: const Icon(Icons.tune),
      ),
      children: [
        _RecordHeader(totalCount: _createHomeRecords().length),
        const SizedBox(height: AppSpacing.lg),
        _RecordFilters(
          selected: _selectedFilter,
          onChanged: (value) => setState(() => _selectedFilter = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) =>
              _RecordGridCard(record: records[index]),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () => context.push(RoutePaths.records),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('기록 카드 만들기'),
        ),
      ],
    );
  }
}

class _RecordHeader extends StatelessWidget {
  const _RecordHeader({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PixelAvatar(label: '지', size: 48),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('대학 동기 여행단', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '사진 $totalCount장 · 메모 7개',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
              ),
            ],
          ),
        ),
        OnmuChip(label: '최근순', selected: true),
      ],
    );
  }
}

class _RecordFilters extends StatelessWidget {
  const _RecordFilters({required this.selected, required this.onChanged});

  List<String> _createFilters() => ['전체', '사진', '카페', '여행', '기타'];

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _createFilters()) ...[
            _FilterChipButton(
              label: filter,
              selected: selected == filter,
              onTap: () => onChanged(filter),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        onTap: onTap,
        child: OnmuChip(label: label, selected: selected),
      ),
    );
  }
}

class _RecordGridCard extends StatelessWidget {
  const _RecordGridCard({required this.record});

  final _HomeRecord record;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      onTap: () => _showSnack(context, '${record.title} 상세는 다음 단계에서 연결할게요.'),
      backgroundColor: AppColors.bgDefault,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PixelAvatar(label: record.author, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  record.author,
                  style: Theme.of(context).textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            record.title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            record.date,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _RecordImage(record: record)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              OnmuChip(label: record.category, selected: record.liked),
              const Spacer(),
              Icon(
                record.liked ? Icons.favorite : Icons.favorite_border,
                color: record.liked
                    ? AppColors.primaryPink
                    : AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordImage extends StatelessWidget {
  const _RecordImage({required this.record});

  final _HomeRecord record;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: record.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Icon(record.icon, size: 42, color: record.iconColor),
              ),
            ),
            Positioned(
              right: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bgDefault.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 12,
                        color: AppColors.primaryPink,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        record.likes,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeRecord {
  const _HomeRecord({
    required this.author,
    required this.title,
    required this.date,
    required this.category,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.likes,
    this.liked = false,
  });

  final String author;
  final String title;
  final String date;
  final String category;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String likes;
  final bool liked;
}

List<_HomeRecord> _createHomeRecords() {
  return [
    _HomeRecord(
      author: '지연',
      title: '성수동 카페',
      date: '2024.05.24',
      category: '카페',
      icon: Icons.local_cafe_outlined,
      backgroundColor: AppColors.photoFrameRoseBg,
      iconColor: AppColors.accentBrown,
      likes: '12',
      liked: true,
    ),
    _HomeRecord(
      author: '민수',
      title: '제주 바다',
      date: '2024.05.16',
      category: '여행',
      icon: Icons.water,
      backgroundColor: AppColors.calendarDateBlueBg,
      iconColor: AppColors.accentBlue,
      likes: '8',
    ),
    _HomeRecord(
      author: '하린',
      title: '전시회 다녀왔어요',
      date: '2024.05.10',
      category: '사진',
      icon: Icons.image_outlined,
      backgroundColor: AppColors.photoFrameGreenBg,
      iconColor: AppColors.accentGreen,
      likes: '5',
    ),
    _HomeRecord(
      author: '현우',
      title: '한강 피크닉',
      date: '2024.05.10',
      category: '기타',
      icon: Icons.park_outlined,
      backgroundColor: AppColors.photoFrameYellowBg,
      iconColor: AppColors.accentOrange,
      likes: '15',
      liked: true,
    ),
  ];
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
