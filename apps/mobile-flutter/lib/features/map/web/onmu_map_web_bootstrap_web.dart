// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

@JS('onmuPmtilesProtocolReady')
external bool? get _onmuPmtilesProtocolReady;

bool get isOnmuMapWebBootstrapReady {
  return _onmuPmtilesProtocolReady == true;
}
