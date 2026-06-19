import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/navigation_extensions.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/map/model/map_models.dart';
import '../../../../features/map/view_model/map_catalog_view_model.dart';
import '../../../../features/map/widgets/onmu_map_view.dart';
import '../../../../shared/models/place_models.dart';
import '../../../../shared/widgets/onmu_card.dart';
import '../../../../shared/widgets/onmu_chip.dart';
import '../../view_model/place_candidates_view_model.dart';
import '../widgets/place_candidate_card.dart';
import '../widgets/plan_visit_time_picker.dart';

enum _MyLocationRequestState {
  idle,
  requesting,
  resolved,
  denied,
  serviceDisabled,
  timeout,
  unavailable,
}

List<PlaceCandidate> activePlaceResultsForMap(List<PlaceCandidate> candidates) {
  return candidates.take(20).toList(growable: false);
}

List<OnmuMapPoint> mapPointsForPlaceCandidates(
  List<PlaceCandidate> candidates,
) {
  const fallback = [
    OnmuLatLng(lat: 37.5665, lng: 126.9780),
    OnmuLatLng(lat: 37.5651, lng: 126.9895),
    OnmuLatLng(lat: 37.5326, lng: 126.9904),
    OnmuLatLng(lat: 37.5700, lng: 126.9820),
    OnmuLatLng(lat: 37.5580, lng: 126.9970),
  ];
  final hasAnyCoordinate = candidates.any(
    (candidate) => candidate.hasCoordinate,
  );
  return [
    for (var index = 0; index < candidates.length; index += 1)
      if (!hasAnyCoordinate || candidates[index].hasCoordinate)
        OnmuMapPoint(
          id: candidates[index].id.toString(),
          label: candidates[index].name,
          coordinate: candidates[index].hasCoordinate
              ? OnmuLatLng(
                  lat: candidates[index].latitude!,
                  lng: candidates[index].longitude!,
                )
              : fallback[index % fallback.length],
          order: index + 1,
        ),
  ];
}

class PlaceMapPage extends ConsumerStatefulWidget {
  const PlaceMapPage({
    required this.groupId,
    required this.planId,
    super.key,
    this.initialQuery = '',
  });

  final String groupId;
  final String planId;
  final String initialQuery;

  @override
  ConsumerState<PlaceMapPage> createState() => _PlaceMapPageState();
}

class _PlaceMapPageState extends ConsumerState<PlaceMapPage> {
  static const _foodCategory = '음식점';
  static const _cafeCategory = '카페';
  static const _attractionCategory = '가볼만한곳';
  static const _primaryCategories = [
    _foodCategory,
    _cafeCategory,
    _attractionCategory,
  ];
  static const _foodFilters = ['한식', '양식', '중식', '일식', '아시안식'];
  static const _cafeFilters = ['디저트', '베이커리', '브런치', '커피'];
  static const _attractionFilters = [
    '공원',
    '해수욕장',
    '박물관',
    '미술관',
    '전시',
    '전망대',
    '산책로',
  ];
  static const _mapSearchRadiusMeters = 1500;
  static const _cameraChangeThreshold = 0.0007;

  bool _searchActive = false;
  String _query = '';
  String _selectedPrimaryCategory = _foodCategory;
  String? _selectedCategoryFilter;
  PlaceCandidate? _selectedCandidate;
  int? _focusedCandidateId;
  OnmuLatLng? _lastCameraCenter;
  OnmuLatLng? _mapSearchAnchorCenter;
  OnmuLatLng? _mapSearchCenter;
  OnmuMapViewport? _catalogViewport;
  Timer? _catalogViewportDebounce;
  bool _filtersExpanded = false;
  final DraggableScrollableController _recommendationSheetController =
      DraggableScrollableController();
  _MyLocationRequestState _myLocationState = _MyLocationRequestState.idle;
  int _myLocationRequestSerial = 0;
  int? _pendingMyLocationSerial;
  double _recommendationSheetSize = _RecommendationSheet.initialSheetSize;
  final Set<int> _savingCandidateIds = {};
  final Map<int, GlobalKey> _candidateTileKeys = {};

  @override
  void initState() {
    super.initState();
    _catalogViewport = _initialCatalogViewport(
      const OnmuLatLng(lat: 37.5665, lng: 126.9780),
      11,
    );
    final initialQuery = widget.initialQuery.trim();
    if (initialQuery.isNotEmpty) {
      _query = initialQuery;
      _searchActive = true;
    }
  }

  @override
  void dispose() {
    _catalogViewportDebounce?.cancel();
    _recommendationSheetController.dispose();
    super.dispose();
  }

  List<PlaceCandidate> _visibleCandidates(List<PlaceCandidate> candidates) {
    final normalizedQuery = _query.trim().toLowerCase();

    final results = candidates.where((candidate) {
      final matchesCategory = _matchesSelectedCategory(candidate);
      final searchableText = [
        candidate.name,
        candidate.category,
        candidate.summary,
        ...candidate.tags,
      ].join(' ').toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);

      return matchesCategory && matchesQuery;
    }).toList();

