part of 'my_page.dart';

class _FriendsTab extends StatefulWidget {
  const _FriendsTab({
    super.key,
    required this.friends,
    required this.onOpenAddFriend,
    required this.onFriendTap,
    required this.onToggleFavorite,
  });

  final List<FriendProfile> friends;
  final VoidCallback onOpenAddFriend;
  final ValueChanged<FriendProfile> onFriendTap;
  final ValueChanged<FriendProfile> onToggleFavorite;

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  var _query = '';
  var _isEditingFavorites = false;

  List<FriendProfile> get _filteredFriends {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.friends;
    }

    return widget.friends.where((friend) {
      return friend.name.toLowerCase().contains(query) ||
          friend.memo.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteFriends = widget.friends
        .where((friend) => friend.isFavorite)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  textAlignVertical: TextAlignVertical.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    constraints: const BoxConstraints.tightFor(height: 56),
                    hintText: '친구 검색',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSub,
                      size: 24,
                    ),
                    filled: true,
                    fillColor: AppColors.bgDefault,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.lineSoft),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Transform.translate(
              offset: const Offset(0, -8.5),
              child: SizedBox(
                width: 56,
                height: 40,
                child: FilledButton(
                  onPressed: widget.onOpenAddFriend,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: AppColors.textInverse,
                    fixedSize: const Size(40, 40),
                    minimumSize: const Size(40, 40),
                    maximumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.person_add_alt_1, size: 25),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                '즐겨찾는 친구 ${favoriteFriends.length}명',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _isEditingFavorites = !_isEditingFavorites);
              },
              child: Text(
                _isEditingFavorites ? '완료' : '편집',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favoriteFriends.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              if (index == favoriteFriends.length) {
                return _AddFavoriteFriendButton(
                  onTap: _showFavoriteFriendPicker,
                );
              }

              final friend = favoriteFriends[index];
              return _FavoriteFriend(
                friend: friend,
                index: index,
                isEditing: _isEditingFavorites,
                isSelected: friend.isFavorite,
                onToggle: () => widget.onToggleFavorite(friend),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _SoftCard(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '전체 친구 ${widget.friends.length}명',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '가나다순',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSub,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSub,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final friend in _filteredFriends) ...[
                _FriendListTile(
                  friend: friend,
                  onTap: () => widget.onFriendTap(friend),
                ),
                if (friend != _filteredFriends.last)
                  const Divider(height: 1, color: AppColors.lineSoft),
              ],
              if (_filteredFriends.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('검색 결과가 없어요.', style: AppTextStyles.bodyMedium),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showFavoriteFriendPicker() async {
    final candidates = widget.friends
        .where((friend) => !friend.isFavorite)
        .toList();

    final selected = await showModalBottomSheet<FriendProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _FavoriteFriendPickerSheet(candidates: candidates),
    );

    if (selected == null) {
      return;
    }

    widget.onToggleFavorite(selected);
  }
}

class _KeywordPreferenceCard extends StatelessWidget {
  const _KeywordPreferenceCard({
    required this.profile,
    required this.onEdit,
    required this.onDetail,
    this.showAction = true,
  });

  final MyProfile profile;
  final VoidCallback? onEdit;
  final VoidCallback? onDetail;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: '음식/메뉴 취향',
            actionLabel: showAction ? '편집' : null,
            onAction: showAction ? onEdit : null,
          ),
          const SizedBox(height: 18),
          _InfoRow(
            icon: Icons.restaurant_menu_rounded,
            label: '선호 음식/메뉴',
            trailingWidget: _KeywordScroller(
              children: [
                for (final keyword in profile.favoriteFoodTags.take(5))
                  _KeywordChip(label: keyword, selected: true),
                const _MoreKeywordChip(selected: true),
              ],
            ),
            onTap: onDetail,
          ),
          const Divider(height: 1, color: AppColors.lineSoft),
          _InfoRow(
            icon: Icons.no_meals_rounded,
            iconColor: AppColors.textSub,
            label: '피하고 싶은 음식/메뉴',
            trailingWidget: _KeywordScroller(
              children: [
                for (final keyword in profile.dislikedFoodTags.take(4))
                  _KeywordChip(label: keyword, selected: false),
                const _MoreKeywordChip(selected: false),
              ],
            ),
            onTap: onDetail,
          ),
        ],
      ),
    );
  }
}

