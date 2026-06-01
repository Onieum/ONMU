import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';

enum PlaceRiskDialogKind { keyword, breakTime, closedDay }

class PlaceRisksPage extends StatelessWidget {
  const PlaceRisksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnmuScaffold(
      title: '운영 리스크',
      subtitle: '외부 API 검증 · 토요일 18:00 약속 기준',
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OnmuSecondaryButton(
                  label: '그래도 후보 추가',
                  icon: Icons.add_circle_outline,
                  onPressed: () => context.go(RoutePaths.placeCompare),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OnmuPrimaryButton(
                  label: '대체 후보',
                  icon: Icons.swap_horiz,
                  color: AppColors.primaryPurple,
                  foregroundColor: AppColors.textInverse,
                  onPressed: () => context.go(RoutePaths.placeSearch),
                ),
              ),
            ],
          ),
        ),
      ),
      children: [
        const _RiskPlaceHeader(),
        const SizedBox(height: AppSpacing.lg),
        Text('감지된 이슈', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final risk in demoPlaceRisks.take(2)) ...[
          _RiskIssueCard(risk: risk),
          const SizedBox(height: AppSpacing.md),
        ],
        Text('근거', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        const _EvidenceCard(),
        const SizedBox(height: AppSpacing.lg),
        Text('경고 모달 3종', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ActionChip(
              label: const Text('비선호 키워드'),
              onPressed: () => context.go(RoutePaths.placeRiskKeyword),
            ),
            ActionChip(
              label: const Text('브레이크 타임'),
              onPressed: () => context.go(RoutePaths.placeRiskBreakTime),
            ),
            ActionChip(
              label: const Text('휴무일'),
              onPressed: () => context.go(RoutePaths.placeRiskClosedDay),
            ),
          ],
        ),
      ],
    );
  }
}

class PlaceRiskDialogPreviewPage extends StatelessWidget {
  const PlaceRiskDialogPreviewPage({required this.kind, super.key});

  final PlaceRiskDialogKind kind;

  @override
  Widget build(BuildContext context) {
    final copy = _dialogCopy(kind);

    return OnmuScaffold(
      title: copy.pageTitle,
      subtitle: '장소 화면 배경 위에 뜨는 경고 모달 미리보기',
      children: [
        Stack(
          children: [
            Opacity(
              opacity: 0.42,
              child: Column(
                children: [
                  const _RiskPlaceHeader(),
                  const SizedBox(height: AppSpacing.md),
                  for (final candidate in demoPlaceCandidates.take(2)) ...[
                    OnmuCard(
                      backgroundColor: AppColors.bgDefault,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(candidate.name),
                        subtitle: Text(candidate.summary),
                        trailing: OnmuChip(
                          label: '${candidate.score.toInt()}점',
                          selected: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: _RiskDialogCard(copy: copy),
              ),
            ),
          ],
        ),
      ],
    );
  }

  _RiskDialogCopy _dialogCopy(PlaceRiskDialogKind kind) {
    return switch (kind) {
      PlaceRiskDialogKind.keyword => const _RiskDialogCopy(
        pageTitle: '비선호 키워드 경고',
        title: '싫어하는 키워드가 있어요',
        body: '하린이 피하고 싶은 견과류 메뉴가 리뷰에 반복해서 등장했어요.',
        primaryLabel: '그래도 추가',
        secondaryLabel: '취소',
        icon: Icons.favorite_border,
      ),
      PlaceRiskDialogKind.breakTime => const _RiskDialogCopy(
        pageTitle: '브레이크 타임 경고',
        title: '약속 시간이 브레이크 타임과 가까워요',
        body: '도착 예상 15:10, 브레이크 타임 15:00-16:30과 겹칠 수 있어요.',
        primaryLabel: '그래도 추가',
        secondaryLabel: '시간 변경',
        icon: Icons.access_time,
      ),
      PlaceRiskDialogKind.closedDay => const _RiskDialogCopy(
        pageTitle: '휴무일 경고',
        title: '약속 후보일에 쉬는 곳이에요',
        body: '하루정원은 월요일 휴무로 등록되어 있어 다른 날짜 확인이 필요해요.',
        primaryLabel: '그래도 추가',
        secondaryLabel: '날짜 변경',
        icon: Icons.event_busy,
      ),
    };
  }
}

class _RiskPlaceHeader extends StatelessWidget {
  const _RiskPlaceHeader();

  @override
  Widget build(BuildContext context) {
    final candidate = demoPlaceCandidates[1];

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineWarm,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${candidate.category} · ${candidate.distanceLabel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '토요일 18:00 약속 기준',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const OnmuChip(label: '중간 리스크', selected: true),
        ],
      ),
    );
  }
}

class _RiskIssueCard extends StatelessWidget {
  const _RiskIssueCard({required this.risk});

  final PlaceRisk risk;

  @override
  Widget build(BuildContext context) {
    final color = switch (risk.level) {
      PlaceRiskLevel.blocker => AppColors.accentOrange,
      PlaceRiskLevel.warning => AppColors.accentOrange,
      PlaceRiskLevel.notice => AppColors.accentBlue,
    };

    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.priority_high, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(risk.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(risk.description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard();

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '지도 API · 2026.05.19 갱신',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '장소 공지 링크 있음 · 신뢰도 0.72',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: const [
              OnmuChip(label: '공지 열기'),
              OnmuChip(label: '전화 확인'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskDialogCard extends StatelessWidget {
  const _RiskDialogCard({required this.copy});

  final _RiskDialogCopy copy;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.92,
      child: OnmuCard(
        backgroundColor: AppColors.bgDefault,
        borderColor: AppColors.linePink,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryPinkSoft,
              foregroundColor: AppColors.primaryPink,
              child: Icon(copy.icon),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(copy.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(copy.body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OnmuSecondaryButton(
                    label: copy.secondaryLabel,
                    onPressed: () => context.go(RoutePaths.placeRisks),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OnmuPrimaryButton(
                    label: copy.primaryLabel,
                    color: AppColors.primaryPink,
                    onPressed: () => context.go(RoutePaths.placeCompare),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskDialogCopy {
  const _RiskDialogCopy({
    required this.pageTitle,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.icon,
  });

  final String pageTitle;
  final String title;
  final String body;
  final String primaryLabel;
  final String secondaryLabel;
  final IconData icon;
}