    return results;
  }

  List<PlaceCandidate> _mergeCandidates(
    List<PlaceCandidate> savedCandidates,
    List<PlaceCandidate> searchedCandidates,
  ) {
    final merged = <PlaceCandidate>[];
    final seen = <String>{};

    void addCandidate(PlaceCandidate candidate) {
      final identities = _candidateIdentities(candidate);
      if (identities.any(seen.contains)) {
        return;
      }
      seen.addAll(identities);
      merged.add(candidate);
    }

    for (final candidate in searchedCandidates) {
      addCandidate(candidate);
    }
    for (final candidate in savedCandidates) {
      addCandidate(candidate);
    }

    return merged;
  }

  Set<String> _candidateIdentities(PlaceCandidate candidate) {
    final identities = <String>{};
    final providerPlaceId = candidate.providerPlaceId.trim();
    if (providerPlaceId.isNotEmpty) {
      identities.add('provider:${candidate.provider}:$providerPlaceId');
    }
    final normalizedName = candidate.name.trim().toLowerCase();
    final normalizedAddress = candidate.address.trim().toLowerCase();
    if (normalizedName.isNotEmpty) {
      identities.add('name:$normalizedName');
      identities.add('place:$normalizedName:$normalizedAddress');
    }
    return identities.isEmpty ? {'id:${candidate.id}'} : identities;
  }

  String _defaultSearchQuery(PlaceCandidatesState state) {
    final location = _normalizedPlanLocation(state.planLocation);
    final categoryKeyword = _selectedSearchKeyword;
    return [
      location,
      categoryKeyword,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
  }

  String _normalizedPlanLocation(String value) {
    var normalized = value.trim();
    for (final token in const ['일대', '주변', '근처', '장소 미정', '미정']) {
      normalized = normalized.replaceAll(token, '').trim();
    }
    return normalized;
  }

  void _activateSearch() {
    if (_searchActive) {
      return;
    }

    setState(() {
      _searchActive = true;
    });
  }

  void _handleCameraIdle(OnmuLatLng center) {
    final previous = _lastCameraCenter;
    if (previous == null) {
      setState(() {
        _lastCameraCenter = center;
        _mapSearchAnchorCenter ??= center;
      });
      return;
    }
    if (_mapSearchAnchorCenter == null) {
      setState(() {
        _lastCameraCenter = center;
        _mapSearchAnchorCenter = center;
      });
      return;
    }
    if (!_isMeaningfullyDifferent(previous, center)) {
      return;
    }
    setState(() {
      _lastCameraCenter = center;
    });
  }

  void _handleViewportIdle(OnmuMapViewport viewport) {
    if (!viewport.isValid) {
      return;
    }
    if (_sameCatalogViewport(_catalogViewport, viewport)) {
      return;
    }
    _catalogViewportDebounce?.cancel();
    _catalogViewportDebounce = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) {
        return;
      }
      if (_sameCatalogViewport(_catalogViewport, viewport)) {
        return;
      }
      setState(() {
        _catalogViewport = viewport;
      });
    });
  }

  bool _sameCatalogViewport(OnmuMapViewport? previous, OnmuMapViewport next) {
    if (!next.isValid) {
      return true;
    }
    if (previous == null ||
        !previous.isValid ||
        previous.apiZoom != next.apiZoom) {
      return false;
    }
    const threshold = 0.0005;
    return (previous.bounds.south - next.bounds.south).abs() < threshold &&
        (previous.bounds.west - next.bounds.west).abs() < threshold &&
        (previous.bounds.north - next.bounds.north).abs() < threshold &&
        (previous.bounds.east - next.bounds.east).abs() < threshold;
  }

  OnmuMapViewport _initialCatalogViewport(OnmuLatLng center, double zoom) {
    final safeZoom = onmuMapSafeZoom(zoom);
    final zoomLevel = onmuMapApiZoom(safeZoom);
    final span = 18 / (1 << zoomLevel);
    final latSpan = span.clamp(0.002, 1.5);
    final lngSpan = (span * 1.2).clamp(0.002, 1.8);
    return OnmuMapViewport(
      bounds: OnmuMapBounds(
        south: (center.lat - latSpan).clamp(-90.0, 90.0).toDouble(),
        west: (center.lng - lngSpan).clamp(-180.0, 180.0).toDouble(),
        north: (center.lat + latSpan).clamp(-90.0, 90.0).toDouble(),
        east: (center.lng + lngSpan).clamp(-180.0, 180.0).toDouble(),
      ),
      zoom: safeZoom,
    );
  }

  void _searchVisibleMapArea() {
    final center = _lastCameraCenter;
    if (center == null) {
      return;
    }
    setState(() {
      _mapSearchCenter = center;
      _mapSearchAnchorCenter = center;
      _searchActive = true;
      _selectedCandidate = null;
      _focusedCandidateId = null;
    });
  }

  Future<void> _requestCurrentLocation() async {
    if (_myLocationState == _MyLocationRequestState.requesting) {
      return;
    }

    setState(() {
      _myLocationState = _MyLocationRequestState.requesting;
    });

    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.locationWhenInUse.request();
    }
    if (!mounted) {
      return;
    }

    if (!status.isGranted && !status.isLimited) {
      setState(() {
        _myLocationState = _MyLocationRequestState.denied;
      });
      _showMapSnackBar(
        status.isPermanentlyDenied
            ? '설정에서 위치 권한을 허용하면 현재 위치 기준으로 검색할 수 있어요.'
            : '위치 권한이 필요해요. 권한을 허용한 뒤 다시 눌러 주세요.',
        action: status.isPermanentlyDenied
            ? SnackBarAction(label: '설정 열기', onPressed: openAppSettings)
            : null,
      );
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) {
      return;
    }
    if (!serviceEnabled) {
      setState(() {
        _myLocationState = _MyLocationRequestState.serviceDisabled;
        _pendingMyLocationSerial = null;
      });
      _showMapSnackBar('기기 위치 서비스가 꺼져 있어요. 위치 서비스를 켠 뒤 다시 눌러 주세요.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) {
        return;
      }
      final center = OnmuLatLng(
        lat: position.latitude,
        lng: position.longitude,
      );
      _handleMyLocationResolved(center);
      setState(() {
        _myLocationRequestSerial += 1;
        _pendingMyLocationSerial = null;
      });
      return;
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() {
        _myLocationState = _MyLocationRequestState.timeout;
        _pendingMyLocationSerial = null;
      });
      _showMapSnackBar('현재 위치 확인 시간이 초과됐어요. 기기 위치를 확인하고 다시 시도해 주세요.');
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _myLocationState = _MyLocationRequestState.unavailable;
      });
      _showMapSnackBar('현재 위치를 가져오지 못했어요. 기기 위치 설정을 확인해 주세요.');
    }

    final serial = _myLocationRequestSerial + 1;
    setState(() {
      _myLocationRequestSerial = serial;
      _pendingMyLocationSerial = serial;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted ||
          _pendingMyLocationSerial != serial ||
          _myLocationState != _MyLocationRequestState.requesting) {
        return;
      }
      setState(() {
        _myLocationState = _MyLocationRequestState.unavailable;
      });
      _showMapSnackBar('현재 위치를 아직 확인하지 못했어요. 지도 이동 후 현 지도에서 검색을 눌러 주세요.');
    });
  }

  void _handleMyLocationResolved(OnmuLatLng center) {
    setState(() {
      _lastCameraCenter = center;
      _mapSearchCenter = center;
      _mapSearchAnchorCenter = center;
      _searchActive = true;
      _selectedCandidate = null;
      _focusedCandidateId = null;
      _myLocationState = _MyLocationRequestState.resolved;
      _pendingMyLocationSerial = null;
    });
    _showMapSnackBar('현재 위치 주변으로 장소를 다시 찾고 있어요.');
  }

  void _handleMyLocationUnavailable() {
    if (_myLocationState != _MyLocationRequestState.requesting) {
      return;
    }
    setState(() {
      _myLocationState = _MyLocationRequestState.unavailable;
      _pendingMyLocationSerial = null;
    });
    _showMapSnackBar('현재 위치를 가져오지 못했어요. 에뮬레이터 위치나 기기 위치 설정을 확인해 주세요.');
  }

  bool _isMeaningfullyDifferent(OnmuLatLng previous, OnmuLatLng next) {
    return (previous.lat - next.lat).abs() > _cameraChangeThreshold ||
        (previous.lng - next.lng).abs() > _cameraChangeThreshold;
  }

  List<String> get _activeCategoryFilters {
    return switch (_selectedPrimaryCategory) {
      _foodCategory => _foodFilters,
      _cafeCategory => _cafeFilters,
      _attractionCategory => _attractionFilters,
      _ => const [],
    };
  }

  String get _selectedSearchCategory =>
      _selectedCategoryFilter ?? _selectedPrimaryCategory;

  String get _selectedSearchKeyword {
    final selectedFilter = _selectedCategoryFilter;
    if (selectedFilter != null) {
      return selectedFilter;
    }
    return switch (_selectedPrimaryCategory) {
      _foodCategory => '맛집',
      _cafeCategory => '카페',
      _attractionCategory => '가볼만한곳',
      _ => _selectedPrimaryCategory,
    };
  }

  String get _myLocationTooltip {
    return switch (_myLocationState) {
      _MyLocationRequestState.requesting => '현재 위치 확인 중',
      _MyLocationRequestState.resolved => '현재 위치 기준으로 다시 이동',
      _MyLocationRequestState.denied => '위치 권한 다시 요청',
      _MyLocationRequestState.serviceDisabled => '위치 서비스 확인',
      _MyLocationRequestState.timeout => '현재 위치 다시 확인',
      _MyLocationRequestState.unavailable => '현재 위치 다시 확인',
      _ => '현재 위치로 이동',
    };
  }

  IconData get _myLocationIcon {
    return switch (_myLocationState) {
      _MyLocationRequestState.resolved => Icons.near_me,
      _MyLocationRequestState.denied => Icons.location_disabled_outlined,
      _MyLocationRequestState.serviceDisabled => Icons.location_off_outlined,
      _MyLocationRequestState.timeout => Icons.location_searching,
      _MyLocationRequestState.unavailable => Icons.location_searching,
      _ => Icons.my_location,
    };
  }

  String? get _myLocationStatusLabel {
    return switch (_myLocationState) {
      _MyLocationRequestState.requesting => '위치 확인 중',
      _MyLocationRequestState.denied => '위치 권한 필요',
      _MyLocationRequestState.serviceDisabled => '위치 서비스 꺼짐',
      _MyLocationRequestState.timeout => '위치 확인 시간 초과',
      _MyLocationRequestState.unavailable => '위치 확인 실패',
      _ => null,
    };
  }

  bool _matchesSelectedCategory(PlaceCandidate candidate) {
    final selectedFilter = _selectedCategoryFilter;
    if (selectedFilter != null) {
      return _matchesAnyCategoryToken(
        candidate,
        _tokensForFilter(selectedFilter),
      );
    }
    return switch (_selectedPrimaryCategory) {
      _foodCategory => _matchesAnyCategoryToken(candidate, const [
        '음식점',
        '식당',
        '맛집',
        '한식',
        '양식',
        '중식',
        '일식',
        '아시안',
        '분식',
        '고기',
        '국밥',
        '레스토랑',
      ]),
      _cafeCategory => _matchesAnyCategoryToken(candidate, const [
        '카페',
        '커피',
        '디저트',
        '베이커리',
        '브런치',
      ]),
      _attractionCategory => _matchesAnyCategoryToken(candidate, const [
        '가볼만한곳',
        '관광',
        '명소',
        '공원',
        '해수욕장',
        '박물관',
        '미술관',
        '전시',
        '전망대',
        '산책로',
        '문화',
        '테마파크',
        '놀이공원',
      ]),
      _ => true,
    };
  }

  List<String> _tokensForFilter(String filter) {
    return switch (filter) {
      '아시안식' => const ['아시안', '태국', '베트남', '인도', '동남아'],
      '브런치' => const ['브런치', '카페'],
      '커피' => const ['커피', '카페'],
      '전시' => const ['전시', '갤러리', '문화'],
      '산책로' => const ['산책로', '둘레길', '거리', '공원'],
      _ => [filter],
    };
  }

  bool _matchesAnyCategoryToken(PlaceCandidate candidate, List<String> tokens) {
    final haystack = [
      candidate.category,
      candidate.name,
      candidate.summary,
      ...candidate.tags,
    ].join(' ').toLowerCase();
    return tokens.any((token) => haystack.contains(token.toLowerCase()));
  }

  void _showMapSnackBar(String message, {SnackBarAction? action}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      placeCandidatesViewModelProvider((
        groupId: widget.groupId,
        planId: widget.planId,
      )),
    );

    return state.when(
      data: (state) => _buildContent(context, state),
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgGrid,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppColors.bgGrid,
        body: SafeArea(
          child: Center(
            child: Text(
              '장소 후보를 불러오지 못했어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PlaceCandidatesState state) {
    final screenSize = MediaQuery.sizeOf(context);
    final localVisibleCandidates = _visibleCandidates(state.candidates);
    final autoSearch = _query.trim().isEmpty;
    final effectiveQuery = autoSearch ? _defaultSearchQuery(state) : _query;
    final searchActive =
        _searchActive || autoSearch || _selectedSearchCategory.isNotEmpty;
    final mapSearchCenter = _mapSearchCenter;
    final activeCategoryFilters = _activeCategoryFilters;
    final remoteSearchState = effectiveQuery.trim().isEmpty
        ? null
        : ref.watch(
            placeSearchResultsProvider((
              groupId: widget.groupId,
              planId: widget.planId,
              query: effectiveQuery,
              category: _selectedSearchCategory,
              lat: mapSearchCenter?.lat,
              lng: mapSearchCenter?.lng,
              radius: mapSearchCenter == null ? null : _mapSearchRadiusMeters,
            )),
          );
    final visibleCandidates =
        remoteSearchState?.maybeWhen(
          data: (results) => results.isEmpty
              ? localVisibleCandidates
              : _mergeCandidates(localVisibleCandidates, results),
          orElse: () => localVisibleCandidates,
        ) ??
        localVisibleCandidates;
    final searchLoading = remoteSearchState?.isLoading ?? false;
    final searchHadError = remoteSearchState?.hasError ?? false;
    final mapCenter = _mapSearchCenter ?? _lastCameraCenter;
    final mapZoom = mapSearchCenter == null ? 11.0 : 14.8;
    final catalogViewport =
        _catalogViewport ??
        _initialCatalogViewport(
          mapCenter ?? const OnmuLatLng(lat: 37.5665, lng: 126.9780),
          mapZoom,
        );
    final catalogState = ref.watch(
      mapCatalogProvider((
        groupId: widget.groupId,
        planId: widget.planId,
        viewport: catalogViewport,
        category: _selectedSearchCategory,
        filter: _selectedCategoryFilter ?? 'all',
        query: _query.trim().isEmpty ? null : _query.trim(),
      )),
    );
    final catalogData = catalogState.maybeWhen(
      data: (data) => data,
      orElse: () => OnmuCatalogMapData.empty(catalogViewport),
    );
    final activeResultCandidates = activePlaceResultsForMap(visibleCandidates);
    final mapAreaSearchEnabled =
        _lastCameraCenter != null &&
        _mapSearchAnchorCenter != null &&
        _isMeaningfullyDifferent(_mapSearchAnchorCenter!, _lastCameraCenter!);
    final sheetBottomPadding =
        (screenSize.height * _recommendationSheetSize + 80).clamp(220.0, 680.0);
    final mapCameraFitPadding = EdgeInsets.fromLTRB(
      56,
      188,
      56,
      sheetBottomPadding,
    );
    final markerSafetyPadding = EdgeInsets.fromLTRB(
      0,
      188,
      0,
      (screenSize.height * _recommendationSheetSize).clamp(160.0, 560.0),
    );

    return Scaffold(
      backgroundColor: AppColors.bgGrid,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: OnmuMapView(
                  points: mapPointsForPlaceCandidates(activeResultCandidates),
                  catalogClusters: catalogData.clusters,
                  catalogPoints: catalogData.points,
                  fallbackLabel: _mapFallbackLabel(
                    activeResultCandidates,
                    searchLoading: searchLoading,
                    searchHadError: searchHadError,
                  ),
                  center: mapCenter,
                  zoom: mapZoom,
                  cameraFitPadding: mapCameraFitPadding,
                  markerScreenSafetyPadding: markerSafetyPadding,
                  focusedPointId:
                      (_selectedCandidate?.id ?? _focusedCandidateId)
                          ?.toString(),
                  onCameraIdle: _handleCameraIdle,
                  onViewportIdle: _handleViewportIdle,
                  onMyLocationResolved: _handleMyLocationResolved,
                  onMyLocationUnavailable: _handleMyLocationUnavailable,
                  myLocationRequestSerial: _myLocationRequestSerial,
                  onPointTap: (point) {
                    _focusActiveResultFromMap(activeResultCandidates, point.id);
                  },
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: 0,
              child: _MapSearchOverlay(
                query: _query,
                primaryCategories: _primaryCategories,
                activeCategoryFilters: activeCategoryFilters,
                selectedPrimaryCategory: _selectedPrimaryCategory,
                selectedCategoryFilter: _selectedCategoryFilter,
                filtersExpanded: _filtersExpanded,
                myLocationState: _myLocationState,
                myLocationTooltip: _myLocationTooltip,
                myLocationIcon: _myLocationIcon,
                myLocationStatusLabel: _myLocationStatusLabel,
                mapAreaSearchEnabled: mapAreaSearchEnabled,
                mapAreaSearchActive: _mapSearchCenter != null,
                onBack: () => context.popOrGo(
                  RoutePaths.planDetail(widget.groupId, widget.planId),
                ),
                onSearchTap: _activateSearch,
                onSearchChanged: (value) {
                  setState(() {
                    _query = value;
                    _searchActive = true;
                    _mapSearchCenter = null;
                    _mapSearchAnchorCenter = _lastCameraCenter;
                    _selectedCandidate = null;
                    _focusedCandidateId = null;
                  });
                },
                onPrimaryCategorySelected: (category) {
                  setState(() {
                    _selectedPrimaryCategory = category;
                    _selectedCategoryFilter = null;
                    _filtersExpanded = false;
                    _mapSearchCenter = null;
                    _mapSearchAnchorCenter = _lastCameraCenter;
                    _searchActive = true;
                    _selectedCandidate = null;
                    _focusedCandidateId = null;
                  });
                },
                onCategoryFilterSelected: (category) {
                  setState(() {
                    _selectedCategoryFilter =
                        _selectedCategoryFilter == category ? null : category;
                    _mapSearchCenter = null;
                    _mapSearchAnchorCenter = _lastCameraCenter;
                    _searchActive = true;
                    _selectedCandidate = null;
                    _focusedCandidateId = null;
                  });
                },
                onFiltersToggle: () {
                  setState(() {
                    _filtersExpanded = !_filtersExpanded;
                  });
                },
                onMapAreaSearchPressed: _searchVisibleMapArea,
                onCurrentLocationPressed:
                    _myLocationState == _MyLocationRequestState.requesting
                    ? null
                    : _requestCurrentLocation,
              ),
            ),
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if ((_recommendationSheetSize - notification.extent).abs() >
                    0.015) {
                  setState(() {
                    _recommendationSheetSize = notification.extent;
                  });
                }
                return false;
              },
              child: DraggableScrollableSheet(
                key: const ValueKey('place-map-bottom-sheet'),
                controller: _recommendationSheetController,
                minChildSize: _RecommendationSheet.minSheetSize,
                initialChildSize: _RecommendationSheet.initialSheetSize,
                maxChildSize: _RecommendationSheet.maxSheetSize,
                snap: true,
                snapSizes: const [
                  _RecommendationSheet.minSheetSize,
                  _RecommendationSheet.initialSheetSize,
                  _RecommendationSheet.maxSheetSize,
                ],
                builder: (context, scrollController) {
                  return _RecommendationSheet(
                    controller: scrollController,
                    candidates: activeResultCandidates,
                    searchActive: searchActive,
                    autoSearch: autoSearch,
                    query: effectiveQuery,
                    selectedCategory: _selectedSearchCategory,
                    searchLoading: searchLoading,
                    searchHadError: searchHadError,
                    mapScopedSearch: _mapSearchCenter != null,
                    searchRadiusMeters: _mapSearchRadiusMeters,
                    selectedCandidate: _selectedCandidate,
                    isAlreadyCandidate: state.hasCandidate,
                    isSavingCandidate: (candidate) =>
                        _savingCandidateIds.contains(candidate.id),
                    onBackToResults: () {
                      setState(() {
                        _selectedCandidate = null;
                      });
                      _openRecommendationSheet(
                        _RecommendationSheet.initialSheetSize,
                      );
                    },
                    onCandidateSelected: (candidate) {
                      setState(() {
                        _selectedCandidate = candidate;
                        _focusedCandidateId = candidate.id;
                      });
                      _openRecommendationSheet(
                        _RecommendationSheet.maxSheetSize,
                      );
                    },
                    onRegisterPressed: (candidate) =>
                        _saveSchedulePlaceAndNavigate(
                          candidate,
                          context,
                          state,
                        ),
                    onAddCandidatePressed: (candidate) =>
                        _saveCandidateAndNavigate(
                          candidate,
                          context,
                          message: '후보에 추가되었어요!',
                          targetPath: RoutePaths.planPlaceCandidates(
                            widget.groupId,
                            widget.planId,
                          ),
                        ),
                    tileKeyFor: _tileKeyFor,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecommendationSheet(double size) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_recommendationSheetController.isAttached) {
        return;
      }
      unawaited(
        _recommendationSheetController.animateTo(
          size,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  Future<void> _saveCandidateAndNavigate(
    PlaceCandidate candidate,
    BuildContext context, {
    required String message,
    required String targetPath,
  }) async {
    if (_savingCandidateIds.contains(candidate.id)) {
      return;
    }

    setState(() {
      _savingCandidateIds.add(candidate.id);
    });

    try {
      final savedCandidate = await ref
          .read(
            placeCandidatesViewModelProvider((
              groupId: widget.groupId,
              planId: widget.planId,
            )).notifier,
          )
          .addCandidate(candidate);
      if (!mounted || !context.mounted) {
        return;
      }
      setState(() {
        _selectedCandidate = savedCandidate;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.push(targetPath);
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('장소를 저장하지 못했어요. 잠시 후 다시 시도해 주세요.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _savingCandidateIds.remove(candidate.id);
        });
      }
    }
  }

  Future<void> _saveSchedulePlaceAndNavigate(
    PlaceCandidate candidate,
    BuildContext context,
    PlaceCandidatesState state,
  ) async {
    if (_savingCandidateIds.contains(candidate.id)) {
      return;
    }
    final picked = await PlanVisitTimePicker.show(
      context: context,
      title: '방문 시간 설정',
      planStartsAt: state.planStartsAt,
      planEndsAt: state.planEndsAt,
      initialStart: _initialVisitStart(state),
      initialEnd: _initialVisitEnd(state),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _savingCandidateIds.add(candidate.id);
    });

    try {
      await ref
          .read(
            placeCandidatesViewModelProvider((
              groupId: widget.groupId,
              planId: widget.planId,
            )).notifier,
          )
          .addCandidateToSchedule(
            candidate,
            startsAt: picked.start,
            endsAt: picked.end,
          );
      if (!mounted || !context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('일정에 등록되었어요!')));
      context.push(RoutePaths.planItinerary(widget.groupId, widget.planId));
    } catch (_) {
      if (!mounted || !context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('일정 장소를 등록하지 못했어요. 잠시 후 다시 시도해 주세요.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _savingCandidateIds.remove(candidate.id);
        });
      }
    }
  }

  DateTime _initialVisitStart(PlaceCandidatesState state) {
    final planStart = state.planStartsAt?.toLocal();
    if (planStart != null && planStart.isAfter(DateTime.now())) {
      return planStart;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  DateTime _initialVisitEnd(PlaceCandidatesState state) {
    final start = _initialVisitStart(state);
    final defaultEnd = start.add(const Duration(hours: 1));
    final planEnd = state.planEndsAt?.toLocal();
    if (planEnd != null &&
        planEnd.isAfter(start) &&
        planEnd.isBefore(defaultEnd)) {
      return planEnd;
    }
    return defaultEnd;
  }

  PlaceCandidate? _candidateByPointId(
    List<PlaceCandidate> candidates,
    String pointId,
  ) {
    for (final candidate in candidates) {
      if (candidate.id.toString() == pointId) {
        return candidate;
      }
    }
    return null;
  }

  void _focusActiveResultFromMap(
    List<PlaceCandidate> candidates,
    String pointId,
  ) {
    final selected = _candidateByPointId(candidates, pointId);
    if (selected == null) {
      return;
    }
    setState(() {
      _focusedCandidateId = selected.id;
      _selectedCandidate = null;
    });
    _openRecommendationSheet(_RecommendationSheet.maxSheetSize);
    _scrollCandidateCardIntoView(selected);
  }

  GlobalKey _tileKeyFor(PlaceCandidate candidate) {
    return _candidateTileKeys.putIfAbsent(candidate.id, GlobalKey.new);
  }

  void _scrollCandidateCardIntoView(PlaceCandidate candidate) {
    final key = _tileKeyFor(candidate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  String _mapFallbackLabel(
    List<PlaceCandidate> candidates, {
    required bool searchLoading,
    required bool searchHadError,
  }) {
    if (candidates.isNotEmpty) {
      return '지도 타일을 준비하는 동안 후보 위치를 표시하고 있어요';
    }
    if (searchLoading) {
      return '지도 위에 보여줄 장소를 찾는 중이에요';
    }
    if (searchHadError) {
      return '지도 타일과 검색 결과를 다시 확인하고 있어요';
    }
    return '검색어를 입력하면 지도 위에 후보 위치가 표시돼요';
  }
}

class _MapSearchOverlay extends StatelessWidget {
  const _MapSearchOverlay({
    required this.query,
    required this.primaryCategories,
    required this.activeCategoryFilters,
    required this.selectedPrimaryCategory,
    required this.selectedCategoryFilter,
    required this.filtersExpanded,
    required this.myLocationState,
    required this.myLocationTooltip,
    required this.myLocationIcon,
    required this.myLocationStatusLabel,
    required this.mapAreaSearchEnabled,
    required this.mapAreaSearchActive,
    required this.onBack,
    required this.onSearchTap,
    required this.onSearchChanged,
    required this.onPrimaryCategorySelected,
    required this.onCategoryFilterSelected,
    required this.onFiltersToggle,
    required this.onMapAreaSearchPressed,
    required this.onCurrentLocationPressed,
  });

  final String query;
  final List<String> primaryCategories;
  final List<String> activeCategoryFilters;
  final String selectedPrimaryCategory;
  final String? selectedCategoryFilter;
  final bool filtersExpanded;
  final _MyLocationRequestState myLocationState;
  final String myLocationTooltip;
  final IconData myLocationIcon;
  final String? myLocationStatusLabel;
  final bool mapAreaSearchEnabled;
  final bool mapAreaSearchActive;
  final VoidCallback onBack;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onPrimaryCategorySelected;
  final ValueChanged<String> onCategoryFilterSelected;
  final VoidCallback onFiltersToggle;
  final VoidCallback onMapAreaSearchPressed;
  final VoidCallback? onCurrentLocationPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SearchBar(
          query: query,
          onBack: onBack,
          onTap: onSearchTap,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _CategoryPills(
          categories: primaryCategories,
          selectedCategory: selectedPrimaryCategory,
          onSelected: onPrimaryCategorySelected,
        ),
        if (activeCategoryFilters.isNotEmpty && filtersExpanded) ...[
          const SizedBox(height: AppSpacing.xs),
          _CategoryPills(
            categories: activeCategoryFilters,
            selectedCategory: selectedCategoryFilter ?? '',
            onSelected: onCategoryFilterSelected,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (mapAreaSearchEnabled || mapAreaSearchActive)
              _MapAreaSearchButton(
                enabled: mapAreaSearchEnabled,
                active: mapAreaSearchActive,
                onPressed: onMapAreaSearchPressed,
              ),
            const Spacer(),
            _FloatingMapIconButton(
              tooltip: filtersExpanded ? '세부 필터 접기' : '세부 필터 열기',
              onPressed: onFiltersToggle,
              selected: filtersExpanded || selectedCategoryFilter != null,
              child: const Icon(Icons.tune),
            ),
            const SizedBox(width: AppSpacing.xs),
            _FloatingMapIconButton(
              tooltip: myLocationTooltip,
              onPressed: onCurrentLocationPressed,
              child: myLocationState == _MyLocationRequestState.requesting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(myLocationIcon),
            ),
          ],
        ),
        if (myLocationStatusLabel case final statusLabel?) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: _MapStatusPill(label: statusLabel),
          ),
        ],
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.query,
    required this.onBack,
    required this.onTap,
    required this.onChanged,
  });

  final String query;
  final VoidCallback onBack;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FloatingMapIconButton(
          tooltip: '뒤로',
          onPressed: onBack,
          child: const Icon(Icons.arrow_back_ios_new),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: OnmuCard(
            backgroundColor: AppColors.bgDefault.withValues(alpha: 0.94),
            borderColor: AppColors.lineSoft,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textSub),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    initialValue: query,
                    onTap: onTap,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      hintText: '장소 검색 (카페, 식당, 관광지)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSub),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingMapIconButton extends StatelessWidget {
  const _FloatingMapIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.selected = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryPinkSoft
          : AppColors.bgDefault.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      elevation: 3,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: selected ? AppColors.primaryPink : AppColors.textMain,
        disabledColor: AppColors.textMuted,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        icon: child,
      ),
    );
  }
}

class _CategoryPills extends StatelessWidget {
  const _CategoryPills({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Row(
          children: [
            for (var index = 0; index < categories.length; index += 1) ...[
              if (index > 0) const SizedBox(width: AppSpacing.xs),
              _CategoryPill(
                label: categories[index],
                selected: categories[index] == selectedCategory,
                onTap: () => onSelected(categories[index]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? AppColors.primaryPink
        : AppColors.textSub;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        key: ValueKey('place-category-pill-$label'),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryPinkSoft : AppColors.bgDefault,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.linePink : AppColors.lineSoft,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 30,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  strutStyle: const StrutStyle(
                    height: 1,
                    forceStrutHeight: true,
                  ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    height: 1,
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

class _MapAreaSearchButton extends StatelessWidget {
  const _MapAreaSearchButton({
    required this.enabled,
    required this.active,
    required this.onPressed,
  });

  final bool enabled;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = active
        ? AppColors.primaryPink
        : AppColors.bgDefault;
    final foregroundColor = active ? AppColors.textInverse : AppColors.textMain;
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore,
                size: 18,
                color: enabled ? foregroundColor : AppColors.textSub,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '현 지도에서 검색',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: enabled ? foregroundColor : AppColors.textSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.lineSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSub, height: 1),
        ),
      ),
    );
  }
}

class MapPin extends StatelessWidget {
  const MapPin({
    required this.order,
    required this.focused,
    required this.candidateName,
    super.key,
  });

  final int order;
  final bool focused;
  final String candidateName;

  @override
  Widget build(BuildContext context) {
    final pin = Column(
      key: focused ? ValueKey('focused-place-pin-$order') : null,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: focused ? AppColors.primaryPurple : AppColors.primaryPink,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.bgDefault,
              width: focused ? 5 : 3,
            ),
            boxShadow: focused
                ? const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: SizedBox.square(
            dimension: focused ? 44 : 36,
            child: Center(
              child: Text(
                '$order',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.textInverse),
              ),
            ),
          ),
        ),
        Icon(
          Icons.location_on,
          color: focused ? AppColors.primaryPurple : AppColors.primaryPink,
        ),
      ],
    );

    if (!focused) {
      return pin;
    }

    return Semantics(
      label: '포커스된 장소 $candidateName',
      container: true,
      child: pin,
    );
  }
}

class CurrentLocationDot extends StatelessWidget {
  const CurrentLocationDot({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentBlue,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.bgDefault, width: 4),
      ),
      child: const SizedBox.square(dimension: 24),
    );
  }
}

class _RecommendationSheet extends StatelessWidget {
  const _RecommendationSheet({
    required this.controller,
    required this.candidates,
    required this.searchActive,
    required this.autoSearch,
    required this.query,
    required this.selectedCategory,
    required this.searchLoading,
    required this.searchHadError,
    required this.mapScopedSearch,
    required this.searchRadiusMeters,
    required this.selectedCandidate,
    required this.isAlreadyCandidate,
    required this.isSavingCandidate,
    required this.onBackToResults,
    required this.onCandidateSelected,
    required this.onRegisterPressed,
    required this.onAddCandidatePressed,
    required this.tileKeyFor,
  });

  static const minSheetSize = 0.16;
  static const initialSheetSize = 0.34;
  static const maxSheetSize = 0.82;
  static const _bottomNavigationSafePadding = 32.0;

  final ScrollController controller;
  final List<PlaceCandidate> candidates;
  final bool searchActive;
  final bool autoSearch;
  final String query;
  final String selectedCategory;
  final bool searchLoading;
  final bool searchHadError;
  final bool mapScopedSearch;
  final int searchRadiusMeters;
  final PlaceCandidate? selectedCandidate;
  final bool Function(PlaceCandidate candidate) isAlreadyCandidate;
  final bool Function(PlaceCandidate candidate) isSavingCandidate;
  final VoidCallback onBackToResults;
  final ValueChanged<PlaceCandidate> onCandidateSelected;
  final ValueChanged<PlaceCandidate> onRegisterPressed;
  final ValueChanged<PlaceCandidate> onAddCandidatePressed;
  final GlobalKey Function(PlaceCandidate candidate) tileKeyFor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          _bottomNavigationSafePadding,
        ),
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.lineBrown,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const SizedBox(width: 44, height: 5),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (selectedCandidate != null) ...[
            _SelectedPlaceDetailSheet(
              candidate: selectedCandidate!,
              isSaving: isSavingCandidate(selectedCandidate!),
              alreadyCandidate: isAlreadyCandidate(selectedCandidate!),
              onBackToResults: onBackToResults,
              onRegisterPressed: () => onRegisterPressed(selectedCandidate!),
              onAddCandidatePressed: () =>
                  onAddCandidatePressed(selectedCandidate!),
            ),
          ] else ...[
            Text(
              autoSearch
                  ? '장소 후보 ✨'
                  : searchActive
                  ? '검색 결과'
                  : '장소 후보',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              searchActive
                  ? _searchResultDescription
                  : '일정에 바로 넣거나 후보 리스트에 담아둘 수 있어요',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.textSub),
            ),
            if (mapScopedSearch) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '현 지도 중심 반경 ${(searchRadiusMeters / 1000).toStringAsFixed(1)}km 기준',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.primaryPink),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            if (candidates.isEmpty) ...[
              _EmptyPlaceSearchCard(
                searchActive: searchActive,
                searchLoading: searchLoading,
                searchHadError: searchHadError,
                selectedCategory: selectedCategory,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (var index = 0; index < candidates.length; index += 1) ...[
              _RecommendationTile(
                key: tileKeyFor(candidates[index]),
                candidate: candidates[index],
                photoIndex: index,
                onTap: () => onCandidateSelected(candidates[index]),
                isSaving: isSavingCandidate(candidates[index]),
                alreadyCandidate: isAlreadyCandidate(candidates[index]),
                onRegisterPressed: () => onRegisterPressed(candidates[index]),
                onAddCandidatePressed: () =>
                    onAddCandidatePressed(candidates[index]),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ],
      ),
    );
  }

  String get _searchResultDescription {
    final normalizedQuery = query.trim();
    if (autoSearch && normalizedQuery.isNotEmpty) {
      return '$normalizedQuery 주변에서 바로 후보를 불러왔어요.';
    }
    if (normalizedQuery.isEmpty) {
      return '$selectedCategory 장소를 지도 위에서 확인해요';
    }

    return '"$normalizedQuery" 검색 결과를 지도 위에서 확인해요';
  }
}

