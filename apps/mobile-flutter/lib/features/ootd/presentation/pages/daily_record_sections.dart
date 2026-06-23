part of 'daily_record_screen.dart';

extension _DailyRecordScreenSections on _DailyRecordScreenState {
  Widget _buildContent() {
    switch (_currentStep) {
      case 0:
        return _buildEntryPage();
      case 1:
        return _buildPhotoMemoPage();
      case 2:
        return _buildMoodWeatherPage();
      case 3:
        return _buildOotdPage();
      case 4:
        return _buildCrewPage();
      case 5:
        return _buildThemePage();
      case 6:
        return _buildCompletePage();
      case 7:
        final savedRecord = _savedRecord;
        if (savedRecord == null) return _buildCompletePage();
        return DailyRecordResultScreen(
          record: savedRecord,
          userCharacter: widget.userCharacter,
          ootdRecord: _linkedOotdRecord,
          includeCrew: _includeCrew,
          photoCount: _savedPhotoCount,
          captureKey: _resultCaptureKey,
          onEdit: () {
            final id = savedRecord.id;
            if (id == null || id.isEmpty) return;
            context.go(RoutePaths.recordEdit(id));
          },
        );
      default:
        return SizedBox();
    }
  }

  Widget _buildEntryPage() {
    return RecordEntryIntro(
      character: widget.userCharacter,
      title: '오늘 하루 기록하기',
      subtitle: '\n하루를 한 장씩 남겨볼까요?',
      bannerText: '사진, 메모, 기분, 날씨, OOTD,\n함께한 크루까지 차례대로 기록해요.',
      topLeftIcon: Icons.auto_stories_outlined,
      topLeftColor: AppColors.primaryPink,
      bottomRightIcon: Icons.edit_note_outlined,
      bottomRightColor: AppColors.textMuted,
    );
  }

