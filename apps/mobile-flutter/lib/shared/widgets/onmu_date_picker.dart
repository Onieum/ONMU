import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class OnmuDatePicker {
  const OnmuDatePicker._();

  static Future<DateTime?> pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? helpText,
    String confirmText = '선택',
    String cancelText = '취소',
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      confirmText: confirmText,
      cancelText: cancelText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPink,
              onPrimary: AppColors.textInverse,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
