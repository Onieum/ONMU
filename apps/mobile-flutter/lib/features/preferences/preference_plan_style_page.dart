import 'package:flutter/material.dart';

import '../../shared/models/preference_profile.dart';
import 'preference_day_page.dart';
import 'preference_flow_widgets.dart';

class PreferencePlanStylePage extends StatefulWidget {
  final PreferenceProfile profile;

  const PreferencePlanStylePage({super.key, required this.profile});

  @override
  State<PreferencePlanStylePage> createState() =>
      _PreferencePlanStylePageState();
}

class _PreferencePlanStylePageState extends State<PreferencePlanStylePage> {
  static const _options = [
    '미리 일정을 정하는 편',
    '당일 번개 약속도 괜찮아요',
    '주말에 여유롭게 만나고 싶어요',
    '대기/웨이팅은 피하고 싶어요',
  ];

  late final Set<String> _selected = widget.profile.planStyles.toSet();

  @override
  Widget build(BuildContext context) {
    return PreferencePageFrame(
      currentStep: 4,
      stepCount: 5,
      title: '약속 스타일',
      buttonLabel: '다음',
      onNext: _selected.isEmpty
          ? null
          : () => pushOnmuPage(
              context,
              PreferenceDayPage(
                profile: widget.profile.copyWith(
                  planStyles: _selected.toList(),
                ),
              ),
            ),
      child: PreferenceOptionSection(
        title: '약속에서 중요한 스타일을 골라주세요',
        caption: '일정 조율과 약속 강도를 추천에 반영할게요.',
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
