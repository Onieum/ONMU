import 'character_model.dart';

class UploadedMedia {
  final String? id;
  final String storageKey;
  final String publicUrl;
  final String mediaType;
  final int? width;
  final int? height;
  final double? durationSeconds;
  final int sortOrder;

  const UploadedMedia({
    this.id,
    required this.storageKey,
    required this.publicUrl,
    this.mediaType = 'IMAGE',
    this.width,
    this.height,
    this.durationSeconds,
    this.sortOrder = 0,
  });

  UploadedMedia copyWith({
    String? id,
    String? storageKey,
    String? publicUrl,
    String? mediaType,
    int? width,
    int? height,
    double? durationSeconds,
    int? sortOrder,
  }) {
    return UploadedMedia(
      id: id ?? this.id,
      storageKey: storageKey ?? this.storageKey,
      publicUrl: publicUrl ?? this.publicUrl,
      mediaType: mediaType ?? this.mediaType,
      width: width ?? this.width,
      height: height ?? this.height,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class OotdAvatarGenerationJob {
  final String jobId;
  final String status;
  final String recordId;
  final String? generatedImageUrl;
  final String? errorCode;
  final bool retryable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OotdAvatarGenerationJob({
    required this.jobId,
    required this.status,
    required this.recordId,
    this.generatedImageUrl,
    this.errorCode,
    this.retryable = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending =>
      status.toUpperCase() == 'PENDING' || status.toUpperCase() == 'PROCESSING';

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  bool get isFailed => status.toUpperCase() == 'FAILED';
}

class TimelineItem {
  final String time;
  final String placeName;
  final String category;
  final String description;
  final String? imageUrl;
  final String? mediaStorageKey;

  const TimelineItem({
    required this.time,
    required this.placeName,
    required this.category,
    required this.description,
    this.imageUrl,
    this.mediaStorageKey,
  });
}

class CrewOotdAppearance {
  final String userId;
  final String nickname;
  final String source;
  final String? ootdRecordId;
  final String? ootdImageUrl;
  final CharacterDraft? character;

  const CrewOotdAppearance({
    required this.userId,
    required this.nickname,
    required this.source,
    this.ootdRecordId,
    this.ootdImageUrl,
    this.character,
  });

  bool get hasOotdImage {
    final value = ootdImageUrl;
    return value != null && value.trim().isNotEmpty;
  }
}

class OotdRecord {
  final String? id;
  final DateTime date;
  final String? imagePath;
  final List<String> imageUrls;
  final List<UploadedMedia> media;
  final CharacterDraft character;
  final List<CharacterDraft> crewCharacters;
  final List<CrewOotdAppearance> crewAppearances;
  final List<String> moodTags;
  final Map<String, String> brands;
  final String weather;
  final String mood;
  final bool isPublic;
  final List<TimelineItem> timeline;

  const OotdRecord({
    this.id,
    required this.date,
    this.imagePath,
    this.imageUrls = const [],
    this.media = const [],
    required this.character,
    this.crewCharacters = const [],
    this.crewAppearances = const [],
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
    List<UploadedMedia>? media,
    CharacterDraft? character,
    List<CharacterDraft>? crewCharacters,
    List<CrewOotdAppearance>? crewAppearances,
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
      media: media ?? this.media,
      character: character ?? this.character,
      crewCharacters: crewCharacters ?? this.crewCharacters,
      crewAppearances: crewAppearances ?? this.crewAppearances,
      moodTags: moodTags ?? this.moodTags,
      brands: brands ?? this.brands,
      weather: weather ?? this.weather,
      mood: mood ?? this.mood,
      isPublic: isPublic ?? this.isPublic,
      timeline: timeline ?? this.timeline,
    );
  }
}
