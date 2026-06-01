import 'package:flutter/material.dart';

import '../../shared/models/preference_profile.dart';
import 'preference_flow_widgets.dart';
import 'preference_time_page.dart';

class PreferenceMeetupStylePage extends StatefulWidget {
  final PreferenceProfile profile;

  const PreferenceMeetupStylePage({super.key, required this.profile});

  @override
  State<PreferenceMeetupStylePage> createState() =>
      _PreferenceMeetupStylePageState();
}

class _PreferenceMeetupStylePageState extends State<PreferenceMeetupStylePage> {
  static const _options = [
    '미리 일정이 확정되면 좋겠어요.',
    '당일 번개 약속은 힘들어요 ⚡',
    '주말엔 쉬고 싶어요 (평일 선호) 🛌',
    '밤샘/막차 끊기는 건 부담돼요 🌙',
  ];

  late final Set<String> _selected = widget.profile.meetupStyles.toSet();

  @override
  Widget build(BuildContext context) {
    return PreferencePageFrame(
      currentStep: 4,
      stepCount: 6,
      title: '약속 스타일',
      buttonLabel: '다음',
      onNext: _selected.isEmpty
          ? null
          : () => pushOnmuPage(
              context,
              PreferenceTimePage(
                profile: widget.profile.copyWith(
                  meetupStyles: _selected.toList(),
                ),
              ),
            ),
      child: PreferenceOptionSection(
        title: '약속할 때 이런 점이 중요해요',
        caption: '일정 조율과 약속 강도에 반영할 스타일을 골라주세요.',
        options: _options,
        selected: _selected,
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
