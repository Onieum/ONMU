import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/onmu_app.dart';

export 'app/onmu_app.dart';

void main() {
  usePathUrlStrategy();
  runApp(const OnmuApp());
}
