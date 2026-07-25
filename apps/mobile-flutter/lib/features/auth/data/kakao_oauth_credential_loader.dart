import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/oauth_provider_credential.dart';

typedef KakaoAuthUrlLauncher = Future<bool> Function(Uri uri);
typedef KakaoInitialLinkReader = Future<Uri?> Function();
typedef KakaoLinkStreamReader = Stream<Uri> Function();
typedef KakaoAppResumeReader = Stream<void> Function();
typedef KakaoStateGenerator = String Function();

class KakaoOAuthCredentialLoader {
  KakaoOAuthCredentialLoader({
    this.clientId = _defaultClientId,
    this.redirectUri = _defaultRedirectUri,
    this.callbackScheme = _defaultCallbackScheme,
    this.callbackHost = _defaultCallbackHost,
    this.callbackPath = _defaultCallbackPath,
    this.timeout = _defaultTimeout,
    KakaoAuthUrlLauncher? launchAuthUrl,
    KakaoInitialLinkReader? initialLinkReader,
    KakaoLinkStreamReader? linkStreamReader,
    KakaoAppResumeReader? appResumeReader,
    KakaoStateGenerator? stateGenerator,
  }) : _launchAuthUrl = launchAuthUrl ?? _launchExternalUrl,
       _initialLinkReader = initialLinkReader ?? _defaultInitialLinkReader,
       _linkStreamReader = linkStreamReader ?? _defaultLinkStreamReader,
       _appResumeReader = appResumeReader ?? _defaultAppResumeReader,
       _stateGenerator = stateGenerator ?? _generateState;

  static const _defaultRestApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );
  static const _defaultClientIdAlias = String.fromEnvironment(
    'KAKAO_OAUTH_CLIENT_ID',
  );
  static const _defaultClientId = _defaultRestApiKey == ''
      ? _defaultClientIdAlias
      : _defaultRestApiKey;
  static const _defaultRedirectUri = String.fromEnvironment(
    'KAKAO_OAUTH_REDIRECT_URI',
    defaultValue:
        'https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback',
  );
  static const _defaultCallbackScheme = 'io.onieum.onmu';
  static const _defaultCallbackHost = 'oauth';
  static const _defaultCallbackPath = '/kakao/callback';
  static const _defaultTimeout = Duration(minutes: 3);

  final String clientId;
  final String redirectUri;
  final String callbackScheme;
  final String callbackHost;
  final String callbackPath;
  final Duration timeout;
  final KakaoAuthUrlLauncher _launchAuthUrl;
  final KakaoInitialLinkReader _initialLinkReader;
  final KakaoLinkStreamReader _linkStreamReader;
  final KakaoAppResumeReader _appResumeReader;
  final KakaoStateGenerator _stateGenerator;

  Future<OAuthProviderCredential> call() async {
    final resolvedClientId = clientId.trim();
    final resolvedRedirectUri = redirectUri.trim();
    if (resolvedClientId.isEmpty) {
      throw const KakaoSignInMissingClientIdException();
    }
    if (resolvedRedirectUri.isEmpty) {
      throw const KakaoSignInMissingRedirectUriException();
    }

    final state = _stateGenerator();
    final authUrl = Uri.https('kauth.kakao.com', '/oauth/authorize', {
      'response_type': 'code',
      'client_id': resolvedClientId,
      'redirect_uri': resolvedRedirectUri,
      'state': state,
    });

    final launched = await _launchAuthUrl(authUrl);
    if (!launched) {
      throw const KakaoSignInLaunchException();
    }

    return _waitForCallback(state).timeout(
      timeout,
      onTimeout: () => throw const KakaoSignInTimeoutException(),
    );
  }

  Future<OAuthProviderCredential> _waitForCallback(String expectedState) async {
    final completer = Completer<OAuthProviderCredential>();
    StreamSubscription<Uri>? subscription;
    StreamSubscription<void>? resumeSubscription;
    Timer? resumeCancellationTimer;

    void completeFromUri(Uri uri) {
      if (completer.isCompleted || !_isKakaoCallback(uri)) {
        return;
      }
      resumeCancellationTimer?.cancel();
      if (uri.queryParameters['state'] != expectedState) {
        return;
      }
      final error = uri.queryParameters['error'];
      if (error != null && error.trim().isNotEmpty) {
        completer.completeError(const KakaoSignInCancelledException());
        return;
      }
      final code = uri.queryParameters['code'];
      if (code == null || code.trim().isEmpty) {
        completer.completeError(const KakaoSignInCallbackException());
        return;
      }
      completer.complete(
        OAuthProviderCredential(
          provider: 'kakao',
          authorizationCode: code.trim(),
          state: expectedState,
        ),
      );
    }

    subscription = _linkStreamReader().listen(
      completeFromUri,
      onError: completer.completeError,
    );
    resumeSubscription = _appResumeReader().listen((_) {
      resumeCancellationTimer?.cancel();
      resumeCancellationTimer = Timer(const Duration(milliseconds: 700), () {
        if (!completer.isCompleted) {
          completer.completeError(const KakaoSignInCancelledException());
        }
      });
    }, onError: completer.completeError);

    final initialLink = await _initialLinkReader();
    if (initialLink != null) {
      completeFromUri(initialLink);
    }

    return completer.future.whenComplete(() {
      resumeCancellationTimer?.cancel();
      subscription?.cancel();
      resumeSubscription?.cancel();
    });
  }

  bool _isKakaoCallback(Uri uri) {
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

  static Stream<void> _defaultAppResumeReader() {
    AppLifecycleListener? listener;
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        listener = AppLifecycleListener(
          onResume: () {
            if (!controller.isClosed) {
              controller.add(null);
            }
          },
        );
      },
      onCancel: () {
        listener?.dispose();
      },
    );
    return controller.stream;
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

class KakaoSignInMissingClientIdException implements Exception {
  const KakaoSignInMissingClientIdException();
}

class KakaoSignInMissingRedirectUriException implements Exception {
  const KakaoSignInMissingRedirectUriException();
}

class KakaoSignInLaunchException implements Exception {
  const KakaoSignInLaunchException();
}

class KakaoSignInTimeoutException implements Exception {
  const KakaoSignInTimeoutException();
}

class KakaoSignInCancelledException implements Exception {
  const KakaoSignInCancelledException();
}

class KakaoSignInCallbackException implements Exception {
  const KakaoSignInCallbackException();
}
