import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension OnmuNavigation on BuildContext {
  void popOrGo(String fallbackLocation, {Object? result}) {
    if (canPop()) {
      pop(result);
      return;
    }

    go(fallbackLocation);
  }
}
