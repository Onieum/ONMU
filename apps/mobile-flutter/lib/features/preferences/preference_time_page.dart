import 'package:flutter/material.dart';

import '../../shared/models/preference_profile.dart';
import 'preference_flow_widgets.dart';
import 'preference_unavailable_date_page.dart';

class PreferenceTimePage extends StatefulWidget {
  final PreferenceProfile profile;

  const PreferenceTimePage({super.key, required this.profile});

  @override
  State<PreferenceTimePage> createState() => _PreferenceTimePageState();
}

class _PreferenceTimePageState extends State<PreferenceTimePage> {
  static const _options = ['오전', '점심', '오후', '저녁', '일정 보고 결정할게요.'];
  late final Set<String> _selected = widget.profile.preferredTimes.toSet();

  @override
  Widget build(BuildContext context) {
    return PreferencePageFrame(
      currentStep: 5,
      stepCount: 6,
      title: '선호하는 시간대',
      buttonLabel: '다음',
      onNext: _selected.isEmpty
          ? null
          : () => pushOnmuPage(
              context,
              PreferenceUnavailableDatePage(
                profile: widget.profile.copyWith(
                  preferredTimes: _selected.toList(),
                ),
              ),
            ),
      child: PreferenceOptionSection(
        title: '언제 만나는 게 편한가요?',
        caption: '여러 개를 선택해도 괜찮아요.',
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
