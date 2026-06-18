part of 'my_page.dart';

class _FriendProfilePage extends ConsumerWidget {
  const _FriendProfilePage({required this.friend});

  final FriendProfile friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(friendProfileProvider(friend));

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
                          friend: friend,
                          profile: profile,
                          onDelete: () => _deleteFriend(context, ref),
                          onCreatePlan: () => context.go(
                            RoutePaths.groupNew,
                            extra: [friend.name],
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
                    error: (_, _) => _FriendProfileErrorCard(friend: friend),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFriend(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(friendRepositoryProvider).deleteFriend(friend);
      ref.invalidate(friendsProvider);
      ref.invalidate(friendProfileProvider(friend));
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
          _CharacterPortrait(size: 84, character: _characterForFriend(friend)),
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
  const _FriendProfileTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
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
    final character = _characterForFriend(friend);
    final cleanIntro = profile.introText.trim();
    final cleanRegion = profile.region.trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CharacterPortrait(
                size: 116,
                character: character,
                profileImageUrl: friend.profileImageUrl,
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
                    const SizedBox(height: 8),
                    if (cleanIntro.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        cleanIntro,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
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
                    const SizedBox(height: 14),
                    if (profile.visibility != ProfileVisibility.private)
                      _HorizontalChipList(
                        labels: profile.preferenceHighlights.take(4).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

CharacterDraft _characterForFriend(FriendProfile friend) {
  final source = [
    friend.publicId,
    friend.userCode,
    friend.name,
  ].firstWhere((value) => value.trim().isNotEmpty, orElse: () => 'friend');
  final seed = source.runes.fold<int>(
    0,
    (value, codePoint) => (value * 31 + codePoint) & 0x7fffffff,
  );

  return CharacterDraft(
    gender: seed.isEven ? 'female' : 'male',
    nickname: friend.name,
    skinToneIndex: seed % CharacterDraft.skinTones.length,
    eyeShapeIndex: (seed ~/ 3) % 3,
    eyeColorIndex: (seed ~/ 5) % CharacterDraft.eyeColors.length,
    hairColorIndex: (seed ~/ 7) % CharacterDraft.hairColors.length,
    hairStyleIndex: (seed ~/ 11) % 4,
    topStyleIndex: (seed ~/ 13) % 3,
  );
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
