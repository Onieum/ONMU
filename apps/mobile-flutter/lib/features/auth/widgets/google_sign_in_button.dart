import 'package:flutter/widgets.dart';

import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart';

Widget buildGoogleSignInButton() {
  return buildPlatformGoogleSignInButton();
}
