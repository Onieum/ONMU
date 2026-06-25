import 'package:dio/dio.dart';

enum OnmuErrorKind {
  validation,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  rateLimited,
  server,
  unavailable,
  timeout,
  network,
  contractMismatch,
  externalProvider,
  permissionDenied,
  cancelled,
  backgroundSync,
  unknown,
}

class OnmuException implements Exception {
  const OnmuException({
    required this.kind,
    required this.userMessage,
    required this.technicalMessage,
    required this.feature,
    this.statusCode,
    this.method,
    this.endpoint,
    this.retryable = false,
    this.reportable = false,
    this.cause,
  });

  final OnmuErrorKind kind;
  final String userMessage;
  final String technicalMessage;
  final int? statusCode;
  final String? method;
  final String? endpoint;
  final String feature;
  final bool retryable;
  final bool reportable;
  final Object? cause;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' statusCode=$statusCode';
    final target = endpoint == null ? '' : ' endpoint=$endpoint';
    return 'OnmuException(kind=$kind$status$target, message=$technicalMessage)';
  }
}

class OnmuApiException extends OnmuException {
  OnmuApiException({
    required super.kind,
    required super.userMessage,
    required super.technicalMessage,
    required super.feature,
    this.serverReason = '',
    this.errorCode = '',
    super.statusCode,
    super.method,
    super.endpoint,
    super.retryable,
    super.reportable,
    super.cause,
  });

  final String serverReason;
  final String errorCode;

  factory OnmuApiException.fromDio(
    DioException error, {
    String feature = 'api',
  }) {
    final statusCode = error.response?.statusCode;
    final kind = _kindFor(error, statusCode);
    final errorCode = _serverErrorCodeFor(error.response?.data);
    return OnmuApiException(
      kind: kind,
      userMessage: _userMessageFor(kind),
      technicalMessage: _technicalMessageFor(error, statusCode),
      feature: feature,
      statusCode: statusCode,
      method: error.requestOptions.method,
      endpoint: error.requestOptions.path,
      retryable: _retryableFor(kind),
      reportable: _reportableFor(kind),
      cause: error,
      serverReason: errorCode.isEmpty
          ? _serverReasonFor(error.response?.data)
          : errorCode,
      errorCode: errorCode,
    );
  }
}

class OnmuContractException extends OnmuException {
  const OnmuContractException({
    required super.userMessage,
    required super.technicalMessage,
    required super.feature,
    super.endpoint,
    super.cause,
  }) : super(
         kind: OnmuErrorKind.contractMismatch,
         retryable: false,
         reportable: true,
       );

  factory OnmuContractException.missingField({
    required String feature,
    required String field,
    String? endpoint,
    Object? cause,
  }) {
    return OnmuContractException(
      userMessage: '앱과 서버 데이터 형식이 맞지 않아요.',
      technicalMessage: 'Required field "$field" is missing.',
      feature: feature,
      endpoint: endpoint,
      cause: cause,
    );
  }
}

class OnmuUserActionException extends OnmuException {
  const OnmuUserActionException({
    required super.kind,
    required super.userMessage,
    required super.technicalMessage,
    required super.feature,
    super.cause,
  }) : super(retryable: false, reportable: false);
}

class OnmuBackgroundException extends OnmuException {
  const OnmuBackgroundException({
    required super.userMessage,
    required super.technicalMessage,
    required super.feature,
    super.cause,
    super.reportable = true,
  }) : super(kind: OnmuErrorKind.backgroundSync, retryable: true);
}

OnmuErrorKind _kindFor(DioException error, int? statusCode) {
  if (statusCode != null) {
    return switch (statusCode) {
      400 || 422 => OnmuErrorKind.validation,
      401 => OnmuErrorKind.unauthorized,
      403 => OnmuErrorKind.forbidden,
      404 => OnmuErrorKind.notFound,
      409 => OnmuErrorKind.conflict,
      429 => OnmuErrorKind.rateLimited,
      500 => OnmuErrorKind.server,
      502 || 503 || 504 => OnmuErrorKind.unavailable,
      >= 500 => OnmuErrorKind.server,
      _ => OnmuErrorKind.unknown,
    };
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => OnmuErrorKind.timeout,
    DioExceptionType.connectionError => OnmuErrorKind.network,
    DioExceptionType.cancel => OnmuErrorKind.cancelled,
    DioExceptionType.badCertificate => OnmuErrorKind.network,
    _ => OnmuErrorKind.unknown,
  };
}

bool _retryableFor(OnmuErrorKind kind) {
  return switch (kind) {
    OnmuErrorKind.server ||
    OnmuErrorKind.unavailable ||
    OnmuErrorKind.timeout ||
    OnmuErrorKind.network ||
    OnmuErrorKind.rateLimited => true,
    _ => false,
  };
}

bool _reportableFor(OnmuErrorKind kind) {
  return switch (kind) {
    OnmuErrorKind.server ||
    OnmuErrorKind.unavailable ||
    OnmuErrorKind.rateLimited ||
    OnmuErrorKind.timeout ||
    OnmuErrorKind.network ||
    OnmuErrorKind.contractMismatch ||
    OnmuErrorKind.unknown => true,
    _ => false,
  };
}

String _userMessageFor(OnmuErrorKind kind) {
  return switch (kind) {
    OnmuErrorKind.validation => '입력값을 확인해 주세요.',
    OnmuErrorKind.unauthorized => '다시 로그인해 주세요.',
    OnmuErrorKind.forbidden => '이 작업을 할 수 있는 권한이 없어요.',
    OnmuErrorKind.notFound => '찾을 수 없어요.',
    OnmuErrorKind.conflict => '이미 처리된 요청이에요.',
    OnmuErrorKind.rateLimited => '요청이 많아요. 잠시 후 다시 시도해 주세요.',
    OnmuErrorKind.timeout || OnmuErrorKind.network => '네트워크 연결을 확인해 주세요.',
    OnmuErrorKind.cancelled => '요청이 취소됐어요.',
    _ => '잠시 문제가 생겼어요. 다시 시도해 주세요.',
  };
}

String _technicalMessageFor(DioException error, int? statusCode) {
  final method = error.requestOptions.method;
  final path = error.requestOptions.path;
  final status = statusCode == null ? 'no-status' : statusCode.toString();
  return '$method $path failed with $status (${error.type.name})';
}

String _serverReasonFor(Object? data) {
  if (data == null) {
    return '';
  }
  return data.toString();
}

String _serverErrorCodeFor(Object? data) {
  if (data is Map) {
    for (final key in const [
      'errorCode',
      'code',
      'reason',
      'detail',
      'message',
    ]) {
      final value = data[key];
      if (value is String) {
        final code = _safeServerCode(value);
        if (code.isNotEmpty) {
          return code;
        }
      }
    }
  }
  if (data is String) {
    return _safeServerCode(data);
  }
  return '';
}

String _safeServerCode(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.length > 120) {
    return '';
  }
  if (!RegExp(r'^[A-Za-z][A-Za-z0-9_.-]*$').hasMatch(trimmed)) {
    return '';
  }
  return trimmed;
}
