import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';

void main() {
  test(
    'date-specific memory places only return places for the selected day',
    () {
      final plan = GroupPlanSummary(
        id: 1,
        title: '수원에서 만나요',
        dateLabel: '2026.06.22',
        placeName: '수원',
        statusLabel: '예정',
        statusType: 'scheduled',
        memberCount: 4,
        extraMemberCount: 0,
        iconKind: 'coffee',
        isPast: false,
        memoryPlaceNames: const ['사계면반 영통본점', '누크녹 행궁점'],
        memoryPlaceNamesByDate: const {
          '2026-06-22': ['사계면반 영통본점'],
          '2026-06-23': ['누크녹 행궁점'],
        },
      );

      expect(plan.memoryPlaceNamesFor(DateTime(2026, 6, 22)), const [
        '사계면반 영통본점',
      ]);
      expect(plan.memoryPlaceNamesFor(DateTime(2026, 6, 23)), const [
        '누크녹 행궁점',
      ]);
      expect(plan.memoryPlaceNamesFor(DateTime(2026, 6, 24)), isEmpty);
    },
  );
}
