class CharacterDraft {
  final String gender; // 'male' or 'female'
  final String nickname;
  final int skinToneIndex;
  final int eyeShapeIndex;
  final int eyeColorIndex;
  final int hairColorIndex;
  final int hairStyleIndex;
  final int topStyleIndex;
  final int bottomStyleIndex;
  final int accessoryStyleIndex;

  const CharacterDraft({
    this.gender = 'female',
    this.nickname = '온무',
    this.skinToneIndex = 0,
    this.eyeShapeIndex = 0,
    this.eyeColorIndex = 0,
    this.hairColorIndex = 0,
    this.hairStyleIndex = 0,
    this.topStyleIndex = -1,
    this.bottomStyleIndex = 0,
    this.accessoryStyleIndex = 0,
  });

  CharacterDraft copyWith({
    String? gender,
    String? nickname,
    int? skinToneIndex,
    int? eyeShapeIndex,
    int? eyeColorIndex,
    int? hairColorIndex,
    int? hairStyleIndex,
    int? topStyleIndex,
    int? bottomStyleIndex,
    int? accessoryStyleIndex,
  }) {
    return CharacterDraft(
      gender: gender ?? this.gender,
      nickname: nickname ?? this.nickname,
      skinToneIndex: skinToneIndex ?? this.skinToneIndex,
      eyeShapeIndex: eyeShapeIndex ?? this.eyeShapeIndex,
      eyeColorIndex: eyeColorIndex ?? this.eyeColorIndex,
      hairColorIndex: hairColorIndex ?? this.hairColorIndex,
      hairStyleIndex: hairStyleIndex ?? this.hairStyleIndex,
      topStyleIndex: topStyleIndex ?? this.topStyleIndex,
      bottomStyleIndex: bottomStyleIndex ?? this.bottomStyleIndex,
      accessoryStyleIndex: accessoryStyleIndex ?? this.accessoryStyleIndex,
    );
  }

  static List<String> get skinTones => [
    '#FEE7DA',
    '#F5CDA7',
    '#E0A96D',
    '#96613F',
    '#4D2C19',
  ];

  static List<String> get hairColors => [
    '#1E1E1E',
    '#7A5230',
    '#E7D08B',
    '#F5F5F5',
    '#E6A3C6',
    '#C94B4B',
    '#7FA9E6',
    '#7ED8B6',
    '#9A79D8',
    '#9AD64D',
  ];

  static List<String> get hairColorLabels => [
    '블랙',
    '브라운',
    '블론드',
    '화이트',
    '핑크',
    '레드',
    '블루',
    '민트',
    '퍼플',
    '라임',
  ];

  static List<String> get eyeColors => [
    '#3A3A3A',
    '#8B5A3C',
    '#4F8FD9',
    '#D86A9C',
    '#6FA45A',
    '#7A7A7A',
    '#8A6BB8',
    '#C99652',
  ];

  static List<String> get eyeColorLabels => [
    '검정',
    '갈색',
    '파랑',
    '핑크',
    '초록',
    '회색',
    '보라',
    '골드',
  ];

  static List<String> get eyeColorEnglishNames => [
    'black',
    'brown',
    'blue',
    'pink',
    'green',
    'gray',
    'purple',
    'gold',
  ];

  static CharacterDraft fromApiJson(
    Map<String, dynamic> json, {
    String nickname = '온무',
  }) {
    return CharacterDraft(
      gender: _readString(json, 'gender', 'female'),
      nickname: nickname,
      skinToneIndex: _readIndexedValue(json['skinTone'], 'skin'),
      hairStyleIndex: _readIndexedValue(json['hairStyle'], 'hair_style'),
      hairColorIndex: _readIndexedValue(json['hairColor'], 'hair_color'),
      eyeShapeIndex: _readIndexedValue(json['eyeStyle'], 'eye_style'),
      eyeColorIndex: _readIndexedValue(json['eyeColor'], 'eye_color'),
      topStyleIndex: _readIndexedValue(json['clothes'], 'top', fallback: -1),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    String key,
    String fallback,
  ) {
    final value = json[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  static int _readIndexedValue(
    Object? value,
    String prefix, {
    int fallback = 0,
  }) {
    final text = value?.toString() ?? '';
    final match = RegExp(
      '^${RegExp.escape(prefix)}_(-?\\d+)\$',
    ).firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? fallback;
    }
    return fallback;
  }
}
