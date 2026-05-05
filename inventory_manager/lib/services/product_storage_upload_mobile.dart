import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Awaited upload. Gallery picks on Android usually return `content://` URIs;
/// [putFile] cannot read those, so we use [putData] from bytes in that case.
Future<TaskSnapshot> uploadProductCoverImpl(
  Reference ref,
  XFile file,
  SettableMetadata meta,
) async {
  final raw = file.path;

  if (raw.isEmpty || raw.startsWith('content://')) {
    final bytes = await file.readAsBytes();
    return await ref.putData(bytes, meta);
  }

  try {
    final ioFile = raw.startsWith('file://')
        ? File(Uri.parse(raw).toFilePath())
        : File(raw);
    if (await ioFile.exists()) {
      return await ref.putFile(ioFile, meta);
    }
  } catch (e, st) {
    debugPrint('Storage putFile failed, falling back to putData: $e');
    debugPrintStack(stackTrace: st);
  }

  final bytes = await file.readAsBytes();
  return await ref.putData(bytes, meta);
}
