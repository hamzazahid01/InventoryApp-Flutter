import 'package:flutter/widgets.dart';

import 'product_thumb_image_mobile.dart'
    if (dart.library.html) 'product_thumb_image_web.dart' as impl;

Widget buildLocalThumbImage({
  required String path,
  required double size,
  required Widget onError,
}) {
  return impl.buildLocalThumbImageImpl(
    path: path,
    size: size,
    onError: onError,
  );
}

