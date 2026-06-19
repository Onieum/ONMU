part of 'my_page.dart';

class _FriendProfilePage extends ConsumerStatefulWidget {
  const _FriendProfilePage({required this.friend});

  final FriendProfile friend;

  @override
  ConsumerState<_FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends ConsumerState<_FriendProfilePage> {
  late String _memo;

  @override
  void initState() {
    super.initState();
    _memo = widget.friend.memo;
  }

  @override
  void didUpdateWidget(covariant _FriendProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.friend.publicId != widget.friend.publicId) {
      _memo = widget.friend.memo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(friendProfileProvider(widget.friend));

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: GridBackground(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: _FriendProfileTopBar(
                    onBack: () => Navigator.of(context).pop(),
                    onEditMemo: () => _editFriendMemo(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                sliver: SliverToBoxAdapter(
                  child: profileAsync.when(
                    data: (profile) => Column(
                      children: [
                        _FriendProfileHero(
                          friend: widget.friend.copyWith(memo: _memo),
                          profile: profile,
                          onDelete: () => _deleteFriend(context),
                          onCreatePlan: () => context.go(
                            RoutePaths.groupNew,
                            extra: [widget.friend.name],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (profile.visibility == ProfileVisibility.private)
                          const _PrivateFriendProfileNotice()
                        else
                          _ProfileTab(
                            profile: profile,
                            onKeywordEdit: () {},
                            onScheduleEdit: () {},
                            onPlaceEdit: () {},
                            onDetail: (section) => _openFriendProfileDetail(
                              context,
                              section,
                              profile,
                            ),
                            showActions: false,
                          ),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => _FriendProfileErrorCard(
                      friend: widget.friend.copyWith(memo: _memo),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFriend(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(friendRepositoryProvider).deleteFriend(widget.friend);
      ref.invalidate(friendsProvider);
      ref.invalidate(friendProfileProvider(widget.friend));
      if (!context.mounted) {
        return;
      }
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('친구를 삭제했어요.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showFriendMessage(context, '친구 삭제에 실패했어요. 다시 시도해주세요.');
    }
  }

  Future<void> _editFriendMemo(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final memo = await showDialog<String>(
      context: context,
      builder: (context) => _FriendMemoDialog(initialMemo: _memo),
    );
    if (memo == null) {
      return;
    }

    try {
      await ref
          .read(myProfileControllerProvider)
          .updateFriendMemo(widget.friend, memo.characters.take(10).toString());
      if (mounted) {
        setState(() => _memo = memo.characters.take(10).toString());
      }
      ref.invalidate(friendsProvider);
      ref.invalidate(friendProfileProvider(widget.friend));
      messenger.showSnackBar(const SnackBar(content: Text('친구 메모를 저장했어요.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('친구 메모 저장에 실패했어요.')));
    }
  }

  void _showFriendMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openFriendProfileDetail(
    BuildContext context,
    _ProfileDetailSection section,
    MyProfile profile,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _ProfileDetailPage(section: section, profile: profile),
      ),
    );
  }
}

class _FriendProfileErrorCard extends StatelessWidget {
  const _FriendProfileErrorCard({required this.friend});

  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _CharacterPortrait(
            size: 84,
            character: friend.character,
            profileImageUrl: friend.profileImageUrl,
            fallbackToViewerCharacter: false,
          ),
          const SizedBox(height: 14),
          Text(
            friend.name,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '친구 프로필을 불러오지 못했어요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSub,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateFriendProfileNotice extends StatelessWidget {
  const _PrivateFriendProfileNotice();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.textSub,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '친구가 프로필 취향 정보를 비공개로 설정했어요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSub,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendProfileTopBar extends StatelessWidget {
  const _FriendProfileTopBar({required this.onBack, required this.onEditMemo});

  final VoidCallback onBack;
  final VoidCallback onEditMemo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        const Spacer(),
        TextButton(
          onPressed: onEditMemo,
          child: Text(
            '메모 수정',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primaryPink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendMemoDialog extends StatefulWidget {
  const _FriendMemoDialog({required this.initialMemo});

  final String initialMemo;

  @override
  State<_FriendMemoDialog> createState() => _FriendMemoDialogState();
}

class _FriendMemoDialogState extends State<_FriendMemoDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMemo.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('친구 메모'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 10,
        decoration: const InputDecoration(hintText: '10자 이내 메모'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class _FriendProfileHero extends StatelessWidget {
  const _FriendProfileHero({
    required this.friend,
    required this.profile,
    required this.onDelete,
    required this.onCreatePlan,
  });

  final FriendProfile friend;
  final MyProfile profile;
  final VoidCallback onDelete;
  final VoidCallback onCreatePlan;

  @override
  Widget build(BuildContext context) {
    final character = profile.character;
    final cleanIntro = profile.introText.trim();
    final cleanRegion = profile.region.trim();
    final highlightLabels = profile.favoriteKeywords.take(5).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CharacterPortrait(
                size: 116,
                character: profile.useDefaultProfileImage ? null : character,
                profileImageUrl: profile.profileImageUrl.isNotEmpty
                    ? profile.profileImageUrl
                    : friend.profileImageUrl,
                fallbackToViewerCharacter: false,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.textMain,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (cleanRegion.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textSub,
                            size: 19,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cleanRegion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSub,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (highlightLabels.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _HorizontalChipList(labels: highlightLabels),
          ),
        ],
        if (cleanIntro.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '"$cleanIntro"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.person_remove_alt_1_outlined, size: 22),
                label: const Text('친구 삭제'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                  side: const BorderSide(
                    color: AppColors.primaryPink,
                    width: 1.4,
                  ),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FilledButton.icon(
                onPressed: onCreatePlan,
                icon: const Icon(Icons.event_available_outlined, size: 22),
                label: const Text('같이 약속 잡기'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: AppColors.textInverse,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FriendAddSheet extends ConsumerStatefulWidget {
  const _FriendAddSheet();

  @override
  ConsumerState<_FriendAddSheet> createState() => _FriendAddSheetState();
}

class _FriendAddSheetState extends ConsumerState<_FriendAddSheet> {
  final TextEditingController _idController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _submit() {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      setState(() => _errorText = '친구의 고유 ID를 입력해주세요.');
      return;
    }
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '친구 추가',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '회원가입 때 발급된 고유 ID로 친구를 추가해요.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _idController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _errorText = null),
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: '친구 고유 ID 입력',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('친구 추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
