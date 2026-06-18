import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/onmu_media_url.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/character_model.dart';
import '../../../../shared/providers/state_providers.dart';
import '../../../../shared/widgets/grid_background.dart';
import '../../../../shared/widgets/onmu_date_picker.dart';
import '../../../../shared/widgets/pixel_character.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../character/presentation/pages/character_start_page.dart';
import '../../../character/repository/character_repository.dart';
import '../../domain/korea_region.dart';
import '../../domain/my_profile.dart';
import '../../repository/friend_repository.dart';
import '../../repository/my_repository.dart';
import '../../view_model/my_profile_controller.dart';

part 'my_page_profile_widgets.dart';
part 'my_page_friends.dart';
part 'friend_profile_page.dart';
part 'profile_detail_page.dart';
part 'profile_section_edit_page.dart';
part 'profile_edit_page.dart';
part 'settings_page.dart';

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key, this.resetToken});

  final String? resetToken;

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  var _selectedTab = _MyTab.profile;

  @override
  void didUpdateWidget(covariant MyPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.resetToken != oldWidget.resetToken) {
      _selectedTab = _MyTab.profile;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authBootstrapProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final authUser = ref.watch(authUserProvider);
    final profile = _profileForAuthUser(
      profileAsync.value ?? _emptyProfile(),
      authUser,
    );
    final friends = friendsAsync.value ?? const <FriendProfile>[];

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
                    profile: profile,
                    publicId: authUser?.publicId,
                    profileImageUrl: authUser?.profileImageUrl,
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
                            profile: profile,
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
                            friends: friends,
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

  Future<void> _toggleFavoriteFriend(FriendProfile friend) async {
    await ref.read(myProfileControllerProvider).toggleFavoriteFriend(friend);
  }

  Future<void> _showProfileEditor() async {
    final profile = _profileForAuthUser(
      ref.read(myProfileProvider).value ?? _emptyProfile(),
      ref.read(authUserProvider),
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _ProfileEditPage(
          profile: profile,
          initialCharacter:
              ref.read(userCharacterProvider) ??
              ref.read(characterProfileProvider).value,
          profileImageUrl: ref.read(authUserProvider)?.profileImageUrl,
          onCharacterSaved: _saveCharacterDraft,
          onSave: (result) => _saveProfileEditResult(result, profile),
        ),
      ),
    );
  }

  Future<void> _saveProfileEditResult(
    _ProfileEditResult result,
    MyProfile fallbackProfile,
  ) async {
    final latestProfile = _profileForAuthUser(
      ref.read(myProfileProvider).value ?? fallbackProfile,
      ref.read(authUserProvider),
    );
    final updatedProfile = latestProfile.copyWith(
      realName: result.realName,
      introText: result.introText,
      region: result.region,
      regionSelection: result.regionSelection,
      regionVisibility: result.regionVisibility,
      visibility: result.visibility,
      favoriteKeywords: result.favoriteKeywords,
    );
    await ref.read(myProfileControllerProvider).saveProfile(updatedProfile);
  }

  Future<void> _saveCharacterDraft(CharacterDraft draft) async {
    await ref.read(myProfileControllerProvider).saveCharacter(draft);
  }

  Future<void> _openProfileSectionEditor(_ProfileEditSection section) async {
    final profile = _profileForAuthUser(
      ref.read(myProfileProvider).value ?? _emptyProfile(),
      ref.read(authUserProvider),
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _ProfileSectionEditPage(
          section: section,
          profile: profile,
          onSave: (result) => _saveProfileSectionEditResult(result, profile),
        ),
      ),
    );
  }

  Future<void> _saveProfileSectionEditResult(
    _ProfileSectionEditResult result,
    MyProfile fallbackProfile,
  ) async {
    final latestProfile = _profileForAuthUser(
      ref.read(myProfileProvider).value ?? fallbackProfile,
      ref.read(authUserProvider),
    );
    final updatedProfile = latestProfile.copyWith(
      favoriteFoodTags: result.favoriteFoodTags,
      dislikedFoodTags: result.dislikedFoodTags,
      favoritePlaceTags: result.favoritePlaceTags,
      dislikedPlaceTags: result.dislikedPlaceTags,
      planStyles: result.planStyles,
      preferredWeekdays: result.preferredWeekdays,
      preferredTimes: result.preferredTimes,
      unavailableDates: result.unavailableDates,
    );
    await ref.read(myProfileControllerProvider).saveProfile(updatedProfile);
  }

  void _openProfileDetailPage(_ProfileDetailSection section) {
    final profile = _profileForAuthUser(
      ref.read(myProfileProvider).value ?? _emptyProfile(),
      ref.read(authUserProvider),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            _ProfileDetailPage(section: section, profile: profile),
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
        builder: (context) => _FriendProfilePage(friend: friend),
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
        return const _FriendAddSheet();
      },
    );

    if (result == null) {
      return;
    }

    await ref.read(myProfileControllerProvider).addFriend(result.publicId);
  }
}

MyProfile _emptyProfile() {
  return const MyProfile(
    realName: '',
    visibility: ProfileVisibility.friends,
    favoriteKeywords: [],
    dislikedKeywords: [],
    preferredTimes: [],
    availableDays: [],
    unavailableDates: [],
    favoritePlaces: [],
    wantToGoPlaces: [],
    dislikedPlaces: [],
  );
}

MyProfile _profileForAuthUser(MyProfile profile, AuthUser? user) {
  if (profile.realName.trim().isNotEmpty) {
    return profile;
  }

  final displayName = user?.displayName.trim();
  if (displayName == null || displayName.isEmpty) {
    return profile.copyWith(realName: '사용자');
  }
  return profile.copyWith(realName: displayName);
}
