import '../../../core/api/onmu_api_client.dart';

class KoreaRegionSelection {
  const KoreaRegionSelection({
    this.country = 'KR',
    required this.sido,
    required this.sigungu,
  });

  final String country;
  final String sido;
  final String sigungu;

  static const empty = KoreaRegionSelection(sido: '', sigungu: '');
  static const fallback = KoreaRegionSelection(sido: '서울', sigungu: '성동구');

  String get displayName {
    final cleanSido = sido.trim();
    final cleanSigungu = sigungu.trim();
    if (cleanSigungu.isEmpty) {
      return cleanSido;
    }
    return '$cleanSido $cleanSigungu';
  }

  Map<String, Object?> toJson() {
    return {
      'country': country,
      'sido': sido.trim(),
      'sigungu': sigungu.trim(),
      'displayName': displayName,
    };
  }

  static KoreaRegionSelection fromJson(Object? value) {
    if (value is Map) {
      final json = OnmuJson.asMap(value);
      final displayName = OnmuJson.readString(json, 'displayName');
      final parsedDisplay = fromDisplayName(displayName);
      final sido = OnmuJson.readString(json, 'sido', parsedDisplay.sido);
      final sigungu = OnmuJson.readString(
        json,
        'sigungu',
        parsedDisplay.sigungu,
      );
      return KoreaRegionSelection(sido: sido.trim(), sigungu: sigungu.trim());
    }
    return fromDisplayName(value?.toString() ?? '');
  }

  static KoreaRegionSelection fromDisplayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return empty;
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return KoreaRegionSelection(sido: parts.first, sigungu: '');
    }
    return KoreaRegionSelection(
      sido: parts.first,
      sigungu: parts.sublist(1).join(' '),
    );
  }

  static KoreaRegionSelection fromParts({
    required String sido,
    required String sigungu,
  }) {
    final cleanSido = sido.trim();
    final cleanSigungu = sigungu.trim();
    if (cleanSido.isEmpty) {
      return empty;
    }

    final candidates = sigunguOptionsFor(cleanSido);
    if (candidates.isEmpty) {
      return KoreaRegionSelection(sido: cleanSido, sigungu: cleanSigungu);
    }

    final fallbackSigungu =
        cleanSido == fallback.sido && candidates.contains(fallback.sigungu)
        ? fallback.sigungu
        : candidates.first;
    final normalizedSigungu = candidates.contains(cleanSigungu)
        ? cleanSigungu
        : fallbackSigungu;
    return KoreaRegionSelection(sido: cleanSido, sigungu: normalizedSigungu);
  }
}

enum RegionVisibility {
  private('PRIVATE', '비공개'),
  public('PUBLIC', '공개');

  const RegionVisibility(this.value, this.label);

  final String value;
  final String label;

  bool get isPublic => this == RegionVisibility.public;

  static RegionVisibility fromJson(Object? value) {
    if (value is bool) {
      return value ? RegionVisibility.public : RegionVisibility.private;
    }
    final normalized = value?.toString().trim().toUpperCase();
    return switch (normalized) {
      'PUBLIC' => RegionVisibility.public,
      _ => RegionVisibility.private,
    };
  }
}

const koreaRegionOptions = <String, List<String>>{
  '서울': ['강남구', '마포구', '성동구', '송파구', '중구'],
  '부산': ['해운대구', '부산진구', '수영구', '중구'],
  '대구': ['수성구', '중구', '달서구'],
  '인천': ['연수구', '남동구', '부평구'],
  '광주': ['동구', '서구', '광산구'],
  '대전': ['유성구', '서구', '중구'],
  '울산': ['남구', '중구', '울주군'],
  '세종': ['세종시'],
  '경기': ['수원시', '성남시', '용인시', '고양시'],
  '강원': ['춘천시', '원주시', '강릉시'],
  '충북': ['청주시', '충주시'],
  '충남': ['천안시', '아산시'],
  '전북': ['전주시', '군산시'],
  '전남': ['목포시', '여수시'],
  '경북': ['포항시', '경주시'],
  '경남': ['창원시', '김해시'],
  '제주': ['제주시', '서귀포시'],
};

List<String> get koreaSidoOptions =>
    koreaRegionOptions.keys.toList(growable: false);

List<String> sigunguOptionsFor(String sido) {
  return koreaRegionOptions[sido.trim()] ?? const [];
}
