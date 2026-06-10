import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/navigation_extensions.dart';
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
  final List<String> _invitedMemberNames = [];
  bool _makeFirstPlanLater = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_sync);
    _descriptionController.addListener(_sync);
    _invitedMemberNames.addAll(widget.initialMemberNames);
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

  List<String> _memberNamesFor(GroupCreateState state) {
    if (_invitedMemberNames.isNotEmpty) {
      return List.unmodifiable(_invitedMemberNames);
    }
    return state.recommendedMemberNames;
  }

  Future<void> _openMemberAddSheet(
    BuildContext context,
    GroupCreateState state,
  ) async {
    final currentNames = _memberNamesFor(state);
    if (currentNames.length >= 20) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('멤버는 최대 20명까지 초대할 수 있어요.')));
      return;
    }

    final memberName = await _showMemberAddSheet(context);
    if (!mounted || memberName == null) {
      return;
    }

    final trimmedName = memberName.trim();
    if (trimmedName.isEmpty) {
      return;
    }
    if (currentNames.contains(trimmedName)) {
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(const SnackBar(content: Text('이미 추가된 멤버예요.')));
      return;
    }

    setState(() {
      if (_invitedMemberNames.isEmpty) {
        _invitedMemberNames.addAll(state.recommendedMemberNames);
      }
      _invitedMemberNames.add(trimmedName);
    });
  }

  Future<String?> _showMemberAddSheet(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDefault,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => const _MemberAddSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(groupCreateViewModelProvider);

        return state.when(
          data: (state) {
            final memberNames = _memberNamesFor(state);

            return OnmuScaffold(
              title: '온모임 만들기',
              showBackButton: true,
              onBack: () => context.popOrGo(RoutePaths.groups),
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
                              memberNames: memberNames,
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
                        memberNames: memberNames,
                        onAddPressed: () => _openMemberAddSheet(context, state),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '함께할 멤버를 선택해 주세요 (최대 20명)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSub,
                        ),
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
            );
          },
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

class _MemberAddSheet extends StatefulWidget {
  const _MemberAddSheet();

  @override
  State<_MemberAddSheet> createState() => _MemberAddSheetState();
}

class _MemberAddSheetState extends State<_MemberAddSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('멤버 추가', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '초대할 멤버 이름을 입력해 주세요.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 20,
              decoration: const InputDecoration(
                hintText: '이름을 입력하세요',
                counterText: '',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('추가하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitePreviewRow extends StatelessWidget {
  const _InvitePreviewRow({
    required this.memberNames,
    required this.onAddPressed,
  });

  final List<String> memberNames;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final name in memberNames) ...[
            _InviteAvatar(name: name),
            const SizedBox(width: AppSpacing.md),
          ],
          Material(
            color: AppColors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: onAddPressed,
              child: Column(
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
            ),
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
