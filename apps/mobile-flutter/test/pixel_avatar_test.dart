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

  testWidgets('resolves dev avatar key through public media route', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PixelAvatar(
            label: '나',
            profileImageUrl: 'dev/avatars/user-me.png',
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      'https://dev-api.onmu.cloud/api/v1/media/public?key=dev%2Favatars%2Fuser-me.png',
    );
    expect(find.text('나'), findsNothing);
  });

  testWidgets('shows person icon fallback when image url is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PixelAvatar(label: '지우')),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.text('지'), findsNothing);
  });

  testWidgets('shows person icon fallback when profile image fails to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PixelAvatar(
            label: '지우',
            profileImageUrl: 'https://example.test/missing.png',
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final fallback = image.errorBuilder!(
      tester.element(find.byType(Image)),
      Exception('load failed'),
      StackTrace.current,
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: fallback)));

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.text('지'), findsNothing);
  });
}
