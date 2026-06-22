import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../error/onmu_exception.dart';
import '../error/onmu_report_policy.dart';
import 'onmu_sentry_bootstrap.dart';

final onmuErrorReporterProvider = Provider<OnmuErrorReporter>((ref) {
  if (OnmuSentryConfig.enabled) {
    return SentryOnmuErrorReporter();
  }
  return const FlutterOnmuErrorReporter();
});

abstract interface class OnmuErrorReporter {
  void captureException(
    Object error,
    StackTrace stackTrace, {
    String feature = 'app',
  });
}

class FlutterOnmuErrorReporter implements OnmuErrorReporter {
  const FlutterOnmuErrorReporter();

  @override
  void captureException(
    Object error,
    StackTrace stackTrace, {
    String feature = 'app',
  }) {
    final report = OnmuErrorReportBuilder.build(
      error,
      stackTrace,
      feature: feature,
    );
    if (report == null) {
      return;
    }

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: report.error,
        stack: FlutterError.demangleStackTrace(report.stackTrace),
        library: 'onmu ${report.tags['feature'] ?? feature}',
        context: ErrorDescription(report.message),
        informationCollector: () sync* {
          for (final entry in report.tags.entries) {
            yield StringProperty('onmu.${entry.key}', entry.value);
          }
        },
      ),
    );
  }
}

typedef SentryOnmuCapture = FutureOr<void> Function(OnmuErrorReport report);
typedef OnmuErrorSampleRateResolver = double Function(Object error);

class SentryOnmuErrorReporter implements OnmuErrorReporter {
  SentryOnmuErrorReporter({
    this.capture = _captureWithSentry,
    OnmuErrorSampleRateResolver? sampleRateResolver,
    double Function()? randomDouble,
  }) : sampleRateResolver =
           sampleRateResolver ?? OnmuReportPolicy.sampleRateFor,
       _randomDouble = randomDouble ?? _defaultRandomDouble;

  final SentryOnmuCapture capture;
  final OnmuErrorSampleRateResolver sampleRateResolver;
  final double Function() _randomDouble;

  @override
  void captureException(
    Object error,
    StackTrace stackTrace, {
    String feature = 'app',
  }) {
    final report = OnmuErrorReportBuilder.build(
      error,
      stackTrace,
      feature: feature,
    );
    if (report == null) {
      return;
    }
    if (!_shouldCapture(report.error)) {
      return;
    }

    unawaited(
      Future<void>.sync(() => capture(report)).catchError((
        Object captureError,
        StackTrace captureStackTrace,
      ) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: captureError,
            stack: FlutterError.demangleStackTrace(captureStackTrace),
            library: 'onmu sentry reporter',
            context: ErrorDescription('Failed to capture an ONMU error.'),
          ),
        );
      }),
    );
  }

  bool _shouldCapture(Object error) {
    final sampleRate = sampleRateResolver(error).clamp(0, 1).toDouble();
    if (sampleRate <= 0) {
      return false;
    }
    if (sampleRate >= 1) {
      return true;
    }
    return _randomDouble() < sampleRate;
  }
}

class OnmuErrorReport {
  const OnmuErrorReport({
    required this.error,
    required this.stackTrace,
    required this.message,
    required this.tags,
  });

  final Object error;
  final StackTrace stackTrace;
  final String message;
  final Map<String, String> tags;
}

class OnmuErrorReportBuilder {
  const OnmuErrorReportBuilder._();

  static OnmuErrorReport? build(
    Object error,
    StackTrace stackTrace, {
    String feature = 'app',
  }) {
    if (!OnmuReportPolicy.shouldReport(error)) {
      return null;
    }
    if (error is OnmuException) {
      return OnmuErrorReport(
        error: error,
        stackTrace: stackTrace,
        message: error.technicalMessage,
        tags: OnmuReportPolicy.safeTags(error),
      );
    }
    return OnmuErrorReport(
      error: error,
      stackTrace: stackTrace,
      message: error.toString(),
      tags: {
        'feature': feature,
        'kind': OnmuErrorKind.unknown.name,
        'retryable': 'true',
      },
    );
  }
}

Future<void> _captureWithSentry(OnmuErrorReport report) async {
  await Sentry.captureException(
    report.error,
    stackTrace: report.stackTrace,
    withScope: (scope) async {
      scope.level = _sentryLevelFor(report);
      for (final entry in report.tags.entries) {
        await scope.setTag(entry.key, entry.value);
      }
    },
  );
}

SentryLevel _sentryLevelFor(OnmuErrorReport report) {
  return switch (report.tags['kind']) {
    'rateLimited' ||
    'timeout' ||
    'network' ||
    'backgroundSync' => SentryLevel.warning,
    _ => SentryLevel.error,
  };
}

final Random _sentrySampleRandom = Random();

double _defaultRandomDouble() => _sentrySampleRandom.nextDouble();
