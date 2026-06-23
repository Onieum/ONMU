import 'package:flutter/services.dart';

class GalleryImageSaver {
  const GalleryImageSaver._();

  static const MethodChannel _channel = MethodChannel(
    'onmu/gallery_image_saver',
  );

  static Future<bool> savePng(
    Uint8List bytes, {
    required String fileName,
  }) async {
    if (bytes.isEmpty) return false;

    try {
      final saved = await _channel.invokeMethod<bool>('savePng', {
        'bytes': bytes,
        'fileName': fileName,
      });
      return saved ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