class _EmptyPlaceSearchCard extends StatelessWidget {
  const _EmptyPlaceSearchCard({
    required this.searchActive,
    required this.searchLoading,
    required this.searchHadError,
    required this.selectedCategory,
  });

  final bool searchActive;
  final bool searchLoading;
  final bool searchHadError;
  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    return OnmuCard(
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(_body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    if (searchLoading) {
      return Icons.explore_outlined;
    }
    if (searchHadError) {
      return Icons.refresh;
    }
    return Icons.search;
  }

  String get _title {
    if (searchLoading) {
      return '장소를 찾는 중이에요';
    }
    if (searchHadError) {
      return '검색 결과를 불러오지 못했어요';
    }
    return searchActive ? '다른 키워드로 다시 찾아볼까요?' : '검색어를 입력해 주세요';
  }

  String get _body {
    if (searchLoading) {
      return '잠시 뒤 후보가 지도와 함께 나타나요.';
    }
    if (searchHadError) {
      return '잠시 후 다시 검색하거나 카테고리를 바꿔보세요.';
    }
    if (searchActive) {
      return '$selectedCategory 말고 다른 필터로 넓혀서 찾아볼 수도 있어요.';
    }
    return '음식점, 카페, 가볼만한곳처럼 입력하면 후보를 지도에 표시해요.';
  }
}

class _SelectedPlaceDetailSheet extends StatelessWidget {
  const _SelectedPlaceDetailSheet({
    required this.candidate,
    required this.isSaving,
    required this.alreadyCandidate,
    required this.onBackToResults,
    required this.onRegisterPressed,
    required this.onAddCandidatePressed,
  });

