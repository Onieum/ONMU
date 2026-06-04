import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildPlatformGoogleSignInButton() {
  return web.renderButton(
    configuration: web.GSIButtonConfiguration(
      size: web.GSIButtonSize.large,
      shape: web.GSIButtonShape.rectangular,
      text: web.GSIButtonText.signinWith,
      theme: web.GSIButtonTheme.outline,
      type: web.GSIButtonType.standard,
      logoAlignment: web.GSIButtonLogoAlignment.left,
      minimumWidth: 240,
      locale: 'ko',
    ),
  );
}
