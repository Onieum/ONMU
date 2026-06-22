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
        'amountWon': 12000,
        'splitType': 'menu',
        'targetUserIds': ['user-jimin', 'user-minsu'],
      });
    });
  });

  group('SettlementPaymentParticipant', () {
    test('uses userId as selection key when display names are duplicated', () {
      const first = SettlementPaymentParticipant(
        userId: 'user-first',
        name: '지민',
        owedAmountLabel: '6,000원',
      );
      const second = SettlementPaymentParticipant(
        userId: 'user-second',
        name: '지민',
        owedAmountLabel: '6,000원',
      );
      const fallback = SettlementPaymentParticipant(
        name: '지민',
        owedAmountLabel: '6,000원',
      );

      expect(first.selectionKey, 'user-first');
      expect(second.selectionKey, 'user-second');
      expect(first.selectionKey, isNot(second.selectionKey));
      expect(fallback.selectionKey, '지민');
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

  test('maps preview settlement flag from Spring response', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'id': 'draft',
                'planTitle': '성수 브런치',
                'totalAmountLabel': '0원',
                'createdDateLabel': '미리보기',
                'itemCountLabel': '결제 항목 0개',
                'paymentItems': [],
                'memberResults': [],
                'transfers': [],
                'preview': true,
              },
            ),
          );
        },
      ),
    );

    final settlement = await ApiSettlementRepository(
      OnmuApiClient(dio),
    ).fetchSettlement(groupId: 1, planId: 101);

    expect(settlement.preview, isTrue);
    expect(settlement.isCreated, isFalse);
  });

  test(
    'maps settlement profile image aliases through common media resolver',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'id': '301',
                  'status': 'finalized',
                  'planTitle': '정산 테스트',
                  'totalAmountLabel': '12,000원',
                  'itemCountLabel': '결제 항목 1개',
                  'paymentItems': [],
                  'memberResults': [
                    {
                      'userId': 'user-b',
                      'name': 'B',
                      'profilePhotoUrl': 'dev/avatars/b.png',
                      'finalShareLabel': '0원',
                      'paidAmountLabel': '12,000원',
                      'resultLabel': '12,000원 받음',
                      'isMe': true,
                      'willReceive': true,
                    },
                  ],
                  'participantStatuses': [
                    {
                      'userId': 'user-b',
                      'name': 'B',
                      'avatarUrl': 'dev/avatars/b.png',
                      'willReceive': true,
                      'sent': false,
                      'received': true,
                      'completed': true,
                    },
                  ],
                  'transfers': [
                    {
                      'id': 'transfer-a',
                      'fromUserId': 'user-a',
                      'fromName': 'A',
                      'fromProfilePhotoUrl': 'dev/avatars/a.png',
                      'toUserId': 'user-b',
                      'toName': 'B',
                      'toAvatarUrl': 'dev/avatars/b.png',
                      'amountWon': 12000,
                      'amountLabel': '12,000원',
                      'status': 'received',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final settlement = await ApiSettlementRepository(
        OnmuApiClient(dio),
      ).fetchSettlement(groupId: 1, planId: 101);

      expect(
        settlement.memberResults.single.profileImageUrl,
        'https://api.test/api/v1/media/public?key=dev%2Favatars%2Fb.png',
      );
      expect(
        settlement.participantStatuses.single.profileImageUrl,
        'https://api.test/api/v1/media/public?key=dev%2Favatars%2Fb.png',
      );
      expect(settlement.participantStatuses.single.received, isTrue);
      expect(
        settlement.transfers.single.fromProfileImageUrl,
        'https://api.test/api/v1/media/public?key=dev%2Favatars%2Fa.png',
      );
    },
  );
}
