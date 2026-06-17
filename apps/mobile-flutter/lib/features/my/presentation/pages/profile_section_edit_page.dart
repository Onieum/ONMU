part of 'my_page.dart';

class _ProfileSectionEditPage extends StatefulWidget {
  const _ProfileSectionEditPage({
    required this.section,
    required this.profile,
    required this.onSave,
  });

  final _ProfileEditSection section;
  final MyProfile profile;
  final Future<void> Function(_ProfileSectionEditResult) onSave;

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
  var _isSaving = false;

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
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: AppColors.bgDefault,
        body: SafeArea(
          child: GridBackground(
            child: Column(
              children: [
                _EditPageTopBar(
                  title: widget.section.title,
                  actionLabel: _isSaving ? '저장 중' : '저장',
                  onBack: _isSaving ? () {} : () => Navigator.of(context).pop(),
                  onAction: _isSaving ? null : _save,
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
                          _ProfileEditSection.schedule =>
                            _buildScheduleEditor(),
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
            onAdd: (value) => _addCustomValue(_favoriteFoodTags, value),
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
            onAdd: (value) => _addCustomValue(_dislikedFoodTags, value),
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
      '대기 시간이 긴 곳은 피하고 싶어요',
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
            onAdd: (value) => _addCustomValue(_planStyles, value),
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
            onAdd: (value) => _addCustomValue(_preferredTimes, value),
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
            onAdd: (value) => _addCustomValue(_favoritePlaceTags, value),
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
            onAdd: (value) => _addCustomValue(_dislikedPlaceTags, value),
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

  void _addCustomValue(List<String> target, String value) {
    final clean = value.trim();
    if (clean.isEmpty || target.contains(clean)) {
      return;
    }
    setState(() => target.add(clean));
  }

  String _formatKoreanDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}/${date.day} ($weekday)';
  }

  Future<void> _pickUnavailableDate() async {
    final now = DateTime.now();
    final picked = await OnmuDatePicker.pickDate(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: '불가능한 날짜 선택',
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

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    final result = _ProfileSectionEditResult(
      favoriteFoodTags: _favoriteFoodTags,
      dislikedFoodTags: _dislikedFoodTags,
      favoritePlaceTags: _favoritePlaceTags,
      dislikedPlaceTags: _dislikedPlaceTags,
      planStyles: _planStyles,
      preferredWeekdays: _preferredWeekdays,
      preferredTimes: _preferredTimes,
      unavailableDates: _unavailableDates,
    );
    setState(() => _isSaving = true);
    try {
      await widget.onSave(result);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 저장에 실패했어요. 잠시 후 다시 시도해주세요.')),
      );
    }
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

class _ToggleChipWrap extends StatefulWidget {
  const _ToggleChipWrap({
    required this.values,
    required this.selectedValues,
    required this.onToggle,
    this.onAdd,
  });

  final List<String> values;
  final List<String> selectedValues;
  final ValueChanged<String> onToggle;
  final ValueChanged<String>? onAdd;

  @override
  State<_ToggleChipWrap> createState() => _ToggleChipWrapState();
}

class _ToggleChipWrapState extends State<_ToggleChipWrap> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onAdd?.call(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final mergedValues = [
      ...widget.values,
      for (final value in widget.selectedValues)
        if (!widget.values.contains(value)) value,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in mergedValues)
              ChoiceChip(
                label: Text(value, overflow: TextOverflow.ellipsis),
                selected: widget.selectedValues.contains(value),
                onSelected: (_) => widget.onToggle(value),
                selectedColor: AppColors.primaryPinkSoft.withOpacity(0.82),
                backgroundColor: AppColors.bgWarm,
                side: BorderSide(
                  color: widget.selectedValues.contains(value)
                      ? AppColors.linePink
                      : AppColors.lineSoft,
                ),
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: widget.selectedValues.contains(value)
                      ? AppColors.primaryPurple
                      : AppColors.textMain,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        if (widget.onAdd != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                  decoration: const InputDecoration(
                    hintText: '직접 추가',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _add, child: const Text('추가')),
            ],
          ),
        ],
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
        SizedBox(
          width: double.infinity,
          height: 42,
          child: dates.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '선택한 날짜가 없어요',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    return Center(
                      child: _EditableTagChip(
                        label: date,
                        selected: false,
                        onRemove: () => onRemoveDate(date),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onAddDate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('날짜 추가'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryPink,
              side: const BorderSide(color: AppColors.linePink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
