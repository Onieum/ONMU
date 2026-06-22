import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/error/onmu_exception.dart';
import 'package:onmu_mobile/core/observability/onmu_error_reporter.dart';

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
}
