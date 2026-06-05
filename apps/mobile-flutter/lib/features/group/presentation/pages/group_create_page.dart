import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_scaffold.dart';
import '../../../../shared/widgets/pixel_avatar.dart';
import '../../view_model/group_create_view_model.dart';

class GroupCreatePage extends StatefulWidget {
  const GroupCreatePage({super.key, this.initialMemberNames = const []});

  final List<String> initialMemberNames;

  @override
  State<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _makeFirstPlanLater = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_sync);
    _descriptionController.addListener(_sync);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_sync)
      ..dispose();
    _descriptionController
      ..removeListener(_sync)
      ..dispose();
    super.dispose();
  }

  void _sync() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(groupCreateViewModelProvider);

        return state.when(
          data: (state) => OnmuScaffold(
            title: '온모임 만들기',
            showBackButton: true,
            onBack: () => context.go(RoutePaths.groups),
            useWarmBackground: false,
            bottom: OnmuPrimaryButton(
              label: '온모임 만들기',
              onPressed: _nameController.text.trim().isEmpty
                  ? null
                  : () async {
                      final created = await ref
                          .read(groupCreateViewModelProvider.notifier)
                          .createGroup(
                            name: _nameController.text,
                            description: _descriptionController.text,
                            memberNames: widget.initialMemberNames.isNotEmpty
                                ? widget.initialMemberNames
                                : state.recommendedMemberNames,
                          );
                      if (!context.mounted) {
                        return;
                      }
                      context.go(RoutePaths.groupDetail(created.id));
                    },
            ),
            children: [
              OnmuCard(
                backgroundColor: AppColors.bgDefault,
                borderColor: AppColors.lineSoft,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LabeledInput(
                      label: '모임 이름',
                      counter: '${_nameController.text.characters.length}/20',
                      child: TextField(
                        controller: _nameController,
                        maxLength: 20,
                        decoration: const InputDecoration(
                          hintText: '모임 이름을 입력하세요',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '멤버 초대',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InvitePreviewRow(
                      initialMemberNames: widget.initialMemberNames,
                      recommendedMemberNames: state.recommendedMemberNames,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '함께할 멤버를 선택해 주세요 (최대 20명)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _LabeledInput(
                      label: '모임 설명',
                      counter:
                          '${_descriptionController.text.characters.length}/100',
                      child: TextField(
                        controller: _descriptionController,
                        maxLength: 100,
                        minLines: 5,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: '모임을 소개해 주세요',
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OnmuCard(
                backgroundColor: AppColors.bgDefault,
                borderColor: AppColors.lineSoft,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '첫 약속은 나중에 만들기',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '지금은 모임만 만들고, 첫 약속은 나중에 만들 수 있어요.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSub),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _makeFirstPlanLater,
                      activeThumbColor: AppColors.primaryPink,
                      onChanged: (value) {
                        setState(() => _makeFirstPlanLater = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 72),
            ],
          ),
          loading: () => const OnmuScaffold(
            title: '온모임 만들기',
            children: [Center(child: CircularProgressIndicator())],
          ),
          error: (error, stackTrace) => OnmuScaffold(
            title: '온모임 만들기',
            children: [
              Text(
                '온모임 생성 정보를 불러오지 못했어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.counter,
    required this.child,
  });

  final String label;
  final String counter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Text(
              counter,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _InvitePreviewRow extends StatelessWidget {
  const _InvitePreviewRow({
    required this.initialMemberNames,
    required this.recommendedMemberNames,
  });

  final List<String> initialMemberNames;
  final List<String> recommendedMemberNames;

  @override
  Widget build(BuildContext context) {
    final memberNames = initialMemberNames.isNotEmpty
        ? initialMemberNames
        : recommendedMemberNames;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final name in memberNames) ...[
            _InviteAvatar(name: name),
            const SizedBox(width: AppSpacing.md),
          ],
          Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.lineBrown),
                ),
                child: const SizedBox.square(
                  dimension: 50,
                  child: Icon(Icons.add, color: AppColors.accentBrown),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('추가', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteAvatar extends StatelessWidget {
  const _InviteAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        children: [
          PixelAvatar(label: name, size: 50),
          const SizedBox(height: AppSpacing.xs),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
