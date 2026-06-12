import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/shared/widgets/pixel_avatar.dart';

void main() {
  testWidgets('renders profile image when url is present', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PixelAvatar(
            label: '지우',
            profileImageUrl: 'https://example.test/avatar.png',
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    expect(
      (image.image as NetworkImage).url,
      'https://example.test/avatar.png',
    );
    expect(find.text('지'), findsNothing);
  });

  testWidgets('keeps pixel fallback when image url is missing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PixelAvatar(label: '지우')),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.text('지'), findsOneWidget);
  });
}
