import 'package:flutter/material.dart';
import '../../shared/models/preference_profile.dart';
import 'preference_flow_widgets.dart';
import 'preference_summary_page.dart';

class PreferenceDayPage extends StatefulWidget {
  final PreferenceProfile profile;

  const PreferenceDayPage({super.key, required this.profile});

  @override
  State<PreferenceDayPage> createState() => _PreferenceDayPageState();
}

class _PreferenceDayPageState extends State<PreferenceDayPage> {
  static const _weekdayOptions = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
    '상관 없어요',
  ];

  static const _timeOptions = ['오전', '점심', '오후', '저녁', '일정 보고 결정할게요'];

  late final Set<String> _selectedWeekdays = widget.profile.preferredWeekdays
      .toSet();
  late final Set<String> _selectedTimes = widget.profile.preferredTimes.toSet();

  @override
  Widget build(BuildContext context) {
    return PreferencePageFrame(
      currentStep: 5,
      stepCount: 5,
      title: '선호 요일과 시간대',
      buttonLabel: '요약 보기',
      onNext: _selectedWeekdays.isEmpty || _selectedTimes.isEmpty
          ? null
          : () {
              pushOnmuPage(
                context,
                PreferenceSummaryPage(
                  profile: widget.profile.copyWith(
                    preferredWeekdays: _selectedWeekdays.toList(),
                    preferredTimes: _selectedTimes.toList(),
                  ),
                ),
              );
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PreferenceOptionSection(
            title: '선호 요일',
            caption: '어떤 요일에 만나기 편한가요?',
            options: _weekdayOptions,
            selected: _selectedWeekdays,
            onTap: _toggleWeekday,
          ),
          const SizedBox(height: 32),
          PreferenceOptionSection(
            title: '선호하는 시간대',
            caption: '만나기 좋은 시간대를 골라주세요.',
            options: _timeOptions,
            selected: _selectedTimes,
            onTap: _toggleTime,
          ),
        ],
      ),
    );
  }

  void _toggleWeekday(String value) {
    setState(() {
      if (value == '상관 없어요') {
        if (_selectedWeekdays.contains(value)) {
          _selectedWeekdays.clear();
        } else {
          _selectedWeekdays
            ..clear()
            ..add(value);
        }
        return;
      }

      _selectedWeekdays.remove('상관 없어요');
      if (!_selectedWeekdays.remove(value)) {
        _selectedWeekdays.add(value);
      }
    });
  }

  void _toggleTime(String value) {
    setState(() {
      if (!_selectedTimes.remove(value)) {
        _selectedTimes.add(value);
      }
    });
  }
}
