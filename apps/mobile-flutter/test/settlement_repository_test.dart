import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
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

  test(
    'does not synthesize summary copy when settlement summary is missing',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'id': 301,
                  'planTitle': '성수 브런치',
                  'totalAmountLabel': '0원',
                  'itemCountLabel': '결제 항목 0개',
                  'paymentItems': [],
                  'memberResults': [],
                  'transfers': [],
                },
              ),
            );
          },
        ),
      );

      final settlement = await ApiSettlementRepository(
        OnmuApiClient(dio),
      ).fetchSettlement(groupId: 1, planId: 101);

      expect(settlement.finalSummaryLabel, isEmpty);
      expect(settlement.displayFinalSummaryLabel, '정산 요약 없음');
    },
  );
}
