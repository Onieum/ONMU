import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/map_models.dart';
import '../repository/tile_manifest_repository.dart';
import '../web/onmu_map_web_bootstrap.dart';

@visibleForTesting
bool shouldUseOnmuMapLibre({
  required TileManifest? manifest,
  required bool platformViewAvailable,
  required bool pmtilesProtocolReady,
}) {
  return platformViewAvailable &&
      (manifest?.styleUrl.trim().isNotEmpty ?? false) &&
      pmtilesProtocolReady;
}

@visibleForTesting
const String mapNativePointDataKey = 'onmuPointId';

@visibleForTesting
const String mapCatalogSourceId = 'onmu-catalog-context-source';

@visibleForTesting
const String mapCatalogClusterLayerId = 'onmu-catalog-clusters';

@visibleForTesting
const String mapCatalogClusterCountLayerId = 'onmu-catalog-cluster-count';

@visibleForTesting
const String mapCatalogDotLayerId = 'onmu-catalog-dots';

@visibleForTesting
const double onmuMapMinUsableZoom = 6.2;

@visibleForTesting
const EdgeInsets onmuMapCameraFitPadding = EdgeInsets.fromLTRB(
  56,
  160,
  56,
  480,
);

@visibleForTesting
const EdgeInsets onmuMapMarkerScreenSafetyPadding = EdgeInsets.fromLTRB(
  0,
  160,
  0,
  240,
);

@visibleForTesting
const double onmuMapMarkerIconSize = 64;

@visibleForTesting
const double onmuMapFocusedMarkerIconSize = 78;

@visibleForTesting
const double onmuMapMarkerFallbackSize = 50;

@visibleForTesting
const double onmuMapFocusedMarkerFallbackSize = 62;

@visibleForTesting
String nativeMarkerIconImageName({required int order, required bool focused}) {
  final state = focused ? 'focused' : 'normal';
  return 'onmu-map-marker-$state-$order';
}

