import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/map_models.dart';
import '../repository/tile_manifest_repository.dart';

class OnmuMapView extends ConsumerWidget {
  const OnmuMapView({
    required this.points,
    this.routeGeometry = const [],
    this.center,
    this.zoom = 11,
    this.focusedPointId,
    this.onPointTap,
    this.fallbackLabel = '지도 스타일을 불러오는 중입니다.',
    super.key,
  });

  final List<OnmuMapPoint> points;
  final List<OnmuLatLng> routeGeometry;
  final OnmuLatLng? center;
  final double zoom;
  final String? focusedPointId;
  final ValueChanged<OnmuMapPoint>? onPointTap;
  final String fallbackLabel;

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
    final useMapLibre = _canUseMapLibre && styleUrl.isNotEmpty;

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
                : _FallbackMapBackground(label: fallbackLabel),
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
        child: Align(
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
    required this.focused,
    required this.onTap,
  });

  final OnmuMapPoint point;
  final Offset offset;
  final bool focused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx - 22,
      top: offset.dy - 42,
      child: GestureDetector(
        key: focused ? ValueKey('focused-place-pin-${point.order}') : null,
        onTap: onTap,
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
    final roadPaint = Paint()
      ..color = AppColors.lineSoft
      ..strokeWidth = 1.4;
    for (var y = 36.0; y < size.height; y += 52) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 24), roadPaint);
    }
    for (var x = 30.0; x < size.width; x += 66) {
      canvas.drawLine(Offset(x, 0), Offset(x + 34, size.height), roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
