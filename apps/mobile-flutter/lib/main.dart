import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/onmu_app.dart';
import 'core/observability/onmu_sentry_bootstrap.dart';

export 'app/onmu_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await OnmuSentryBootstrap.run(
    () => runApp(OnmuSentryBootstrap.wrapApp(const OnmuApp())),
  );
}