@visibleForTesting
Future<Uint8List> createNativeMarkerIconBytes({
  required int order,
  required bool focused,
}) async {
  final size = focused ? onmuMapFocusedMarkerIconSize : onmuMapMarkerIconSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(size / 2, size / 2);
  final radius = focused ? 30.0 : 24.0;

  final shadowPaint = Paint()
    ..color = const Color(0x33000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  canvas.drawCircle(center.translate(0, 3), radius + 1.5, shadowPaint);

  final fillPaint = Paint()
    ..color = focused ? const Color(0xFFE86D75) : const Color(0xFFFF8FA3);
  canvas.drawCircle(center, radius, fillPaint);

  final strokePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = focused ? 6 : 5;
  canvas.drawCircle(center, radius, strokePaint);

  final textPainter = TextPainter(
    text: TextSpan(
      text: '$order',
      style: TextStyle(
        color: Colors.white,
        fontSize: focused ? 30 : 25,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size);
  textPainter.paint(
    canvas,
    Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
  );

  final image = await recorder.endRecording().toImage(size.ceil(), size.ceil());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) {
    return Uint8List(0);
  }
  return byteData.buffer.asUint8List();
}

@visibleForTesting
SymbolOptions nativeSymbolOptionsForPoint({
  required OnmuMapPoint point,
  required bool focused,
}) {
  return SymbolOptions(
    geometry: LatLng(point.coordinate.lat, point.coordinate.lng),
    iconImage: nativeMarkerIconImageName(order: point.order, focused: focused),
    iconAnchor: 'center',
    iconSize: 1,
    zIndex: focused ? 40 : 10,
  );
}

@visibleForTesting
LineOptions? nativeLineOptionsForRoute(List<OnmuLatLng> routeGeometry) {
  final safeRouteGeometry = validOnmuMapCoordinates(routeGeometry);
  if (safeRouteGeometry.length < 2) {
    return null;
  }
  return LineOptions(
    geometry: safeRouteGeometry
        .map((point) => LatLng(point.lat, point.lng))
        .toList(growable: false),
    lineColor: '#2563EB',
    lineWidth: 8.0,
    lineOpacity: 0.98,
    lineJoin: 'round',
  );
}

@visibleForTesting
LineOptions? nativeLineCasingOptionsForRoute(List<OnmuLatLng> routeGeometry) {
  final safeRouteGeometry = validOnmuMapCoordinates(routeGeometry);
  if (safeRouteGeometry.length < 2) {
    return null;
  }
  return LineOptions(
    geometry: safeRouteGeometry
        .map((point) => LatLng(point.lat, point.lng))
        .toList(growable: false),
    lineColor: '#FFFFFF',
    lineWidth: 13.0,
    lineOpacity: 0.96,
    lineJoin: 'round',
  );
}

@visibleForTesting
bool shouldFitCameraForMapUpdate({
  required bool pointsChanged,
  required bool routeGeometryChanged,
  required bool centerChanged,
  required bool zoomChanged,
  required bool styleLoaded,
}) {
  return pointsChanged || routeGeometryChanged || styleLoaded;
}

@visibleForTesting
bool haveSameMapPointCameraTargets(
  List<OnmuMapPoint> previous,
  List<OnmuMapPoint> next,
) {
  if (previous.length != next.length) {
    return false;
  }
  for (var i = 0; i < previous.length; i += 1) {
    final previousPoint = previous[i];
    final nextPoint = next[i];
    if (previousPoint.id != nextPoint.id ||
        previousPoint.order != nextPoint.order ||
        !_sameCoordinate(previousPoint.coordinate, nextPoint.coordinate)) {
      return false;
    }
  }
  return true;
}

@visibleForTesting
bool haveSameRouteCameraTargets(
  List<OnmuLatLng> previous,
  List<OnmuLatLng> next,
) {
  if (previous.length != next.length) {
    return false;
  }
  for (var i = 0; i < previous.length; i += 1) {
    if (!_sameCoordinate(previous[i], next[i])) {
      return false;
    }
  }
  return true;
}

@visibleForTesting
bool haveSameOptionalCameraTarget(OnmuLatLng? previous, OnmuLatLng? next) {
  if (previous == null || next == null) {
    return previous == null && next == null;
  }
  return _sameCoordinate(previous, next);
}

bool _sameCoordinate(OnmuLatLng previous, OnmuLatLng next) {
  return previous.lat == next.lat && previous.lng == next.lng;
}

@visibleForTesting
bool haveSameCatalogLayerPoints(
  List<OnmuCatalogMapPoint> previous,
  List<OnmuCatalogMapPoint> next,
) {
  if (previous.length != next.length) {
    return false;
  }
  for (var i = 0; i < previous.length; i += 1) {
    final previousPoint = previous[i];
    final nextPoint = next[i];
    if (previousPoint.id != nextPoint.id ||
        previousPoint.category != nextPoint.category ||
        previousPoint.providerPlaceId != nextPoint.providerPlaceId ||
        !_sameCoordinate(previousPoint.coordinate, nextPoint.coordinate)) {
      return false;
    }
  }
  return true;
}

@visibleForTesting
bool haveSameCatalogLayerClusters(
  List<OnmuCatalogMapCluster> previous,
  List<OnmuCatalogMapCluster> next,
) {
  if (previous.length != next.length) {
    return false;
  }
  for (var i = 0; i < previous.length; i += 1) {
    final previousCluster = previous[i];
    final nextCluster = next[i];
    if (previousCluster.id != nextCluster.id ||
        previousCluster.count != nextCluster.count ||
        !_sameCoordinate(previousCluster.coordinate, nextCluster.coordinate)) {
      return false;
    }
  }
  return true;
}

@visibleForTesting
Map<String, dynamic> catalogGeoJsonForLayer({
  required List<OnmuCatalogMapCluster> clusters,
  required List<OnmuCatalogMapPoint> points,
}) {
  return {
    'type': 'FeatureCollection',
    'features': [
      for (final cluster in clusters)
        {
          'type': 'Feature',
          'id': cluster.id,
          'properties': {
            'id': cluster.id,
            'type': 'cluster',
            'point_count': cluster.count,
            'point_count_abbreviated': _abbreviatedCount(cluster.count),
            'south': cluster.bounds.south,
            'west': cluster.bounds.west,
            'north': cluster.bounds.north,
            'east': cluster.bounds.east,
            if (cluster.categories.isNotEmpty)
              'categories': cluster.categories.join(','),
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [cluster.coordinate.lng, cluster.coordinate.lat],
          },
        },
      for (final point in points)
        {
          'type': 'Feature',
          'id': point.id,
          'properties': {
            'id': point.id,
            'type': 'point',
            if (point.providerPlaceId.trim().isNotEmpty)
              'providerPlaceId': point.providerPlaceId.trim(),
            if (point.category.trim().isNotEmpty)
              'category': point.category.trim(),
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [point.coordinate.lng, point.coordinate.lat],
          },
        },
    ],
  };
}

@visibleForTesting
GeojsonSourceProperties catalogGeoJsonSourceProperties(
  List<OnmuCatalogMapPoint> points, {
  List<OnmuCatalogMapCluster> clusters = const [],
}) {
  return GeojsonSourceProperties(
    data: catalogGeoJsonForLayer(clusters: clusters, points: points),
    cluster: false,
    promoteId: 'id',
  );
}

String _abbreviatedCount(int count) {
  if (count >= 1000) {
    final value = count / 1000;
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}k';
  }
  return count.toString();
}

@visibleForTesting
CircleLayerProperties catalogClusterCircleLayerProperties() {
  return const CircleLayerProperties(
    circleColor: '#FF8FA3',
    circleOpacity: 0.82,
    circleStrokeColor: '#FFFFFF',
    circleStrokeWidth: 3,
    circleRadius: [
      'step',
      ['get', 'point_count'],
      18,
      10,
      22,
      50,
      28,
    ],
  );
}

@visibleForTesting
SymbolLayerProperties catalogClusterCountLayerProperties() {
  return const SymbolLayerProperties(
    textField: ['get', 'point_count_abbreviated'],
    textColor: '#FFFFFF',
    textSize: 12,
    textFont: ['Open Sans Bold', 'Arial Unicode MS Bold'],
    textAllowOverlap: true,
    textIgnorePlacement: true,
  );
}

@visibleForTesting
CircleLayerProperties catalogDotLayerProperties() {
  return const CircleLayerProperties(
    circleColor: '#E86D75',
    circleOpacity: 0.72,
    circleRadius: 4.2,
    circleStrokeColor: '#FFFFFF',
    circleStrokeWidth: 1.6,
  );
}

const _catalogClusterFilter = ['has', 'point_count'];
const _catalogUnclusteredFilter = [
  '!',
  ['has', 'point_count'],
];

@visibleForTesting
List<OnmuLatLng> validOnmuMapCoordinates(Iterable<OnmuLatLng> coordinates) {
  return coordinates.where(isValidOnmuLatLng).toList(growable: false);
}

@visibleForTesting
List<OnmuMapPoint> validOnmuMapPoints(Iterable<OnmuMapPoint> points) {
  return points
      .where((point) => isValidOnmuLatLng(point.coordinate))
      .toList(growable: false);
}

@visibleForTesting
String onmuMapCameraSeedKey({
  required Iterable<OnmuMapPoint> points,
  required Iterable<OnmuLatLng> routeGeometry,
}) {
  // Keep user-driven camera movement out of the platform-view key.
  final coordinates = [
    ...validOnmuMapPoints(points).map((point) => point.coordinate),
    ...validOnmuMapCoordinates(routeGeometry),
  ];
  return coordinates
      .map(
        (coordinate) =>
            '${coordinate.lat.toStringAsFixed(6)},'
            '${coordinate.lng.toStringAsFixed(6)}',
      )
      .join('|');
}

@visibleForTesting
double onmuMapInitialZoomForCoordinates({
  required Iterable<OnmuLatLng> coordinates,
  required double fallbackZoom,
}) {
  final safeCoordinates = validOnmuMapCoordinates(coordinates);
  if (safeCoordinates.isEmpty) {
    return fallbackZoom;
  }
  if (safeCoordinates.length == 1) {
    return 14.2;
  }

  final minLat = safeCoordinates.map((value) => value.lat).reduce(math.min);
  final maxLat = safeCoordinates.map((value) => value.lat).reduce(math.max);
  final minLng = safeCoordinates.map((value) => value.lng).reduce(math.min);
  final maxLng = safeCoordinates.map((value) => value.lng).reduce(math.max);
  final spread = math.max((maxLat - minLat).abs(), (maxLng - minLng).abs());
  if (!spread.isFinite) {
    return fallbackZoom;
  }
  if (spread <= 0.004) {
    return 14.0;
  }
  if (spread <= 0.01) {
    return 13.5;
  }
  if (spread <= 0.03) {
    return 12.6;
  }
  if (spread <= 0.08) {
    return 11.5;
  }
  if (spread <= 0.2) {
    return 10.4;
  }
  if (spread <= 0.5) {
    return 9.2;
  }
  if (spread <= 1.0) {
    return 8.2;
  }
  if (spread <= 2.0) {
    return 7.2;
  }
  return onmuMapMinUsableZoom;
}

@visibleForTesting
CameraTargetBounds cameraTargetBoundsFromManifest(TileManifest? manifest) {
  final bounds = manifest?.bounds;
  if (bounds == null || bounds.length < 4) {
    return CameraTargetBounds.unbounded;
  }
  final minLng = bounds[0];
  final minLat = bounds[1];
  final maxLng = bounds[2];
  final maxLat = bounds[3];
  if (minLat >= maxLat || minLng >= maxLng) {
    return CameraTargetBounds.unbounded;
  }
  return CameraTargetBounds(
    LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    ),
  );
}

