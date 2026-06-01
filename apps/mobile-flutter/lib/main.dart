import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/onmu_app.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: OnmuApp()));
}
