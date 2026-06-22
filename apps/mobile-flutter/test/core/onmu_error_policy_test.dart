import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/error/onmu_exception.dart';
import 'package:onmu_mobile/core/error/onmu_report_policy.dart';
import 'package:onmu_mobile/core/error/onmu_ui_error.dart';

void main() {
  group('OnmuApiException', () {
    test('maps validation response without reporting', () {
      final error = OnmuApiException.fromDio(
        _dioError(statusCode: 400, path: '/api/v1/groups'),
        feature: 'group',
      );

      expect(error.kind, OnmuErrorKind.validation);
      expect(error.statusCode, 400);
      expect(error.endpoint, '/api/v1/groups');
      expect(error.feature, 'group');
      expect(error.retryable, isFalse);
      expect(error.reportable, isFalse);
      expect(OnmuReportPolicy.shouldReport(error), isFalse);
    });

    test('maps unavailable response as retryable and reportable', () {
      final error = OnmuApiException.fromDio(
        _dioError(statusCode: 503, path: '/api/v1/place-search'),
        feature: 'place',
      );

      expect(error.kind, OnmuErrorKind.unavailable);
      expect(error.statusCode, 503);
      expect(error.retryable, isTrue);
      expect(error.reportable, isTrue);
      expect(OnmuReportPolicy.shouldReport(error), isTrue);
    });

    test('maps receive timeout as retryable timeout', () {
      final error = OnmuApiException.fromDio(
        _dioError(type: DioExceptionType.receiveTimeout),
        feature: 'plan',
      );

      expect(error.kind, OnmuErrorKind.timeout);
      expect(error.statusCode, isNull);
      expect(error.retryable, isTrue);
      expect(error.reportable, isFalse);
    });
  });

  group('OnmuContractException', () {
    test('missing required field is always reportable', () {
      final error = OnmuContractException.missingField(
        feature: 'record',
        field: 'storageKey',
        endpoint: '/api/v1/media/upload',
      );

      expect(error.kind, OnmuErrorKind.contractMismatch);
      expect(error.reportable, isTrue);
      expect(OnmuReportPolicy.shouldReport(error), isTrue);
      expect(error.technicalMessage, contains('storageKey'));
    });
  });

  group('OnmuUiError', () {
    test('server load failure becomes retryable full screen error', () {
      final error = OnmuUiError.fromException(
        OnmuApiException.fromDio(_dioError(statusCode: 500)),
        context: OnmuErrorUiContext.initialLoad,
      );

      expect(error.presentation, OnmuErrorPresentation.fullScreen);
      expect(error.canRetry, isTrue);
      expect(error.message, '잠시 문제가 생겼어요. 다시 시도해 주세요.');
    });

    test('validation mutation failure becomes snackbar', () {
      final error = OnmuUiError.fromException(
        OnmuApiException.fromDio(_dioError(statusCode: 422)),
        context: OnmuErrorUiContext.mutation,
      );

      expect(error.presentation, OnmuErrorPresentation.snackbar);
      expect(error.canRetry, isFalse);
      expect(error.message, '입력값을 확인해 주세요.');
    });
  });
}

DioException _dioError({
  int? statusCode,
  String path = '/api/v1/test',
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final requestOptions = RequestOptions(path: path, method: 'GET');
  return DioException(
    requestOptions: requestOptions,
    type: type,
    response: statusCode == null
        ? null
        : Response<Object?>(
            requestOptions: requestOptions,
            statusCode: statusCode,
          ),
  );
}