class OnmuMapView extends ConsumerStatefulWidget {
  const OnmuMapView({
    required this.points,
    this.catalogClusters = const [],
    this.catalogPoints = const [],
    this.routeGeometry = const [],
    this.center,
    this.zoom = 11,
    this.focusedPointId,
    this.onPointTap,
    this.onCameraIdle,
    this.onViewportIdle,
    this.onMyLocationResolved,
    this.onMyLocationUnavailable,
    this.myLocationEnabled = false,
    this.myLocationRequestSerial = 0,
    this.cameraFocusTarget,
    this.cameraFocusRequestSerial = 0,
    this.cameraFitPadding = onmuMapCameraFitPadding,
    this.markerScreenSafetyPadding = onmuMapMarkerScreenSafetyPadding,
    this.fallbackLabel = '지도 스타일을 불러오는 중입니다.',
    this.debugWebPmtilesProtocolReady,
    super.key,
  });

  final List<OnmuMapPoint> points;
  final List<OnmuCatalogMapCluster> catalogClusters;
  final List<OnmuCatalogMapPoint> catalogPoints;
  final List<OnmuLatLng> routeGeometry;
  final OnmuLatLng? center;
  final double zoom;
  final String? focusedPointId;
  final ValueChanged<OnmuMapPoint>? onPointTap;
  final ValueChanged<OnmuLatLng>? onCameraIdle;
  final ValueChanged<OnmuMapViewport>? onViewportIdle;
  final ValueChanged<OnmuLatLng>? onMyLocationResolved;
  final VoidCallback? onMyLocationUnavailable;
  final bool myLocationEnabled;
  final int myLocationRequestSerial;
  final OnmuLatLng? cameraFocusTarget;
  final int cameraFocusRequestSerial;
  final EdgeInsets cameraFitPadding;
  final EdgeInsets markerScreenSafetyPadding;
  final String fallbackLabel;
  final bool? debugWebPmtilesProtocolReady;

  @override
  ConsumerState<OnmuMapView> createState() => _OnmuMapViewState();
}

class _OnmuMapViewState extends ConsumerState<OnmuMapView> {
  MapLibreMapController? _mapController;
  bool _styleLoaded = false;
  bool _catalogSourceAdded = false;
  bool _myLocationLayerEnabled = false;
  int _handledMyLocationRequestSerial = 0;
  int _handledCameraFocusRequestSerial = 0;
  int _nativeSyncGeneration = 0;
  final Set<String> _registeredNativeMarkerImages = {};

