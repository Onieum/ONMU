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
    this.nickname = '온뮤',
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

  // 기본 프리셋들
  static List<String> get skinTones => [
    '#FFECCA', // 1단계 (가장 밝음)
    '#FCD0B4', // 2단계
    '#EBB390', // 3단계
    '#D49673', // 4단계
    '#B87B57', // 5단계 (가장 어두움)
  ];

  // 헤어 컬러 10가지
  static List<String> get hairColors => [
    '#1E1E1E', // 블랙
    '#7A5230', // 브라운
    '#E7D08B', // 블론드
    '#F5F5F5', // 화이트
    '#E6A3C6', // 핑크
    '#C94B4B', // 레드
    '#7FA9E6', // 블루
    '#7ED8B6', // 민트
    '#9A79D8', // 퍼플
    '#9AD64D', // 라임
  ];

  static List<String> get hairColorLabels => [
    '블랙', '브라운', '블론드', '화이트', '핑크',
    '레드', '블루', '민트', '퍼플', '라임'
  ];

  // 눈 컬러 8가지
  static List<String> get eyeColors => [
    '#3A3A3A', // 검정
    '#8B5A3C', // 갈색
    '#4F8FD9', // 파랑
    '#D86A9C', // 핑크
    '#6FA45A', // 초록
    '#7A7A7A', // 회색
    '#8A6BB8', // 보라
    '#C99652', // 골드
  ];

  static List<String> get eyeColorLabels => [
    '검정', '갈색', '파랑', '핑크', '초록', '회색', '보라', '골드'
  ];

  static List<String> get eyeColorEnglishNames => [
    'black', 'brown', 'blue', 'pink', 'green', 'gray', 'purple', 'gold'
  ];
}
