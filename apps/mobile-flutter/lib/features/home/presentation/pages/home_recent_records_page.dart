import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../view_model/home_view_model.dart';
import '../widgets/home_recent_record_cards.dart';

class HomeRecentRecordsPage extends ConsumerWidget {
  const HomeRecentRecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(homeRecentRecordsProvider);

    return OnmuScaffold(
      title: '최근 기록',
      showBackButton: true,
      onBack: () => context.popOrGo(RoutePaths.home),
      children: [
        records.when(
          data: (records) {
            if (records.isEmpty) {
              return const HomeRecentRecordsEmptyCard();
            }
            return Column(
              children: [
                for (final record in records) ...[
                  HomeRecentRecordCard(
                    record: record,
                    onTap: record.id == null
                        ? null
                        : () =>
                              context.push(RoutePaths.recordDetail(record.id!)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const HomeRecentRecordsEmptyCard(),
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