  @override
  void didUpdateWidget(covariant OnmuMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCameraSeedKey = onmuMapCameraSeedKey(
      points: oldWidget.points,
      routeGeometry: oldWidget.routeGeometry,
    );
    final nextCameraSeedKey = onmuMapCameraSeedKey(
      points: widget.points,
      routeGeometry: widget.routeGeometry,
    );
    if (oldCameraSeedKey != nextCameraSeedKey) {
      _styleLoaded = false;
      _registeredNativeMarkerImages.clear();
      _nativeSyncGeneration += 1;
    }
    final pointsChanged = !haveSameMapPointCameraTargets(
      oldWidget.points,
      widget.points,
    );
    final routeGeometryChanged = !haveSameRouteCameraTargets(
      oldWidget.routeGeometry,
      widget.routeGeometry,
    );
    final catalogPointsChanged = !haveSameCatalogLayerPoints(
      oldWidget.catalogPoints,
      widget.catalogPoints,
    );
    final catalogClustersChanged = !haveSameCatalogLayerClusters(
      oldWidget.catalogClusters,
      widget.catalogClusters,
    );
    final centerChanged = !haveSameOptionalCameraTarget(
      oldWidget.center,
      widget.center,
    );
    final zoomChanged = oldWidget.zoom != widget.zoom;
    final focusChanged = oldWidget.focusedPointId != widget.focusedPointId;
    if (pointsChanged ||
        routeGeometryChanged ||
        catalogPointsChanged ||
        catalogClustersChanged ||
        centerChanged ||
        zoomChanged ||
        focusChanged) {
      _syncNativeMap(
        fitCamera: shouldFitCameraForMapUpdate(
          pointsChanged: pointsChanged,
          routeGeometryChanged: routeGeometryChanged,
          centerChanged: centerChanged,
          zoomChanged: zoomChanged,
          styleLoaded: false,
        ),
      );
    }
    if (widget.myLocationRequestSerial > 0 &&
        widget.myLocationRequestSerial != _handledMyLocationRequestSerial) {
      _handledMyLocationRequestSerial = widget.myLocationRequestSerial;
      if (!_myLocationLayerEnabled) {
        setState(() {
          _myLocationLayerEnabled = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_focusNativeMyLocation());
          }
        });
      } else {
        unawaited(_focusNativeMyLocation());
      }
    }
    if (widget.cameraFocusRequestSerial > 0 &&
        widget.cameraFocusRequestSerial != _handledCameraFocusRequestSerial) {
      _handledCameraFocusRequestSerial = widget.cameraFocusRequestSerial;
      unawaited(_focusExplicitCameraTarget(widget.cameraFocusTarget));
    }
  }

  @override
  void dispose() {
    final controller = _mapController;
    if (controller != null) {
      controller.onSymbolTapped.remove(_handleSymbolTapped);
    }
    _mapController = null;
    _styleLoaded = false;
    _nativeSyncGeneration += 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manifestState = ref.watch(tileManifestProvider);
    final manifest = manifestState.asData?.value;
    final safePoints = validOnmuMapPoints(widget.points);
    final safeRouteGeometry = validOnmuMapCoordinates(widget.routeGeometry);
    final mapDataCoordinates = [
      ...safePoints.map((point) => point.coordinate),
      ...safeRouteGeometry,
    ];
    final mapCenter =
        widget.center ??
        _centerFromData() ??
        manifest?.center ??
        const OnmuLatLng(lat: 36.5, lng: 127.8);
    final initialZoom = math.max(
      onmuMapInitialZoomForCoordinates(
        coordinates: mapDataCoordinates,
        fallbackZoom: widget.zoom,
      ),
      onmuMapMinUsableZoom,
    );
    final cameraSeedKey = onmuMapCameraSeedKey(
      points: safePoints,
      routeGeometry: safeRouteGeometry,
    );
    final styleUrl = manifest?.styleUrl ?? '';
    final webBootstrapReady =
        widget.debugWebPmtilesProtocolReady ?? isOnmuMapWebBootstrapReady;
    final useMapLibre = shouldUseOnmuMapLibre(
      manifest: manifest,
      platformViewAvailable: _canUseMapLibre,
      pmtilesProtocolReady: webBootstrapReady,
    );
    final effectiveFallbackLabel = styleUrl.isNotEmpty && !webBootstrapReady
        ? '지도 스크립트를 준비하는 중입니다.'
        : widget.fallbackLabel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        children: [
          Positioned.fill(
            child: useMapLibre
                ? MapLibreMap(
                    key: ValueKey(cameraSeedKey),
                    styleString: styleUrl,
                    translucentTextureSurface: true,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(mapCenter.lat, mapCenter.lng),
                      zoom: initialZoom,
                    ),
                    cameraTargetBounds: cameraTargetBoundsFromManifest(
                      manifest,
                    ),
                    minMaxZoomPreference: const MinMaxZoomPreference(
                      onmuMapMinUsableZoom,
                      18,
                    ),
                    onMapCreated: _handleMapCreated,
                    onStyleLoadedCallback: _handleStyleLoaded,
                    onMapClick: _handleMapClick,
                    onCameraIdle: _handleCameraIdle,
                    trackCameraPosition: true,
                    compassEnabled: false,
                    logoEnabled: false,
                    attributionButtonPosition:
                        AttributionButtonPosition.bottomLeft,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    myLocationEnabled:
                        widget.myLocationEnabled || _myLocationLayerEnabled,
                    myLocationTrackingMode: MyLocationTrackingMode.none,
                    myLocationRenderMode: MyLocationRenderMode.normal,
                    annotationOrder: const [
                      AnnotationType.line,
                      AnnotationType.symbol,
                    ],
                    annotationConsumeTapEvents: const [
                      AnnotationType.symbol,
                      AnnotationType.line,
                    ],
                  )
                : _FallbackMapBackground(label: effectiveFallbackLabel),
          ),
          if (!useMapLibre)
            Positioned.fill(
              child: _ProjectedMapOverlay(
                points: widget.points,
                routeGeometry: widget.routeGeometry,
                focusedPointId: widget.focusedPointId,
                onPointTap: widget.onPointTap,
                center: mapCenter,
              ),
            ),
        ],
      ),
    );
  }

  bool get _canUseMapLibre {
    return WidgetsBinding.instance.runtimeType.toString() !=
        'AutomatedTestWidgetsFlutterBinding';
  }

  void _handleMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.onSymbolTapped.add(_handleSymbolTapped);
  }

  void _handleStyleLoaded() {
    _styleLoaded = true;
    _catalogSourceAdded = false;
    _registeredNativeMarkerImages.clear();
    unawaited(_configureNativeMarkerSymbolsAndSync());
  }

  Future<void> _configureNativeMarkerSymbolsAndSync() async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    try {
      await controller.setSymbolIconAllowOverlap(true);
      await controller.setSymbolIconIgnorePlacement(true);
      await controller.setSymbolTextAllowOverlap(true);
      await controller.setSymbolTextIgnorePlacement(true);
    } catch (_) {
      // 일부 플랫폼은 style 초기화 직후 placement 옵션 반영이 늦을 수 있다.
    }
    await _syncNativeMap(fitCamera: true);
  }

  void _handleMapClick(math.Point<double> point, LatLng coordinates) {
    unawaited(_zoomIntoCatalogCluster(point: point, fallback: coordinates));
  }

  Future<void> _zoomIntoCatalogCluster({
    required math.Point<double> point,
    required LatLng fallback,
  }) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded || widget.catalogClusters.isEmpty) {
      return;
    }
    try {
      final features = await controller.queryRenderedFeatures(point, const [
        mapCatalogClusterLayerId,
      ], null);
      if (features.isEmpty) {
        return;
      }
      final clusterBounds = _boundsFromRenderedFeature(features.first);
      if (clusterBounds != null) {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            clusterBounds,
            left: 48,
            top: 160,
            right: 48,
            bottom: 320,
          ),
          duration: const Duration(milliseconds: 320),
        );
        return;
      }
      final target = _latLngFromRenderedFeature(features.first) ?? fallback;
      final currentZoom = controller.cameraPosition?.zoom ?? widget.zoom;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          target,
          math.min(18, math.max(currentZoom + 1.8, 12.6)),
        ),
        duration: const Duration(milliseconds: 320),
      );
    } catch (_) {
      // Cluster hit-test 실패는 지도 상호작용 자체를 막지 않는다.
    }
  }

  LatLng? _latLngFromRenderedFeature(Object? feature) {
    if (feature is! Map) {
      return null;
    }
    final geometry = feature['geometry'];
    if (geometry is! Map) {
      return null;
    }
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) {
      return null;
    }
    final lng = _readDouble(coordinates[0]);
    final lat = _readDouble(coordinates[1]);
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  LatLngBounds? _boundsFromRenderedFeature(Object? feature) {
    if (feature is! Map) {
      return null;
    }
    final properties = _asMap(feature['properties']);
    final south = _readDouble(properties['south']);
    final west = _readDouble(properties['west']);
    final north = _readDouble(properties['north']);
    final east = _readDouble(properties['east']);
    if (south == null || west == null || north == null || east == null) {
      return null;
    }
    if (south >= north || west >= east) {
      return null;
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const {};
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  void _handleSymbolTapped(Symbol symbol) {
    _handleNativePointTap(symbol.data?[mapNativePointDataKey]);
  }

  void _handleCameraIdle() {
    _emitCurrentCameraTarget();
    unawaited(_emitCurrentViewport());
  }

  void _emitCurrentCameraTarget() {
    if (widget.onCameraIdle == null) {
      return;
    }
    final target = _mapController?.cameraPosition?.target;
    if (target != null) {
      widget.onCameraIdle!(
        OnmuLatLng(lat: target.latitude, lng: target.longitude),
      );
      return;
    }
    final fallbackCenter = _centerFromData();
    if (fallbackCenter != null) {
      widget.onCameraIdle!(fallbackCenter);
    }
  }

  Future<void> _emitCurrentViewport() async {
    if (widget.onViewportIdle == null) {
      return;
    }
    final controller = _mapController;
    if (controller == null) {
      final center = _centerFromData() ?? widget.center;
      if (center != null) {
        _emitViewportIfValid(_approximateViewport(center, widget.zoom));
      }
      return;
    }
    try {
      final visible = await controller.getVisibleRegion();
      final viewport = OnmuMapViewport(
        bounds: OnmuMapBounds(
          south: visible.southwest.latitude,
          west: visible.southwest.longitude,
          north: visible.northeast.latitude,
          east: visible.northeast.longitude,
        ),
        zoom: onmuMapSafeZoom(
          controller.cameraPosition?.zoom ?? widget.zoom,
          fallback: widget.zoom,
        ),
      );
      if (_emitViewportIfValid(viewport)) {
        return;
      }
      final fallback = _fallbackViewport(controller);
      if (fallback != null) {
        _emitViewportIfValid(fallback);
      }
    } catch (_) {
      final fallback = _fallbackViewport(controller);
      if (fallback != null) {
        _emitViewportIfValid(fallback);
      }
    }
  }

  bool _emitViewportIfValid(OnmuMapViewport viewport) {
    if (!viewport.isValid) {
      return false;
    }
    widget.onViewportIdle?.call(viewport);
    return true;
  }

  OnmuMapViewport? _fallbackViewport(MapLibreMapController controller) {
    final target = controller.cameraPosition?.target;
    if (target != null) {
      final center = OnmuLatLng(lat: target.latitude, lng: target.longitude);
      if (isValidOnmuLatLng(center)) {
        return _approximateViewport(
          center,
          controller.cameraPosition?.zoom ?? widget.zoom,
        );
      }
    }
    final center = _centerFromData() ?? widget.center;
    if (center == null || !isValidOnmuLatLng(center)) {
      return null;
    }
    return _approximateViewport(center, widget.zoom);
  }

  OnmuMapViewport _approximateViewport(OnmuLatLng center, double zoom) {
    final safeCenter = isValidOnmuLatLng(center)
        ? center
        : const OnmuLatLng(lat: 37.5665, lng: 126.9780);
    final safeZoom = onmuMapSafeZoom(zoom, fallback: widget.zoom);
    final span = math.max(0.002, 18 / math.pow(2, safeZoom));
    final latSpan = span;
    final lngSpan = span * 1.2;
    return OnmuMapViewport(
      bounds: OnmuMapBounds(
        south: (safeCenter.lat - latSpan).clamp(-90.0, 90.0).toDouble(),
        west: (safeCenter.lng - lngSpan).clamp(-180.0, 180.0).toDouble(),
        north: (safeCenter.lat + latSpan).clamp(-90.0, 90.0).toDouble(),
        east: (safeCenter.lng + lngSpan).clamp(-180.0, 180.0).toDouble(),
      ),
      zoom: safeZoom,
    );
  }

  Future<void> _focusNativeMyLocation() async {
    final controller = _mapController;
    if (controller == null) {
      widget.onMyLocationUnavailable?.call();
      return;
    }
    try {
      final location = await controller.requestMyLocationLatLng();
      if (location == null) {
        widget.onMyLocationUnavailable?.call();
        return;
      }
      final target = OnmuLatLng(
        lat: location.latitude,
        lng: location.longitude,
      );
      widget.onMyLocationResolved?.call(target);
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(location, 14.8),
        duration: const Duration(milliseconds: 320),
      );
    } catch (_) {
      widget.onMyLocationUnavailable?.call();
      // 위치 권한 거부나 플랫폼 위치 미사용 상태에서는 지도를 유지한다.
    }
  }

  Future<void> _focusExplicitCameraTarget(OnmuLatLng? target) async {
    final controller = _mapController;
    if (controller == null || target == null || !isValidOnmuLatLng(target)) {
      return;
    }
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(target.lat, target.lng), 14.8),
        duration: const Duration(milliseconds: 320),
      );
      _emitCurrentCameraTarget();
      unawaited(_emitCurrentViewport());
    } catch (_) {
      // 명시적 카메라 이동 실패는 지도 화면 자체를 깨지 않게 무시한다.
    }
  }

  void _handleNativePointTap(Object? pointId) {
    final id = pointId?.toString();
    if (id == null || widget.onPointTap == null) {
      return;
    }
    for (final point in widget.points) {
      if (point.id == id) {
        widget.onPointTap!(point);
        return;
      }
    }
  }

  Future<void> _syncNativeMap({required bool fitCamera}) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) {
      return;
    }
    final points = validOnmuMapPoints(widget.points);
    final routeGeometry = validOnmuMapCoordinates(widget.routeGeometry);
    final generation = ++_nativeSyncGeneration;
    try {
      await controller.clearSymbols();
      await controller.clearCircles();
      await controller.clearLines();
      if (!mounted || generation != _nativeSyncGeneration) {
        return;
      }
      await _syncCatalogNativeLayer(controller);
      if (!mounted || generation != _nativeSyncGeneration) {
        return;
      }
      await _ensureNativeMarkerImages(controller);
      if (!mounted || generation != _nativeSyncGeneration) {
        return;
      }

      final lineCasingOptions = nativeLineCasingOptionsForRoute(routeGeometry);
      if (lineCasingOptions != null) {
        await controller.addLine(lineCasingOptions, const {
          'type': 'route-casing',
        });
      }
      final lineOptions = nativeLineOptionsForRoute(routeGeometry);
      if (lineOptions != null) {
        await controller.addLine(lineOptions, const {'type': 'route'});
      }

      final symbolOptions = <SymbolOptions>[];
      final pointData = <Map<String, dynamic>>[];
      for (final point in points) {
        final focused = widget.focusedPointId == point.id;
        symbolOptions.add(
          nativeSymbolOptionsForPoint(point: point, focused: focused),
        );
        pointData.add({mapNativePointDataKey: point.id});
      }
      if (symbolOptions.isNotEmpty) {
        await controller.addSymbols(symbolOptions, pointData);
      }
      debugPrint(
        'ONMU_MAP_NATIVE_SYNC points=${points.length} '
        'symbols=${symbolOptions.length} '
        'images=${_registeredNativeMarkerImages.length} '
        'fitCameraRequest=$fitCamera runtimeFit=false',
      );

      if (!mounted || generation != _nativeSyncGeneration) {
        return;
      }
      _emitCurrentCameraTarget();
      unawaited(_emitCurrentViewport());
      await _logNativeMarkerScreenSummary(controller);
    } catch (_) {
      // 지도 annotation 동기화 실패는 플랫폼 뷰 수명주기 경쟁일 수 있어 UI를 유지한다.
    }
  }

  Future<void> _syncCatalogNativeLayer(MapLibreMapController controller) async {
    final geojson = catalogGeoJsonForLayer(
      clusters: widget.catalogClusters,
      points: widget.catalogPoints,
    );
    if (!_catalogSourceAdded) {
      await controller.addSource(
        mapCatalogSourceId,
        catalogGeoJsonSourceProperties(
          widget.catalogPoints,
          clusters: widget.catalogClusters,
        ),
      );
      await controller.addLayer(
        mapCatalogSourceId,
        mapCatalogClusterLayerId,
        catalogClusterCircleLayerProperties(),
        filter: _catalogClusterFilter,
        enableInteraction: false,
      );
      await controller.addLayer(
        mapCatalogSourceId,
        mapCatalogClusterCountLayerId,
        catalogClusterCountLayerProperties(),
        filter: _catalogClusterFilter,
        enableInteraction: false,
      );
      await controller.addLayer(
        mapCatalogSourceId,
        mapCatalogDotLayerId,
        catalogDotLayerProperties(),
        filter: _catalogUnclusteredFilter,
        enableInteraction: false,
      );
      _catalogSourceAdded = true;
      return;
    }
    await controller.setGeoJsonSource(mapCatalogSourceId, geojson);
  }

  Future<void> _logNativeMarkerScreenSummary(
    MapLibreMapController controller,
  ) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size;
    if (size == null || widget.points.isEmpty) {
      return;
    }
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = size.width * devicePixelRatio;
    final screenHeight = size.height * devicePixelRatio;
    final locations = await controller.toScreenLocationBatch(
      widget.points.map(
        (point) => LatLng(point.coordinate.lat, point.coordinate.lng),
      ),
    );
    var onscreen = 0;
    var coveredBySearch = 0;
    var coveredBySheet = 0;
    var visibleSafeArea = 0;
    var offscreen = 0;
    final searchBottom =
        widget.markerScreenSafetyPadding.top * devicePixelRatio;
    final sheetTop =
        (size.height - widget.markerScreenSafetyPadding.bottom) *
        devicePixelRatio;
    for (final location in locations) {
      final x = location.x.toDouble();
      final y = location.y.toDouble();
      final isOnscreen =
          x >= 0 && x <= screenWidth && y >= 0 && y <= screenHeight;
      if (!isOnscreen) {
        offscreen += 1;
        continue;
      }
      onscreen += 1;
      if (y < searchBottom) {
        coveredBySearch += 1;
      } else if (y > sheetTop) {
        coveredBySheet += 1;
      } else {
        visibleSafeArea += 1;
      }
    }
    debugPrint(
      'ONMU_MAP_NATIVE_SCREEN points=${widget.points.length} '
      'onscreen=$onscreen visibleSafeArea=$visibleSafeArea '
      'coveredBySearch=$coveredBySearch coveredBySheet=$coveredBySheet '
      'offscreen=$offscreen',
    );
  }

  Future<void> _ensureNativeMarkerImages(
    MapLibreMapController controller,
  ) async {
    for (final point in validOnmuMapPoints(widget.points)) {
      for (final focused in const [false, true]) {
        final imageName = nativeMarkerIconImageName(
          order: point.order,
          focused: focused,
        );
        if (_registeredNativeMarkerImages.contains(imageName)) {
          continue;
        }
        final imageBytes = await createNativeMarkerIconBytes(
          order: point.order,
          focused: focused,
        );
        await controller.addImage(imageName, imageBytes);
        _registeredNativeMarkerImages.add(imageName);
      }
    }
  }

  OnmuLatLng? _centerFromData() {
    final values = validOnmuMapCoordinates([
      ...widget.points.map((point) => point.coordinate),
      ...widget.routeGeometry,
    ]);
    if (values.isEmpty) {
      return null;
    }
    final lat =
        values.map((value) => value.lat).reduce((a, b) => a + b) /
        values.length;
    final lng =
        values.map((value) => value.lng).reduce((a, b) => a + b) /
        values.length;
    return OnmuLatLng(lat: lat, lng: lng);
  }
}

