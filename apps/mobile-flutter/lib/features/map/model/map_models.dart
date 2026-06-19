class OnmuLatLng {
  const OnmuLatLng({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class OnmuMapBounds {
  const OnmuMapBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  Map<String, Object?> toJson() {
    return {'south': south, 'west': west, 'north': north, 'east': east};
  }
}

class OnmuMapViewport {
  const OnmuMapViewport({required this.bounds, required this.zoom});

  final OnmuMapBounds bounds;
  final double zoom;

  int get apiZoom => zoom.round().clamp(0, 22).toInt();
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
    this.provider = '',
    this.providerPlaceId = '',
    this.name = '',
    this.address = '',
    this.roadAddress = '',
  });

  final String id;
  final OnmuLatLng coordinate;
  final String category;
  final String provider;
  final String providerPlaceId;
  final String name;
  final String address;
  final String roadAddress;

  factory OnmuCatalogMapPoint.fromJson(Map<String, dynamic> json) {
    return OnmuCatalogMapPoint(
      id: _readString(json['id']),
      provider: _readString(json['provider']),
      providerPlaceId: _readString(json['providerPlaceId']),
      name: _readString(json['name']),
      category: _readString(json['category']),
      address: _readString(json['address']),
      roadAddress: _readString(json['roadAddress']),
      coordinate: OnmuLatLng(
        lat: _readDouble(json['lat']),
        lng: _readDouble(json['lng']),
      ),
    );
  }
}

class OnmuCatalogMapCluster {
  const OnmuCatalogMapCluster({
    required this.id,
    required this.count,
    required this.coordinate,
    required this.bounds,
    this.categories = const [],
  });

  final String id;
  final int count;
  final OnmuLatLng coordinate;
  final OnmuMapBounds bounds;
  final List<String> categories;

  factory OnmuCatalogMapCluster.fromJson(Map<String, dynamic> json) {
    final bounds = _asMap(json['bounds']);
    return OnmuCatalogMapCluster(
      id: _readString(json['id']),
      count: _readInt(json['count']),
      coordinate: OnmuLatLng(
        lat: _readDouble(json['lat']),
        lng: _readDouble(json['lng']),
      ),
      bounds: OnmuMapBounds(
        south: _readDouble(bounds['south']),
        west: _readDouble(bounds['west']),
        north: _readDouble(bounds['north']),
        east: _readDouble(bounds['east']),
      ),
      categories: _stringList(json['categories']),
    );
  }
}

class OnmuCatalogMapData {
  const OnmuCatalogMapData({
    required this.mode,
    required this.zoom,
    required this.bounds,
    required this.clusters,
    required this.points,
  });

  final String mode;
  final int zoom;
  final OnmuMapBounds bounds;
  final List<OnmuCatalogMapCluster> clusters;
  final List<OnmuCatalogMapPoint> points;

  factory OnmuCatalogMapData.empty(OnmuMapViewport viewport) {
    return OnmuCatalogMapData(
      mode: 'points',
      zoom: viewport.apiZoom,
      bounds: viewport.bounds,
      clusters: const [],
      points: const [],
    );
  }

  factory OnmuCatalogMapData.fromJson(Map<String, dynamic> json) {
    final bounds = _asMap(json['bounds']);
    return OnmuCatalogMapData(
      mode: _readString(json['mode']),
      zoom: _readInt(json['zoom']),
      bounds: OnmuMapBounds(
        south: _readDouble(bounds['south']),
        west: _readDouble(bounds['west']),
        north: _readDouble(bounds['north']),
        east: _readDouble(bounds['east']),
      ),
      clusters: _asMapList(
        json['clusters'],
      ).map(OnmuCatalogMapCluster.fromJson).toList(growable: false),
      points: _asMapList(
        json['points'],
      ).map(OnmuCatalogMapPoint.fromJson).toList(growable: false),
    );
  }
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

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<Map<String, dynamic>> _asMapList(Object? value) {
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

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const [];
}

String _readString(Object? value, [String fallback = '']) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}

int _readInt(Object? value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _readDouble(Object? value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
