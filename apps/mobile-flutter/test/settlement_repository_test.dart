import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/settlement/repository/settlement_repository.dart';
import 'package:onmu_mobile/shared/models/settlement_models.dart';

void main() {
  group('SettlementDraftItemInput', () {
    test('serializes Spring settlement item request body', () {
      final item = SettlementDraftItemInput(
        id: 401,
        title: '커피',
        amount: 12000,
        payerUserId: 'user-jimin',
        payerName: '지민',
        splitType: SettlementSplitType.custom,
        targetUserIds: ['user-jimin', 'user-minsu'],
        targetNames: ['지민', '민수'],
      );

      expect(item.toJson(), {
        'id': '401',
        'title': '커피',
        'amount': 12000,
        'amountWon': 12000,
        'payerUserId': 'user-jimin',
        'payerName': '지민',
        'splitType': 'custom',
        'targetUserIds': ['user-jimin', 'user-minsu'],
        'targetNames': ['지민', '민수'],
      });
    });
  });
}