class _FallbackMapBackground extends StatelessWidget {
  const _FallbackMapBackground({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.bgGrid),
      child: CustomPaint(
        painter: _FallbackMapPainter(),
        child: label.isEmpty
            ? const SizedBox.expand()
            : Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bgDefault.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.lineSoft),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProjectedMapOverlay extends StatelessWidget {
  const _ProjectedMapOverlay({
    required this.points,
    required this.routeGeometry,
    required this.focusedPointId,
    required this.onPointTap,
    required this.center,
  });

  final List<OnmuMapPoint> points;
  final List<OnmuLatLng> routeGeometry;
  final String? focusedPointId;
  final ValueChanged<OnmuMapPoint>? onPointTap;
  final OnmuLatLng center;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final safePoints = validOnmuMapPoints(points);
        final safeRouteGeometry = validOnmuMapCoordinates(routeGeometry);
        final projection = _Projection(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          coordinates: [
            ...safePoints.map((point) => point.coordinate),
            ...safeRouteGeometry,
            center,
          ],
        );
        return Stack(
          children: [
            if (safeRouteGeometry.length >= 2)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RouteOverlayPainter(
                      offsets: safeRouteGeometry
                          .map(projection.offsetFor)
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
            for (final point in safePoints)
              _PositionedMapPin(
                point: point,
                offset: projection.offsetFor(point.coordinate),
                viewportSize: projection.size,
                focused: focusedPointId == point.id,
                onTap: onPointTap == null ? null : () => onPointTap!(point),
              ),
          ],
        );
      },
    );
  }
}

