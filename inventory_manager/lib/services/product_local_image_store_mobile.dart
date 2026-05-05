import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> saveProductImageLocallyImpl(
  String productId,
  XFile picked,
) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'product_images'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final extRaw = p.extension(picked.name).trim();
    final ext = extRaw.isEmpty ? '.jpg' : extRaw;
    final targetPath = p.join(folder.path, '$productId$ext');
    final bytes = await picked.readAsBytes();
    final out = File(targetPath);
    await out.writeAsBytes(bytes, flush: true);
    return out.path;
  } catch (e, st) {
    debugPrint('Local image save failed: $e');
    debugPrintStack(stackTrace: st);
    return null;
  }
}

Future<void> deleteLocalProductImageImpl(String? localPath) async {
  final lp = localPath?.trim();
  if (lp == null || lp.isEmpty) return;
  try {
    final f = File(lp);
    if (await f.exists()) {
      await f.delete();
    }
  } catch (e) {
    debugPrint('Local image delete skipped: $e');
  }
}

