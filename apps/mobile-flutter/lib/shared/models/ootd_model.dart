import 'character_model.dart';

class TimelineItem {
  final String time;
  final String placeName;
  final String category; // 'restaurant', 'cafe', 'shopping', 'walk', etc.
  final String description;
  final String? imageUrl;

  const TimelineItem({
    required this.time,
    required this.placeName,
    required this.category,
    required this.description,
    this.imageUrl,
  });
}

class OotdRecord {
  final String? id;
  final DateTime date;
  final String? imagePath; // 오늘의 착장 실제 사진 (시뮬레이션용 경로 혹은 null)
  final List<String> imageUrls;
  final CharacterDraft character; // 그 날 장착한 픽셀 캐릭터
  final List<String> moodTags; // #캐주얼, #성수동 등
  final Map<String, String> brands; // {'상의': '아디다스', '하의': '리바이스'}
  final String weather; // 'sunny', 'cloudy', 'rainy'
  final String mood; // 감정 (예: 'happy', 'excited', 'calm')
  final bool isPublic; // true: 🌍 전체공개, false: 🔒 우리 멤버만
  final List<TimelineItem> timeline; // 시간별 이동 동선

  const OotdRecord({
    this.id,
    required this.date,
    this.imagePath,
    this.imageUrls = const [],
    required this.character,
    required this.moodTags,
    required this.brands,
    this.weather = 'sunny',
    this.mood = 'happy',
    this.isPublic = false,
    this.timeline = const [],
  });

  OotdRecord copyWith({
    String? id,
    DateTime? date,
    String? imagePath,
    bool clearImagePath = false,
    List<String>? imageUrls,
    CharacterDraft? character,
    List<String>? moodTags,
    Map<String, String>? brands,
    String? weather,
    String? mood,
    bool? isPublic,
    List<TimelineItem>? timeline,
  }) {
    return OotdRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
      imageUrls: imageUrls ?? this.imageUrls,
      character: character ?? this.character,
      moodTags: moodTags ?? this.moodTags,
      brands: brands ?? this.brands,
      weather: weather ?? this.weather,
      mood: mood ?? this.mood,
      isPublic: isPublic ?? this.isPublic,
      timeline: timeline ?? this.timeline,
    );
  }
}
