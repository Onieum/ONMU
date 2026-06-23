part of 'daily_record_screen.dart';

class DailyRecordResultScreen extends StatelessWidget {
  final OotdRecord record;
  final CharacterDraft userCharacter;
  final OotdRecord? ootdRecord;
  final bool includeCrew;
  final int photoCount;
  final GlobalKey? captureKey;
  final VoidCallback onEdit;

  const DailyRecordResultScreen({
    super.key,
    required this.record,
    required this.userCharacter,
    required this.includeCrew,
    required this.photoCount,
    required this.onEdit,
    this.captureKey,
    this.ootdRecord,
  });

  static final _backgrounds = [
    'assets/images/diary_decorate/background/IMG_1911.PNG',
    'assets/images/diary_decorate/background/IMG_1964.PNG',
    'assets/images/diary_decorate/background/IMG_1966.PNG',
    'assets/images/diary_decorate/background/IMG_1967.PNG',
    'assets/images/diary_decorate/background/IMG_1968.PNG',
    'assets/images/diary_decorate/background/IMG_1969.PNG',
    'assets/images/diary_decorate/background/IMG_1970.PNG',
    'assets/images/diary_decorate/background/IMG_1971.PNG',
    'assets/images/diary_decorate/background/IMG_1972.PNG',
    'assets/images/diary_decorate/background/IMG_1973.PNG',
    'assets/images/diary_decorate/background/IMG_1985.PNG',
    'assets/images/diary_decorate/background/IMG_1986.PNG',
  ];

  static final _scratchPapers = [
    'assets/images/diary_decorate/scratch_paper/1.png',
    'assets/images/diary_decorate/scratch_paper/2.png',
    'assets/images/diary_decorate/scratch_paper/3.png',
    'assets/images/diary_decorate/scratch_paper/4.png',
    'assets/images/diary_decorate/scratch_paper/IMG_1959.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1960.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1961.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1962.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1964.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1979.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1982.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1983.PNG',
    'assets/images/diary_decorate/scratch_paper/IMG_1984.PNG',
  ];

  static final _clips = [
    'assets/images/diary_decorate/clip/IMG_1974.PNG',
    'assets/images/diary_decorate/clip/IMG_1975.PNG',
    'assets/images/diary_decorate/clip/IMG_1976.PNG',
    'assets/images/diary_decorate/clip/IMG_1977.PNG',
    'assets/images/diary_decorate/clip/IMG_1978.PNG',
  ];

  static final _tapes = [
    'assets/images/diary_decorate/masking_tape/IMG_1914.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1915.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1916.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1917.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1918.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1919.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1920.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1921.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1923.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1924.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1925.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1926.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1927.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1928.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1929.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1930.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1931.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1932.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1933.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1934.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1935.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1936.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1937.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1938.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1939.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1940.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1942.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1943.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1944.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1945.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1946.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1947.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1948.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1949.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1950.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1951.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1952.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1953.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1954.PNG',
    'assets/images/diary_decorate/masking_tape/IMG_1955.PNG',
  ];

  static final _stamps = [
    'assets/images/diary_decorate/stamp/IMG_1987.PNG',
    'assets/images/diary_decorate/stamp/IMG_1988.PNG',
    'assets/images/diary_decorate/stamp/IMG_1989.PNG',
    'assets/images/diary_decorate/stamp/IMG_1990.PNG',
    'assets/images/diary_decorate/stamp/IMG_1991.PNG',
    'assets/images/diary_decorate/stamp/IMG_1992.PNG',
    'assets/images/diary_decorate/stamp/IMG_1993.PNG',
    'assets/images/diary_decorate/stamp/IMG_1994.PNG',
    'assets/images/diary_decorate/stamp/IMG_1995.PNG',
    'assets/images/diary_decorate/stamp/IMG_1996.PNG',
    'assets/images/diary_decorate/stamp/IMG_1997.PNG',
    'assets/images/diary_decorate/stamp/IMG_1998.PNG',
    'assets/images/diary_decorate/stamp/IMG_1999.PNG',
  ];

