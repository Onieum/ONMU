import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class OnmuSentryConfig {
  const OnmuSentryConfig._();

  static const String dsn = String.fromEnvironment('SENTRY_DSN');
  static const String _sentryEnvironment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
  );
  static const String _onmuEnvironment = String.fromEnvironment(
    'ONMU_ENV',
    defaultValue: 'local',
  );
  static const String _tracesSampleRateSource = String.fromEnvironment(
    'SENTRY_TRACES_SAMPLE_RATE',
    defaultValue: '0',
  );

  static bool get enabled => dsn.trim().isNotEmpty;

  static double get tracesSampleRate {
    final value = double.tryParse(_tracesSampleRateSource.trim());
    if (value == null || value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  static String get environment {
    final sentryEnvironment = _sentryEnvironment.trim();
    if (sentryEnvironment.isNotEmpty) {
      return sentryEnvironment;
    }
    return _onmuEnvironment.trim().isEmpty ? 'local' : _onmuEnvironment.trim();
  }
}

class OnmuSentryBootstrap {
  const OnmuSentryBootstrap._();

  static Future<void> run(FutureOr<void> Function() appRunner) async {
    if (!OnmuSentryConfig.enabled) {
      await appRunner();
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = OnmuSentryConfig.dsn;
      options.environment = OnmuSentryConfig.environment;
      options.tracesSampleRate = OnmuSentryConfig.tracesSampleRate;
      options.maxRequestBodySize = MaxRequestBodySize.never;
      options.sendDefaultPii = false;
      options.attachStacktrace = true;
      options.beforeSend = _scrubEvent;
    }, appRunner: appRunner);
  }

  static Widget wrapApp(Widget child) {
    if (!OnmuSentryConfig.enabled) {
      return child;
    }
    return SentryWidget(child: child);
  }
}

SentryEvent? _scrubEvent(SentryEvent event, Hint hint) {
  final request = event.request;
  if (request == null) {
    return event;
  }

  final headers = Map<String, String>.from(request.headers)
    ..removeWhere((key, _) => key.toLowerCase() == 'authorization');

  return event.copyWith(
    request: request.copyWith(
      headers: headers,
      data: const <String, Never>{},
      removeCookies: true,
    ),
  );
}
