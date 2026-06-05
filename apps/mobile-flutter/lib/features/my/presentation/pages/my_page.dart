import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../../../shared/widgets/pixel_character.dart';
import '../../../character/character_start_page.dart';
import '../../domain/my_profile.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key, this.resetToken});

  final String? resetToken;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  var _selectedTab = _MyTab.profile;
  var _profile = _createInitialProfile();
  var _friends = _createInitialFriends();
  Set<String>? _favoriteFriendNames;

  Set<String> get _safeFavoriteFriendNames {
    return _favoriteFriendNames ??= {'지연', '민수', '하린', '현우', '소연'};
  }

  @override
  void didUpdateWidget(covariant MyPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.resetToken != oldWidget.resetToken) {
      _selectedTab = _MyTab.profile;
    }
  }

  List<FriendProfile> get _activeFriends {
    return _friends.where((friend) => friend.isFriend).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: GridBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: _PageHeader(
                    onAlarmTap: () =>
                        context.push(RoutePaths.homeNotifications),
                    onSettingTap: _openSettingsPage,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: _ProfileHero(
                    profile: _profile,
                    onEdit: _showProfileEditor,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: _HeroTabBar(
                    selectedTab: _selectedTab,
                    onChanged: (tab) => setState(() => _selectedTab = tab),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                sliver: SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _selectedTab == _MyTab.profile
                        ? _ProfileTab(
                            key: const ValueKey('profile'),
                            profile: _profile,
                            onKeywordEdit: () => _openProfileSectionEditor(
                              _ProfileEditSection.keywords,
                            ),
                            onScheduleEdit: () => _openProfileSectionEditor(
                              _ProfileEditSection.schedule,
                            ),
                            onPlaceEdit: () => _openProfileSectionEditor(
                              _ProfileEditSection.places,
                            ),
                            onDetail: _openProfileDetailPage,
                          )
                        : _FriendsTab(
                            key: const ValueKey('friends'),
                            friends: _activeFriends,
                            favoriteFriendNames: _safeFavoriteFriendNames,
                            onOpenAddFriend: _showFriendAddSheet,
                            onFriendTap: _openFriendProfile,
                            onToggleFavorite: _toggleFavoriteFriend,
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

  void _toggleFavoriteFriend(FriendProfile friend) {
    setState(() {
      final favoriteFriendNames = _safeFavoriteFriendNames;
      if (favoriteFriendNames.contains(friend.name)) {
        favoriteFriendNames.remove(friend.name);
        return;
      }

      favoriteFriendNames.add(friend.name);
    });
  }

  Future<void> _showProfileEditor() async {
    final result = await Navigator.of(context).push<_ProfileEditResult>(
      MaterialPageRoute(
        builder: (context) => _ProfileEditPage(profile: _profile),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _profile = _profile.copyWith(
        realName: result.realName,
        visibility: result.visibility,
        favoriteKeywords: result.favoriteKeywords,
      );
    });
  }

  Future<void> _openProfileSectionEditor(_ProfileEditSection section) async {
    final result = await Navigator.of(context).push<_ProfileSectionEditResult>(
      MaterialPageRoute(
        builder: (context) =>
            _ProfileSectionEditPage(section: section, profile: _profile),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _profile = _profile.copyWith(
        favoriteFoodTags: result.favoriteFoodTags,
        dislikedFoodTags: result.dislikedFoodTags,
        favoritePlaceTags: result.favoritePlaceTags,
        dislikedPlaceTags: result.dislikedPlaceTags,
        planStyles: result.planStyles,
        preferredWeekdays: result.preferredWeekdays,
        preferredTimes: result.preferredTimes,
        unavailableDates: result.unavailableDates,
      );
    });
  }

  void _openProfileDetailPage(_ProfileDetailSection section) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _ProfileDetailPage(section: section, profile: _profile),
      ),
    );
  }

  void _openSettingsPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const _SettingsPage()));
  }

  void _openFriendProfile(FriendProfile friend) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FriendProfilePage(
          friend: friend,
          profile: _profile.copyWith(realName: friend.name),
        ),
      ),
    );
  }

  Future<void> _showFriendAddSheet() async {
    final result = await showModalBottomSheet<FriendProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _FriendAddSheet(
          candidates: _friends.where((friend) => !friend.isFriend).toList(),
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _friends = [
        for (final friend in _friends)
          if (friend.name == result.name)
            friend.copyWith(isFriend: true)
          else
            friend,
      ];
    });
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onAlarmTap, required this.onSettingTap});

  final VoidCallback onAlarmTap;
  final VoidCallback onSettingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textMain,
              letterSpacing: 0,
            ),
            children: [
              const TextSpan(text: '마이 '),
              TextSpan(
                text: 'ONMU',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          showDot: true,
          onTap: onAlarmTap,
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(icon: Icons.settings_outlined, onTap: onSettingTap),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 27, color: AppColors.textMain),
            if (showDot)
              Positioned(
                top: 5,
                right: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.onEdit});

  final MyProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CharacterPortrait(size: 88),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        profile.realName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _EditProfileButton(onTap: onEdit),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '기록하고, 만나고, 추억해요  ♥',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textSub,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '서울 성수동',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _HorizontalChipList(
                  labels: profile.preferenceHighlights.take(5).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterPortrait extends StatelessWidget {
  const _CharacterPortrait({required this.size, this.character});

  final double size;
  final CharacterDraft? character;

  @override
  Widget build(BuildContext context) {
    final draft =
        character ??
        const CharacterDraft(
          gender: 'female',
          nickname: '온이음',
          skinToneIndex: 0,
          eyeShapeIndex: 0,
          eyeColorIndex: 1,
          hairColorIndex: 1,
          hairStyleIndex: 0,
          topStyleIndex: 0,
        );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primaryPinkSoft.withOpacity(0.32),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.linePink.withOpacity(0.55)),
      ),
      child: OverflowBox(
        minWidth: 0,
        minHeight: 0,
        maxWidth: size * 1.45,
        maxHeight: size * 1.65,
        child: Transform.translate(
          offset: Offset(0, size * 0.08),
          child: PixelCharacterWidget(
            character: draft,
            size: size * 1.1,
            showShadow: false,
          ),
        ),
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryPurple,
        side: const BorderSide(color: AppColors.primaryPink, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        textStyle: AppTextStyles.labelMedium,
      ),
      child: const Text('프로필 수정'),
    );
  }
}

