class PlaceCandidate {
  const PlaceCandidate({
    required this.id,
    required this.name,
    required this.category,
    required this.summary,
    required this.score,
    required this.matchPercent,
    required this.distanceLabel,
    required this.travelTimeLabel,
    required this.priceLabel,
    required this.isOpen,
    required this.address,
    required this.openingLabel,
    required this.sourceLabel,
    required this.riskLabel,
    required this.riskTone,
    required this.memberFits,
    required this.tags,
    required this.reasons,
    required this.risks,
    this.provider = '',
    this.providerPlaceId = '',
    this.roadAddress = '',
    this.sourceUrl = '',
    this.latitude,
    this.longitude,
    this.fetchedAt,
  });

  final int id;
  final String name;
  final String category;
  final String summary;
  final double score;
  final int matchPercent;
  final String distanceLabel;
  final String travelTimeLabel;
  final String priceLabel;
  final bool isOpen;
  final String address;
  final String openingLabel;
  final String sourceLabel;
  final String riskLabel;
  final String riskTone;
  final List<MemberFit> memberFits;
  final List<String> tags;
  final List<String> reasons;
  final List<String> risks;
  final String provider;
  final String providerPlaceId;
  final String roadAddress;
  final String sourceUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? fetchedAt;

  bool get hasCoordinate => latitude != null && longitude != null;

  String get categoryDistanceLabel {
    final distance = distanceLabel.trim();
    final categoryLabel = category.trim().isEmpty ? '장소' : category.trim();
    return distance.isEmpty ? categoryLabel : '$categoryLabel · $distance';
  }

  String get categoryTravelLabel {
    final travelTime = travelTimeLabel.trim();
    final categoryLabel = category.trim().isEmpty ? '장소' : category.trim();
    return travelTime.isEmpty ? categoryLabel : '$categoryLabel · $travelTime';
  }

  String get displayAddress {
    final directAddress = address.trim();
    if (directAddress.isNotEmpty) {
      return directAddress;
    }
    return roadAddress.trim();
  }
}

class MemberFit {
  const MemberFit({
    required this.label,
    required this.score,
    required this.note,
  });

  final String label;
  final int score;
  final String note;
}

class PlaceVoteResult {
  const PlaceVoteResult({
    required this.title,
    required this.selectedPlaceName,
    required this.voters,
    required this.note,
  });

  final String title;
  final String selectedPlaceName;
  final List<String> voters;
  final String note;
}

class PlaceRisk {
  const PlaceRisk({
    required this.title,
    required this.description,
    required this.level,
    required this.actionLabel,
    required this.evidence,
  });

  final String title;
  final String description;
  final PlaceRiskLevel level;
  final String actionLabel;
  final String evidence;
}

enum PlaceRiskLevel { notice, warning, blocker }