  final PlaceCandidate candidate;
  final bool isSaving;
  final bool alreadyCandidate;
  final VoidCallback onBackToResults;
  final VoidCallback onRegisterPressed;
  final VoidCallback onAddCandidatePressed;

  @override
  Widget build(BuildContext context) {
    final detailRows = _detailRows(candidate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: '검색 결과로 돌아가기',
              onPressed: onBackToResults,
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                '장소 상세',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        OnmuCard(
          backgroundColor: AppColors.bgDefault,
          borderColor: AppColors.lineSoft,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                candidate.categoryDistanceLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (candidate.displayAddress.isNotEmpty)
                Text(
                  candidate.displayAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSub),
                ),
              if (detailRows.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _PlaceDetailFacts(rows: detailRows),
              ],
              if (candidate.openingLabel.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _InfoBlock(
                  title: candidate.openingLabel,
                  body: '방문 전 영업시간을 한 번 더 확인해 주세요.',
                  trailing: candidate.isOpen ? '영업중' : '확인 필요',
                ),
              ],
              if (candidate.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('분류 키워드', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    for (final tag in candidate.tags.take(4))
                      OnmuChip(label: tag, selected: true),
                  ],
                ),
              ],
              if (candidate.memberFits.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('참여자 선호', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                MemberPreferenceList(candidate: candidate),
              ],
              if (candidate.sourceUrl.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _ExternalPlaceLinkButton(sourceUrl: candidate.sourceUrl),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _PlaceActionButtons(
          candidateId: candidate.id,
          isSaving: isSaving,
          alreadyCandidate: alreadyCandidate,
          onAddCandidatePressed: onAddCandidatePressed,
          onRegisterPressed: onRegisterPressed,
        ),
      ],
    );
  }

