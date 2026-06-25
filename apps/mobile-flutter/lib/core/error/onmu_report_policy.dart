import 'onmu_exception.dart';

class OnmuReportPolicy {
  const OnmuReportPolicy._();

  static bool shouldReport(Object error) {
    if (error is OnmuException) {
      return error.reportable;
    }
    return true;
  }

  static double sampleRateFor(Object error) {
    final kind = error is OnmuException ? error.kind : OnmuErrorKind.unknown;
    return switch (kind) {
      OnmuErrorKind.server ||
      OnmuErrorKind.unavailable ||
      OnmuErrorKind.contractMismatch ||
      OnmuErrorKind.unknown => 1,
      OnmuErrorKind.timeout || OnmuErrorKind.rateLimited => 0.2,
      OnmuErrorKind.network => 0.05,
      _ => 0,
    };
  }

  static Map<String, String> safeTags(OnmuException error) {
    return {
      'feature': error.feature,
      'kind': error.kind.name,
      'retryable': error.retryable.toString(),
      if (error.statusCode != null) 'statusCode': error.statusCode.toString(),
      if (error.method != null && error.method!.trim().isNotEmpty)
        'method': error.method!.trim(),
      if (error.endpoint != null && error.endpoint!.trim().isNotEmpty)
        'endpoint_template': _endpointTemplate(error.endpoint!.trim()),
      if (error is OnmuApiException && error.errorCode.trim().isNotEmpty)
        'error_code': error.errorCode.trim(),
    };
  }
}

String _endpointTemplate(String endpoint) {
  final path = Uri.tryParse(endpoint)?.path ?? endpoint.split('?').first;
  return path
      .split('/')
      .map((segment) {
        if (segment.isEmpty) {
          return segment;
        }
        if (_looksLikeIdentifier(segment)) {
          return '{id}';
        }
        return segment;
      })
      .join('/');
}

bool _looksLikeIdentifier(String segment) {
  if (RegExp(r'^\d+$').hasMatch(segment)) {
    return true;
  }
  if (RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(segment)) {
    return true;
  }
  return RegExp(
    r'^(usr|grp|plan|place|vote|settle)_[A-Za-z0-9_-]+$',
  ).hasMatch(segment);
}
