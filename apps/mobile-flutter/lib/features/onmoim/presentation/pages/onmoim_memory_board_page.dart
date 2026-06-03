import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/onmoim_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';

class OnMoimMemoryBoardPage extends StatelessWidget {
  const OnMoimMemoryBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final group = demoOnMoimGroups.first;

    return OnmuScaffold(
      title: group.name,
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
          return;
        }

        context.go(RoutePaths.onmoimDemo);
      },
      action: IconButton(
        tooltip: '기록 옵션',
        onPressed: () => context.go(RoutePaths.onmoimSettings(group.id)),
        icon: const Icon(Icons.more_vert),
      ),
      useWarmBackground: false,
      children: [
        _GroupTabs(group: group),
        const SizedBox(height: AppSpacing.md),
        const _MemoryFilterRow(),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.63,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var index = 0; index < demoOnMoimMemories.length; index += 1)
              _MemoryCard(memory: demoOnMoimMemories[index], photoIndex: index),
          ],
        ),
        const SizedBox(height: 72),
      ],
    );
  }
}

class _GroupTabs extends StatelessWidget {
  const _GroupTabs({required this.group});

  final OnMoimGroup group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GroupTab(
          label: '약속',
          selected: false,
          onTap: () => context.go(RoutePaths.onmoimDetail(group.id)),
        ),
        _GroupTab(label: '기록', selected: true, onTap: () {}),
        _GroupTab(
          label: '채팅',
          selected: false,
          onTap: () => context.go(RoutePaths.onmoimChat(group.id)),
        ),
      ],
    );
  }
}

class _GroupTab extends StatelessWidget {
  const _GroupTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primaryPink : AppColors.lineSoft,
                width: selected ? 3 : 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? AppColors.textMain : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryFilterRow extends StatelessWidget {
  const _MemoryFilterRow();

  @override
  Widget build(BuildContext context) {
    const filters = ['전체', '사진', '카페', '여행', '기타'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index += 1) ...[
            _MemoryFilterChip(label: filters[index], selected: index == 0),
            if (index != filters.length - 1)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _MemoryFilterChip extends StatelessWidget {
  const _MemoryFilterChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.bgDefault : AppColors.bgWarm,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: selected ? AppColors.lineBrown : AppColors.lineSoft,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? AppColors.textMain : AppColors.textSub,
          ),
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory, required this.photoIndex});

  final OnMoimMemoryRecord memory;
  final int photoIndex;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxs,
              AppSpacing.xxs,
              AppSpacing.xxs,
              0,
            ),
            child: Row(
              children: [
                PixelAvatar(label: memory.author, size: 24),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  memory.author,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              memory.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              memory.dateLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _MemoryPhoto(index: photoIndex),
                  Positioned(
                    right: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.bgDefault.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxs),
                        child: Icon(
                          Icons.favorite,
                          size: 18,
                          color: photoIndex == 3
                              ? AppColors.accentRed
                              : AppColors.textInverse,
                        ),
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

class _MemoryPhoto extends StatelessWidget {
  const _MemoryPhoto({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MemoryPhotoPainter(index));
  }
}

class _MemoryPhotoPainter extends CustomPainter {
  const _MemoryPhotoPainter(this.index);

  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    void rect(Rect rect, Color color) {
      paint.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
    }

    switch (index % 4) {
      case 0:
        rect(Offset.zero & size, const Color(0xFFF5E4D2));
        rect(
          Rect.fromLTWH(
            size.width * 0.08,
            size.height * 0.1,
            size.width * 0.44,
            size.height * 0.44,
          ),
          const Color(0xFFE2C3A7),
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.58,
            size.height * 0.12,
            size.width * 0.3,
            size.height * 0.34,
          ),
          const Color(0xFFD9EDF0),
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.14,
            size.height * 0.62,
            size.width * 0.72,
            size.height * 0.16,
          ),
          const Color(0xFFC69A76),
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.2,
            size.height * 0.5,
            size.width * 0.22,
            size.height * 0.2,
          ),
          const Color(0xFFFFFAF3),
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.52,
            size.height * 0.48,
            size.width * 0.2,
            size.height * 0.22,
          ),
          const Color(0xFF8B5E3C),
        );
        break;
      case 1:
        rect(Offset.zero & size, const Color(0xFFCDEAF6));
        rect(
          Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.24),
          const Color(0xFF72B7D9),
        );
        rect(
          Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
          const Color(0xFFEFDAB5),
        );
        paint
          ..color = AppColors.bgDefault.withValues(alpha: 0.75)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;
        final wave = Path()
          ..moveTo(size.width * 0.1, size.height * 0.55)
          ..quadraticBezierTo(
            size.width * 0.28,
            size.height * 0.47,
            size.width * 0.48,
            size.height * 0.55,
          )
          ..quadraticBezierTo(
            size.width * 0.68,
            size.height * 0.64,
            size.width * 0.9,
            size.height * 0.54,
          );
        canvas.drawPath(wave, paint);
        paint.style = PaintingStyle.fill;
        break;
      case 2:
        rect(Offset.zero & size, const Color(0xFFEDE1D8));
        rect(
          Rect.fromLTWH(
            size.width * 0.18,
            size.height * 0.12,
            size.width * 0.58,
            size.height * 0.48,
          ),
          AppColors.bgDefault,
        );
        rect(
          Rect.fromLTWH(
            size.width * 0.26,
            size.height * 0.2,
            size.width * 0.42,
            size.height * 0.32,
          ),
          const Color(0xFFC6B8AE),
        );
        rect(
          Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
          const Color(0xFFBFAF9E),
        );
        break;
      default:
        rect(Offset.zero & size, const Color(0xFFD7EEF8));
        rect(
          Rect.fromLTWH(0, size.height * 0.58, size.width, size.height * 0.42),
          const Color(0xFFA7C38E),
        );
        rect(
          Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.18),
          const Color(0xFF93BDD7),
        );
        for (final x in [0.14, 0.34, 0.68]) {
          paint.color = const Color(0xFF6F8D62);
          canvas.drawCircle(
            Offset(size.width * x, size.height * 0.45),
            size.width * 0.12,
            paint,
          );
          rect(
            Rect.fromLTWH(
              size.width * x - 3,
              size.height * 0.48,
              6,
              size.height * 0.26,
            ),
            const Color(0xFF8B6A4D),
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MemoryPhotoPainter oldDelegate) =>
      oldDelegate.index != index;
}
