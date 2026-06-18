part of 'my_page.dart';

class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        onSignOut: () => _signOut(context, ref),
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

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authActionProvider).signOut();
      if (!context.mounted) {
        return;
      }
      context.go(RoutePaths.onboarding);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그아웃에 실패했어요. 다시 시도해주세요.')));
    }
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

class _RegionSelector extends StatefulWidget {
  const _RegionSelector({required this.controller});

  final TextEditingController controller;

  @override
  State<_RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<_RegionSelector> {
  late String _sido;
  late String _sigungu;

  @override
  void initState() {
    super.initState();
    final initial = KoreaRegionSelection.fromDisplayName(
      widget.controller.text,
    );
    final hasInitialRegion = widget.controller.text.trim().isNotEmpty;
    _sido = !hasInitialRegion || initial.sido.trim().isEmpty
        ? KoreaRegionSelection.fallback.sido
        : initial.sido;
    final sigunguOptions = sigunguOptionsFor(_sido);
    _sigungu = initial.sigungu.trim().isEmpty
        ? hasInitialRegion
              ? ''
              : sigunguOptions.isEmpty
              ? KoreaRegionSelection.fallback.sigungu
              : sigunguOptions.first
        : initial.sigungu;
    _syncController();
  }

  @override
  Widget build(BuildContext context) {
    final sidoOptions = _sidoOptions();
    final sigunguOptions = _sigunguOptions();
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _sido,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_on_outlined),
            labelText: '시/도',
          ),
          items: [
            for (final sido in sidoOptions)
              DropdownMenuItem(value: sido, child: Text(sido)),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _sido = value;
              final nextSigunguOptions = sigunguOptionsFor(value);
              _sigungu = nextSigunguOptions.isEmpty
                  ? _sigungu
                  : nextSigunguOptions.first;
              _syncController();
            });
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _sigungu,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_city_outlined),
            labelText: '시/군/구',
          ),
          items: [
            for (final sigungu in sigunguOptions)
              DropdownMenuItem(
                value: sigungu,
                child: Text(sigungu.isEmpty ? '선택 안 함' : sigungu),
              ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _sigungu = value;
              _syncController();
            });
          },
        ),
      ],
    );
  }

  void _syncController() {
    widget.controller.text = KoreaRegionSelection(
      sido: _sido,
      sigungu: _sigungu,
    ).displayName;
  }

  List<String> _sidoOptions() {
    if (koreaRegionOptions.containsKey(_sido)) {
      return koreaSidoOptions;
    }
    return [_sido, ...koreaSidoOptions];
  }

  List<String> _sigunguOptions() {
    final options = sigunguOptionsFor(_sido);
    if (_sigungu.trim().isEmpty) {
      return ['', ...options];
    }
    if (options.contains(_sigungu)) {
      return options;
    }
    return [_sigungu, ...options];
  }
}

class _RegionVisibilitySelector extends StatelessWidget {
  const _RegionVisibilitySelector({
    required this.value,
    required this.onChanged,
  });

  final RegionVisibility value;
  final ValueChanged<RegionVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          value.isPublic ? Icons.visibility_outlined : Icons.lock_outline,
          color: AppColors.textSub,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '공개 범위',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SegmentedButton<RegionVisibility>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            selectedBackgroundColor: AppColors.primaryPinkSoft,
            selectedForegroundColor: AppColors.primaryPurple,
            foregroundColor: AppColors.textSub,
            side: const BorderSide(color: AppColors.lineSoft),
            textStyle: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          segments: const [
            ButtonSegment(value: RegionVisibility.private, label: Text('비공개')),
            ButtonSegment(value: RegionVisibility.public, label: Text('공개')),
          ],
          selected: {value},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
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
  const _AccountActionCard({required this.onSignOut});

  final VoidCallback onSignOut;

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
            onTap: onSignOut,
          ),
          const Divider(height: 1, color: AppColors.lineSoft),
          _AccountActionTile(
            icon: Icons.person_outline,
            label: '회원탈퇴',
            color: AppColors.textMuted,
            onTap: null,
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

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
    required this.introText,
    required this.region,
    required this.regionSelection,
    required this.regionVisibility,
    required this.visibility,
    required this.favoriteKeywords,
  });

  final String realName;
  final String introText;
  final String region;
  final KoreaRegionSelection regionSelection;
  final RegionVisibility regionVisibility;
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

enum _ProfilePhotoOption { character }
