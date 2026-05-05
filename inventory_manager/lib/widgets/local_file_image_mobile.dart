import 'dart:io';

import 'package:flutter/widgets.dart';

Widget buildLocalFileImageImpl({
  required String path,
  required BoxFit fit,
  required Widget onError,
}) {
  return Image.file(
    File(path),
    fit: fit,
    filterQuality: FilterQuality.medium,
    errorBuilder: (context, error, stackTrace) => onError,
  );
}

