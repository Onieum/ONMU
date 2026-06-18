part of 'my_page.dart';

class _ProfileEditPage extends StatefulWidget {
  const _ProfileEditPage({
    required this.profile,
    this.initialCharacter,
    this.profileImageUrl,
    required this.onCharacterSaved,
    required this.onProfileImageUpload,
    required this.onSave,
  });

  final MyProfile profile;
  final CharacterDraft? initialCharacter;
  final String? profileImageUrl;
  final Future<void> Function(CharacterDraft) onCharacterSaved;
  final Future<String> Function(Uint8List bytes, String fileName)
  onProfileImageUpload;
  final Future<void> Function(_ProfileEditResult) onSave;

  @override
  State<_ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<_ProfileEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _introController;
  late final TextEditingController _regionController;
  late final TextEditingController _interestController;
  late ProfileVisibility _visibility;
  late RegionVisibility _regionVisibility;
  late List<String> _interests;
  Uint8List? _profileImageBytes;
  String? _profileImageFileName;
  late String _profileImageUrl;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.realName);
    _introController = TextEditingController(text: widget.profile.introText);
    _regionController = TextEditingController(
      text: widget.profile.effectiveRegionSelection.displayName,
    );
    _interestController = TextEditingController();
    _visibility = widget.profile.visibility;
    _regionVisibility = widget.profile.regionVisibility;
    _interests = widget.profile.favoriteKeywords.take(5).toList();
    _profileImageUrl = widget.profileImageUrl?.trim() ?? '';
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
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: AppColors.bgDefault,
        body: SafeArea(
          child: GridBackground(
            child: Column(
              children: [
                _EditPageTopBar(
                  title: '프로필 수정',
                  onBack: _isSaving ? () {} : () => Navigator.of(context).pop(),
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
                              _CharacterPortrait(
                                size: 132,
                                profileImageUrl: _profileImageUrl,
                                profileImageBytes: _profileImageBytes,
                              ),
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
                          icon: const Icon(
                            Icons.add_a_photo_outlined,
                            size: 18,
                          ),
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
                          label: '현재 거주지역',
                          subLabel: '지역 설정하기',
                          child: Column(
                            children: [
                              _RegionSelector(controller: _regionController),
                              const SizedBox(height: 12),
                              _RegionVisibilitySelector(
                                value: _regionVisibility,
                                onChanged: (value) {
                                  setState(() => _regionVisibility = value);
                                },
                              ),
                            ],
                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '추가',
                                        style: AppTextStyles.labelLarge
                                            .copyWith(
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
                            onPressed: _isSaving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryPink,
                              foregroundColor: AppColors.textInverse,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              _isSaving ? '저장 중' : '저장하기',
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
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      var profileImageUrl = _profileImageUrl;
      final profileImageBytes = _profileImageBytes;
      final profileImageFileName = _profileImageFileName;
      if (profileImageBytes != null && profileImageFileName != null) {
        profileImageUrl = await widget.onProfileImageUpload(
          profileImageBytes,
          profileImageFileName,
        );
      }
      final region = _regionController.text.trim().isEmpty
          ? widget.profile.region
          : _regionController.text.trim();
      final result = _ProfileEditResult(
        realName: _nameController.text.trim().isEmpty
            ? widget.profile.realName
            : _nameController.text.trim(),
        introText: _introController.text.trim(),
        profileImageUrl: profileImageUrl,
        region: region,
        regionSelection: KoreaRegionSelection.fromDisplayName(region),
        regionVisibility: _regionVisibility,
        visibility: _visibility,
        favoriteKeywords: _interests,
      );
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
      case _ProfilePhotoOption.gallery:
        await _pickProfileImage(ImageSource.gallery);
      case _ProfilePhotoOption.camera:
        await _pickProfileImage(ImageSource.camera);
      case _ProfilePhotoOption.character:
        setState(() {
          _profileImageBytes = null;
          _profileImageFileName = null;
          _profileImageUrl = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장된 캐릭터 이미지를 프로필 사진으로 사용할게요.')),
        );
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 1440,
    );
    if (!mounted || picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _profileImageBytes = bytes;
      _profileImageFileName = picked.name.isEmpty
          ? 'profile-image.jpg'
          : picked.name;
      _profileImageUrl = '';
    });
  }

  Future<void> _openCharacterEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CharacterStartPage(
          returnButtonLabel: '프로필 수정으로 돌아가기',
          completionButtonLabel: '프로필 수정으로 돌아가기',
          initialDraft: widget.initialCharacter,
          onBackToOnboarding: () {
            Navigator.of(context).pop();
          },
          onCompleted: (draft) async {
            await widget.onCharacterSaved(draft);
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );
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
              '앨범, 카메라, 저장된 ONMU 캐릭터 중 하나를 선택해요.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _ProfilePhotoOptionTile(
              icon: Icons.photo_library_outlined,
              title: '앨범에서 고르기',
              subtitle: '기기에 저장된 사진을 프로필 사진으로 써요',
              option: _ProfilePhotoOption.gallery,
            ),
            _ProfilePhotoOptionTile(
              icon: Icons.photo_camera_outlined,
              title: '지금 사진 찍기',
              subtitle: '카메라로 촬영한 사진을 바로 사용해요',
              option: _ProfilePhotoOption.camera,
            ),
            _ProfilePhotoOptionTile(
              icon: Icons.face_retouching_natural_outlined,
              title: '캐릭터 이미지 사용',
              subtitle: '마지막으로 저장한 ONMU 캐릭터를 사용해요',
              option: _ProfilePhotoOption.character,
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
