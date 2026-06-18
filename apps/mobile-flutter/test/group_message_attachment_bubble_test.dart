import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/group/presentation/widgets/group_cards.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';

void main() {
  testWidgets('첨부 이미지 말풍선은 텍스트 없이도 fallback preview를 렌더링한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: GroupMessage(
              sender: '나',
              message: '',
              timeLabel: '방금',
              isMine: true,
              attachments: [
                GroupMessageAttachment(
                  type: 'image',
                  publicUrl: '',
                  storageKey: 'records/media/photo.jpg',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('방금'), findsOneWidget);
  });

  testWidgets('채팅 activity card는 서버 card event를 timeline 안에 렌더링한다', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatActivityCard(
            message: const GroupMessage(
              sender: 'ONMU',
              message: '제주도 여행 장소 투표가 열렸어요.',
              timeLabel: '14:03',
              isMine: false,
              messageType: 'vote_card',
              cardType: 'vote_card',
              planId: '101',
              voteId: '501',
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('투표가 열렸어요'), findsOneWidget);
    expect(find.text('제주도 여행 장소 투표가 열렸어요.'), findsOneWidget);
    expect(find.text('투표 보기'), findsOneWidget);
    expect(find.byIcon(Icons.how_to_vote_outlined), findsOneWidget);
  });
}
