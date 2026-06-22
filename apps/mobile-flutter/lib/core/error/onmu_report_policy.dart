import 'onmu_exception.dart';

class OnmuReportPolicy {
  const OnmuReportPolicy._();

  static bool shouldReport(Object error) {
    if (error is OnmuException) {
      return error.reportable;
    }
    return true;
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
        'endpoint_template': error.endpoint!.trim(),
    };
  }
}