class _KeywordScroller extends StatelessWidget {
  const _KeywordScroller({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Center(child: children[index]);
        },
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryPinkSoft.withOpacity(0.68)
            : AppColors.bgPaper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.linePink : AppColors.lineWarm,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: selected ? AppColors.primaryPurple : AppColors.textMain,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MoreKeywordChip extends StatelessWidget {
  const _MoreKeywordChip({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryPinkSoft.withOpacity(0.24)
            : AppColors.bgPaper,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.linePink : AppColors.lineWarm,
        ),
      ),
      child: Icon(
        Icons.more_horiz_rounded,
        color: selected ? AppColors.primaryPurple : AppColors.textSub,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: title,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
          const SizedBox(height: 8),
          for (final child in children) ...[
            child,
            if (child != children.last)
              const Divider(height: 1, color: AppColors.lineSoft),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primaryPurple,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor = AppColors.primaryPink,
    this.trailingWidget,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 23),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSub,
                    size: 25,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 37),
              child: trailingWidget ?? const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacePreferenceCard extends StatelessWidget {
  const _PlacePreferenceCard({
    required this.title,
    required this.rows,
    required this.onEdit,
    required this.onDetail,
    this.showAction = true,
  });

  final String title;
  final List<_PlacePreferenceRowData> rows;
  final VoidCallback? onEdit;
  final VoidCallback? onDetail;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: title,
            actionLabel: showAction && onEdit != null ? '편집' : null,
            onAction: showAction ? onEdit : null,
          ),
          const SizedBox(height: 12),
          for (final row in rows) ...[
            _PlacePreferenceRow(data: row, onTap: onDetail),
            if (row != rows.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _PlacePreferenceRow extends StatelessWidget {
  const _PlacePreferenceRow({required this.data, required this.onTap});

  final _PlacePreferenceRowData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: data.iconColor.withOpacity(0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: data.iconColor, size: 21),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 112,
              child: Text(
                data.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: _HorizontalChipList(labels: data.places.take(5).toList()),
            ),
            const SizedBox(width: 8),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSub,
                size: 26,
              ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteFriend extends StatelessWidget {
  const _FavoriteFriend({
    required this.friend,
    required this.index,
    required this.isEditing,
    required this.isSelected,
    required this.onToggle,
  });

  final FriendProfile friend;
  final int index;
  final bool isEditing;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final friends = _createInitialFriends();
    final characters = _createFriendCharacters();
    final characterIndex = friends
        .indexWhere((item) => item.name == friend.name)
        .clamp(0, characters.length - 1)
        .toInt();

    return InkWell(
      onTap: isEditing ? onToggle : null,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: 1,
                  child: _CharacterPortrait(
                    size: 54,
                    character: characters[characterIndex],
                    profileImageUrl: friend.profileImageUrl,
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isEditing
                          ? AppColors.textSub
                          : AppColors.primaryPink,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bgDefault, width: 2),
                    ),
                    child: Icon(
                      isEditing ? Icons.remove_rounded : Icons.star,
                      color: AppColors.textInverse,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              friend.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFavoriteFriendButton extends StatelessWidget {
  const _AddFavoriteFriendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.bgDefault,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.linePink),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.primaryPurple,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '추가',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteFriendPickerSheet extends StatefulWidget {
  const _FavoriteFriendPickerSheet({required this.candidates});

  final List<FriendProfile> candidates;

  @override
  State<_FavoriteFriendPickerSheet> createState() =>
      _FavoriteFriendPickerSheetState();
}

class _FavoriteFriendPickerSheetState
    extends State<_FavoriteFriendPickerSheet> {
  var _query = '';

  List<FriendProfile> get _filteredCandidates {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.candidates;
    }

    return widget.candidates
        .where(
          (friend) =>
              friend.name.toLowerCase().contains(query) ||
              friend.memo.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
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
                  '즐겨찾기 추가',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: '친구 이름 검색',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final friend in _filteredCandidates) ...[
                      _FavoriteFriendCandidateTile(friend: friend),
                      const Divider(height: 1, color: AppColors.lineSoft),
                    ],
                    if (_filteredCandidates.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text(
                            '추가할 친구가 없어요.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textMuted,
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
      ),
    );
  }
}

class _FavoriteFriendCandidateTile extends StatelessWidget {
  const _FavoriteFriendCandidateTile({required this.friend});

  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(friend),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _CharacterPortrait(
              size: 46,
              character: _characterForFriend(friend),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friend.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primaryPink,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendListTile extends StatelessWidget {
  const _FriendListTile({required this.friend, required this.onTap});

  final FriendProfile friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final friends = _createInitialFriends();
    final characters = _createFriendCharacters();
    final index = friends.indexWhere((item) => item.name == friend.name);
    final characterIndex = index.clamp(0, characters.length - 1).toInt();
    final character = characters[characterIndex];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _CharacterPortrait(
              size: 52,
              character: character,
              profileImageUrl: friend.profileImageUrl,
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    friend.memo,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                friend.preferenceSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSub,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSub,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
