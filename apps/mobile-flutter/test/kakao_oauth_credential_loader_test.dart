import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/auth/data/kakao_oauth_credential_loader.dart';

void main() {
  test('loads Kakao authorization code without exposing client secret', () async {
    final links = StreamController<Uri>();
    Uri? launchedUri;
    final loader = KakaoOAuthCredentialLoader(
      clientId: 'rest-api-key',
      redirectUri:
          'https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback',
      stateGenerator: () => 'state-123',
      initialLinkReader: () async => null,
      linkStreamReader: () => links.stream,
      launchAuthUrl: (uri) async {
        launchedUri = uri;
        scheduleMicrotask(() {
          links.add(
            Uri.parse(
              'io.onieum.onmu://oauth/kakao/callback?code=auth-code&state=state-123',
            ),
          );
        });
        return true;
      },
      timeout: const Duration(seconds: 1),
    );

    final credential = await loader.call();
    await links.close();

    expect(credential.provider, 'kakao');
    expect(credential.authorizationCode, 'auth-code');
    expect(credential.state, 'state-123');
    expect(credential.providerAccessToken, isNull);
    expect(launchedUri?.host, 'kauth.kakao.com');
    expect(launchedUri?.path, '/oauth/authorize');
    expect(launchedUri?.queryParameters['client_id'], 'rest-api-key');
    expect(launchedUri?.queryParameters['redirect_uri'], contains('dev-api'));
    expect(launchedUri?.queryParameters['state'], 'state-123');
    expect(launchedUri?.queryParameters.containsKey('client_secret'), isFalse);
  });

  test('fails before launch when Kakao REST API key is missing', () async {
    final loader = KakaoOAuthCredentialLoader(
      clientId: '',
      initialLinkReader: () async => null,
      linkStreamReader: () => const Stream.empty(),
      launchAuthUrl: (_) async => true,
    );

    await expectLater(
      loader.call(),
      throwsA(isA<KakaoSignInMissingClientIdException>()),
    );
  });
}