class _PositionedMapPin extends StatelessWidget {
  const _PositionedMapPin({
    required this.point,
    required this.offset,
    required this.viewportSize,
    required this.focused,
    required this.onTap,
  });

  final OnmuMapPoint point;
  final Offset offset;
  final Size viewportSize;
  final bool focused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = focused
        ? onmuMapFocusedMarkerFallbackSize
        : onmuMapMarkerFallbackSize;
    final left = (offset.dx - width / 2)
        .clamp(8.0, math.max(8.0, viewportSize.width - width - 8))
        .toDouble();
    final top = (offset.dy - width / 2)
        .clamp(8.0, math.max(8.0, viewportSize.height - width - 8))
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      child: Semantics(
        button: onTap != null,
        label: '장소 후보 ${point.order}',
        child: GestureDetector(
          key: focused ? ValueKey('focused-place-pin-${point.order}') : null,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: focused ? AppColors.primaryPurple : AppColors.primaryPink,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.bgDefault,
                width: focused ? 4 : 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox.square(
              dimension: width,
              child: Center(
                child: Text(
                  '${point.order}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Projection {
  _Projection({required this.size, required List<OnmuLatLng> coordinates}) {
    final validCoordinates = validOnmuMapCoordinates(coordinates);
    final safeCoordinates = validCoordinates.isEmpty
        ? const [OnmuLatLng(lat: 36.5, lng: 127.8)]
        : validCoordinates;
    minLat = safeCoordinates.map((value) => value.lat).reduce(math.min);
    maxLat = safeCoordinates.map((value) => value.lat).reduce(math.max);
    minLng = safeCoordinates.map((value) => value.lng).reduce(math.min);
    maxLng = safeCoordinates.map((value) => value.lng).reduce(math.max);
    if ((maxLat - minLat).abs() < 0.002) {
      minLat -= 0.002;
      maxLat += 0.002;
    }
    if ((maxLng - minLng).abs() < 0.002) {
      minLng -= 0.002;
      maxLng += 0.002;
    }
  }

  final Size size;
  late double minLat;
  late double maxLat;
  late double minLng;
  late double maxLng;

  Offset offsetFor(OnmuLatLng coordinate) {
    const preferredPadding = 42.0;
    final horizontalPadding = math.min(
      preferredPadding,
      math.max(0.0, size.width / 2 - 1),
    );
    final verticalPadding = math.min(
      preferredPadding,
      math.max(0.0, size.height / 2 - 1),
    );
    final width = math.max(1.0, size.width - horizontalPadding * 2);
    final height = math.max(1.0, size.height - verticalPadding * 2);
    final x =
        horizontalPadding +
        ((coordinate.lng - minLng) / (maxLng - minLng)) * width;
    final y =
        verticalPadding +
        ((maxLat - coordinate.lat) / (maxLat - minLat)) * height;
    return Offset(
      x.clamp(horizontalPadding, size.width - horizontalPadding).toDouble(),
      y.clamp(verticalPadding, size.height - verticalPadding).toDouble(),
    );
  }
}

class _RouteOverlayPainter extends CustomPainter {
  const _RouteOverlayPainter({required this.offsets});

  final List<Offset> offsets;

  @override
  void paint(Canvas canvas, Size size) {
    if (offsets.length < 2) {
      return;
    }
    final casingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 10;
    final routePaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 6;
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(path, casingPaint);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant _RouteOverlayPainter oldDelegate) {
    return oldDelegate.offsets != offsets;
  }
}

class _FallbackMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final parkPaint = Paint()
      ..color = AppColors.accentGreen.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final waterPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final boundaryPaint = Paint()
      ..color = AppColors.lineBrown.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final minorRoadPaint = Paint()
      ..color = AppColors.lineWarm.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;
    final majorRoadPaint = Paint()
      ..color = AppColors.primaryPink.withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.04, size.height * 0.22)
        ..lineTo(size.width * 0.28, size.height * 0.16)
        ..lineTo(size.width * 0.36, size.height * 0.34)
        ..lineTo(size.width * 0.18, size.height * 0.44)
        ..close(),
      parkPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.72, size.height * 0.08)
        ..lineTo(size.width * 0.98, size.height * 0.14)
        ..lineTo(size.width * 0.92, size.height * 0.34)
        ..lineTo(size.width * 0.66, size.height * 0.29)
        ..close(),
      parkPaint,
    );

    final river = Path()
      ..moveTo(size.width * 0.45, -20)
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.18,
        size.width * 0.38,
        size.height * 0.38,
        size.width * 0.54,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.72,
        size.width * 0.58,
        size.height * 0.86,
        size.width * 0.72,
        size.height + 24,
      )
      ..lineTo(size.width * 0.82, size.height + 24)
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.82,
        size.width * 0.76,
        size.height * 0.68,
        size.width * 0.6,
        size.height * 0.5,
      )
      ..cubicTo(
        size.width * 0.47,
        size.height * 0.35,
        size.width * 0.68,
        size.height * 0.16,
        size.width * 0.54,
        -20,
      )
      ..close();
    canvas.drawPath(river, waterPaint);

    for (var y = 24.0; y < size.height; y += 54) {
      final path = Path()
        ..moveTo(-20, y)
        ..cubicTo(
          size.width * 0.3,
          y - 28,
          size.width * 0.62,
          y + 28,
          size.width + 20,
          y - 8,
        );
      canvas.drawPath(path, minorRoadPaint);
    }
    for (var x = 24.0; x < size.width; x += 68) {
      final path = Path()
        ..moveTo(x, -20)
        ..cubicTo(
          x - 24,
          size.height * 0.28,
          x + 28,
          size.height * 0.62,
          x + 8,
          size.height + 20,
        );
      canvas.drawPath(path, minorRoadPaint);
    }

    canvas.drawPath(
      Path()
        ..moveTo(-20, size.height * 0.68)
        ..lineTo(size.width * 0.32, size.height * 0.5)
        ..lineTo(size.width * 0.76, size.height * 0.58)
        ..lineTo(size.width + 20, size.height * 0.44),
      majorRoadPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.18, -20)
        ..lineTo(size.width * 0.36, size.height * 0.32)
        ..lineTo(size.width * 0.3, size.height + 20),
      majorRoadPaint,
    );

    for (var x = size.width * 0.18; x < size.width; x += size.width * 0.28) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.width * 0.1, size.height),
        boundaryPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
