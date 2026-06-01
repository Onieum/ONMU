import 'package:flutter/material.dart';

import '../../shared/models/preference_profile.dart';
import 'preference_flow_widgets.dart';
import 'preference_summary_page.dart';

class PreferenceUnavailableDatePage extends StatefulWidget {
  final PreferenceProfile profile;

  const PreferenceUnavailableDatePage({super.key, required this.profile});

  @override
  State<PreferenceUnavailableDatePage> createState() =>
      _PreferenceUnavailableDatePageState();
}

class _PreferenceUnavailableDatePageState
    extends State<PreferenceUnavailableDatePage> {
  static const _options = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
    '아직 모르겠어요.',
  ];
  late final Set<String> _selected = widget.profile.unavailableWeekdays.toSet();

  @override
  Widget build(BuildContext context) {
    return PreferencePageFrame(
      currentStep: 6,
      stepCount: 6,
      title: '불가능한 요일',
      buttonLabel: '요약 보기',
      onNext: () => pushOnmuPage(
        context,
        PreferenceSummaryPage(
          profile: widget.profile.copyWith(
            unavailableWeekdays: _selected.toList(),
          ),
        ),
      ),
      child: PreferenceOptionSection(
        title: '이번 주, 약속이 불가능한 요일을 알려주세요.',
        caption: '선택하지 않아도 다음 단계로 넘어갈 수 있어요.',
        options: _options,
        selected: _selected,
        isDislike: true,
        onTap: _toggle,
      ),
    );
  }

  void _toggle(String value) {
    setState(() {
      if (!_selected.remove(value)) {
        _selected.add(value);
      }
    });
  }
}
