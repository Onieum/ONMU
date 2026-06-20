part of 'my_page.dart';

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
    final unavailableDates = visibleUnavailableDates(
      profile.unavailableDates,
    ).map(formatUnavailableDateForDisplay).toList(growable: false);
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
          values: unavailableDates,
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w900,
                  ),
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
