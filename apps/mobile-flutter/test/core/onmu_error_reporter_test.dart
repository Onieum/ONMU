import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/error/onmu_exception.dart';
import 'package:onmu_mobile/core/observability/onmu_error_reporter.dart';
import 'package:onmu_mobile/core/observability/onmu_sentry_bootstrap.dart';

void main() {
  test('buildReport drops non-reportable ONMU errors', () {
    final report = OnmuErrorReportBuilder.build(
      const OnmuException(
        kind: OnmuErrorKind.validation,
        userMessage: '입력값을 확인해 주세요.',
        technicalMessage: 'validation failed',
        feature: 'plan',
      ),
      StackTrace.empty,
    );

    expect(report, isNull);
  });

  test('buildReport keeps safe tags for reportable ONMU errors', () {
    final report = OnmuErrorReportBuilder.build(
      const OnmuException(
        kind: OnmuErrorKind.server,
        userMessage: '잠시 문제가 생겼어요. 다시 시도해 주세요.',
        technicalMessage: 'GET /api/v1/groups failed with 500',
        feature: 'group',
        statusCode: 500,
        method: 'GET',
        endpoint: '/api/v1/groups',
        retryable: true,
        reportable: true,
      ),
      StackTrace.empty,
    );

    expect(report, isNotNull);
    expect(report!.tags, {
      'feature': 'group',
      'kind': 'server',
      'retryable': 'true',
      'statusCode': '500',
      'method': 'GET',
      'endpoint_template': '/api/v1/groups',
    });
  });

  test(
    'sentry reporter forwards only reportable errors with safe tags',
    () async {
      final captured = <OnmuErrorReport>[];
      final captureCompleted = Completer<void>();
      final reporter = SentryOnmuErrorReporter(
        capture: (report) {
          captured.add(report);
          captureCompleted.complete();
        },
      );

      reporter.captureException(
        const OnmuException(
          kind: OnmuErrorKind.unavailable,
          userMessage: '잠시 문제가 생겼어요. 다시 시도해 주세요.',
          technicalMessage: 'GET /api/v1/groups failed with 503',
          feature: 'group',
          statusCode: 503,
          method: 'GET',
          endpoint: '/api/v1/groups/123/messages',
          retryable: true,
          reportable: true,
        ),
        StackTrace.empty,
      );

      await captureCompleted.future;

      expect(captured, hasLength(1));
      expect(captured.single.tags, {
        'feature': 'group',
        'kind': 'unavailable',
        'retryable': 'true',
        'statusCode': '503',
        'method': 'GET',
        'endpoint_template': '/api/v1/groups/{id}/messages',
      });
    },
  );

  test('sentry reporter drops non-reportable errors', () async {
    var called = false;
    final reporter = SentryOnmuErrorReporter(
      capture: (_) {
        called = true;
      },
    );

    reporter.captureException(
      const OnmuException(
        kind: OnmuErrorKind.validation,
        userMessage: '입력값을 확인해 주세요.',
        technicalMessage: 'validation failed',
        feature: 'plan',
      ),
      StackTrace.empty,
    );

    await Future<void>.delayed(Duration.zero);

    expect(called, isFalse);
  });

  test('sentry reporter applies error sample rate', () async {
    final captured = <OnmuErrorReport>[];
    final reporter = SentryOnmuErrorReporter(
      sampleRateResolver: (_) => 0,
      capture: captured.add,
    );

    reporter.captureException(
      const OnmuException(
        kind: OnmuErrorKind.timeout,
        userMessage: '네트워크 연결을 확인해 주세요.',
        technicalMessage: 'GET /api/v1/groups timed out',
        feature: 'group',
        retryable: true,
        reportable: true,
      ),
      StackTrace.empty,
    );

    await Future<void>.delayed(Duration.zero);

    expect(captured, isEmpty);
  });

  test('sentry bootstrap runs app without SDK when DSN is absent', () async {
    var ran = false;

    await OnmuSentryBootstrap.run(() {
      ran = true;
    });

    expect(OnmuSentryConfig.enabled, isFalse);
    expect(ran, isTrue);
  });
}
