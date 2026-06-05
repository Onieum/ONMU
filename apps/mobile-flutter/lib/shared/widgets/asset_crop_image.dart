import 'package:flutter/material.dart';

class AssetCropImage extends StatelessWidget {
  const AssetCropImage({
    super.key,
    required this.assetPath,
    required this.imageSize,
    required this.cropRect,
    required this.width,
    this.filterQuality = FilterQuality.none,
  });

  final String assetPath;
  final Size imageSize;
  final Rect cropRect;
  final double width;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final height = width * cropRect.height / cropRect.width;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / cropRect.width;
            return OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: imageSize.width * scale,
              maxWidth: imageSize.width * scale,
              minHeight: imageSize.height * scale,
              maxHeight: imageSize.height * scale,
              child: Transform.translate(
                offset: Offset(-cropRect.left * scale, -cropRect.top * scale),
                child: SizedBox(
                  width: imageSize.width * scale,
                  height: imageSize.height * scale,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.fill,
                    filterQuality: filterQuality,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
