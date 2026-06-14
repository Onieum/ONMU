import 'dart:math' as math;

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

class OnmuMapView extends ConsumerWidget {
  const OnmuMapView({
    required this.points,
    this.routeGeometry = const [],
    this.center,
    this.zoom = 11,
    this.focusedPointId,
    this.onPointTap,
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
  final String fallbackLabel;
  final bool? debugWebPmtilesProtocolReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifestState = ref.watch(tileManifestProvider);
    final manifest = manifestState.asData?.value;
    final mapCenter =
        center ??
        _centerFromData() ??
        manifest?.center ??
        const OnmuLatLng(lat: 36.5, lng: 127.8);
    final styleUrl = manifest?.styleUrl ?? '';
    final webBootstrapReady =
        debugWebPmtilesProtocolReady ?? isOnmuMapWebBootstrapReady;
    final useMapLibre = shouldUseOnmuMapLibre(
      manifest: manifest,
      platformViewAvailable: _canUseMapLibre,
      pmtilesProtocolReady: webBootstrapReady,
    );
    final effectiveFallbackLabel = styleUrl.isNotEmpty && !webBootstrapReady
        ? '지도 스크립트를 준비하는 중입니다.'
        : fallbackLabel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        children: [
          Positioned.fill(
            child: useMapLibre
                ? MapLibreMap(
                    styleString: styleUrl,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(mapCenter.lat, mapCenter.lng),
                      zoom: zoom,
                    ),
                    compassEnabled: false,
                    logoEnabled: false,
                    attributionButtonPosition:
                        AttributionButtonPosition.bottomLeft,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    myLocationEnabled: false,
                  )
                : _FallbackMapBackground(label: effectiveFallbackLabel),
          ),
          Positioned.fill(
            child: _ProjectedMapOverlay(
              points: points,
              routeGeometry: routeGeometry,
              focusedPointId: focusedPointId,
              onPointTap: onPointTap,
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

  OnmuLatLng? _centerFromData() {
    final values = [
      ...points.map((point) => point.coordinate),
      ...routeGeometry,
    ];
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
        final projection = _Projection(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          coordinates: [
            ...points.map((point) => point.coordinate),
            ...routeGeometry,
            center,
          ],
        );
        return Stack(
          children: [
            if (routeGeometry.length >= 2)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RouteOverlayPainter(
                      offsets: routeGeometry
                          .map(projection.offsetFor)
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
            for (final point in points)
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
    final width = math.min(168.0, math.max(88.0, viewportSize.width - 16));
    final left = (offset.dx - width / 2)
        .clamp(8.0, math.max(8.0, viewportSize.width - width - 8))
        .toDouble();
    final top = (offset.dy - 42)
        .clamp(8.0, math.max(8.0, viewportSize.height - 72))
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        key: focused ? ValueKey('focused-place-pin-${point.order}') : null,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: focused
                      ? AppColors.primaryPurple
                      : AppColors.primaryPink,
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
                  dimension: focused ? 42 : 34,
                  child: Center(
                    child: Text(
                      '${point.order}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textInverse,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.lineSoft),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    text: TextSpan(
                      text: point.label,
                      style: DefaultTextStyle.of(
                        context,
                      ).style.merge(Theme.of(context).textTheme.labelSmall),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Projection {
  _Projection({required this.size, required List<OnmuLatLng> coordinates}) {
    final safeCoordinates = coordinates.isEmpty
        ? const [OnmuLatLng(lat: 36.5, lng: 127.8)]
        : coordinates;
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
    const padding = 42.0;
    final width = math.max(1.0, size.width - padding * 2);
    final height = math.max(1.0, size.height - padding * 2);
    final x = padding + ((coordinate.lng - minLng) / (maxLng - minLng)) * width;
    final y =
        padding + ((maxLat - coordinate.lat) / (maxLat - minLat)) * height;
    return Offset(
      x.clamp(padding, size.width - padding).toDouble(),
      y.clamp(padding, size.height - padding).toDouble(),
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
    final paint = Paint()
      ..color = AppColors.primaryPink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4;
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(path, paint);
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
