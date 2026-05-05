import 'dart:io';

import 'package:flutter/widgets.dart';

Widget buildLocalThumbImageImpl({
  required String path,
  required double size,
  required Widget onError,
}) {
  final f = File(path);
  return Image.file(
    f,
    width: size,
    height: size,
    fit: BoxFit.cover,
    filterQuality: FilterQuality.medium,
    errorBuilder: (context, error, stackTrace) => onError,
  );
}

