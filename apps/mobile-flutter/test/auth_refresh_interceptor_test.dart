import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/token_refresh_interceptor.dart';
import 'package:onmu_mobile/features/auth/domain/auth_session.dart';

/// 테스트에서 예외를 캡처하기 위한 헬퍼 함수
Future<Object> captureFailure(Future<Object> future) async {
  try {
    return await future;
  } catch (error) {
    return error;
  }
}

/// HttpClientAdapter 모의 구현으로 테스트에서 요청/응답을 제어
class MockHttpClientAdapter implements HttpClientAdapter {
  MockHttpClientAdapter({
    Response<dynamic>? Function(RequestOptions)? responseBuilder,
  }) : _responseBuilder = responseBuilder ?? _defaultResponseBuilder;

  Response<dynamic>? Function(RequestOptions) _responseBuilder;
  final List<RequestOptions> capturedRequests = [];

  /// 테스트에서 응답 빌더를 동적으로 변경하기 위한 세터
  set responseBuilder(Response<dynamic>? Function(RequestOptions) value) {
    _responseBuilder = value;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? data,
    Future<void>? cancel,
  ) async {
    capturedRequests.add(options);
    final response = _responseBuilder(options);
    final body = response?.data;
    final headers = response?.headers;
    final status = response?.statusCode ?? 200;

    final bodyBytes = switch (body) {
      final String s => Uint8List.fromList(utf8.encode(s)),
      final List<int> l => Uint8List.fromList(l),
      final Map m => Uint8List.fromList(utf8.encode(jsonEncode(m))),
      _ => Uint8List(0),
    };

    // Headers?.map returns Map<String, List<String>>, which is exactly what ResponseBody expects
    final headersMap = headers?.map ?? {};

    return ResponseBody.fromBytes(
      bodyBytes,
      status,
      statusMessage: status == 200 ? 'OK' : 'Error',
      headers: headersMap,
    );
  }

  @override
  void close({bool force = false}) {
    // No-op for test
  }

  static Response<dynamic>? _defaultResponseBuilder(RequestOptions options) {
    return Response(
      requestOptions: options,
      data: {},
      statusCode: 200,
    );
  }
}

