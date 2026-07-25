import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/core/error/onmu_exception.dart';

void main() {
  group('ONMU API config', () {
    test('defaults to dev API base URL', () {
      expect(defaultOnmuApiBaseUrl, 'https://dev-api.onmu.cloud');
    });

    test('prefers access JWT over legacy dev access token', () {
      expect(
        resolveOnmuAccessToken(
          accessJwt: 'jwt-token',
          legacyDevAccessToken: 'legacy-token',
        ),
        'jwt-token',
      );
      expect(
        resolveOnmuAccessToken(
          accessJwt: '',
          legacyDevAccessToken: 'legacy-token',
        ),
        'legacy-token',
      );
    });

    test('normalizes DioException before exposing API failures', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<Object?>(
                  requestOptions: options,
                  statusCode: 503,
                ),
              ),
            );
          },
        ),
      );
      final client = OnmuApiClient(dio);

      await expectLater(
        client.getObject('/api/v1/groups'),
        throwsA(
          isA<OnmuApiException>()
              .having((error) => error.kind, 'kind', OnmuErrorKind.unavailable)
              .having((error) => error.statusCode, 'statusCode', 503)
              .having((error) => error.endpoint, 'endpoint', '/api/v1/groups'),
        ),
      );
    });
  });
}
