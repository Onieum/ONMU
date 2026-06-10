import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/group/presentation/widgets/group_memory_photo.dart';

void main() {
  testWidgets('GroupMemoryPhoto uses Image.network when imageUrl exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      const SizedBox(
        width: 120,
        height: 90,
        child: GroupMemoryPhoto(
          index: 0,
          imageUrl: 'https://dev-api.onmu.cloud/api/v1/media/public?key=test',
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    expect(find.byType(CustomPaint), findsNothing);
  });

  testWidgets('GroupMemoryPhoto keeps painter fallback without imageUrl', (
    tester,
  ) async {
    await tester.pumpWidget(
      const SizedBox(width: 120, height: 90, child: GroupMemoryPhoto(index: 1)),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