void main() {
  group('AuthRefreshInterceptor', () {
    late Dio dio;
    late MockHttpClientAdapter mockAdapter;
    late AuthRefreshInterceptor interceptor;
    late OnmuAuthTokens? lastRefreshedTokens;
    late int clearSessionCallCount;
    late int refreshCallCount;
    late int onRefreshedCallCount;
    late String? storedRefreshToken;

    setUp(() {
      mockAdapter = MockHttpClientAdapter();

      dio = Dio(
        BaseOptions(
          baseUrl: 'https://dev-api.onmu.cloud',
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          responseType: ResponseType.json,
          headers: {'Accept': 'application/json'},
        ),
      );
      dio.httpClientAdapter = mockAdapter;

      lastRefreshedTokens = null;
      clearSessionCallCount = 0;
      refreshCallCount = 0;
      onRefreshedCallCount = 0;
      storedRefreshToken = 'initial-refresh-token';
    });

    group('eligible 401 success retry', () {
      test('401 응답 시 refresh 성공 후 재시도로 200 반환', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          final isRetry = options.headers['x-onmu-refresh-retry'] == 'true';
          if (isRetry) {
            return Response(
              requestOptions: options,
              data: {'result': 'success'},
              statusCode: 200,
            );
          } else {
            return Response(
              requestOptions: options,
              statusCode: 401,
            );
          }
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            return const OnmuAuthTokens(
              accessToken: 'refreshed-access-token',
              refreshToken: 'rotated-refresh-token',
            );
          },
          onRefreshed: (tokens) async {
            onRefreshedCallCount++;
            lastRefreshedTokens = tokens;
          },
          onRefreshFailed: () async {
            clearSessionCallCount++;
          },
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        final response = await dio.get('/api/v1/users/me');

        expect(response.statusCode, 200);
        expect(requestCount, 2); // 원본 요청 + 재시도 요청
        expect(mockAdapter.capturedRequests[0].headers['x-onmu-refresh-retry'], isNull);
        expect(mockAdapter.capturedRequests[1].headers['x-onmu-refresh-retry'], 'true');
        expect(refreshCallCount, 1);
        expect(onRefreshedCallCount, 1);
        expect(clearSessionCallCount, 0);
        expect(lastRefreshedTokens?.accessToken, 'refreshed-access-token');
      });

      test('401 시 refresh 토큰이 갱신되어 Authorization 헤더 업데이트', () async {
        String? capturedAccessToken;
        int requestCount = 0;

        mockAdapter.responseBuilder = (options) {
          requestCount++;
          capturedAccessToken = options.headers['Authorization']?.toString();
          final isRetry = options.headers['x-onmu-refresh-retry'] == 'true';
          if (isRetry) {
            return Response(requestOptions: options, statusCode: 200);
          } else {
            return Response(requestOptions: options, statusCode: 401);
          }
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            return const OnmuAuthTokens(
              accessToken: 'new-access-token',
              refreshToken: 'new-refresh-token',
            );
          },
          onRefreshed: (tokens) async {
            // API 클라이언트의 Authorization 헤더 업데이트 시뮬레이션
            dio.options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          },
          onRefreshFailed: () async {},
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await dio.get('/api/v1/users/me');

        expect(requestCount, 2);
        // 첫 요청은 원래 access token 없음 (초기 상태)
        expect(capturedAccessToken, contains('new-access-token'));
      });
    });

    group('excluded paths', () {
      test('refresh endpoint 401은 갱신 시도하지 않음', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          return Response(requestOptions: options, statusCode: 401);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            throw 'should not be called';
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {
            clearSessionCallCount++;
          },
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await expectLater(
          dio.post('/api/v1/auth/refresh', data: {'refreshToken': 'token'}),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
        );

        expect(requestCount, 1); // 한 번만 호출 (재시도 없음)
        expect(refreshCallCount, 0);
        expect(clearSessionCallCount, 0);
      });

      test('OAuth 로그인 요청 401은 갱신 시도하지 않음', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          return Response(requestOptions: options, statusCode: 401);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            throw 'should not be called';
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {},
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await expectLater(
          dio.post('/api/v1/auth/oauth/kakao'),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
        );

        expect(requestCount, 1);
        expect(refreshCallCount, 0);
      });

      test('logout 요청 401은 갱신 시도하지 않음', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          return Response(requestOptions: options, statusCode: 401);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            throw 'should not be called';
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {},
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await expectLater(
          dio.post('/api/v1/auth/logout'),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
        );

        expect(requestCount, 1);
        expect(refreshCallCount, 0);
      });
    });

    group('already-retried requests', () {
      test('이미 재시도된 요청은 다시 갱신하지 않음 (무한 루프 방지)', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          return Response(requestOptions: options, statusCode: 401);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            throw 'should not be called';
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {},
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        // 재시도 마크가 있는 요청 생성
        final options = RequestOptions(path: '/api/v1/users/me');
        options.headers['x-onmu-refresh-retry'] = 'true';

        await expectLater(
          dio.fetch(options),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
        );

        expect(requestCount, 1); // 한 번만 호출
        expect(refreshCallCount, 0); // refresh 시도하지 않음
      });

      test('재시도 후에도 401이면 추가 갱신하지 않음 (정확히 한 번만 재시도)', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          // 모든 요청을 401로 응답
          return Response(requestOptions: options, statusCode: 401);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            return const OnmuAuthTokens(
              accessToken: 'refreshed-access-token',
              refreshToken: 'rotated-refresh-token',
            );
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {},
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await expectLater(
          dio.get('/api/v1/users/me'),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
        );

        // 최초 요청 + 정확히 한 번 재시도
        expect(requestCount, 2);
        expect(mockAdapter.capturedRequests[0].headers['x-onmu-refresh-retry'], isNull);
        expect(mockAdapter.capturedRequests[1].headers['x-onmu-refresh-retry'], 'true');
        expect(refreshCallCount, 1); // refresh는 한 번만 호출
      });
    });

    group('non-401 errors', () {
      test('비 401 에러는 갱신 시도하지 않음', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          return Response(requestOptions: options, statusCode: 404);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            throw 'should not be called';
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {},
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await expectLater(
          dio.get('/api/v1/not-found'),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 404)),
        );

        expect(requestCount, 1);
        expect(refreshCallCount, 0);
      });

      test('403 에러는 갱신 시도하지 않음', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          return Response(requestOptions: options, statusCode: 403);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            throw 'should not be called';
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {},
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await expectLater(
          dio.get('/api/v1/forbidden'),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 403)),
        );

        expect(requestCount, 1);
        expect(refreshCallCount, 0);
      });
    });

    group('concurrent eligible 401 requests share exactly one refresh', () {
      test('동시 401 요청은 단일 비행으로 합쳐서 refresh 정확히 한 번만 호출', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          final isRetry = options.headers['x-onmu-refresh-retry'] == 'true';
          if (isRetry) {
            return Response(requestOptions: options, statusCode: 200);
          } else {
            return Response(requestOptions: options, statusCode: 401);
          }
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            // 충분히 지연하여 두 번째 요청이 진행 중인 refresh를 기다리도록 함
            await Future.delayed(const Duration(milliseconds: 50));
            return const OnmuAuthTokens(
              accessToken: 'refreshed-access-token',
              refreshToken: 'rotated-refresh-token',
            );
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {},
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        // 동시에 두 요청 실행
        final results = await Future.wait([
          dio.get('/api/v1/users/me'),
          dio.get('/api/v1/users/me'),
        ]);

        for (final response in results) {
          expect(response.statusCode, 200);
        }

        // 두 요청이 단일 refresh를 공유
        expect(refreshCallCount, 1);
        // 각 요청당 2번씩 (원본 + 재시도) = 총 4번
        expect(requestCount, 4);
      });
    });

    group('shared refresh failure clears once', () {
      test('refresh 실패(null 반환) 시 clearSession 한 번만 호출 후 원 에러 전파', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          return Response(requestOptions: options, statusCode: 401);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            return null; // refresh 실패
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {
            clearSessionCallCount++;
          },
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await expectLater(
          dio.get('/api/v1/users/me'),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
        );

        expect(requestCount, 1); // 재시도 없이 바로 실패
        expect(refreshCallCount, 1);
        expect(clearSessionCallCount, 1); // 실패 시 clearSession 정확히 한 번 호출
      });

      test('refresh 예외 시 clearSession 한 번만 호출 후 원 에러 전파', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          return Response(requestOptions: options, statusCode: 401);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            throw Exception('network error');
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {
            clearSessionCallCount++;
          },
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await expectLater(
          dio.get('/api/v1/users/me'),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
        );

        expect(requestCount, 1);
        expect(refreshCallCount, 1);
        expect(clearSessionCallCount, 1);
      });

      test('저장된 refresh 토큰이 없으면 갱신 시도하지 않고 clearSession 한 번 호출', () async {
        int requestCount = 0;
        storedRefreshToken = null; // 토큰 없음

        mockAdapter.responseBuilder = (options) {
          requestCount++;
          return Response(requestOptions: options, statusCode: 401);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            throw 'should not be called';
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {
            clearSessionCallCount++;
          },
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await expectLater(
          dio.get('/api/v1/users/me'),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
        );

        expect(requestCount, 1);
        expect(refreshCallCount, 0); // 토큰이 없으면 performRefresh 호출 안 함
        expect(clearSessionCallCount, 1);
      });

      test('빈 refresh 토큰이면 갱신 시도하지 않고 clearSession 한 번 호출', () async {
        int requestCount = 0;
        storedRefreshToken = ''; // 빈 토큰

        mockAdapter.responseBuilder = (options) {
          requestCount++;
          return Response(requestOptions: options, statusCode: 401);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            throw 'should not be called';
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {
            clearSessionCallCount++;
          },
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        await expectLater(
          dio.get('/api/v1/users/me'),
          throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401)),
        );

        expect(requestCount, 1);
        expect(refreshCallCount, 0);
        expect(clearSessionCallCount, 1);
      });

      test('동시 401 요청이 refresh 실패 시 clearSession 한 번만 호출, 모두 401 반환', () async {
        int requestCount = 0;
        mockAdapter.responseBuilder = (options) {
          requestCount++;
          // 모든 요청을 401로 응답
          return Response(requestOptions: options, statusCode: 401);
        };

        interceptor = AuthRefreshInterceptor(
          readRefreshToken: () async => storedRefreshToken,
          performRefresh: (token) async {
            refreshCallCount++;
            await Future.delayed(const Duration(milliseconds: 50));
            return null; // refresh 실패
          },
          onRefreshed: (tokens) async {},
          onRefreshFailed: () async {
            clearSessionCallCount++;
          },
          dio: dio,
        );
        dio.interceptors.add(interceptor);

        // 동시에 두 요청 실행
        final results = await Future.wait([
          captureFailure(dio.get('/api/v1/users/me')),
          captureFailure(dio.get('/api/v1/users/me')),
        ]);

        // 두 요청 모두 401로 실패해야 함
        for (final result in results) {
          expect(result, isA<DioException>().having((e) => e.response?.statusCode, 'statusCode', 401));
        }

        // 단일 refresh만 호출
        expect(refreshCallCount, 1);
        // clearSession은 실패한 refresh 사이클당 한 번만 호출
        expect(clearSessionCallCount, 1);
        // 두 개의 원본 요청만 (재시도 없음)
        expect(requestCount, 2);

        // 단일 refresh만 호출
        expect(refreshCallCount, 1);
        // clearSession은 실패한 refresh 사이클당 한 번만 호출
        expect(clearSessionCallCount, 1);
      });
    });

    group('constants', () {
      test('재시도 헤더 상수 확인', () {
        expect(AuthRefreshInterceptor.retryHeader, 'x-onmu-refresh-retry');
      });
    });
  });
}