  List<_PlaceDetailFact> _detailRows(PlaceCandidate candidate) {
    return [
      if (candidate.roadAddress.trim().isNotEmpty &&
          candidate.roadAddress.trim() != candidate.displayAddress.trim())
        _PlaceDetailFact(label: '도로명', value: candidate.roadAddress.trim()),
    ];
  }
}

class _PlaceDetailFact {
  const _PlaceDetailFact({required this.label, required this.value});

  final String label;
  final String value;
}

class _PlaceDetailFacts extends StatelessWidget {
  const _PlaceDetailFacts({required this.rows});

  final List<_PlaceDetailFact> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  row.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textSub),
                ),
              ),
              Expanded(
                child: Text(
                  row.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    height: 1.16,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
          if (row != rows.last) const SizedBox(height: AppSpacing.xxs),
        ],
      ],
    );
  }
}

class _ExternalPlaceLinkButton extends StatelessWidget {
  const _ExternalPlaceLinkButton({required this.sourceUrl});

  final String sourceUrl;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _launchSource(context),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('외부 상세 보기'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }

  Future<void> _launchSource(BuildContext context) async {
    final uri = Uri.tryParse(sourceUrl.trim());
    if (uri == null || !uri.hasScheme) {
      _showLaunchFailure(context);
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showLaunchFailure(context);
    }
  }

