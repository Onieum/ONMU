import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/domain/auth_session.dart';

/// 401 응답 시 refresh 토큰으로 자동 갱신하고 원 요청을 재시도하는 Dio 인터셉터.
///
/// 동작:
/// - access 토큰 만료 401에만 refresh 시도
/// - refresh endpoint, login, 공개 인증 요청은 재갱신 대상에서 제외
/// - 동시 401 요청은 단일 비행(single-flight)으로 합쳐 refresh 폭주 방지
/// - 갱신 성공 시 콜백을 통해 access token 반영
/// - 원 요청은 최대 한 번만 재시도 (무한 루프 방지)
/// - refresh 실패 시 세션 클리어 콜백 호출 후 원 에러 전파
///
/// 프레임워크에 의존하지 않고 순수 함수로 콜백을 받아 순환 의존을 방지한다.
class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor({
    required this.readRefreshToken,
    required this.performRefresh,
    required this.onRefreshed,
    required this.onRefreshFailed,
    required this._dio,
  });

  /// 현재 저장된 refresh 토큰을 읽어오는 함수.
  final Future<String?> Function() readRefreshToken;

  /// refresh 토큰을 사용하여 서버에서 새 토큰을 받아오는 함수.
  final Future<OnmuAuthTokens?> Function(String refreshToken) performRefresh;

  /// refresh 성공 시 호출되는 함수. 새 토큰을 저장하고 API 클라이언트를 업데이트한다.
  final Future<void> Function(OnmuAuthTokens tokens) onRefreshed;

  /// refresh 실패 시 호출되는 함수. 세션을 클리어한다.
  final Future<void> Function() onRefreshFailed;

  final Dio _dio;
  Future<OnmuAuthTokens?>? _refreshInFlight; // 진행 중인 refresh future (단일 비행)

  // 재시도 마크 헤더 키 (무한 루프 방지)
  static const retryHeader = 'x-onmu-refresh-retry';

  // 재갱신 제외 경로
  static const _excludedPaths = [
    '/api/v1/auth/refresh', // refresh 자신
    '/api/v1/auth/oauth', // login/exchange
    '/api/v1/auth/logout',
  ];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401이 아니면 바로 전파
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // 이미 재시도된 요청이면 바로 전파 (무한 루프 방지)
    final requestOptions = err.requestOptions;
    if (requestOptions.headers[retryHeader] == 'true') {
      handler.next(err);
      return;
    }

    // 제외 경로면 refresh 없이 전파
    if (_isExcludedPath(requestOptions.path)) {
      handler.next(err);
      return;
    }

    // 단일 비행: 진행 중인 refresh가 있으면 대기, 없으면 새로 시작
    final inFlightRefresh = _refreshInFlight;
    if (inFlightRefresh != null) {
      // 이미 진행 중인 refresh가 있으면 완료까지 대기
      final tokens = await inFlightRefresh;
      if (tokens != null) {
        await _retryRequest(err, handler);
      } else {
        // refresh 실패했으면 원래 401 전파
        handler.next(err);
      }
      return;
    }

    // 새로운 refresh 사이클 시작
    // onRefreshFailed가 정확히 한 번만 호출되도록 whenComplete로 실패 처리
    _refreshInFlight = _refreshOnce().whenComplete(() {
      // refresh 완료 후 _refreshInFlight 정리 (다음 사이클 준비)
      _refreshInFlight = null;
    });

    final tokens = await _refreshInFlight!;
    if (tokens != null) {
      await _retryRequest(err, handler);
    } else {
      // refresh 실패했으면 원래 401 전파
      handler.next(err);
    }
  }

  /// refresh 토큰으로 갱신을 시도하고 결과를 반환.
  /// 성공 시 onRefreshed 호출, 실패 시 onRefreshFailed 정확히 한 번 호출 후 null 반환.
  Future<OnmuAuthTokens?> _refreshOnce() async {
    try {
      final refreshToken = await readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await onRefreshFailed();
        return null;
      }

      final tokens = await performRefresh(refreshToken);
      if (tokens != null) {
        await onRefreshed(tokens);
        return tokens;
      }

      // refresh 서버가 null 반환 (401/403 등 갱신 불가)
      await onRefreshFailed();
      return null;
    } catch (e) {
      // refresh 자체가 예외로 실패
      await onRefreshFailed();
      return null;
    }
  }

  bool _isExcludedPath(String path) {
    final normalized = path.toLowerCase();
    for (final excluded in _excludedPaths) {
      if (normalized.startsWith(excluded.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  Future<void> _retryRequest(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;

    // 재시도 마크 (무한 루프 방지)
    final retryHeaders = Map<String, dynamic>.from(requestOptions.headers);
    retryHeaders[retryHeader] = 'true';

    // dio.options.headers에서 업데이트된 Authorization 헤더를 반영
    // onRefreshed 콜백에서 apiClient.setAccessToken()을 호출하면
    // dio.options.headers['Authorization']이 업데이트되므로 이를 반영
    final authHeader = _dio.options.headers['Authorization'];
    if (authHeader != null) {
      retryHeaders['Authorization'] = authHeader;
    }

    try {
      final response = await _dio.fetch(
        requestOptions.copyWith(headers: retryHeaders),
      );
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        handler.next(e);
      } else {
        handler.next(DioException(
          requestOptions: requestOptions,
          error: e,
          type: DioExceptionType.unknown,
        ));
      }
    }
  }
}
