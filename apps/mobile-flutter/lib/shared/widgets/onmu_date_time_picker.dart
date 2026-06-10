import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'onmu_button.dart';

class OnmuDateTimePicker {
  const OnmuDateTimePicker._();

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDateTime,
    String title = '날짜와 시간 선택',
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) =>
          _DateTimePickerSheet(initialDateTime: initialDateTime, title: title),
    );
  }
}

class _DateTimePickerSheet extends StatefulWidget {
  const _DateTimePickerSheet({
    required this.initialDateTime,
    required this.title,
  });

  final DateTime initialDateTime;
  final String title;

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  late DateTime _selectedDateTime = widget.initialDateTime;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          bottomPadding + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 216,
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  primaryColor: AppColors.primaryPink,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 20,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  initialDateTime: widget.initialDateTime,
                  minimumDate: DateTime.now().subtract(const Duration(days: 1)),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  mode: CupertinoDatePickerMode.dateAndTime,
                  minuteInterval: 5,
                  use24hFormat: true,
                  onDateTimeChanged: (value) {
                    _selectedDateTime = value;
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OnmuPrimaryButton(
              label: '선택 완료',
              icon: Icons.check_rounded,
              color: AppColors.primaryPink,
              foregroundColor: AppColors.textInverse,
              onPressed: () => Navigator.of(context).pop(_selectedDateTime),
            ),
          ],
        ),
      ),
    );
  }
}