  static final _stickers = [
    'assets/images/diary_decorate/sticker/camera_1.png',
    'assets/images/diary_decorate/sticker/camera_2.png',
    'assets/images/diary_decorate/sticker/coffee_1.png',
    'assets/images/diary_decorate/sticker/coffee_2.png',
    'assets/images/diary_decorate/sticker/coffee_3.png',
    'assets/images/diary_decorate/sticker/deco_1.png',
    'assets/images/diary_decorate/sticker/deco_2.png',
    'assets/images/diary_decorate/sticker/deco_3.png',
    'assets/images/diary_decorate/sticker/deco_4.png',
    'assets/images/diary_decorate/sticker/deco_5.png',
    'assets/images/diary_decorate/sticker/deco_6.png',
    'assets/images/diary_decorate/sticker/deco_7.png',
    'assets/images/diary_decorate/sticker/envelope_1.png',
    'assets/images/diary_decorate/sticker/envelope_2.png',
    'assets/images/diary_decorate/sticker/envelope_3.png',
    'assets/images/diary_decorate/sticker/envelope_4.png',
    'assets/images/diary_decorate/sticker/flower_1.png',
    'assets/images/diary_decorate/sticker/flower_2.png',
    'assets/images/diary_decorate/sticker/flower_3.png',
    'assets/images/diary_decorate/sticker/flower_4.png',
    'assets/images/diary_decorate/sticker/flower_5.png',
    'assets/images/diary_decorate/sticker/flower_6.png',
    'assets/images/diary_decorate/sticker/flower_7.png',
    'assets/images/diary_decorate/sticker/flower_8.png',
    'assets/images/diary_decorate/sticker/flower_9.png',
    'assets/images/diary_decorate/sticker/heart_1.png',
    'assets/images/diary_decorate/sticker/heart_2.png',
    'assets/images/diary_decorate/sticker/heart_3.png',
    'assets/images/diary_decorate/sticker/heart_4.png',
    'assets/images/diary_decorate/sticker/music note_1.png',
    'assets/images/diary_decorate/sticker/music note_2.png',
    'assets/images/diary_decorate/sticker/music note_3.png',
    'assets/images/diary_decorate/sticker/pin_1.png',
    'assets/images/diary_decorate/sticker/pin_2.png',
    'assets/images/diary_decorate/sticker/pin_3.png',
    'assets/images/diary_decorate/sticker/pin_4.png',
    'assets/images/diary_decorate/sticker/pin_5.png',
    'assets/images/diary_decorate/sticker/postal sticker_1.png',
    'assets/images/diary_decorate/sticker/postal sticker_2.png',
    'assets/images/diary_decorate/sticker/postal sticker_3.png',
    'assets/images/diary_decorate/sticker/postal sticker_4.png',
    'assets/images/diary_decorate/sticker/ribbon_1.png',
    'assets/images/diary_decorate/sticker/ribbon_2.png',
    'assets/images/diary_decorate/sticker/ribbon_3.png',
    'assets/images/diary_decorate/sticker/ribbon_4.png',
    'assets/images/diary_decorate/sticker/snack_1.png',
    'assets/images/diary_decorate/sticker/snack_2.png',
    'assets/images/diary_decorate/sticker/snack_3.png',
    'assets/images/diary_decorate/sticker/snack_4.png',
    'assets/images/diary_decorate/sticker/snack_5.png',
    'assets/images/diary_decorate/sticker/snack_7.png',
    'assets/images/diary_decorate/sticker/snack_8.png',
    'assets/images/diary_decorate/sticker/snack_9.png',
    'assets/images/diary_decorate/sticker/snack_10.png',
    'assets/images/diary_decorate/sticker/snack_11.png',
    'assets/images/diary_decorate/sticker/snack_12.png',
    'assets/images/diary_decorate/sticker/snack_13.png',
    'assets/images/diary_decorate/sticker/snack_14.png',
    'assets/images/diary_decorate/sticker/sparkle_1.png',
    'assets/images/diary_decorate/sticker/sparkle_2.png',
    'assets/images/diary_decorate/sticker/sparkle_3.png',
    'assets/images/diary_decorate/sticker/sparkle_4.png',
    'assets/images/diary_decorate/sticker/sparkle_5.png',
    'assets/images/diary_decorate/sticker/star_1.png',
    'assets/images/diary_decorate/sticker/star_2.png',
  ];

  @override
  Widget build(BuildContext context) {
    final isDiary = record.brands['theme'] == 'diary';
    final photoItems = record.timeline
        .where((item) => item.category == 'photo')
        .toList(growable: false);
    final dailyItems = record.timeline
        .where((item) => item.category == 'daily')
        .toList(growable: false);
    final dailyMemo = dailyItems.isEmpty ? null : dailyItems.first.description;

    final content = isDiary
        ? _buildDiaryResult(context, photoItems, dailyMemo)
        : _buildCleanResult(context, photoItems, dailyMemo);

    if (captureKey == null) return content;
    return RepaintBoundary(key: captureKey, child: content);
  }

  Widget _buildDiaryResult(
    BuildContext context,
    List<TimelineItem> photoItems,
    String? dailyMemo,
  ) {
    final hasMappedPhotoUrls = photoItems.any((item) => item.imageUrl != null);
    final limitedPhotoItems = photoItems.take(5).toList(growable: false);
    final imageUrls = limitedPhotoItems
        .asMap()
        .entries
        .map((entry) {
          return entry.value.imageUrl ??
              (!hasMappedPhotoUrls && entry.key < record.imageUrls.length
                  ? record.imageUrls[entry.key]
                  : null);
        })
        .toList(growable: false);

    return _DiaryResultLayout(
      record: record,
      photoItems: limitedPhotoItems,
      imageUrls: imageUrls,
      dailyMemo: dailyMemo ?? '오늘의 소중한 순간을 기록했어요.',
      includeCrew: includeCrew,
      userCharacter: userCharacter,
      memoryPlaces: _memoryPlaceNamesFromTimeline(record.timeline),
      crewCharacters: includeCrew ? record.crewCharacters : const [],
      crewAppearances: includeCrew ? record.crewAppearances : const [],
      backgrounds: _backgrounds,
      scratchPapers: _scratchPapers,
      clips: _clips,
      tapes: _tapes,
      stamps: _stamps,
      stickers: _stickers,
    );
  }