  Widget _buildPhotoMemoPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('사진과 코멘트', '사진을 추가하고 사진마다 짧은 코멘트를 남겨보세요.'),
        ...List.generate(
          _photoMemos.length,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == _photoMemos.length - 1 ? 12 : 16,
            ),
            child: _buildPhotoMemoCard(index),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _addPhotoMemo,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text('사진 추가하기'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: AppColors.primaryPink,
            side: const BorderSide(color: AppColors.linePink),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodWeatherPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('오늘의 기분과 날씨', '하루의 분위기와 날씨를 기록해 보세요.'),
        Text('오늘의 기분', style: _dailyRecordLabelStyle),
        SizedBox(height: 8),
        _choiceGrid(
          _moods,
          _selectedMood,
          (index) => _updateState(() => _selectedMood = index),
        ),
        SizedBox(height: 20),
        Text('오늘의 날씨', style: _dailyRecordLabelStyle),
        SizedBox(height: 8),
        _choiceGrid(
          _weathers,
          _selectedWeather,
          (index) => _updateState(() => _selectedWeather = index),
        ),
        SizedBox(height: 20),
        Text('하루 태그', style: _dailyRecordLabelStyle),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(hintText: '# 카페 #산책 #기록'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTag(),
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 92,
              child: ElevatedButton(
                onPressed: _addTag,
                child: const Text('추가', maxLines: 1, softWrap: false),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _hashtags
              .map(
                (tag) => Chip(
                  label: Text(tag, style: AppTextStyles.labelMedium),
                  backgroundColor: AppColors.primaryPinkSoft,
                  deleteIconColor: AppColors.primaryPink,
                  onDeleted: _hashtags.length == 1
                      ? null
                      : () => _updateState(() => _hashtags.remove(tag)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPhotoMemoCard(int index) {
    final photo = _photoMemos[index];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: photo.hasPhoto ? AppColors.primaryPink : AppColors.lineSoft,
          width: photo.hasPhoto ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMain.withValues(alpha: 0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryPinkSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '사진 ${index + 1}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
              ),
              if (_photoMemos.length > 1)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removePhotoMemo(index),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () => _pickPhoto(index),
            child: Container(
              width: double.infinity,
              height: 126,
              decoration: BoxDecoration(
                color: photo.hasPhoto
                    ? AppColors.primaryPinkSoft.withOpacity(0.52)
                    : AppColors.bgPaper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: photo.hasPhoto
                      ? AppColors.primaryPink
                      : AppColors.lineBrown,
                ),
              ),
              child: photo.imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        photo.imageBytes!,
                        width: double.infinity,
                        height: 126,
                        fit: BoxFit.cover,
                      ),
                    )
                  : photo.originalUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        photo.originalUrl!,
                        width: double.infinity,
                        height: 126,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          photo.hasPhoto
                              ? Icons.image_outlined
                              : Icons.add_a_photo_outlined,
                          color: photo.hasPhoto
                              ? AppColors.primaryPink
                              : AppColors.textMuted,
                          size: 11,
                        ),
                        SizedBox(height: 8),
                        Text(
                          photo.hasPhoto ? '사진 선택됨' : '사진 선택하기',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: photo.controller,
            maxLines: 2,
            maxLength: _photoCommentMaxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: '사진에 대한 코멘트',
              counterStyle: AppTextStyles.tiny.copyWith(
                color: AppColors.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOotdPage() {
    final ootd = _linkedOotdRecord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('오늘의 OOTD', '오늘 입은 코디도 함께 기록할 수 있어요. 건너뛰면 하루 일과만 저장됩니다.'),
        if (ootd != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryPurple, width: 1.4),
            ),
            child: Column(
              children: [
                Text(
                  'OOTD 기록이 연결되었어요',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                SizedBox(height: 14),
                PixelCharacterWidget(character: ootd.character, size: 96),
                SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: ootd.moodTags
                      .take(4)
                      .map(
                        (tag) => Chip(
                          label: Text(tag, style: AppTextStyles.labelSmall),
                          backgroundColor: AppColors.primaryPurpleSoft,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgPaper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.checkroom_outlined,
                  size: 38,
                  color: AppColors.primaryPurple,
                ),
                SizedBox(height: 12),
                Text(
                  '건너뛰면 하루 일과만 저장됩니다.',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'OOTD를 기록하면 오늘의 일과에 함께 남길 수 있어요.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSub,
                  ),
                ),
                SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final saved = await widget.onCreateOotd();
                    if (!mounted || saved == null) return;
                    _updateState(() {
                      _linkedOotdRecord = saved;
                      _includeCrew = true;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text('OOTD 기록하고 돌아오기'),
                ),
                SizedBox(height: 8),
                Text(
                  '건너뛰면 하루 일과만 저장됩니다.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCrewPage() {
    if (_shouldSkipCrewStep) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            '\uD568\uAED8\uD55C \uD06C\uB8E8',
            '\uC624\uB298 \uC5F0\uACB0\uB41C \uC57D\uC18D \uBA64\uBC84\uAC00 \uC5C6\uC5B4 \uD06C\uB8E8 \uC120\uD0DD\uC744 \uAC74\uB108\uB701\uC5B4\uC694.',
          ),
          SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.bgDefault,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: Text(
              '\uD568\uAED8\uD55C \uD06C\uB8E8\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4. \uD63C\uC790\uB9CC\uC758 \uD558\uB8E8\uB97C \uAE30\uB85D\uD560\uAC8C\uC694.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSub,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('함께한 크루', '오늘을 함께한 크루를 선택해 주세요.'),
        Row(
          children: [
            Expanded(child: _toggleCard('크루와 함께', Icons.groups_outlined, true)),
            SizedBox(width: 12),
            Expanded(child: _toggleCard('나만 넣기', Icons.person_outline, false)),
          ],
        ),
        SizedBox(height: 28),
        Center(
          child: _isLoadingCrewAppearances
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: CircularProgressIndicator(),
                )
              : Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    PixelCharacterWidget(
                      character: widget.userCharacter,
                      size: 86,
                    ),
                    if (_includeCrew && _crewAppearances.isNotEmpty)
                      ..._crewAppearances.map(
                        (appearance) =>
                            _crewAppearanceAvatar(appearance, size: 76),
                      )
                    else if (_includeCrew)
                      ..._crewCharacters.map(
                        (character) => PixelCharacterWidget(
                          character: character,
                          size: 76,
                        ),
                      ),
                  ],
                ),
        ),
        if (_includeCrew && !_isLoadingCrewAppearances && !_hasCrew) ...[
          SizedBox(height: 18),
          Text(
            '\uC624\uB298 \uC57D\uC18D\uC5D0\uC11C \uBD88\uB7EC\uC62C \uD06C\uB8E8 \uCE90\uB9AD\uD130\uAC00 \uC5C6\uC5B4\uC694.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
          ),
        ],
      ],
    );
  }

  Widget _buildThemePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('기록 스타일', '다이어리처럼 꾸미거나 깔끔한 카드로 남겨보세요.'),
        _themeCard(
          index: 0,
          title: '다이어리 형식',
          subtitle: '사진과 스티커가 어우러진 감성적인 스크랩북 스타일로 저장해요.',
          icon: Icons.interests_outlined,
          color: AppColors.primaryPink,
        ),
        SizedBox(height: 14),
        _themeCard(
          index: 1,
          title: '클린 형식',
          subtitle: '사진과 메모를 깔끔하게 정리한 카드 스타일로 저장해요.',
          icon: Icons.view_agenda_outlined,
          color: AppColors.primaryPurple,
        ),
        SizedBox(height: 20),
        TextField(
          controller: _dayMemoController,
          maxLines: 5,
          maxLength: 300,
          decoration: const InputDecoration(hintText: '오늘 하루를 자유롭게 적어보세요.'),
        ),
      ],
    );
  }

  Widget _buildCompletePage() {
    final isDiary = _selectedTheme == 0;

    return Column(
      children: [
        SizedBox(height: 8),
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.accentGreen,
          size: 34,
        ),
        SizedBox(height: 10),
        Text(
          '하루 일과 기록이 저장됐어요',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: 8),
        Text(
          isDiary ? '다이어리 형식으로 하루를 꾸며 저장했어요.' : '클린 형식으로 하루를 정리해 저장했어요.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDiary ? AppColors.bgPaper : AppColors.bgDefault,
            borderRadius: BorderRadius.circular(isDiary ? 16 : 10),
            border: Border.all(
              color: isDiary ? AppColors.lineBrown : AppColors.lineSoft,
              width: isDiary ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (_linkedOotdRecord != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PixelCharacterWidget(
                      character: widget.userCharacter,
                      size: 78,
                    ),
                    if (_selectedCrewAppearances.isNotEmpty)
                      ..._selectedCrewAppearances
                          .take(3)
                          .map(
                            (appearance) => Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: _crewAppearanceAvatar(
                                appearance,
                                size: 66,
                              ),
                            ),
                          )
                    else if (_selectedCrewCharacters.isNotEmpty)
                      ..._selectedCrewCharacters
                          .take(3)
                          .map(
                            (character) => Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: PixelCharacterWidget(
                                character: character,
                                size: 66,
                              ),
                            ),
                          ),
                  ],
                ),
                SizedBox(height: 14),
              ],
              Text(
                '${_weathers[_selectedWeather].label} · ${_moods[_selectedMood].label}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textMain,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _hashtags
                    .map(
                      (tag) => Text(
                        tag,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryPink,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_currentStep == 7) {
      final saved = _savedRecord;
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.bgWarm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saved == null || _isSavingResultImage
                    ? null
                    : _saveResultImage,
                icon: const Icon(Icons.download_outlined, size: 20),
                label: FittedBox(
                  child: Text(
                    _isSavingResultImage ? '이미지 저장 중...' : '결과 이미지 저장하기',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: AppColors.textInverse,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: saved?.id == null
                        ? null
                        : () => context.go(RoutePaths.recordEdit(saved!.id!)),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const FittedBox(child: Text('수정하기')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPinkSoft,
                      foregroundColor: AppColors.primaryPink,
                      side: const BorderSide(color: AppColors.linePink),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _closeResult,
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const FittedBox(child: Text('기록으로 가기')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textMain,
                      side: const BorderSide(color: AppColors.lineSoft),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final label = _currentStep == 0
        ? '시작하기'
        : _currentStep == 6
        ? '저장하기'
        : '다음';

    return RecordFlowBottomBar(
      primaryLabel: label,
      onPrimaryPressed: _next,
      onBackPressed: _back,
      showBackButton: _currentStep > 0 && _currentStep < 7,
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.textMain),
          ),
          SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSub,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceGrid(
    List<_ChoiceData> choices,
    int selected,
    ValueChanged<int> onSelect,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: choices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.55,
      ),
      itemBuilder: (context, index) {
        final choice = choices[index];
        final isSelected = selected == index;
        return GestureDetector(
          onTap: () => onSelect(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? choice.color.withOpacity(0.16)
                  : AppColors.bgDefault,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? choice.color : AppColors.lineSoft,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(choice.icon, color: choice.color, size: 22),
                SizedBox(width: 8),
                Text(
                  choice.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toggleCard(String title, IconData icon, bool value) {
    final selected = _includeCrew == value;
    return GestureDetector(
      onTap: () => _updateState(() => _includeCrew = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryPink : AppColors.lineSoft,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primaryPink : AppColors.textMuted,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final selected = _selectedTheme == index;
    return GestureDetector(
      onTap: () => _updateState(() => _selectedTheme = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppColors.bgDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.lineSoft,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSub,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _dailyRecordLabelStyle = AppTextStyles.labelLarge.copyWith(
    color: AppColors.textSub,
  );
}
