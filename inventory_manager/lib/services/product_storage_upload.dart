import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'product_storage_upload_mobile.dart'
    if (dart.library.html) 'product_storage_upload_web.dart' as storage_impl;

/// Awaited Storage upload (`putFile` on mobile/desktop, `putData` on web).
///
/// Returns the completed [TaskSnapshot] so callers can do
/// `snapshot.ref.getDownloadURL()` reliably.
Future<TaskSnapshot> uploadProductCover(
  Reference ref,
  XFile file,
  SettableMetadata meta,
) {
  return storage_impl.uploadProductCoverImpl(ref, file, meta);
}
