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
}
