import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/oauth_provider_credential.dart';

typedef NaverAuthUrlLauncher = Future<bool> Function(Uri uri);
typedef NaverInitialLinkReader = Future<Uri?> Function();
typedef NaverLinkStreamReader = Stream<Uri> Function();
typedef NaverStateGenerator = String Function();

class NaverOAuthCredentialLoader {
  NaverOAuthCredentialLoader({
    this.clientId = _defaultClientId,
    this.redirectUri = _defaultRedirectUri,
    this.callbackScheme = _defaultCallbackScheme,
    this.callbackHost = _defaultCallbackHost,
    this.callbackPath = _defaultCallbackPath,
    this.timeout = _defaultTimeout,
    NaverAuthUrlLauncher? launchAuthUrl,
    NaverInitialLinkReader? initialLinkReader,
    NaverLinkStreamReader? linkStreamReader,
    NaverStateGenerator? stateGenerator,
  }) : _launchAuthUrl = launchAuthUrl ?? _launchExternalUrl,
       _initialLinkReader = initialLinkReader ?? _defaultInitialLinkReader,
       _linkStreamReader = linkStreamReader ?? _defaultLinkStreamReader,
       _stateGenerator = stateGenerator ?? _generateState;

  static const _defaultClientId = String.fromEnvironment(
    'NAVER_OAUTH_CLIENT_ID',
  );
  static const _defaultRedirectUri = String.fromEnvironment(
    'NAVER_OAUTH_REDIRECT_URI',
    defaultValue: 'https://dev-api.onmu.cloud/api/v1/auth/oauth/naver/callback',
  );
  static const _defaultCallbackScheme = 'io.onieum.onmu';
  static const _defaultCallbackHost = 'oauth';
  static const _defaultCallbackPath = '/naver/callback';
  static const _defaultTimeout = Duration(minutes: 3);

  final String clientId;
  final String redirectUri;
  final String callbackScheme;
  final String callbackHost;
  final String callbackPath;
  final Duration timeout;
  final NaverAuthUrlLauncher _launchAuthUrl;
  final NaverInitialLinkReader _initialLinkReader;
  final NaverLinkStreamReader _linkStreamReader;
  final NaverStateGenerator _stateGenerator;

  Future<OAuthProviderCredential> call() async {
    final resolvedClientId = clientId.trim();
    final resolvedRedirectUri = redirectUri.trim();
    if (resolvedClientId.isEmpty) {
      throw const NaverSignInMissingClientIdException();
    }
    if (resolvedRedirectUri.isEmpty) {
      throw const NaverSignInMissingRedirectUriException();
    }

    final state = _stateGenerator();
    final authUrl = Uri.https('nid.naver.com', '/oauth2.0/authorize', {
      'response_type': 'code',
      'client_id': resolvedClientId,
      'redirect_uri': resolvedRedirectUri,
      'state': state,
    });

    final launched = await _launchAuthUrl(authUrl);
    if (!launched) {
      throw const NaverSignInLaunchException();
    }

    return _waitForCallback(state).timeout(
      timeout,
      onTimeout: () => throw const NaverSignInTimeoutException(),
    );
  }

  Future<OAuthProviderCredential> _waitForCallback(String expectedState) async {
    final completer = Completer<OAuthProviderCredential>();
    StreamSubscription<Uri>? subscription;

    void completeFromUri(Uri uri) {
      if (completer.isCompleted || !_isNaverCallback(uri)) {
        return;
      }
      if (uri.queryParameters['state'] != expectedState) {
        return;
      }
      final error = uri.queryParameters['error'];
      if (error != null && error.trim().isNotEmpty) {
        completer.completeError(const NaverSignInCancelledException());
        return;
      }
      final code = uri.queryParameters['code'];
      if (code == null || code.trim().isEmpty) {
        completer.completeError(const NaverSignInCallbackException());
        return;
      }
      completer.complete(
        OAuthProviderCredential(
          provider: 'naver',
          authorizationCode: code.trim(),
          state: expectedState,
        ),
      );
    }

    subscription = _linkStreamReader().listen(
      completeFromUri,
      onError: completer.completeError,
    );

    final initialLink = await _initialLinkReader();
    if (initialLink != null) {
      completeFromUri(initialLink);
    }

    return completer.future.whenComplete(() => subscription?.cancel());
  }

  bool _isNaverCallback(Uri uri) {
    return uri.scheme == callbackScheme &&
        uri.host == callbackHost &&
        uri.path == callbackPath;
  }

  static Future<bool> _launchExternalUrl(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<Uri?> _defaultInitialLinkReader() {
    return AppLinks().getInitialLink();
  }

  static Stream<Uri> _defaultLinkStreamReader() {
    return AppLinks().uriLinkStream;
  }

  static String _generateState() {
    final random = Random.secure();
    const alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      32,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}

class NaverSignInMissingClientIdException implements Exception {
  const NaverSignInMissingClientIdException();
}

class NaverSignInMissingRedirectUriException implements Exception {
  const NaverSignInMissingRedirectUriException();
}

class NaverSignInLaunchException implements Exception {
  const NaverSignInLaunchException();
}

class NaverSignInTimeoutException implements Exception {
  const NaverSignInTimeoutException();
}

class NaverSignInCancelledException implements Exception {
  const NaverSignInCancelledException();
}

class NaverSignInCallbackException implements Exception {
  const NaverSignInCallbackException();
}
