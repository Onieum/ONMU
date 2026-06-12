import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/auth/data/naver_oauth_credential_loader.dart';

void main() {
  test('loads Naver authorization code without exposing client secret', () async {
    final links = StreamController<Uri>();
    Uri? launchedUri;
    final loader = NaverOAuthCredentialLoader(
      clientId: 'client-id',
      redirectUri:
          'https://dev-api.onmu.cloud/api/v1/auth/oauth/naver/callback',
      stateGenerator: () => 'state-123',
      initialLinkReader: () async => null,
      linkStreamReader: () => links.stream,
      launchAuthUrl: (uri) async {
        launchedUri = uri;
        scheduleMicrotask(() {
          links.add(
            Uri.parse(
              'io.onieum.onmu://oauth/naver/callback?code=auth-code&state=state-123',
            ),
          );
        });
        return true;
      },
      timeout: const Duration(seconds: 1),
    );

    final credential = await loader.call();
    await links.close();

    expect(credential.provider, 'naver');
    expect(credential.authorizationCode, 'auth-code');
    expect(credential.state, 'state-123');
    expect(credential.providerAccessToken, isNull);
    expect(launchedUri?.host, 'nid.naver.com');
    expect(launchedUri?.queryParameters['client_id'], 'client-id');
    expect(launchedUri?.queryParameters['redirect_uri'], contains('dev-api'));
    expect(launchedUri?.queryParameters['state'], 'state-123');
    expect(launchedUri?.queryParameters.containsKey('client_secret'), isFalse);
  });

  test('fails before launch when Naver client id is missing', () async {
    final loader = NaverOAuthCredentialLoader(
      clientId: '',
      initialLinkReader: () async => null,
      linkStreamReader: () => const Stream.empty(),
      launchAuthUrl: (_) async => true,
    );

    await expectLater(
      loader.call(),
      throwsA(isA<NaverSignInMissingClientIdException>()),
    );
  });
}