  Widget _buildCleanResult(
    BuildContext context,
    List<TimelineItem> photoItems,
    String? dailyMemo,
  ) {
    final displayedPhotoCount = max(photoItems.length, photoCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _dateLabel(record.date),
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textMain,
            height: 1.25,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: record.moodTags
              .map(
                (tag) => Chip(
                  label: Text(tag),
                  backgroundColor: AppColors.bgPurpleSoft,
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
        SizedBox(height: 22),
        if (photoItems.isNotEmpty) ...[
          Text(
            '사진 기록',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
          ),
          SizedBox(height: 12),
          ...photoItems.asMap().entries.map(
            (entry) => _CleanPhotoCard(index: entry.key, item: entry.value),
          ),
        ],
        SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgWarm,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: _ResultMetaRow(
            mood: record.mood,
            weather: record.weather,
            photoCount: displayedPhotoCount,
          ),
        ),
        SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgDefault,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Text(
            dailyMemo ?? '오늘의 소중한 순간을 기록했어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMain,
              height: 1.45,
            ),
          ),
        ),
        if (ootdRecord != null) ...[
          SizedBox(height: 20),
          Text(
            '함께 기록한 OOTD',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMain),
          ),
          SizedBox(height: 12),
          _CleanOotdBlock(ootdRecord: ootdRecord!),
        ],
        if (includeCrew ||
            record.crewAppearances.isNotEmpty ||
            record.crewCharacters.isNotEmpty) ...[
          SizedBox(height: 20),
          _CleanPeopleBlock(
            userCharacter: userCharacter,
            includeCrew: includeCrew,
            crewCharacters: record.crewCharacters,
            crewAppearances: record.crewAppearances,
          ),
        ],
      ],
    );
  }
}

List<String> _memoryPlaceNamesFromTimeline(List<TimelineItem> timeline) {
  final seen = <String>{};
  final places = <String>[];
  for (final item in timeline) {
    if (item.category != 'place') continue;
    final place = item.placeName.trim().isNotEmpty
        ? item.placeName.trim()
        : item.description.trim();
    if (place.isEmpty) continue;
    if (seen.add(place)) places.add(place);
  }
  return places;
}

class _DiaryResultLayout extends StatelessWidget {
  final OotdRecord record;
  final List<TimelineItem> photoItems;
  final List<String?> imageUrls;
  final String dailyMemo;
  final bool includeCrew;
  final CharacterDraft userCharacter;
  final List<String> memoryPlaces;
  final List<CharacterDraft> crewCharacters;
  final List<CrewOotdAppearance> crewAppearances;
  final List<String> backgrounds;
  final List<String> scratchPapers;
  final List<String> clips;
  final List<String> tapes;
  final List<String> stamps;
  final List<String> stickers;

  const _DiaryResultLayout({
    required this.record,
    required this.photoItems,
    required this.imageUrls,
    required this.dailyMemo,
    required this.includeCrew,
    required this.userCharacter,
    required this.memoryPlaces,
    this.crewCharacters = const [],
    this.crewAppearances = const [],
    required this.backgrounds,
    required this.scratchPapers,
    required this.clips,
    required this.tapes,
    required this.stamps,
    required this.stickers,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random(record.date.millisecondsSinceEpoch);
    final photoEntries = photoItems.asMap().entries.toList(growable: false);
    final decoratedPhotos = photoEntries
        .map((entry) {
          final imageUrl = entry.key < imageUrls.length
              ? imageUrls[entry.key]
              : null;
          return _DiaryDecoratedPhoto(
            index: entry.key,
            item: entry.value,
            imageUrl: imageUrl,
            tapeAsset: _pick(tapes, random.nextInt(9999)),
            clipAsset: _pick(clips, random.nextInt(9999)),
            backgroundAsset: _pick(backgrounds, random.nextInt(9999)),
            scratchAsset: _pick(scratchPapers, random.nextInt(9999)),
          );
        })
        .toList(growable: false);

    return GridBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DiaryHeader(record: record),
            const SizedBox(height: 24),
            _DiaryCollageCanvas(
              record: record,
              photos: decoratedPhotos,
              dailyMemo: dailyMemo,
              includeCrew: includeCrew,
              userCharacter: userCharacter,
              memoryPlaces: memoryPlaces,
              crewCharacters: crewCharacters,
              crewAppearances: crewAppearances,
              stampAsset: _pick(stamps, random.nextInt(9999)),
              stickers: stickers,
              seed: record.date.millisecondsSinceEpoch + photoItems.length,
            ),
          ],
        ),
      ),
    );
  }

  static String _pick(List<String> assets, int seed) {
    if (assets.isEmpty) return '';
    return assets[Random(seed).nextInt(assets.length)];
  }
}

class _DiaryDecoratedPhoto {
  final int index;
  final TimelineItem item;
  final String? imageUrl;
  final String tapeAsset;
  final String clipAsset;
  final String backgroundAsset;
  final String scratchAsset;

  const _DiaryDecoratedPhoto({
    required this.index,
    required this.item,
    required this.imageUrl,
    required this.tapeAsset,
    required this.clipAsset,
    required this.backgroundAsset,
    required this.scratchAsset,
  });
}

class _DiaryCollageCanvas extends StatelessWidget {
  final OotdRecord record;
  final List<_DiaryDecoratedPhoto> photos;
  final String dailyMemo;
  final bool includeCrew;
  final CharacterDraft userCharacter;
  final List<String> memoryPlaces;
  final List<CharacterDraft> crewCharacters;
  final List<CrewOotdAppearance> crewAppearances;
  final String stampAsset;
  final List<String> stickers;
  final int seed;

  const _DiaryCollageCanvas({
    required this.record,
    required this.photos,
    required this.dailyMemo,
    required this.includeCrew,
    required this.userCharacter,
    required this.memoryPlaces,
    this.crewCharacters = const [],
    this.crewAppearances = const [],
    required this.stampAsset,
    required this.stickers,
    required this.seed,
  });

  static const double _baseWidth = 344;

