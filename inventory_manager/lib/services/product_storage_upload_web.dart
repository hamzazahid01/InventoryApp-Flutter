import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Web uses bytes (no dart:io [File]); behavior matches awaited upload semantics.
Future<TaskSnapshot> uploadProductCoverImpl(
  Reference ref,
  XFile file,
  SettableMetadata meta,
) async {
  final bytes = await file.readAsBytes();
  return await ref.putData(bytes, meta);
}
