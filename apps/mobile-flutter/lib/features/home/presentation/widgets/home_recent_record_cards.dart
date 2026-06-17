import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/ootd_model.dart';
import '../../../../shared/widgets/onmu_card.dart';

class HomeRecentRecordCard extends StatelessWidget {
  const HomeRecentRecordCard({required this.record, super.key, this.onTap});

  final OotdRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = homeRecentRecordTitle(record);
    final subtitle = homeRecentRecordSubtitle(record);

    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryPinkSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox.square(
              dimension: 44,
              child: Icon(
                Icons.photo_library_outlined,
                color: AppColors.primaryPink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.moodTags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    record.moodTags.take(3).map((tag) => '#$tag').join(' '),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryPurple,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeRecentRecordsEmptyCard extends StatelessWidget {
  const HomeRecentRecordsEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.photo_library_outlined, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text('최근 기록이 없어요.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '기록을 만들면 이곳에 표시돼요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

String homeRecentRecordTitle(OotdRecord record) {
  final title = record.brands['title']?.trim();
  if (title != null && title.isNotEmpty) {
    return title;
  }
  if (record.timeline.isNotEmpty) {
    final placeName = record.timeline.first.placeName.trim();
    if (placeName.isNotEmpty) {
      return placeName;
    }
  }
  return record.brands['recordType'] == 'daily' ? '하루 기록' : 'OOTD 기록';
}

String homeRecentRecordSubtitle(OotdRecord record) {
  final date = record.date.toLocal();
  final dateLabel = '${date.month}월 ${date.day}일';
  if (record.timeline.isNotEmpty) {
    final description = record.timeline.first.description.trim();
    if (description.isNotEmpty) {
      return '$dateLabel · $description';
    }
  }
  return dateLabel;
}
