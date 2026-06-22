import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/onmu_exception.dart';
import '../error/onmu_report_policy.dart';

final onmuErrorReporterProvider = Provider<OnmuErrorReporter>((ref) {
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
