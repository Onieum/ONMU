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
const double onmuMapMinUsableZoom = 6.2;

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
  final size = focused ? 56.0 : 46.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(size / 2, size / 2);
  final radius = focused ? 22.0 : 18.0;

  final shadowPaint = Paint()
    ..color = const Color(0x33000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  canvas.drawCircle(center.translate(0, 2), radius + 1, shadowPaint);

  final fillPaint = Paint()
    ..color = focused ? const Color(0xFFE86D75) : const Color(0xFFFF8FA3);
  canvas.drawCircle(center, radius, fillPaint);

  final strokePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = focused ? 5 : 4;
  canvas.drawCircle(center, radius, strokePaint);

  final textPainter = TextPainter(
    text: TextSpan(
      text: '$order',
      style: TextStyle(
        color: Colors.white,
        fontSize: focused ? 24 : 20,
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
    zIndex: focused ? 20 : 10,
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
    lineColor: '#1D4ED8',
    lineWidth: 6.5,
    lineOpacity: 0.94,
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
    lineWidth: 10.5,
    lineOpacity: 0.92,
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
  return pointsChanged ||
      routeGeometryChanged ||
      centerChanged ||
      zoomChanged ||
      styleLoaded;
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
  required OnmuLatLng? center,
  required double zoom,
}) {
  final coordinates = [
    ...validOnmuMapPoints(points).map((point) => point.coordinate),
    ...validOnmuMapCoordinates(routeGeometry),
    if (center != null && isValidOnmuLatLng(center)) center,
  ];
  final coordinateKey = coordinates
      .map(
        (coordinate) =>
            '${coordinate.lat.toStringAsFixed(6)},'
            '${coordinate.lng.toStringAsFixed(6)}',
      )
      .join('|');
  return '${zoom.toStringAsFixed(2)}:$coordinateKey';
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
    this.routeGeometry = const [],
    this.center,
    this.zoom = 11,
    this.focusedPointId,
    this.onPointTap,
    this.onCameraIdle,
    this.onMyLocationResolved,
    this.onMyLocationUnavailable,
    this.myLocationEnabled = false,
    this.myLocationRequestSerial = 0,
    this.fallbackLabel = '지도 스타일을 불러오는 중입니다.',
    this.debugWebPmtilesProtocolReady,
    super.key,
  });

  final List<OnmuMapPoint> points;
  final List<OnmuLatLng> routeGeometry;
  final OnmuLatLng? center;
  final double zoom;
  final String? focusedPointId;
  final ValueChanged<OnmuMapPoint>? onPointTap;
  final ValueChanged<OnmuLatLng>? onCameraIdle;
  final ValueChanged<OnmuLatLng>? onMyLocationResolved;
  final VoidCallback? onMyLocationUnavailable;
  final bool myLocationEnabled;
  final int myLocationRequestSerial;
  final String fallbackLabel;
  final bool? debugWebPmtilesProtocolReady;

  @override
  ConsumerState<OnmuMapView> createState() => _OnmuMapViewState();
}

class _OnmuMapViewState extends ConsumerState<OnmuMapView> {
  MapLibreMapController? _mapController;
  bool _styleLoaded = false;
  bool _myLocationLayerEnabled = false;
  int _handledMyLocationRequestSerial = 0;
  int _nativeSyncGeneration = 0;
  final Set<String> _registeredNativeMarkerImages = {};

  @override
  void didUpdateWidget(covariant OnmuMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCameraSeedKey = onmuMapCameraSeedKey(
      points: oldWidget.points,
      routeGeometry: oldWidget.routeGeometry,
      center: oldWidget.center,
      zoom: onmuMapInitialZoomForCoordinates(
        coordinates: [
          ...validOnmuMapPoints(oldWidget.points).map(
            (point) => point.coordinate,
          ),
          ...validOnmuMapCoordinates(oldWidget.routeGeometry),
        ],
        fallbackZoom: oldWidget.zoom,
      ),
    );
    final nextCameraSeedKey = onmuMapCameraSeedKey(
      points: widget.points,
      routeGeometry: widget.routeGeometry,
      center: widget.center,
      zoom: onmuMapInitialZoomForCoordinates(
        coordinates: [
          ...validOnmuMapPoints(widget.points).map(
            (point) => point.coordinate,
          ),
          ...validOnmuMapCoordinates(widget.routeGeometry),
        ],
        fallbackZoom: widget.zoom,
      ),
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
    final centerChanged = !haveSameOptionalCameraTarget(
      oldWidget.center,
      widget.center,
    );
    final zoomChanged = oldWidget.zoom != widget.zoom;
    final focusChanged = oldWidget.focusedPointId != widget.focusedPointId;
    if (pointsChanged ||
        routeGeometryChanged ||
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
      center: widget.center,
      zoom: initialZoom,
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

  void _handleSymbolTapped(Symbol symbol) {
    _handleNativePointTap(symbol.data?[mapNativePointDataKey]);
  }

  void _handleCameraIdle() {
    _emitCurrentCameraTarget();
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
    } catch (_) {
      // 지도 annotation 동기화 실패는 플랫폼 뷰 수명주기 경쟁일 수 있어 UI를 유지한다.
    }
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
    final width = focused ? 46.0 : 38.0;
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
