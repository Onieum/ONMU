class OnmuLatLng {
  const OnmuLatLng({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class OnmuMapPoint {
  const OnmuMapPoint({
    required this.id,
    required this.label,
    required this.coordinate,
    required this.order,
  });

  final String id;
  final String label;
  final OnmuLatLng coordinate;
  final int order;
}

class OnmuCatalogMapPoint {
  const OnmuCatalogMapPoint({
    required this.id,
    required this.coordinate,
    this.category = '',
  });

  final String id;
  final OnmuLatLng coordinate;
  final String category;
}

class TileManifest {
  const TileManifest({
    required this.styleUrl,
    required this.currentPmtilesUrl,
    required this.bounds,
    required this.center,
    required this.generatedAt,
  });

  final String styleUrl;
  final String currentPmtilesUrl;
  final List<double> bounds;
  final OnmuLatLng center;
  final DateTime? generatedAt;

  factory TileManifest.fromJson(Map<String, dynamic> json) {
    final current = _asMap(json['current']);
    final tileset = _asMap(current['tileset'] ?? json['tileset']);
    final center = _asDoubleList(current['center'] ?? json['center']);
    return TileManifest(
      styleUrl: _readString(current['styleUrl'] ?? json['styleUrl']),
      currentPmtilesUrl: _readString(tileset['url']),
      bounds: _asDoubleList(current['bounds'] ?? json['bounds']),
      center: OnmuLatLng(
        lat: center.length >= 2 ? center[1] : 36.5,
        lng: center.isNotEmpty ? center[0] : 127.8,
      ),
      generatedAt: DateTime.tryParse(_readString(json['generatedAt'])),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const {};
  }

  static List<double> _asDoubleList(Object? value) {
    if (value is List) {
      return value
          .map(
            (item) => item is num ? item.toDouble() : double.tryParse('$item'),
          )
          .whereType<double>()
          .toList(growable: false);
    }
    return const [];
  }

  static String _readString(Object? value) => value?.toString() ?? '';
}

class RouteRecommendation {
  const RouteRecommendation({
    required this.provider,
    required this.stops,
    required this.geometry,
    required this.legs,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.travelMode,
    required this.liveProvider,
    required this.fallbackReason,
    required this.fetchedAt,
  });

  final String provider;
  final List<OnmuMapPoint> stops;
  final List<OnmuLatLng> geometry;
  final List<RouteLeg> legs;
  final int distanceMeters;
  final int durationSeconds;
  final String travelMode;
  final bool liveProvider;
  final String fallbackReason;
  final DateTime? fetchedAt;

  bool get isFallback => !liveProvider || provider == 'dev-mock';

  factory RouteRecommendation.fromJson(Map<String, dynamic> json) {
    final stops = _asMapList(json['stops']);
    final geometry = json['geometry'] is List
        ? json['geometry'] as List
        : const [];
    return RouteRecommendation(
      provider: _readString(json['provider'], 'dev-mock'),
      stops: [
        for (var index = 0; index < stops.length; index += 1)
          OnmuMapPoint(
            id: _readString(stops[index]['id'], 'stop-$index'),
            label: _readString(stops[index]['name'], 'Stop ${index + 1}'),
            coordinate: OnmuLatLng(
              lat: _readDouble(stops[index]['lat'], 37.5665),
              lng: _readDouble(stops[index]['lng'], 126.9780),
            ),
            order: _readInt(stops[index]['order'], index + 1),
          ),
      ],
      geometry: [
        for (final point in geometry)
          if (point is List && point.length >= 2)
            OnmuLatLng(
              lat: _readDouble(point[1], 37.5665),
              lng: _readDouble(point[0], 126.9780),
            ),
      ],
      legs: [
        for (final leg in _asMapList(json['legs']))
          RouteLeg(
            order: _readInt(leg['order']),
            fromStopId: _readString(leg['fromStopId']),
            toStopId: _readString(leg['toStopId']),
            fromName: _readString(leg['fromName']),
            toName: _readString(leg['toName']),
            distanceMeters: _readNullableInt(leg['distanceMeters']),
            durationSeconds: _readNullableInt(leg['durationSeconds']),
          ),
      ],
      distanceMeters: _readInt(json['distanceMeters'], 0),
      durationSeconds: _readInt(json['durationSeconds'], 0),
      travelMode: _readString(json['travelMode'], 'walk'),
      liveProvider: _readBool(json['liveProvider'], false),
      fallbackReason: _readString(json['fallbackReason']),
      fetchedAt: DateTime.tryParse(_readString(json['fetchedAt'])),
    );
  }

  static List<Map<String, dynamic>> _asMapList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false);
    }
    return const [];
  }

  static String _readString(Object? value, [String fallback = '']) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(Object? value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int? _readNullableInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static double _readDouble(Object? value, [double fallback = 0]) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _readBool(Object? value, [bool fallback = false]) {
    if (value is bool) {
      return value;
    }
    final text = value?.toString().toLowerCase();
    if (text == 'true') {
      return true;
    }
    if (text == 'false') {
      return false;
    }
    return fallback;
  }
}

class RouteLeg {
  const RouteLeg({
    required this.order,
    required this.fromStopId,
    required this.toStopId,
    required this.fromName,
    required this.toName,
    this.distanceMeters,
    this.durationSeconds,
  });

  final int order;
  final String fromStopId;
  final String toStopId;
  final String fromName;
  final String toName;
  final int? distanceMeters;
  final int? durationSeconds;
}
