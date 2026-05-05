import 'package:flutter/widgets.dart';

import 'local_file_image_mobile.dart'
    if (dart.library.html) 'local_file_image_web.dart' as impl;

Widget buildLocalFileImage({
  required String path,
  BoxFit fit = BoxFit.cover,
  required Widget onError,
}) {
  return impl.buildLocalFileImageImpl(
    path: path,
    fit: fit,
    onError: onError,
  );
}