  void _showLaunchFailure(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('외부 상세 페이지를 열 수 없어요.')));
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.body,
    required this.trailing,
  });

  final String title;
  final String body;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        OnmuChip(label: trailing, selected: true),
      ],
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    super.key,
    required this.candidate,
    required this.photoIndex,
    required this.onTap,
    required this.isSaving,
    required this.alreadyCandidate,
    required this.onRegisterPressed,
    required this.onAddCandidatePressed,
  });

  final PlaceCandidate candidate;
  final int photoIndex;
  final VoidCallback onTap;
  final bool isSaving;
  final bool alreadyCandidate;
  final VoidCallback onRegisterPressed;
  final VoidCallback onAddCandidatePressed;

  @override
  Widget build(BuildContext context) {
    final tags = candidate.tags.isEmpty
        ? <String>[candidate.category]
        : candidate.tags.take(3).toList(growable: false);

    return OnmuCard(
      onTap: onTap,
      backgroundColor: AppColors.bgDefault,
      borderColor: AppColors.lineSoft,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlacePhoto(candidate: candidate, index: photoIndex),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            candidate.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      candidate.displayAddress.isEmpty
                          ? candidate.summary
                          : candidate.displayAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSub,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        if (candidate.travelTimeLabel.trim().isNotEmpty)
                          _MetricChip(
                            icon: Icons.directions_walk,
                            label: candidate.travelTimeLabel,
                          ),
                        if (candidate.openingLabel.trim().isNotEmpty)
                          _MetricChip(
                            icon: candidate.isOpen
                                ? Icons.circle
                                : Icons.error_outline,
                            label: candidate.isOpen ? '영업 중' : '확인 필요',
                            color: candidate.isOpen
                                ? AppColors.accentRed
                                : AppColors.textMuted,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        for (final tag in tags.take(2)) OnmuChip(label: tag),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _PlaceActionButtons(
            candidateId: candidate.id,
            isSaving: isSaving,
            alreadyCandidate: alreadyCandidate,
            onAddCandidatePressed: onAddCandidatePressed,
            onRegisterPressed: onRegisterPressed,
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    this.color = AppColors.primaryPink,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgPaper,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.lineWarm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceActionButtons extends StatelessWidget {
  const _PlaceActionButtons({
    required this.candidateId,
    required this.isSaving,
    required this.alreadyCandidate,
    required this.onAddCandidatePressed,
    required this.onRegisterPressed,
  });

  static const _buttonHeight = 44.0;

  final int candidateId;
  final bool isSaving;
  final bool alreadyCandidate;
  final VoidCallback onAddCandidatePressed;
  final VoidCallback onRegisterPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            key: ValueKey('place-action-$candidateId-candidate'),
            height: _buttonHeight,
            child: _CompactPlaceActionButton(
              label: isSaving
                  ? '저장 중'
                  : alreadyCandidate
                  ? '후보에 있음'
                  : '후보에 추가',
              icon: alreadyCandidate ? Icons.favorite : Icons.favorite_border,
              outlined: true,
              onPressed: isSaving || alreadyCandidate
                  ? null
                  : onAddCandidatePressed,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SizedBox(
            key: ValueKey('place-action-$candidateId-schedule'),
            height: _buttonHeight,
            child: _CompactPlaceActionButton(
              label: isSaving ? '저장 중' : '일정에 추가',
              icon: Icons.event_available_outlined,
              onPressed: isSaving ? null : onRegisterPressed,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactPlaceActionButton extends StatelessWidget {
  const _CompactPlaceActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(label, maxLines: 1),
        ],
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );
    final padding = const EdgeInsets.symmetric(horizontal: AppSpacing.xs);
    final minimumSize = const Size(0, _PlaceActionButtons._buttonHeight);
    final textStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMain,
          backgroundColor: AppColors.bgDefault,
          side: const BorderSide(color: AppColors.lineBrown),
          minimumSize: minimumSize,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.textInverse,
        minimumSize: minimumSize,
        padding: padding,
        shape: shape,
        textStyle: textStyle,
      ),
      child: child,
    );
  }
}

class _PlacePhoto extends StatelessWidget {
  const _PlacePhoto({required this.candidate, required this.index});

  final PlaceCandidate candidate;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${candidate.name} 대표 사진',
      image: true,
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          width: 56,
          height: 68,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _photoColors,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -8,
                  child: Icon(
                    Icons.circle,
                    size: 34,
                    color: AppColors.bgDefault.withValues(alpha: 0.36),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 12,
                  child: Icon(
                    _photoIcon,
                    color: AppColors.textInverse,
                    size: 22,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bgDefault.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.bgDefault.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const SizedBox.square(dimension: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> get _photoColors {
    switch (index % 3) {
      case 0:
        return const [AppColors.accentBrown, AppColors.primaryPink];
      case 1:
        return const [AppColors.accentBlue, AppColors.primaryPurple];
      default:
        return const [AppColors.accentGreen, AppColors.accentOrange];
    }
  }

  IconData get _photoIcon {
    switch (candidate.category) {
      case '카페':
        return Icons.local_cafe;
      case '관광지':
        return Icons.park;
      default:
        return Icons.restaurant;
    }
  }
}