class _HeroTabBar extends StatelessWidget {
  const _HeroTabBar({required this.selectedTab, required this.onChanged});

  final _MyTab selectedTab;
  final ValueChanged<_MyTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        children: [
          for (final tab in _MyTab.values)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(tab),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          tab.label,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: selectedTab == tab
                                ? AppColors.primaryPurple
                                : AppColors.textSub,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: double.infinity,
                        height: 3,
                        decoration: BoxDecoration(
                          color: selectedTab == tab
                              ? AppColors.primaryPink
                              : AppColors.transparent,
                          borderRadius: BorderRadius.circular(999),
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    super.key,
    required this.profile,
    required this.onKeywordEdit,
    required this.onScheduleEdit,
    required this.onPlaceEdit,
    required this.onDetail,
    this.showActions = true,
  });

  final MyProfile profile;
  final VoidCallback onKeywordEdit;
  final VoidCallback onScheduleEdit;
  final VoidCallback onPlaceEdit;
  final ValueChanged<_ProfileDetailSection>? onDetail;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        _KeywordPreferenceCard(
          profile: profile,
          onEdit: onKeywordEdit,
          onDetail: onDetail == null
              ? null
              : () => onDetail!(_ProfileDetailSection.keywords),
          showAction: showActions,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: '약속 스타일',
          actionLabel: showActions ? '편집' : null,
          onAction: showActions ? onScheduleEdit : null,
          children: [
            _InfoRow(
              icon: Icons.handshake_outlined,
              label: '약속 스타일',
              trailingWidget: _KeywordScroller(
                children: [
                  for (final style in profile.planStyles)
                    _KeywordChip(label: style, selected: true),
                ],
              ),
              onTap: onDetail == null
                  ? null
                  : () => onDetail!(_ProfileDetailSection.schedule),
            ),
            _InfoRow(
              icon: Icons.calendar_month_rounded,
              label: '선호 요일',
              trailingWidget: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in profile.preferredWeekdays)
                    _OutlinedToken(label: day),
                ],
              ),
              onTap: onDetail == null
                  ? null
                  : () => onDetail!(_ProfileDetailSection.schedule),
            ),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: '선호 시간대',
              trailingWidget: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in profile.preferredTimes)
                    _OutlinedToken(label: time),
                ],
              ),
              onTap: onDetail == null
                  ? null
                  : () => onDetail!(_ProfileDetailSection.schedule),
            ),
            _InfoRow(
              icon: Icons.event_busy_rounded,
              label: '불가능한 날짜',
              trailingWidget: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final date in profile.unavailableDates)
                    _OutlinedToken(label: date),
                ],
              ),
              onTap: onDetail == null
                  ? null
                  : () => onDetail!(_ProfileDetailSection.schedule),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PlacePreferenceCard(
          title: '장소/분위기 취향',
          onEdit: onPlaceEdit,
          onDetail: onDetail == null
              ? null
              : () => onDetail!(_ProfileDetailSection.places),
          showAction: showActions,
          rows: [
            _PlacePreferenceRowData(
              icon: Icons.favorite_border_rounded,
              iconColor: AppColors.primaryPink,
              label: '선호 태그',
              places: profile.favoritePlaceTags,
            ),
            _PlacePreferenceRowData(
              icon: Icons.heart_broken_rounded,
              iconColor: AppColors.textMuted,
              label: '피하고 싶은 태그',
              places: profile.dislikedPlaceTags,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PlacePreferenceCard(
          title: '저장 장소 목록',
          onEdit: null,
          onDetail: onDetail == null
              ? null
              : () => onDetail!(_ProfileDetailSection.savedPlaces),
          showAction: false,
          rows: [
            _PlacePreferenceRowData(
              icon: Icons.favorite_rounded,
              iconColor: AppColors.primaryPink,
              label: '좋아하는 장소',
              places: profile.favoritePlaces
                  .map((place) => place.name)
                  .toList(),
            ),
            _PlacePreferenceRowData(
              icon: Icons.star_rounded,
              iconColor: AppColors.primaryPurple,
              label: '가고싶은 장소',
              places: profile.wantToGoPlaces
                  .map((place) => place.name)
                  .toList(),
            ),
            _PlacePreferenceRowData(
              icon: Icons.close_rounded,
              iconColor: AppColors.textMuted,
              label: '싫어하는 장소',
              places: profile.dislikedPlaces
                  .map((place) => place.name)
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }
}

class _FriendsTab extends StatefulWidget {
  const _FriendsTab({
    super.key,
    required this.friends,
    required this.favoriteFriendNames,
    required this.onOpenAddFriend,
    required this.onFriendTap,
    required this.onToggleFavorite,
  });

  final List<FriendProfile> friends;
  final Set<String>? favoriteFriendNames;
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
    final favoriteFriendNames = widget.favoriteFriendNames ?? const <String>{};
    final favoriteFriends = widget.friends
        .where((friend) => favoriteFriendNames.contains(friend.name))
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
                  onTap: () => _showFavoriteFriendPicker(favoriteFriendNames),
                );
              }

              final friend = favoriteFriends[index];
              return _FavoriteFriend(
                friend: friend,
                index: index,
                isEditing: _isEditingFavorites,
                isSelected: favoriteFriendNames.contains(friend.name),
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

  Future<void> _showFavoriteFriendPicker(
    Set<String> favoriteFriendNames,
  ) async {
    final candidates = widget.friends
        .where((friend) => !favoriteFriendNames.contains(friend.name))
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
            _CharacterPortrait(size: 52, character: character),
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

class _FriendProfilePage extends StatelessWidget {
  const _FriendProfilePage({required this.friend, required this.profile});

  final FriendProfile friend;
  final MyProfile profile;

  @override
  Widget build(BuildContext context) {
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
                  child: Column(
                    children: [
                      _FriendProfileHero(
                        friend: friend,
                        profile: profile,
                        onDelete: () =>
                            _showFriendMessage(context, '친구 삭제 기능을 준비 중이에요.'),
                        onCreatePlan: () => context.go(
                          RoutePaths.groupNew,
                          extra: [friend.name],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ProfileTab(
                        profile: profile,
                        onKeywordEdit: () {},
                        onScheduleEdit: () {},
                        onPlaceEdit: () {},
                        onDetail: (section) =>
                            _openFriendProfileDetail(context, section),
                        showActions: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFriendMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openFriendProfileDetail(
    BuildContext context,
    _ProfileDetailSection section,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _ProfileDetailPage(section: section, profile: profile),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CharacterPortrait(size: 116, character: character),
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
                    Text(
                      '기록하고, 만나고, 추억해요  ♥',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textSub,
                          size: 19,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '서울 성수동',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSub,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                  textStyle: AppTextStyles.labelLarge.copyWith(
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
                  textStyle: AppTextStyles.labelLarge.copyWith(
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
  final friends = _createInitialFriends();
  final characters = _createFriendCharacters();
  final index = friends.indexWhere((item) => item.name == friend.name);
  final safeIndex = index.clamp(0, characters.length - 1).toInt();

  return characters[safeIndex];
}

class _FriendAddSheet extends StatefulWidget {
  const _FriendAddSheet({required this.candidates});

  final List<FriendProfile> candidates;

  @override
  State<_FriendAddSheet> createState() => _FriendAddSheetState();
}

class _FriendAddSheetState extends State<_FriendAddSheet> {
  var _query = '';

  List<FriendProfile> get _filteredCandidates {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.candidates;
    }

    return widget.candidates
        .where((candidate) => candidate.name.toLowerCase().contains(query))
        .toList();
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
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: '이름으로 검색',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final candidate in _filteredCandidates) ...[
                      _FriendCandidateTile(candidate: candidate),
                      const SizedBox(height: 10),
                    ],
                    if (_filteredCandidates.isEmpty)
                      const _SoftCard(
                        child: Center(child: Text('추가할 친구가 없어요.')),
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

class _FriendCandidateTile extends StatelessWidget {
  const _FriendCandidateTile({required this.candidate});

  final FriendProfile candidate;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const _CharacterPortrait(size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(candidate.name, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  candidate.preferenceSummary,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(candidate),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailPage extends StatelessWidget {
  const _ProfileDetailPage({required this.section, required this.profile});

  final _ProfileDetailSection section;
  final MyProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              _SettingsTopBar(
                title: section.title,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  child: switch (section) {
                    _ProfileDetailSection.keywords => _buildKeywordDetail(),
                    _ProfileDetailSection.schedule => _buildScheduleDetail(),
                    _ProfileDetailSection.places => _buildPlaceDetail(),
                    _ProfileDetailSection.savedPlaces =>
                      _buildSavedPlaceDetail(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordDetail() {
    return Column(
      children: [
        _DetailChipSection(
          icon: Icons.restaurant_menu_rounded,
          title: '선호 음식/메뉴',
          values: profile.favoriteFoodTags,
          selected: true,
        ),
        const SizedBox(height: 14),
        _DetailChipSection(
          icon: Icons.no_meals_rounded,
          title: '피하고 싶은 음식/메뉴',
          values: profile.dislikedFoodTags,
          selected: false,
        ),
      ],
    );
  }

  Widget _buildScheduleDetail() {
    return Column(
      children: [
        _DetailChipSection(
          icon: Icons.handshake_outlined,
          title: '약속 스타일',
          values: profile.planStyles,
          selected: true,
        ),
        const SizedBox(height: 14),
        _DetailChipSection(
          icon: Icons.calendar_month_rounded,
          title: '선호 요일',
          values: profile.preferredWeekdays,
          selected: true,
        ),
        const SizedBox(height: 14),
        _DetailChipSection(
          icon: Icons.schedule_rounded,
          title: '선호 시간대',
          values: profile.preferredTimes,
          selected: true,
        ),
        const SizedBox(height: 14),
        _DetailChipSection(
          icon: Icons.event_busy_rounded,
          title: '불가능한 날짜',
          values: profile.unavailableDates,
          selected: false,
        ),
      ],
    );
  }

  Widget _buildPlaceDetail() {
    return Column(
      children: [
        _DetailChipSection(
          icon: Icons.favorite_border_rounded,
          title: '선호 장소/분위기',
          values: profile.favoritePlaceTags,
          selected: true,
        ),
        const SizedBox(height: 14),
        _DetailChipSection(
          icon: Icons.heart_broken_rounded,
          title: '피하고 싶은 장소/분위기',
          values: profile.dislikedPlaceTags,
          selected: false,
        ),
      ],
    );
  }

  Widget _buildSavedPlaceDetail() {
    return Column(
      children: [
        _DetailChipSection(
          icon: Icons.favorite_rounded,
          title: '좋아하는 장소',
          values: profile.favoritePlaces.map((place) => place.name).toList(),
          selected: true,
        ),
        const SizedBox(height: 14),
        _DetailChipSection(
          icon: Icons.star_rounded,
          title: '가고싶은 장소',
          values: profile.wantToGoPlaces.map((place) => place.name).toList(),
          selected: true,
        ),
        const SizedBox(height: 14),
        _DetailChipSection(
          icon: Icons.close_rounded,
          title: '싫어하는 장소',
          values: profile.dislikedPlaces.map((place) => place.name).toList(),
          selected: false,
        ),
      ],
    );
  }
}

class _DetailChipSection extends StatelessWidget {
  const _DetailChipSection({
    required this.icon,
    required this.title,
    required this.values,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final List<String> values;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primaryPink : AppColors.textSub,
                size: 23,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                _KeywordChip(label: value, selected: selected),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionEditPage extends StatefulWidget {
  const _ProfileSectionEditPage({required this.section, required this.profile});

  final _ProfileEditSection section;
  final MyProfile profile;

  @override
  State<_ProfileSectionEditPage> createState() =>
      _ProfileSectionEditPageState();
}

class _ProfileSectionEditPageState extends State<_ProfileSectionEditPage> {
  late List<String> _favoriteFoodTags;
  late List<String> _dislikedFoodTags;
  late List<String> _favoritePlaceTags;
  late List<String> _dislikedPlaceTags;
  late List<String> _planStyles;
  late List<String> _preferredTimes;
  late List<String> _preferredWeekdays;
  late List<String> _unavailableDates;

  @override
  void initState() {
    super.initState();
    _favoriteFoodTags = [...widget.profile.favoriteFoodTags];
    _dislikedFoodTags = [...widget.profile.dislikedFoodTags];
    _favoritePlaceTags = [...widget.profile.favoritePlaceTags];
    _dislikedPlaceTags = [...widget.profile.dislikedPlaceTags];
    _planStyles = [...widget.profile.planStyles];
    _preferredTimes = [...widget.profile.preferredTimes];
    _preferredWeekdays = [...widget.profile.preferredWeekdays];
    _unavailableDates = [...widget.profile.unavailableDates];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              _EditPageTopBar(
                title: widget.section.title,
                actionLabel: '저장',
                onBack: () => Navigator.of(context).pop(),
                onAction: _save,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionEditIntro(section: widget.section),
                      const SizedBox(height: 16),
                      switch (widget.section) {
                        _ProfileEditSection.keywords => _buildKeywordEditor(),
                        _ProfileEditSection.schedule => _buildScheduleEditor(),
                        _ProfileEditSection.places => _buildPlaceEditor(),
                      },
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordEditor() {
    final favoriteFoodOptions = [
      '한식',
      '일식',
      '양식',
      '중식',
      '매운 음식',
      '디저트 카페',
      '고기/구이',
      '비건/건강식',
      '상관 없어요',
    ];
    final dislikedFoodOptions = [
      '너무 매운 음식',
      '해산물',
      '향신료 강한 음식',
      '기름진 음식',
      '주차 어려운 곳',
      '상관 없어요',
    ];

    return Column(
      children: [
        _EditFieldCard(
          icon: Icons.restaurant_menu_rounded,
          label: '선호 음식/메뉴',
          child: _ToggleChipWrap(
            values: favoriteFoodOptions,
            selectedValues: _favoriteFoodTags,
            onToggle: (value) => _toggleValue(_favoriteFoodTags, value),
          ),
        ),
        const SizedBox(height: 12),
        _EditFieldCard(
          icon: Icons.no_meals_rounded,
          label: '피하고 싶은 음식/메뉴',
          child: _ToggleChipWrap(
            values: dislikedFoodOptions,
            selectedValues: _dislikedFoodTags,
            onToggle: (value) => _toggleValue(_dislikedFoodTags, value),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleEditor() {
    final styleOptions = [
      '미리 일정을 정하는 편',
      '당일 번개 약속도 괜찮아요',
      '주말에 여유롭게 만나고 싶어요',
      '대기/웨이팅은 피하고 싶어요',
    ];
    final weekdayOptions = [
      '월요일',
      '화요일',
      '수요일',
      '목요일',
      '금요일',
      '토요일',
      '일요일',
      '상관 없어요',
    ];
    final timeOptions = ['오전', '점심', '오후', '저녁', '일정 보고 결정할게요'];

    return Column(
      children: [
        _EditFieldCard(
          icon: Icons.handshake_outlined,
          label: '약속 스타일',
          child: _ToggleChipWrap(
            values: styleOptions,
            selectedValues: _planStyles,
            onToggle: (value) => _toggleValue(_planStyles, value),
          ),
        ),
        const SizedBox(height: 12),
        _EditFieldCard(
          icon: Icons.calendar_month_rounded,
          label: '선호 요일',
          child: _ToggleChipWrap(
            values: weekdayOptions,
            selectedValues: _preferredWeekdays,
            onToggle: (value) => _toggleValue(_preferredWeekdays, value),
          ),
        ),
        const SizedBox(height: 12),
        _EditFieldCard(
          icon: Icons.schedule_rounded,
          label: '선호 시간대',
          child: _ToggleChipWrap(
            values: timeOptions,
            selectedValues: _preferredTimes,
            onToggle: (value) => _toggleValue(_preferredTimes, value),
          ),
        ),
        const SizedBox(height: 12),
        _EditFieldCard(
          icon: Icons.event_busy_rounded,
          label: '불가능한 날짜',
          child: _CalendarDateSelector(
            dates: _unavailableDates,
            onAddDate: _pickUnavailableDate,
            onRemoveDate: (value) =>
                setState(() => _unavailableDates.remove(value)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceEditor() {
    final favoritePlaceOptions = [
      '조용한 대화 공간',
      '감성 있는 사진 맛집',
      '가성비 좋은 곳',
      '주차가 편한 곳',
      '넓고 쾌적한 공간',
      '상관 없어요',
    ];
    final dislikedPlaceOptions = [
      '이동 시간이 긴 곳',
      '소음이 큰 곳',
      '사람이 너무 많은 곳',
      '상관 없어요',
    ];

    return Column(
      children: [
        _EditFieldCard(
          icon: Icons.favorite_border_rounded,
          label: '선호 장소/분위기',
          child: _ToggleChipWrap(
            values: favoritePlaceOptions,
            selectedValues: _favoritePlaceTags,
            onToggle: (value) => _toggleValue(_favoritePlaceTags, value),
          ),
        ),
        const SizedBox(height: 12),
        _EditFieldCard(
          icon: Icons.heart_broken_rounded,
          label: '피하고 싶은 장소/분위기',
          child: _ToggleChipWrap(
            values: dislikedPlaceOptions,
            selectedValues: _dislikedPlaceTags,
            onToggle: (value) => _toggleValue(_dislikedPlaceTags, value),
          ),
        ),
      ],
    );
  }

  void _toggleValue(List<String> target, String value) {
    setState(() {
      if (target.contains(value)) {
        target.remove(value);
        return;
      }

      target.add(value);
    });
  }

  Future<void> _pickUnavailableDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: '불가능한 날짜 선택',
      confirmText: '선택',
      cancelText: '취소',
    );

    if (picked == null) {
      return;
    }

    final label = _formatKoreanDate(picked);
    if (_unavailableDates.contains(label)) {
      return;
    }

    setState(() => _unavailableDates.add(label));
  }

  void _save() {
    Navigator.of(context).pop(
      _ProfileSectionEditResult(
        favoriteFoodTags: _favoriteFoodTags,
        dislikedFoodTags: _dislikedFoodTags,
        favoritePlaceTags: _favoritePlaceTags,
        dislikedPlaceTags: _dislikedPlaceTags,
        planStyles: _planStyles,
        preferredWeekdays: _preferredWeekdays,
        preferredTimes: _preferredTimes,
        unavailableDates: _unavailableDates,
      ),
    );
  }
}

class _SectionEditIntro extends StatelessWidget {
  const _SectionEditIntro({required this.section});

  final _ProfileEditSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryPinkSoft.withOpacity(0.42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        section.description,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSub,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _EditableTagChip extends StatelessWidget {
  const _EditableTagChip({
    required this.label,
    required this.selected,
    required this.onRemove,
  });

  final String label;
  final bool selected;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryPinkSoft.withOpacity(0.74)
            : AppColors.bgWarm,
        borderRadius: BorderRadius.circular(999),
        border: selected ? null : Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected ? AppColors.primaryPurple : AppColors.textMain,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close_rounded,
              size: 15,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChipWrap extends StatelessWidget {
  const _ToggleChipWrap({
    required this.values,
    required this.selectedValues,
    required this.onToggle,
  });

  final List<String> values;
  final List<String> selectedValues;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(value),
            selected: selectedValues.contains(value),
            onSelected: (_) => onToggle(value),
            selectedColor: AppColors.primaryPinkSoft.withOpacity(0.82),
            backgroundColor: AppColors.bgWarm,
            side: BorderSide(
              color: selectedValues.contains(value)
                  ? AppColors.linePink
                  : AppColors.lineSoft,
            ),
            labelStyle: AppTextStyles.labelMedium.copyWith(
              color: selectedValues.contains(value)
                  ? AppColors.primaryPurple
                  : AppColors.textMain,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _CalendarDateSelector extends StatelessWidget {
  const _CalendarDateSelector({
    required this.dates,
    required this.onAddDate,
    required this.onRemoveDate,
  });

  final List<String> dates;
  final VoidCallback onAddDate;
  final ValueChanged<String> onRemoveDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final date in dates)
              _EditableTagChip(
                label: date,
                selected: false,
                onRemove: () => onRemoveDate(date),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onAddDate,
            icon: const Icon(Icons.calendar_month_rounded, size: 20),
            label: const Text('캘린더에서 날짜 선택'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryPurple,
              side: const BorderSide(color: AppColors.linePink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatKoreanDate(DateTime date) {
  final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}/${date.day} (${weekdays[date.weekday - 1]})';
}

class _ProfileEditPage extends StatefulWidget {
  const _ProfileEditPage({required this.profile});

  final MyProfile profile;

  @override
  State<_ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<_ProfileEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _introController;
  late final TextEditingController _regionController;
  late final TextEditingController _interestController;
  late ProfileVisibility _visibility;
  late List<String> _interests;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.realName);
    _introController = TextEditingController(text: '기록하고, 만나고, 추억해요  ♥');
    _regionController = TextEditingController(text: '서울 성수동');
    _interestController = TextEditingController();
    _visibility = widget.profile.visibility;
    _interests = widget.profile.favoriteKeywords.take(5).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _introController.dispose();
    _regionController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              _EditPageTopBar(
                title: '프로필 수정',
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _showProfilePhotoOptions,
                        borderRadius: BorderRadius.circular(999),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const _CharacterPortrait(size: 132),
                            Positioned(
                              right: 4,
                              bottom: 10,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPink,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.bgDefault,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.photo_camera_outlined,
                                  color: AppColors.textInverse,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _showProfilePhotoOptions,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: const Text('프로필 사진 변경'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryPurple,
                          textStyle: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openCharacterEditor,
                        icon: const Icon(
                          Icons.face_retouching_natural_outlined,
                        ),
                        label: const Text('캐릭터 수정'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryPurple,
                          side: const BorderSide(color: AppColors.linePink),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _EditFieldCard(
                        icon: Icons.badge_outlined,
                        label: '이름',
                        child: _CountedTextField(
                          controller: _nameController,
                          maxLength: 10,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EditFieldCard(
                        icon: Icons.edit_outlined,
                        label: '소개',
                        child: _CountedTextField(
                          controller: _introController,
                          maxLength: 50,
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _EditFieldCard(
                        icon: Icons.location_on_outlined,
                        label: '지역',
                        child: _RegionSelector(controller: _regionController),
                      ),
                      const SizedBox(height: 14),
                      _EditFieldCard(
                        icon: Icons.favorite_border,
                        label: '관심사',
                        subLabel: '(최대 5개)',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final interest in _interests)
                                    _RemovableInterestChip(
                                      label: interest,
                                      onRemove: () {
                                        setState(
                                          () => _interests.remove(interest),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _interestController,
                                    enabled: _interests.length < 5,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _addInterest(),
                                    decoration: InputDecoration(
                                      hintText: _interests.length < 5
                                          ? '관심사 입력'
                                          : '관심사는 최대 5개까지 가능해요',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 46,
                                  child: FilledButton(
                                    onPressed: _interests.length < 5
                                        ? _addInterest
                                        : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryPink,
                                      foregroundColor: AppColors.textInverse,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      '추가',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.textInverse,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton.icon(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            foregroundColor: AppColors.textInverse,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                            '저장하기',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textInverse,
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
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(
      _ProfileEditResult(
        realName: _nameController.text.trim().isEmpty
            ? widget.profile.realName
            : _nameController.text.trim(),
        visibility: _visibility,
        favoriteKeywords: _interests,
      ),
    );
  }

  void _addInterest() {
    final value = _interestController.text.trim();
    if (value.isEmpty || _interests.contains(value) || _interests.length >= 5) {
      return;
    }

    setState(() {
      _interests.add(value);
      _interestController.clear();
    });
  }

  Future<void> _showProfilePhotoOptions() async {
    final selected = await showModalBottomSheet<_ProfilePhotoOption>(
      context: context,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => const _ProfilePhotoOptionSheet(),
    );

    if (!mounted || selected == null) {
      return;
    }

    switch (selected) {
      case _ProfilePhotoOption.character:
        _openCharacterEditor();
      case _ProfilePhotoOption.album:
        _showEditMessage('앨범에서 고르기 기능을 준비 중이에요.');
      case _ProfilePhotoOption.camera:
        _showEditMessage('지금 사진 찍기 기능을 준비 중이에요.');
    }
  }

  Future<void> _openCharacterEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CharacterStartPage(
          onBackToOnboarding: () {
            Navigator.of(context).pop();
            GoRouter.of(this.context).go(RoutePaths.onboarding);
          },
          onCompleted: (_) => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showEditMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfilePhotoOptionSheet extends StatelessWidget {
  const _ProfilePhotoOptionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '프로필 사진 변경',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '사용할 이미지를 선택해주세요.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _ProfilePhotoOptionTile(
              icon: Icons.face_retouching_natural_outlined,
              title: '캐릭터 이미지 사용',
              subtitle: 'ONMU 캐릭터를 프로필 사진으로 써요',
              option: _ProfilePhotoOption.character,
            ),
            _ProfilePhotoOptionTile(
              icon: Icons.photo_library_outlined,
              title: '앨범에서 고르기',
              subtitle: '저장된 사진을 선택해요',
              option: _ProfilePhotoOption.album,
            ),
            _ProfilePhotoOptionTile(
              icon: Icons.photo_camera_outlined,
              title: '지금 사진 찍기',
              subtitle: '카메라로 바로 촬영해요',
              option: _ProfilePhotoOption.camera,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhotoOptionTile extends StatelessWidget {
  const _ProfilePhotoOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.option,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _ProfilePhotoOption option;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(option),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryPinkSoft.withOpacity(0.62),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSub,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              _SettingsTopBar(
                title: '설정',
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 36, 22, 28),
                  child: Column(
                    children: [
                      _SettingsMenuCard(
                        items: const [
                          _SettingsMenuItemData(
                            type: _SettingsDetailType.account,
                            icon: Icons.person_outline,
                            title: '계정',
                            subtitle: '이메일, 비밀번호, 휴대폰 번호 등',
                          ),
                          _SettingsMenuItemData(
                            type: _SettingsDetailType.privacy,
                            icon: Icons.verified_user_outlined,
                            title: '개인정보 및 보안',
                            subtitle: '개인정보 설정, 차단, 공개 범위 등',
                          ),
                          _SettingsMenuItemData(
                            type: _SettingsDetailType.notification,
                            icon: Icons.notifications_none_rounded,
                            title: '알림',
                            subtitle: '푸시 알림, 알림 시간, 소식 알림 등',
                          ),
                          _SettingsMenuItemData(
                            type: _SettingsDetailType.app,
                            icon: Icons.palette_outlined,
                            title: '앱 설정',
                            subtitle: '테마, 언어, 다크 모드, 글자 크기 등',
                          ),
                          _SettingsMenuItemData(
                            type: _SettingsDetailType.support,
                            icon: Icons.help_outline_rounded,
                            title: '고객 지원',
                            subtitle: '고객센터, FAQ, 이용약관 등',
                          ),
                        ],
                        onSelected: (item) => _openDetail(context, item.type),
                      ),
                      const SizedBox(height: 28),
                      _AccountActionCard(
                        onTap: () => _showSettingsToast(context),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'v1.2.0',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, _SettingsDetailType type) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => _SettingsDetailPage(type: type)),
    );
  }

  void _showSettingsToast(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('곧 연결될 기능이에요.')));
  }
}

class _EditPageTopBar extends StatelessWidget {
  const _EditPageTopBar({
    required this.title,
    required this.onBack,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback onBack;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          const SizedBox(width: 10),
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textMain,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textMain,
                ),
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
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            const SizedBox(width: 58),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _SettingsTopBar extends StatelessWidget {
  const _SettingsTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          const SizedBox(width: 10),
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textMain,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 58),
        ],
      ),
    );
  }
}

class _SettingsDetailPage extends StatelessWidget {
  const _SettingsDetailPage({required this.type});

  final _SettingsDetailType type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              _SettingsTopBar(
                title: type.title,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (type) {
      _SettingsDetailType.account => Column(
        children: const [
          _SettingsSection(
            title: '계정 정보',
            rows: [
              _SettingsValueRow(label: '이메일', value: 'onmu@email.com'),
              _SettingsValueRow(label: '비밀번호 변경'),
              _SettingsValueRow(label: '휴대폰 번호', value: '010-1234-5678'),
              _SettingsValueRow(label: '로그인 방식', value: '일반 로그인'),
            ],
          ),
          SizedBox(height: 34),
          _SettingsSection(
            title: '계정 관리',
            rows: [
              _SettingsIconValueRow(label: '연결된 계정'),
              _SettingsValueRow(label: '계정 삭제'),
            ],
          ),
        ],
      ),
      _SettingsDetailType.privacy => Column(
        children: const [
          _SettingsSection(
            title: '개인정보 설정',
            rows: [
              _SettingsValueRow(label: '프로필 공개 범위', value: '전체 공개'),
              _SettingsSwitchRow(
                label: '검색 허용',
                description: 'ONMU ID / 이메일로 검색 허용',
                initialValue: true,
              ),
              _SettingsSwitchRow(
                label: '활동 상태 표시',
                description: '다른 사용자에게 내 활동 상태 표시',
                initialValue: true,
              ),
              _SettingsSwitchRow(
                label: '위치 정보 사용',
                description: 'ONMU 서비스에서 위치 정보 사용',
                initialValue: true,
              ),
            ],
          ),
          SizedBox(height: 34),
          _SettingsSection(
            title: '보안',
            rows: [
              _SettingsValueRow(label: '차단한 사용자'),
              _SettingsValueRow(label: '로그인 기기 관리'),
              _SettingsValueRow(label: '2단계 인증', value: '사용 안 함'),
            ],
          ),
        ],
      ),
      _SettingsDetailType.notification => Column(
        children: const [
          _SettingsSection(
            title: '푸시 알림',
            rows: [
              _SettingsSwitchRow(label: '푸시 알림 허용', initialValue: true),
              _SettingsSwitchRow(
                label: '모임/약속 알림',
                description: '약속 초대, 일정 변경 등',
                initialValue: true,
              ),
              _SettingsSwitchRow(
                label: '메시지 알림',
                description: '메시지 수신 시',
                initialValue: true,
              ),
              _SettingsSwitchRow(
                label: '친구 알림',
                description: '친구 요청, 친구 추가 등',
                initialValue: true,
              ),
              _SettingsSwitchRow(
                label: '소식/이벤트 알림',
                description: 'ONMU 소식 및 이벤트',
                initialValue: false,
              ),
            ],
          ),
          SizedBox(height: 34),
          _SettingsSection(
            title: '알림 시간 설정',
            rows: [
              _SettingsValueRow(label: '조용한 시간', value: '오후 10:00 ~ 오전 8:00'),
            ],
          ),
        ],
      ),
      _SettingsDetailType.app => Column(
        children: const [
          _SettingsSection(
            title: '화면 설정',
            rows: [
              _SettingsValueRow(label: '테마', value: '라이트 모드'),
              _SettingsSwitchRow(label: '다크 모드', initialValue: false),
              _SettingsValueRow(label: '글자 크기', value: '보통'),
            ],
          ),
          SizedBox(height: 34),
          _SettingsSection(
            title: '언어 설정',
            rows: [_SettingsValueRow(label: '언어', value: '한국어')],
          ),
          SizedBox(height: 34),
          _SettingsSection(
            title: '기타 설정',
            rows: [
              _SettingsValueRow(label: '기본 지역', value: '서울 성수동'),
              _SettingsValueRow(label: '캐시 삭제', value: '12.5 MB'),
              _SettingsValueRow(label: '앱 정보', value: 'v1.2.0'),
            ],
          ),
        ],
      ),
      _SettingsDetailType.support => Column(
        children: const [
          _SettingsSection(
            title: '도움말',
            rows: [
              _SettingsValueRow(label: '고객센터'),
              _SettingsValueRow(label: '자주 묻는 질문 (FAQ)'),
              _SettingsValueRow(label: '문의하기'),
              _SettingsValueRow(label: '의견 보내기'),
            ],
          ),
          SizedBox(height: 34),
          _SettingsSection(
            title: '이용약관 및 정책',
            rows: [
              _SettingsValueRow(label: '이용약관'),
              _SettingsValueRow(label: '개인정보 처리방침'),
              _SettingsValueRow(label: '위치기반 서비스 이용약관'),
              _SettingsValueRow(label: '오픈소스 라이선스'),
            ],
          ),
        ],
      ),
    };
  }
}

class _EditFieldCard extends StatelessWidget {
  const _EditFieldCard({
    required this.icon,
    required this.label,
    required this.child,
    this.subLabel,
  });

  final IconData icon;
  final String label;
  final String? subLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSub, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subLabel != null) ...[
                const SizedBox(width: 6),
                Text(subLabel!, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CountedTextField extends StatefulWidget {
  const _CountedTextField({
    required this.controller,
    required this.maxLength,
    required this.maxLines,
  });

  final TextEditingController controller;
  final int maxLength;
  final int maxLines;

  @override
  State<_CountedTextField> createState() => _CountedTextFieldState();
}

class _CountedTextFieldState extends State<_CountedTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        counterText: '${widget.controller.text.length}/${widget.maxLength}',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }

  void _handleChange() {
    setState(() {});
  }
}

class _RegionSelector extends StatelessWidget {
  const _RegionSelector({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: const InputDecoration(
        suffixIcon: Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _RemovableInterestChip extends StatelessWidget {
  const _RemovableInterestChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primaryPinkSoft.withOpacity(0.68),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close_rounded,
              size: 15,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuCard extends StatelessWidget {
  const _SettingsMenuCard({required this.items, required this.onSelected});

  final List<_SettingsMenuItemData> items;
  final ValueChanged<_SettingsMenuItemData> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          _SettingsTile(data: item, onTap: () => onSelected(item)),
          if (item != items.last) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.data, required this.onTap});

  final _SettingsMenuItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: _SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(data.icon, color: AppColors.primaryPink, size: 34),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSub,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final row in rows) ...[
                row,
                if (row != rows.last)
                  const Divider(height: 1, color: AppColors.lineSoft),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsValueRow extends StatelessWidget {
  const _SettingsValueRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSub,
              size: 25,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsIconValueRow extends StatelessWidget {
  const _SettingsIconValueRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const _ProviderDot(color: Color(0xFFFFD400)),
            const SizedBox(width: 14),
            const _ProviderLetter(label: 'G', color: Color(0xFF4285F4)),
            const SizedBox(width: 14),
            const Icon(Icons.apple, color: AppColors.textMain, size: 24),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSub,
              size: 25,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatefulWidget {
  const _SettingsSwitchRow({
    required this.label,
    required this.initialValue,
    this.description,
  });

  final String label;
  final String? description;
  final bool initialValue;

  @override
  State<_SettingsSwitchRow> createState() => _SettingsSwitchRowState();
}

class _SettingsSwitchRowState extends State<_SettingsSwitchRow> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.description!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: _value,
            activeColor: AppColors.primaryPink,
            inactiveThumbColor: AppColors.bgDefault,
            inactiveTrackColor: AppColors.lineSoft,
            onChanged: (value) => setState(() => _value = value),
          ),
        ],
      ),
    );
  }
}

class _ProviderDot extends StatelessWidget {
  const _ProviderDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Container(
          width: 11,
          height: 11,
          decoration: const BoxDecoration(
            color: AppColors.textMain,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ProviderLetter extends StatelessWidget {
  const _ProviderLetter({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.titleMedium.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _AccountActionCard extends StatelessWidget {
  const _AccountActionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _AccountActionTile(
            icon: Icons.logout_rounded,
            label: '로그아웃',
            color: AppColors.textSub,
            onTap: onTap,
          ),
          const Divider(height: 1, color: AppColors.lineSoft),
          _AccountActionTile(
            icon: Icons.person_outline,
            label: '회원탈퇴',
            color: AppColors.primaryPurple,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 24),
            Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsMenuItemData {
  const _SettingsMenuItemData({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final _SettingsDetailType type;
  final IconData icon;
  final String title;
  final String subtitle;
}

enum _SettingsDetailType {
  account('계정'),
  privacy('개인정보 및 보안'),
  notification('알림'),
  app('앱 설정'),
  support('고객 지원');

  const _SettingsDetailType(this.title);

  final String title;
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineBrown),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryPinkSoft.withOpacity(0.64),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HorizontalChipList extends StatelessWidget {
  const _HorizontalChipList({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          return Center(child: _PillChip(label: labels[index]));
        },
      ),
    );
  }
}

class _OutlinedToken extends StatelessWidget {
  const _OutlinedToken({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMain),
      ),
    );
  }
}

class _PlacePreferenceRowData {
  const _PlacePreferenceRowData({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.places,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final List<String> places;
}

class _ProfileEditResult {
  const _ProfileEditResult({
    required this.realName,
    required this.visibility,
    required this.favoriteKeywords,
  });

  final String realName;
  final ProfileVisibility visibility;
  final List<String> favoriteKeywords;
}

class _ProfileSectionEditResult {
  const _ProfileSectionEditResult({
    required this.favoriteFoodTags,
    required this.dislikedFoodTags,
    required this.favoritePlaceTags,
    required this.dislikedPlaceTags,
    required this.planStyles,
    required this.preferredWeekdays,
    required this.preferredTimes,
    required this.unavailableDates,
  });

  final List<String> favoriteFoodTags;
  final List<String> dislikedFoodTags;
  final List<String> favoritePlaceTags;
  final List<String> dislikedPlaceTags;
  final List<String> planStyles;
  final List<String> preferredWeekdays;
  final List<String> preferredTimes;
  final List<String> unavailableDates;
}

enum _MyTab {
  profile('프로필'),
  friends('친구');

  const _MyTab(this.label);

  final String label;
}

enum _ProfileEditSection {
  keywords('음식/메뉴 취향 편집', '처음 취향 설정에서 고른 기준에 맞춰 좋아하는 메뉴와 피하고 싶은 메뉴를 관리해요.'),
  schedule('약속 스타일 편집', '약속 스타일, 선호 요일과 시간대를 조정하고 불가능한 날짜도 관리해요.'),
  places('장소/분위기 취향 편집', '처음 취향 설정에서 고른 장소 분위기와 피하고 싶은 조건을 관리해요.');

  const _ProfileEditSection(this.title, this.description);

  final String title;
  final String description;
}

enum _ProfileDetailSection {
  keywords('음식/메뉴 취향'),
  schedule('약속 스타일'),
  places('장소/분위기 취향'),
  savedPlaces('저장 장소 목록');

  const _ProfileDetailSection(this.title);

  final String title;
}

enum _ProfilePhotoOption { character, album, camera }

MyProfile _createInitialProfile() {
  return MyProfile(
    realName: '온이음',
    visibility: ProfileVisibility.friends,
    favoriteKeywords: ['한식', '디저트 카페', '조용한 대화 공간', '감성 있는 사진 맛집', '주말 약속'],
    dislikedKeywords: ['너무 매운 음식', '이동 시간이 긴 곳', '소음이 큰 곳'],
    favoriteFoodTags: ['한식', '디저트 카페', '고기/구이'],
    dislikedFoodTags: ['너무 매운 음식', '해산물'],
    favoritePlaceTags: ['조용한 대화 공간', '감성 있는 사진 맛집', '넓고 쾌적한 공간'],
    dislikedPlaceTags: ['이동 시간이 긴 곳', '소음이 큰 곳'],
    planStyles: ['미리 일정을 정하는 편', '주말에 여유롭게 만나고 싶어요'],
    preferredWeekdays: ['토요일', '일요일'],
    preferredTimes: ['오후', '저녁'],
    availableDays: ['토', '일'],
    unavailableDates: ['5/25 (일)', '6/8 (일)', '6/22 (일)'],
    favoritePlaces: [
      ProfilePlace(
        name: '성수 감성 카페',
        category: '카페',
        description: '조용하고 사진 찍기 좋은 곳',
      ),
    ],
    wantToGoPlaces: [
      ProfilePlace(name: '한강 피크닉', category: '야외', description: '노을 보는 산책 코스'),
    ],
    dislikedPlaces: [
      ProfilePlace(
        name: '복잡한 번화가',
        category: '혼잡',
        description: '소음과 대기가 많은 곳',
      ),
    ],
  );
}

List<FriendProfile> _createInitialFriends() {
  return [
    FriendProfile(
      name: '지연',
      preferenceSummary: '성수동 카페 투어 중  ☕',
      isFriend: true,
      memo: '@jiyoun',
    ),
    FriendProfile(
      name: '민수',
      preferenceSummary: '전시회, 음악 좋아해요  🎨',
      isFriend: true,
      memo: '@minsu',
    ),
    FriendProfile(
      name: '하린',
      preferenceSummary: '맛집 탐방러  🍜',
      isFriend: true,
      memo: '@harin',
    ),
    FriendProfile(
      name: '현우',
      preferenceSummary: '산책과 사진 찍기  📷',
      isFriend: true,
      memo: '@hyunwoo',
    ),
    FriendProfile(
      name: '소연',
      preferenceSummary: '감성 장소 찾는 중  ✨',
      isFriend: true,
      memo: '@soyeon',
    ),
    FriendProfile(
      name: '태오',
      preferenceSummary: '여행을 좋아해요  ✈',
      isFriend: true,
      memo: '@taeo',
    ),
    FriendProfile(
      name: '유나',
      preferenceSummary: '주말 브런치 메이트',
      isFriend: false,
      memo: '@yuna',
    ),
  ];
}

List<CharacterDraft> _createFriendCharacters() {
  return [
    CharacterDraft(
      gender: 'male',
      hairColorIndex: 0,
      hairStyleIndex: 0,
      topStyleIndex: 1,
    ),
    CharacterDraft(
      gender: 'female',
      hairColorIndex: 8,
      hairStyleIndex: 1,
      topStyleIndex: 2,
    ),
    CharacterDraft(
      gender: 'female',
      hairColorIndex: 5,
      hairStyleIndex: 2,
      topStyleIndex: 1,
    ),
    CharacterDraft(
      gender: 'male',
      hairColorIndex: 0,
      hairStyleIndex: 1,
      topStyleIndex: 2,
    ),
    CharacterDraft(
      gender: 'female',
      hairColorIndex: 1,
      hairStyleIndex: 0,
      topStyleIndex: 0,
    ),
    CharacterDraft(
      gender: 'male',
      hairColorIndex: 0,
      hairStyleIndex: 0,
      topStyleIndex: 2,
    ),
    CharacterDraft(
      gender: 'female',
      hairColorIndex: 4,
      hairStyleIndex: 3,
      topStyleIndex: 1,
    ),
  ];
}
