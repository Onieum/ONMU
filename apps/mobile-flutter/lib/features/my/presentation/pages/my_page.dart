import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/onmu_button.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../domain/my_profile.dart';
import '../widgets/profile_avatar.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  var _selectedTab = _MyTab.profile;
  var _profile = _mockProfile;
  var _friends = _mockFriends;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이 ONMU')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(profile: _profile, onEdit: _showProfileEditor),
              const SizedBox(height: AppSpacing.md),
              _MyTabBar(
                selectedTab: _selectedTab,
                onChanged: (tab) => setState(() => _selectedTab = tab),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_selectedTab == _MyTab.profile)
                _ProfileTab(profile: _profile, onEditList: _showListEditor)
              else
                _FriendsTab(
                  friends: _friends.where((friend) => friend.isFriend).toList(),
                  onOpenAddFriend: _showFriendAddSheet,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProfileEditor() async {
    final result = await showModalBottomSheet<_ProfileEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProfileEditSheet(profile: _profile),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _profile = _profile.copyWith(
        realName: result.realName,
        visibility: result.visibility,
      );
    });
  }

  Future<void> _showListEditor(_PreferenceField field) async {
    if (field == _PreferenceField.availableDays) {
      final values = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return _WeekdaySelectSheet(values: _profile.availableDays);
        },
      );

      if (values == null) {
        return;
      }

      setState(() {
        _profile = _profile.copyWith(availableDays: values);
      });
      return;
    }

    if (field == _PreferenceField.unavailableDates) {
      final values = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return _UnavailableDateSheet(values: _profile.unavailableDates);
        },
      );

      if (values == null) {
        return;
      }

      setState(() {
        _profile = _profile.copyWith(unavailableDates: values);
      });
      return;
    }

    final currentValues = switch (field) {
      _PreferenceField.favoriteKeywords => _profile.favoriteKeywords,
      _PreferenceField.dislikedKeywords => _profile.dislikedKeywords,
      _PreferenceField.preferredTimes => _profile.preferredTimes,
      _PreferenceField.availableDays => _profile.availableDays,
      _PreferenceField.unavailableDates => _profile.unavailableDates,
    };

    final values = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _ListEditSheet(title: field.title, values: currentValues);
      },
    );

    if (values == null) {
      return;
    }

    setState(() {
      _profile = switch (field) {
        _PreferenceField.favoriteKeywords => _profile.copyWith(
          favoriteKeywords: values,
        ),
        _PreferenceField.dislikedKeywords => _profile.copyWith(
          dislikedKeywords: values,
        ),
        _PreferenceField.preferredTimes => _profile.copyWith(
          preferredTimes: values,
        ),
        _PreferenceField.availableDays => _profile.copyWith(
          availableDays: values,
        ),
        _PreferenceField.unavailableDates => _profile.copyWith(
          unavailableDates: values,
        ),
      };
    });
  }

  void _addFriend(FriendProfile target) {
    setState(() {
      _friends = [
        for (final friend in _friends)
          if (friend.name == target.name)
            friend.copyWith(isFriend: true)
          else
            friend,
      ];
    });
  }

  Future<void> _showFriendAddSheet() async {
    final result = await showModalBottomSheet<FriendProfile>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _FriendAddSheet(
          candidates: _friends.where((friend) => !friend.isFriend).toList(),
        );
      },
    );

    if (result == null) {
      return;
    }

    _addFriend(result);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});

  final MyProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      child: Row(
        children: [
          const ProfileAvatar(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.realName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('나의 아바타', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                OnmuSecondaryButton(
                  label: '프로필 수정',
                  onPressed: onEdit,
                  icon: Icons.edit_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyTabBar extends StatelessWidget {
  const _MyTabBar({required this.selectedTab, required this.onChanged});

  final _MyTab selectedTab;
  final ValueChanged<_MyTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth < 300.0
            ? constraints.maxWidth
            : 300.0;

        return Center(
          child: SizedBox(
            width: tabWidth,
            child: DefaultTabController(
              length: _MyTab.values.length,
              initialIndex: selectedTab.index,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bgDefault,
                  border: Border.all(color: AppColors.lineSoft),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: TabBar(
                  onTap: (index) => onChanged(_MyTab.values[index]),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primaryPinkSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primaryPink),
                  ),
                  labelColor: AppColors.textMain,
                  unselectedLabelColor: AppColors.textSub,
                  tabs: const [
                    Tab(icon: Icon(Icons.badge_outlined), text: '프로필'),
                    Tab(icon: Icon(Icons.group_outlined), text: '친구'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.profile, required this.onEditList});

  final MyProfile profile;
  final ValueChanged<_PreferenceField> onEditList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreferenceCard(
          title: _PreferenceField.favoriteKeywords.title,
          values: profile.favoriteKeywords,
          icon: Icons.favorite_outline,
          onEdit: () => onEditList(_PreferenceField.favoriteKeywords),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PreferenceCard(
          title: _PreferenceField.dislikedKeywords.title,
          values: profile.dislikedKeywords,
          icon: Icons.heart_broken_outlined,
          onEdit: () => onEditList(_PreferenceField.dislikedKeywords),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PreferenceCard(
          title: _PreferenceField.preferredTimes.title,
          values: profile.preferredTimes,
          icon: Icons.schedule_outlined,
          onEdit: () => onEditList(_PreferenceField.preferredTimes),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PreferenceCard(
          title: _PreferenceField.availableDays.title,
          values: profile.availableDays,
          icon: Icons.calendar_month_outlined,
          onEdit: () => onEditList(_PreferenceField.availableDays),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PreferenceCard(
          title: _PreferenceField.unavailableDates.title,
          values: profile.unavailableDates,
          icon: Icons.event_busy_outlined,
          onEdit: () => onEditList(_PreferenceField.unavailableDates),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PlaceListSection(title: '좋아하는 장소', places: profile.favoritePlaces),
        const SizedBox(height: AppSpacing.sm),
        _PlaceListSection(title: '가고싶은 장소', places: profile.wantToGoPlaces),
        const SizedBox(height: AppSpacing.sm),
        _PlaceListSection(title: '싫어하는 장소', places: profile.dislikedPlaces),
      ],
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.title,
    required this.values,
    required this.icon,
    required this.onEdit,
  });

  final String title;
  final List<String> values;
  final IconData icon;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditableSectionHeader(title: title, onEdit: onEdit),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final value in values) OnmuChip(label: value, icon: icon),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditableSectionHeader extends StatelessWidget {
  const _EditableSectionHeader({required this.title, required this.onEdit});

  final String title;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton(onPressed: onEdit, child: const Text('수정')),
      ],
    );
  }
}

class _PlaceListSection extends StatelessWidget {
  const _PlaceListSection({required this.title, required this.places});

  final String title;
  final List<ProfilePlace> places;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final place in places) ...[
            _PlaceTile(place: place),
            if (place != places.last) const Divider(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place});

  final ProfilePlace place;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bgGrid,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.place_outlined, color: AppColors.accentBrown),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text('${place.category} · ${place.description}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({required this.friends, required this.onOpenAddFriend});

  final List<FriendProfile> friends;
  final VoidCallback onOpenAddFriend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OnmuSecondaryButton(
            label: '친구 추가',
            icon: Icons.person_add_alt_1_outlined,
            onPressed: onOpenAddFriend,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final friend in friends) ...[
          _FriendCard(friend: friend),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (friends.isEmpty) const OnmuCard(child: Text('아직 친구가 없어요.')),
      ],
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend});

  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      child: Row(
        children: [
          const ProfileAvatar(size: 52),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(friend.preferenceSummary),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
    if (_query.trim().isEmpty) {
      return widget.candidates;
    }

    return widget.candidates
        .where((candidate) => candidate.name.contains(_query.trim()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '친구 추가',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '친구로 추가할 이름 검색',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final candidate in _filteredCandidates) ...[
                    _FriendCandidateCard(candidate: candidate),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (_filteredCandidates.isEmpty)
                    const OnmuCard(child: Text('검색 결과가 없어요.')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCandidateCard extends StatelessWidget {
  const _FriendCandidateCard({required this.candidate});

  final FriendProfile candidate;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      child: Row(
        children: [
          const ProfileAvatar(size: 52),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(candidate.preferenceSummary),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _FriendCandidateAddButton(
            onPressed: () => Navigator.of(context).pop(candidate),
          ),
        ],
      ),
    );
  }
}

class _FriendCandidateAddButton extends StatelessWidget {
  const _FriendCandidateAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMain,
          backgroundColor: AppColors.bgDefault,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: AppColors.lineBrown),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: Text(
          '추가하기',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textMain,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({required this.profile});

  final MyProfile profile;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _nameController;
  late ProfileVisibility _visibility;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.realName);
    _visibility = widget.profile.visibility;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('프로필 수정', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '본명'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('공개 범위 설정', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final visibility in ProfileVisibility.values)
                ChoiceChip(
                  label: Text(visibility.label),
                  selected: _visibility == visibility,
                  onSelected: (_) => setState(() => _visibility = visibility),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _ProfileEditResult(
                    realName: _nameController.text.trim(),
                    visibility: _visibility,
                  ),
                );
              },
              child: const Text('저장하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdaySelectSheet extends StatefulWidget {
  const _WeekdaySelectSheet({required this.values});

  final List<String> values;

  @override
  State<_WeekdaySelectSheet> createState() => _WeekdaySelectSheetState();
}

class _WeekdaySelectSheetState extends State<_WeekdaySelectSheet> {
  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  late final Set<String> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.values.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('가능 요일 선택', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '약속이 가능한 요일을 여러 개 선택해요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final weekday in _weekdays)
                  ChoiceChip(
                    label: Text(weekday),
                    selected: _selectedDays.contains(weekday),
                    onSelected: (_) {
                      setState(() {
                        if (_selectedDays.contains(weekday)) {
                          _selectedDays.remove(weekday);
                        } else {
                          _selectedDays.add(weekday);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final values = _weekdays
                      .where((weekday) => _selectedDays.contains(weekday))
                      .toList();
                  Navigator.of(context).pop(values);
                },
                child: const Text('저장하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableDateSheet extends StatefulWidget {
  const _UnavailableDateSheet({required this.values});

  final List<String> values;

  @override
  State<_UnavailableDateSheet> createState() => _UnavailableDateSheetState();
}

class _UnavailableDateSheetState extends State<_UnavailableDateSheet> {
  late final Set<int> _selectedDays;
  final _month = DateTime(2026, 6);

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.values.map(_parseDay).whereType<int>().toSet();
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_month.year, _month.month).weekday % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('불가능한 날짜 선택', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '약속이 어려운 날짜를 여러 개 선택해요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                '6월 2026',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _CalendarWeekHeader(),
            const SizedBox(height: AppSpacing.xs),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: firstWeekday + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
              ),
              itemBuilder: (context, index) {
                if (index < firstWeekday) {
                  return const SizedBox.shrink();
                }

                final day = index - firstWeekday + 1;
                final selected = _selectedDays.contains(day);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryPinkSoft
                          : AppColors.bgDefault,
                      border: Border.all(
                        color: selected
                            ? AppColors.linePink
                            : AppColors.lineSoft,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: selected
                                  ? AppColors.primaryPink
                                  : AppColors.textSub,
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final day in _selectedDays.toList()..sort())
                  OnmuChip(label: '6월 $day일', icon: Icons.event_busy_outlined),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final values = (_selectedDays.toList()..sort())
                      .map((day) => '6월 $day일')
                      .toList();
                  Navigator.of(context).pop(values);
                },
                child: const Text('저장하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _parseDay(String value) {
    final match = RegExp(r'6월\s*(\d+)일').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}

class _CalendarWeekHeader extends StatelessWidget {
  const _CalendarWeekHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
      ],
    );
  }
}

class _ListEditSheet extends StatefulWidget {
  const _ListEditSheet({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  State<_ListEditSheet> createState() => _ListEditSheetState();
}

class _ListEditSheetState extends State<_ListEditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.values.join(', '));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(helperText: '쉼표로 구분해 입력해요.'),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final values = _controller.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList();
                Navigator.of(context).pop(values);
              },
              child: const Text('저장하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditResult {
  const _ProfileEditResult({required this.realName, required this.visibility});

  final String realName;
  final ProfileVisibility visibility;
}

enum _MyTab { profile, friends }

enum _PreferenceField {
  favoriteKeywords('선호 키워드'),
  dislikedKeywords('비선호 키워드'),
  preferredTimes('선호 약속 시간'),
  availableDays('가능 요일'),
  unavailableDates('불가능한 날짜');

  const _PreferenceField(this.title);

  final String title;
}

const _mockProfile = MyProfile(
  realName: '김온무',
  visibility: ProfileVisibility.friends,
  favoriteKeywords: ['조용한 카페', '파스타', '전시'],
  dislikedKeywords: ['웨이팅 긴 곳', '매운 음식'],
  preferredTimes: ['평일 저녁', '토요일 오후'],
  availableDays: ['화', '목', '토'],
  unavailableDates: ['6월 12일', '6월 21일'],
  favoritePlaces: [
    ProfilePlace(
      name: '연남 작은정원',
      category: '브런치',
      description: '친구와 오래 이야기하기 좋아요',
    ),
    ProfilePlace(
      name: '성수 문구방',
      category: '소품샵',
      description: '기록 스티커를 고르기 좋아요',
    ),
  ],
  wantToGoPlaces: [
    ProfilePlace(
      name: '망원 북스테이',
      category: '책방',
      description: '비 오는 날 가보고 싶어요',
    ),
  ],
  dislikedPlaces: [
    ProfilePlace(name: '강남 혼잡골목', category: '번화가', description: '소음과 대기가 많아요'),
  ],
);

const _mockFriends = [
  FriendProfile(
    name: '이지수',
    preferenceSummary: '한강 산책과 카페를 좋아해요',
    isFriend: false,
  ),
  FriendProfile(
    name: '최민준',
    preferenceSummary: '조용한 밥집과 전시 약속을 선호해요',
    isFriend: true,
  ),
  FriendProfile(
    name: '한서연',
    preferenceSummary: '디저트 카페와 주말 낮 약속을 좋아해요',
    isFriend: true,
  ),
];
