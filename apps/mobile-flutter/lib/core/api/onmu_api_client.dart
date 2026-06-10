import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const defaultOnmuApiBaseUrl = 'https://dev-api.onmu.cloud';

final onmuApiClientProvider = Provider<OnmuApiClient>((ref) {
  const baseUrl = String.fromEnvironment(
    'ONMU_API_BASE_URL',
    defaultValue: defaultOnmuApiBaseUrl,
  );
  const accessJwt = String.fromEnvironment('ONMU_API_ACCESS_JWT');
  const legacyDevAccessToken = String.fromEnvironment('ONMU_DEV_ACCESS_TOKEN');
  final accessToken = resolveOnmuAccessToken(
    accessJwt: accessJwt,
    legacyDevAccessToken: legacyDevAccessToken,
  );
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
        if (accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      },
    ),
  );
  return OnmuApiClient(dio);
});

String resolveOnmuAccessToken({
  required String accessJwt,
  required String legacyDevAccessToken,
}) {
  return accessJwt.isNotEmpty ? accessJwt : legacyDevAccessToken;
}

class OnmuApiClient {
  OnmuApiClient(this._dio);

  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  Future<Map<String, dynamic>> getObject(String path) async {
    final response = await _dio.get<Object?>(path);
    return OnmuJson.asMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final response = await _dio.get<Object?>(path);
    return OnmuJson.asMapList(response.data);
  }

  Future<Map<String, dynamic>> postObject(
    String path, {
    Map<String, Object?> body = const {},
  }) async {
    final response = await _dio.post<Object?>(path, data: body);
    return OnmuJson.asMap(response.data);
  }

  Future<Map<String, dynamic>> patchObject(
    String path, {
    Map<String, Object?> body = const {},
  }) async {
    final response = await _dio.patch<Object?>(path, data: body);
    return OnmuJson.asMap(response.data);
  }
}

class OnmuJson {
  const OnmuJson._();

  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> asMapList(Object? value) {
    if (value is List) {
      return value.map(asMap).toList(growable: false);
    }
    return const [];
  }

  static List<String> stringList(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const [];
  }

  static int readInt(
    Map<String, dynamic> json,
    String key, [
    int fallback = 0,
  ]) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double readDouble(
    Map<String, dynamic> json,
    String key, [
    double fallback = 0,
  ]) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool readBool(
    Map<String, dynamic> json,
    String key, [
    bool fallback = false,
  ]) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    return fallback;
  }

  static String readString(
    Map<String, dynamic> json,
    String key, [
    String fallback = '',
  ]) {
    final value = json[key];
    if (value == null) {
      return fallback;
    }
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }
}