  @override
  Widget build(BuildContext context) {
    final count = photos.isEmpty ? 1 : photos.length.clamp(1, 5).toInt();
    final showCharacter =
        includeCrew ||
        record.brands['linkedOotd'] == 'true' ||
        record.brands['recordType'] != 'daily';
    final spec = _DiaryCollageSpec.resolve(count, showCharacter);
    final hasMemory = memoryPlaces.isNotEmpty;
    final memoryHeight = _DiaryTodayMemoryBlock.estimatedHeight(
      memoryPlaces.length,
    );
    final memoryPlace = spec.memoryPlace.copyWith(
      height: hasMemory ? max(spec.memoryPlace.height, memoryHeight) : 0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / _baseWidth;
        final canvasHeight = max(
          spec.contentHeight,
          memoryPlace.y + memoryPlace.height + 24,
        );
        return SizedBox(
          width: constraints.maxWidth,
          height: canvasHeight * scale,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _baseWidth,
              height: canvasHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ...photos.map((photo) {
                    final place = spec.memoPlaces[photo.index];
                    return _placed(
                      place,
                      _DiaryPhotoMemoCard(
                        index: photo.index,
                        text: photo.item.description,
                        scratchAsset: photo.scratchAsset,
                        useScratchPaper: photo.index.isEven,
                      ),
                    );
                  }),
                  if (photos.isEmpty)
                    _placed(
                      const _DiaryPlace(8, 8, 168, 142, -0.04),
                      _DiaryEmptyPhotoCard(),
                    )
                  else
                    ...photos.map((photo) {
                      final place = spec.photoPlaces[photo.index];
                      return _placed(
                        place,
                        _DiaryPhotoCard(
                          index: photo.index,
                          imageUrl: photo.imageUrl,
                          tapeAsset: photo.tapeAsset,
                          clipAsset: photo.clipAsset,
                          backgroundAsset: photo.backgroundAsset,
                          useBackgroundPaper: photo.index.isOdd,
                          useClip: photo.index.isEven && photo.index % 4 == 0,
                          rotation: place.rotation,
                        ),
                      );
                    }),

                  if (showCharacter && spec.characterPlace != null)
                    _placed(
                      spec.characterPlace!,
                      _DiaryCharacterPair(
                        userCharacter: userCharacter,
                        includeCrew: includeCrew,
                        crewCharacters: crewCharacters,
                        crewAppearances: crewAppearances,
                      ),
                    ),
                  if (memoryPlaces.isNotEmpty)
                    _placed(
                      memoryPlace,
                      _DiaryTodayMemoryBlock(places: memoryPlaces),
                    ),
                  _placed(
                    hasMemory
                        ? spec.statusPlace
                        : spec.statusPlace.copyWith(
                            x: spec.memoryPlace.x,
                            width:
                                spec.memoryPlace.width +
                                spec.statusPlace.width +
                                16,
                          ),
                    _DiaryTodayStatusBlock(
                      record: record,
                      expanded: !hasMemory,
                    ),
                  ),
                  _placed(
                    spec.memoFooterPlace,
                    _DiaryMemoFooter(memo: dailyMemo, stampAsset: stampAsset),
                  ),
                  Positioned.fill(
                    child: _DiaryCanvasStickers(
                      stickers: stickers,
                      places: spec.stickerPlaces,
                      seed: seed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placed(_DiaryPlace place, Widget child) {
    return Positioned(
      left: place.x,
      top: place.y,
      width: place.width,
      height: place.height,
      child: Transform.rotate(angle: place.rotation, child: child),
    );
  }
}

class _DiaryCollageSpec {
  final double height;
  final List<_DiaryPlace> photoPlaces;
  final List<_DiaryPlace> memoPlaces;
  final _DiaryPlace memoryPlace;
  final _DiaryPlace statusPlace;
  final _DiaryPlace memoFooterPlace;
  final _DiaryPlace? characterPlace;
  final List<_DiaryPlace> stickerPlaces;

  const _DiaryCollageSpec({
    required this.height,
    required this.photoPlaces,
    required this.memoPlaces,
    required this.memoryPlace,
    required this.statusPlace,
    required this.memoFooterPlace,
    required this.stickerPlaces,
    this.characterPlace,
  });

  static _DiaryCollageSpec resolve(int count, bool includeCrew) {
    if (includeCrew) return _withCharacter(count);
    return _withoutCharacter(count);
  }

  double get contentHeight {
    final places = <_DiaryPlace>[
      ...photoPlaces,
      ...memoPlaces,
      memoryPlace,
      statusPlace,
      memoFooterPlace,
      ?characterPlace,
      ...stickerPlaces,
    ];
    final bottom = places
        .map((place) => place.y + place.height)
        .fold<double>(height, max);
    return bottom + 24;
  }

  static _DiaryCollageSpec _withCharacter(int count) {
    switch (count) {
      case 1:
        return const _DiaryCollageSpec(
          height: 450,
          photoPlaces: [_DiaryPlace(10, 0, 166, 146, -0.025)],
          memoPlaces: [_DiaryPlace(188, 16, 140, 104, 0.01)],
          characterPlace: _DiaryPlace(112, 148, 120, 88, 0),
          memoryPlace: _DiaryPlace(10, 252, 178, 96, -0.005),
          statusPlace: _DiaryPlace(204, 264, 128, 84, 0.005),
          memoFooterPlace: _DiaryPlace(28, 368, 288, 62, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(24, 146, 24, 24, -0.18),
            _DiaryPlace(304, 358, 24, 24, -0.12),
          ],
        );
      case 2:
        return const _DiaryCollageSpec(
          height: 500,
          photoPlaces: [
            _DiaryPlace(10, 0, 150, 132, -0.025),
            _DiaryPlace(184, 132, 150, 132, 0.025),
          ],
          memoPlaces: [
            _DiaryPlace(174, 10, 154, 92, 0.01),
            _DiaryPlace(18, 148, 154, 92, -0.01),
          ],
          characterPlace: _DiaryPlace(112, 254, 120, 82, 0),
          memoryPlace: _DiaryPlace(10, 350, 178, 88, -0.005),
          statusPlace: _DiaryPlace(204, 358, 128, 80, 0.005),
          memoFooterPlace: _DiaryPlace(28, 450, 288, 42, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 246, 24, 24, 0.14),
            _DiaryPlace(18, 438, 24, 24, -0.14),
          ],
        );
      case 3:
        return const _DiaryCollageSpec(
          height: 610,
          photoPlaces: [
            _DiaryPlace(10, 0, 150, 132, -0.025),
            _DiaryPlace(184, 132, 150, 132, 0.025),
            _DiaryPlace(10, 264, 150, 132, -0.025),
          ],
          memoPlaces: [
            _DiaryPlace(174, 10, 154, 92, 0.01),
            _DiaryPlace(18, 148, 154, 92, -0.01),
            _DiaryPlace(174, 276, 154, 92, 0.01),
          ],
          characterPlace: _DiaryPlace(112, 372, 120, 78, 0),
          memoryPlace: _DiaryPlace(10, 456, 178, 98, -0.005),
          statusPlace: _DiaryPlace(204, 456, 128, 98, 0.005),
          memoFooterPlace: _DiaryPlace(28, 562, 288, 42, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 366, 24, 24, 0.14),
            _DiaryPlace(18, 548, 24, 24, -0.14),
          ],
        );
      case 4:
        return const _DiaryCollageSpec(
          height: 700,
          photoPlaces: [
            _DiaryPlace(10, 0, 126, 112, -0.025),
            _DiaryPlace(208, 104, 126, 112, 0.025),
            _DiaryPlace(10, 208, 126, 112, -0.025),
            _DiaryPlace(208, 312, 126, 112, 0.025),
          ],
          memoPlaces: [
            _DiaryPlace(150, 8, 176, 76, 0.01),
            _DiaryPlace(18, 118, 176, 76, -0.01),
            _DiaryPlace(150, 216, 176, 76, 0.01),
            _DiaryPlace(18, 326, 176, 76, -0.01),
          ],
          characterPlace: _DiaryPlace(112, 430, 120, 72, 0),
          memoryPlace: _DiaryPlace(10, 528, 178, 84, -0.005),
          statusPlace: _DiaryPlace(204, 528, 128, 84, 0.005),
          memoFooterPlace: _DiaryPlace(28, 634, 288, 52, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 420, 24, 24, 0.14),
            _DiaryPlace(18, 622, 24, 24, -0.14),
          ],
        );
      default:
        return const _DiaryCollageSpec(
          height: 790,
          photoPlaces: [
            _DiaryPlace(10, 0, 116, 104, -0.025),
            _DiaryPlace(218, 92, 116, 104, 0.025),
            _DiaryPlace(10, 184, 116, 104, -0.025),
            _DiaryPlace(218, 276, 116, 104, 0.025),
            _DiaryPlace(10, 368, 116, 104, -0.025),
          ],
          memoPlaces: [
            _DiaryPlace(140, 6, 188, 70, 0.01),
            _DiaryPlace(18, 106, 188, 70, -0.01),
            _DiaryPlace(140, 190, 188, 70, 0.01),
            _DiaryPlace(18, 290, 188, 70, -0.01),
            _DiaryPlace(140, 374, 188, 70, 0.01),
          ],
          characterPlace: _DiaryPlace(112, 490, 120, 70, 0),
          memoryPlace: _DiaryPlace(10, 584, 178, 84, -0.005),
          statusPlace: _DiaryPlace(204, 584, 128, 84, 0.005),
          memoFooterPlace: _DiaryPlace(28, 696, 288, 60, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 480, 24, 24, 0.14),
            _DiaryPlace(18, 684, 24, 24, -0.14),
          ],
        );
    }
  }

  static _DiaryCollageSpec _withoutCharacter(int count) {
    switch (count) {
      case 1:
        return const _DiaryCollageSpec(
          height: 360,
          photoPlaces: [_DiaryPlace(10, 0, 166, 146, -0.025)],
          memoPlaces: [_DiaryPlace(180, -10, 140, 150, 0.01)],
          memoryPlace: _DiaryPlace(10, 168, 178, 120, -0.005),
          statusPlace: _DiaryPlace(204, 174, 128, 86, 0.005),
          memoFooterPlace: _DiaryPlace(28, 300, 288, 62, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(20, 155, 24, 24, -0.18),
            _DiaryPlace(300, 272, 24, 24, -0.12),
          ],
        );
      case 2:
        return const _DiaryCollageSpec(
          height: 440,
          photoPlaces: [
            _DiaryPlace(10, 0, 150, 132, -0.025),
            _DiaryPlace(184, 132, 150, 132, 0.025),
          ],
          memoPlaces: [
            _DiaryPlace(174, 10, 154, 92, 0.01),
            _DiaryPlace(18, 148, 154, 92, -0.01),
          ],
          memoryPlace: _DiaryPlace(10, 266, 178, 120, -0.005),
          statusPlace: _DiaryPlace(204, 268, 128, 86, 0.005),
          memoFooterPlace: _DiaryPlace(28, 400, 288, 54, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 246, 24, 24, 0.14),
            _DiaryPlace(18, 362, 24, 24, -0.14),
          ],
        );
      case 3:
        return const _DiaryCollageSpec(
          height: 540,
          photoPlaces: [
            _DiaryPlace(10, 0, 150, 132, -0.025),
            _DiaryPlace(184, 132, 150, 132, 0.025),
            _DiaryPlace(10, 264, 150, 132, -0.025),
          ],
          memoPlaces: [
            _DiaryPlace(174, 10, 154, 92, 0.01),
            _DiaryPlace(18, 148, 154, 92, -0.01),
            _DiaryPlace(160, 276, 165, 100, 0.01),
          ],
          memoryPlace: _DiaryPlace(150, 382, 178, 120, -0.005),
          statusPlace: _DiaryPlace(10, 410, 128, 86, 0.005),
          memoFooterPlace: _DiaryPlace(28, 510, 288, 54, 0),
          stickerPlaces: [
            _DiaryPlace(306, 10, 24, 24, 0.18),
            _DiaryPlace(304, 375, 24, 24, 0.14),
            _DiaryPlace(18, 474, 24, 24, -0.14),
          ],
        );
      case 4:
        return const _DiaryCollageSpec(
          height: 640,
          photoPlaces: [
            _DiaryPlace(10, 0, 126, 112, -0.025),
            _DiaryPlace(208, 104, 126, 112, 0.025),
            _DiaryPlace(10, 208, 126, 112, -0.025),
            _DiaryPlace(185, 312, 140, 140, 0.025),
          ],
          memoPlaces: [
            _DiaryPlace(150, 8, 176, 92, 0.01),
            _DiaryPlace(50, 118, 150, 80, -0.01),
            _DiaryPlace(150, 216, 176, 92, 0.01),
            _DiaryPlace(30, 336, 150, 80, -0.01),
          ],
          memoryPlace: _DiaryPlace(10, 430, 178, 120, -0.005),
          statusPlace: _DiaryPlace(196, 460, 128, 86, 0.005),
          memoFooterPlace: _DiaryPlace(28, 560, 288, 56, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 430, 24, 24, 0.14),
            _DiaryPlace(18, 546, 24, 24, -0.14),
          ],
        );
      default:
        return const _DiaryCollageSpec(
          height: 710,
          photoPlaces: [
            _DiaryPlace(10, -5, 140, 130, -0.025),
            _DiaryPlace(218, 85, 116, 104, 0.025),
            _DiaryPlace(10, 180, 116, 104, -0.025),
            _DiaryPlace(170, 260, 140, 130, 0.025),
            _DiaryPlace(10, 368, 116, 104, -0.025),
          ],
          memoPlaces: [
            _DiaryPlace(140, 6, 188, 70, 0.01),
            _DiaryPlace(80, 110, 150, 80, -0.01),
            _DiaryPlace(120, 190, 188, 70, 0.01),
            _DiaryPlace(18, 290, 150, 80, -0.01),
            _DiaryPlace(130, 390, 188, 70, 0.01),
          ],
          memoryPlace: _DiaryPlace(10, 490, 178, 120, -0.005),
          statusPlace: _DiaryPlace(204, 490, 128, 86, 0.005),
          memoFooterPlace: _DiaryPlace(28, 625, 288, 60, 0),
          stickerPlaces: [
            _DiaryPlace(306, 2, 24, 24, 0.18),
            _DiaryPlace(304, 482, 24, 24, 0.50),
            _DiaryPlace(18, 600, 24, 24, -0.14),
          ],
        );
    }
  }
}

