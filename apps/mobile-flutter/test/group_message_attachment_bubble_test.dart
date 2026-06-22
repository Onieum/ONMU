import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/group/repository/media_repository.dart';
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

  testWidgets('내 채팅 말풍선은 sender 이름 라벨을 숨긴다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: GroupMessage(
              sender: '나',
              message: '사진 좋아요',
              timeLabel: '방금',
              isMine: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('나'), findsNothing);
    expect(find.text('사진 좋아요'), findsOneWidget);
    expect(find.text('방금'), findsOneWidget);
  });

  testWidgets('여러 첨부 이미지는 하나의 그리드 말풍선으로 렌더링한다', (tester) async {
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
                  storageKey: 'records/media/photo-1.jpg',
                ),
                GroupMessageAttachment(
                  type: 'image',
                  publicUrl: '',
                  storageKey: 'records/media/photo-2.jpg',
                ),
                GroupMessageAttachment(
                  type: 'image',
                  publicUrl: '',
                  storageKey: 'records/media/photo-3.jpg',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.broken_image_outlined), findsNWidgets(3));
    expect(find.text('방금'), findsOneWidget);
  });

  testWidgets('첨부 이미지를 탭하면 전체 화면 viewer를 연다', (tester) async {
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

    await tester.tap(find.byTooltip('사진 크게 보기'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 1'), findsNothing);
  });

  testWidgets('선택한 사진 tray는 추가, 삭제, 전체 삭제 액션을 제공한다', (tester) async {
    var addCount = 0;
    var removedIndex = -1;
    var clearCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposerImageTray(
            images: const [
              PickedChatImage(
                path: '/tmp/missing-1.jpg',
                fileName: 'photo-1.jpg',
              ),
              PickedChatImage(
                path: '/tmp/missing-2.jpg',
                fileName: 'photo-2.jpg',
              ),
            ],
            onAddImage: () => addCount += 1,
            onRemoveImage: (index) => removedIndex = index,
            onClearImages: () => clearCount += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('사진 2장 선택됨'), findsOneWidget);

    await tester.tap(find.byTooltip('사진 더 추가'));
    await tester.tap(find.byTooltip('photo-1.jpg 제거'));
    await tester.tap(find.text('전체 삭제'));

    expect(addCount, 1);
    expect(removedIndex, 0);
    expect(clearCount, 1);
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
