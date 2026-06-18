part of 'my_page.dart';

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
  const _ProfileHero({
    required this.profile,
    this.publicId,
    this.profileImageUrl,
    required this.onEdit,
  });

  final MyProfile profile;
  final String? publicId;
  final String? profileImageUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cleanPublicId = publicId?.trim();
    final cleanRegion = profile.region.trim();
    final cleanIntro = profile.introText.trim();
    final cleanRealName = profile.realName.trim();
    final headline =
        cleanRealName.isEmpty || cleanRealName.toLowerCase() == 'onmu user'
        ? '사용자'
        : cleanRealName;

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CharacterPortrait(size: 88, profileImageUrl: profileImageUrl),
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
                            headline,
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
                    const SizedBox(height: 4),
                    Text(
                      cleanPublicId == null || cleanPublicId.isEmpty
                          ? '@ID 준비 중'
                          : '@$cleanPublicId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    if (cleanRegion.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textSub,
                            size: 17,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              cleanRegion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
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
          const SizedBox(height: 12),
          _HorizontalChipList(
            labels: profile.favoriteKeywords.take(5).toList(),
          ),
          if (cleanIntro.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '"$cleanIntro"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CharacterPortrait extends ConsumerWidget {
  const _CharacterPortrait({
    required this.size,
    this.character,
    this.profileImageUrl,
  });

  final double size;
  final CharacterDraft? character;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft =
        character ??
        ref.watch(userCharacterProvider) ??
        ref.watch(characterProfileProvider).value ??
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

    final imageUrl = resolveOnmuMediaUrl(profileImageUrl);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primaryPinkSoft.withOpacity(0.32),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.linePink.withOpacity(0.55)),
      ),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _CharacterPortraitFallback(size: size, draft: draft),
            )
          : _CharacterPortraitFallback(size: size, draft: draft),
    );
  }
}

class _CharacterPortraitFallback extends StatelessWidget {
  const _CharacterPortraitFallback({required this.size, required this.draft});

  final double size;
  final CharacterDraft draft;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
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
              trailingWidget: _KeywordScroller(
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
              trailingWidget: _KeywordScroller(
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
              trailingWidget: _KeywordScroller(
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