class _DiaryPlace {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  const _DiaryPlace(this.x, this.y, this.width, this.height, this.rotation);

  _DiaryPlace copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    return _DiaryPlace(
      x ?? this.x,
      y ?? this.y,
      width ?? this.width,
      height ?? this.height,
      rotation ?? this.rotation,
    );
  }
}

class _DiaryCanvasStickers extends StatelessWidget {
  final List<String> stickers;
  final List<_DiaryPlace> places;
  final int seed;

  const _DiaryCanvasStickers({
    required this.stickers,
    required this.places,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    if (stickers.isEmpty) return const SizedBox.shrink();
    final random = Random(seed);
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: places.map((place) {
          final asset = stickers[random.nextInt(stickers.length)];
          final safeLeft = min(place.x, 344 - place.width - 18);
          return Positioned(
            left: max(8, safeLeft),
            top: place.y,
            width: place.width,
            height: place.height,
            child: Transform.rotate(
              angle: place.rotation,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DiaryCharacterPair extends StatelessWidget {
  final CharacterDraft userCharacter;
  final bool includeCrew;
  final List<CharacterDraft> crewCharacters;
  final List<CrewOotdAppearance> crewAppearances;

  const _DiaryCharacterPair({
    required this.userCharacter,
    required this.includeCrew,
    this.crewCharacters = const [],
    this.crewAppearances = const [],
  });

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[
      PixelCharacterWidget(
        character: userCharacter,
        size: 50,
        showShadow: false,
      ),
      if (includeCrew && crewAppearances.isNotEmpty)
        ...crewAppearances
            .take(4)
            .map((appearance) => _crewAppearanceAvatar(appearance, size: 44))
      else if (includeCrew)
        ...crewCharacters
            .take(4)
            .map(
              (character) => PixelCharacterWidget(
                character: character,
                size: 44,
                showShadow: false,
              ),
            ),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 2,
      runSpacing: 0,
      children: widgets,
    );
  }
}

class _DiaryHeader extends StatelessWidget {
  final OotdRecord record;

  const _DiaryHeader({required this.record});

  @override
  Widget build(BuildContext context) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return Column(
      children: [
        Text(
          '${record.date.year}.${record.date.month.toString().padLeft(2, '0')}.${record.date.day.toString().padLeft(2, '0')} (${weekdays[record.date.weekday - 1]})',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSub),
        ),
        SizedBox(height: 4),
        Text(
          record.brands['title']?.trim().isNotEmpty == true
              ? record.brands['title']!.trim()
              : '하루 일과 기록',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: record.moodTags
              .map(
                (tag) => Text(
                  tag,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSub,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _DiaryPhotoCard extends StatelessWidget {
  final int index;
  final String? imageUrl;
  final String tapeAsset;
  final String clipAsset;
  final String backgroundAsset;
  final bool useBackgroundPaper;
  final bool useClip;
  final double rotation;

  const _DiaryPhotoCard({
    required this.index,
    required this.imageUrl,
    required this.tapeAsset,
    required this.clipAsset,
    required this.backgroundAsset,
    required this.useBackgroundPaper,
    required this.useClip,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (useBackgroundPaper)
            Positioned.fill(
              child: Transform.rotate(
                angle: 0.08,
                child: Image.asset(
                  backgroundAsset,
                  fit: BoxFit.fill,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(useBackgroundPaper ? 10 : 0),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgDefault,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lineSoft),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A6B4A3D),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: imageUrl == null || imageUrl!.isEmpty
                      ? Container(
                          color: AppColors.bgPurpleSoft,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textSub,
                          ),
                        )
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.bgPurpleSoft,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textSub,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (useClip)
            Positioned(
              top: -14,
              left: -8,
              child: Image.asset(
                clipAsset,
                width: 42,
                height: 52,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            )
          else if (!useBackgroundPaper) ...[
            Positioned(
              top: -12,
              left: index.isEven ? 8 : null,
              right: index.isEven ? null : 8,
              child: Image.asset(
                tapeAsset,
                width: 66,
                height: 26,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            if (index.isEven)
              Positioned(
                bottom: -10,
                right: 2,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Image.asset(
                    tapeAsset,
                    width: 58,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DiaryPhotoMemoCard extends StatelessWidget {
  final int index;
  final String text;
  final String scratchAsset;
  final bool useScratchPaper;

  const _DiaryPhotoMemoCard({
    required this.index,
    required this.text,
    required this.scratchAsset,
    required this.useScratchPaper,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: BoxConstraints(minHeight: useScratchPaper ? 0 : 112),
      padding: EdgeInsets.fromLTRB(
        useScratchPaper ? 16 : 14,
        useScratchPaper ? 12 : 14,
        useScratchPaper ? 14 : 14,
        useScratchPaper ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: useScratchPaper
            ? Colors.transparent
            : AppColors.bgDefault.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: useScratchPaper ? null : Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PHOTO ${index + 1}',
            style:
                (useScratchPaper
                        ? AppTextStyles.tiny
                        : AppTextStyles.labelSmall)
                    .copyWith(
                      color: AppColors.accentBrown,
                      fontSize: useScratchPaper ? 9 : 9,
                    ),
          ),
          SizedBox(height: useScratchPaper ? 3 : 5),
          Text(
            text,
            maxLines: useScratchPaper ? 2 : 2,
            overflow: TextOverflow.ellipsis,
            style:
                (useScratchPaper ? AppTextStyles.tiny : AppTextStyles.bodySmall)
                    .copyWith(
                      color: AppColors.textMain,
                      fontSize: useScratchPaper ? 10 : 10,
                      height: useScratchPaper ? 1.18 : 1.18,
                    ),
          ),
        ],
      ),
    );

    if (!useScratchPaper) return content;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            scratchAsset,
            fit: BoxFit.fill,
            errorBuilder: (_, _, _) => Container(
              decoration: BoxDecoration(
                color: AppColors.bgDefault.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lineSoft),
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }
}

class _DiaryEmptyPhotoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Text(
        '사진을 추가하지 않아 오늘은 메모만 기록했어요.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSub,
          height: 1.45,
        ),
      ),
    );
  }
}

class _DiaryMemoFooter extends StatelessWidget {
  final String memo;
  final String stampAsset;

  const _DiaryMemoFooter({required this.memo, required this.stampAsset});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 58, 12),
          decoration: BoxDecoration(
            color: AppColors.bgDefault.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Text(
            memo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSub,
              height: 1.35,
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: -16,
          child: Image.asset(
            stampAsset,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _DiaryTodayMemoryBlock extends StatelessWidget {
  final List<String> places;

  const _DiaryTodayMemoryBlock({required this.places});

  static double estimatedHeight(int placeCount) {
    if (placeCount <= 0) {
      return 0;
    }
    final visibleCount = placeCount <= 4 ? placeCount : 5;
    return 42 + visibleCount * 20;
  }

  @override
  Widget build(BuildContext context) {
    final visiblePlaces = places.take(4).toList(growable: false);
    final overflowCount = places.length - visiblePlaces.length;
    final rows = visiblePlaces.isEmpty
        ? const [
            '\uC5F0\uACB0\uB41C \uC57D\uC18D \uC7A5\uC18C\uAC00 \uC5C6\uC5B4\uC694',
          ]
        : [
            ...visiblePlaces,
            if (overflowCount > 0) '+ $overflowCount\uAC1C \uC7A5\uC18C',
          ];
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S MEMORY",
            style: AppTextStyles.tiny.copyWith(color: AppColors.textMain),
          ),
          const SizedBox(height: 5),
          ...rows.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 5),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.textMuted),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tiny.copyWith(
                        color: AppColors.textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryTodayStatusBlock extends StatelessWidget {
  final OotdRecord record;
  final bool expanded;

  const _DiaryTodayStatusBlock({required this.record, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDefault.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S STATUS",
            style: AppTextStyles.tiny.copyWith(color: AppColors.textMain),
          ),
          const SizedBox(height: 8),
          if (expanded)
            Row(
              children: [
                Expanded(
                  child: _statusLine(
                    'MOOD',
                    _dailyMoodIcon(record.mood),
                    record.mood,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statusLine(
                    'WEATHER',
                    _dailyWeatherIcon(record.weather),
                    record.weather,
                  ),
                ),
              ],
            )
          else ...[
            _statusLine('MOOD', _dailyMoodIcon(record.mood), record.mood),
            const SizedBox(height: 3),
            _statusLine(
              'WEATHER',
              _dailyWeatherIcon(record.weather),
              record.weather,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusLine(String label, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primaryPink),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            '$label  $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.tiny.copyWith(color: AppColors.textMain),
          ),
        ),
      ],
    );
  }
}

class _CleanPhotoCard extends StatelessWidget {
  final int index;
  final TimelineItem item;

  const _CleanPhotoCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMain.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: index.isEven
                    ? AppColors.primaryPinkSoft
                    : AppColors.primaryPurpleSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? const Icon(Icons.photo_outlined, color: AppColors.textSub)
                  : Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textSub,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  item.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSub,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanOotdBlock extends StatelessWidget {
  final OotdRecord ootdRecord;

  const _CleanOotdBlock({required this.ootdRecord});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPurpleSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          OotdGeneratedImageView(
            record: ootdRecord,
            characterSize: 62,
            width: 78,
            height: 78,
            preferAvatarImage: true,
            showFallbackCharacter: false,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              ootdRecord.moodTags.take(4).join(' '),
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textMain,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanPeopleBlock extends StatelessWidget {
  final CharacterDraft userCharacter;
  final bool includeCrew;
  final List<CharacterDraft> crewCharacters;
  final List<CrewOotdAppearance> crewAppearances;

  const _CleanPeopleBlock({
    required this.userCharacter,
    required this.includeCrew,
    this.crewCharacters = const [],
    this.crewAppearances = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasCrew =
        includeCrew &&
        (crewAppearances.isNotEmpty || crewCharacters.isNotEmpty);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                PixelCharacterWidget(character: userCharacter, size: 52),
                if (hasCrew && crewAppearances.isNotEmpty)
                  ...crewAppearances
                      .take(4)
                      .map(
                        (appearance) =>
                            _crewAppearanceAvatar(appearance, size: 48),
                      )
                else if (hasCrew)
                  ...crewCharacters
                      .take(4)
                      .map(
                        (character) => PixelCharacterWidget(
                          character: character,
                          size: 48,
                        ),
                      ),
              ],
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              hasCrew
                  ? '\uD568\uAED8\uD55C \uD06C\uB8E8\uC640 \uC624\uB298\uC758 \uBD84\uC704\uAE30\uB97C \uAE30\uB85D\uD588\uC5B4\uC694.'
                  : '\uD568\uAED8\uD55C \uD06C\uB8E8\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4. \uD63C\uC790\uB9CC\uC758 \uD558\uB8E8\uB97C \uAE30\uB85D\uD588\uC5B4\uC694.',

              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSub,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetaRow extends StatelessWidget {
  final String mood;
  final String weather;
  final int photoCount;

  const _ResultMetaRow({
    required this.mood,
    required this.weather,
    required this.photoCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _meta('MOOD', mood, _dailyMoodIcon(mood))),
        Expanded(child: _meta('WEATHER', weather, _dailyWeatherIcon(weather))),
        Expanded(
          child: _meta('PHOTO', '$photoCount장', Icons.photo_library_outlined),
        ),
      ],
    );
  }

  Widget _meta(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryPink, size: 18),
        SizedBox(height: 5),
        Text(
          label,
          style: AppTextStyles.tiny.copyWith(color: AppColors.accentBrown),
        ),
        SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMain),
        ),
      ],
    );
  }
}

IconData _dailyMoodIcon(String mood) {
  switch (mood) {
    case '?됱삩':
      return Icons.self_improvement;
    case '?됰났':
      return Icons.sentiment_very_satisfied;
    case '?좊궓':
      return Icons.celebration;
    case '?쇨낀':
      return Icons.mode_night;
    default:
      return Icons.sentiment_satisfied_alt;
  }
}

IconData _dailyWeatherIcon(String weather) {
  switch (weather) {
    case '맑음':
    case 'sunny':
      return Icons.wb_sunny;
    case '흐림':
    case 'cloudy':
      return Icons.cloud;
    case '비':
    case 'rain':
    case 'rainy':
      return Icons.water_drop;
    case '눈':
    case 'snow':
    case 'snowy':
      return Icons.ac_unit;
    default:
      return Icons.wb_sunny_outlined;
  }
}
