import 'package:image_picker/image_picker.dart';

import 'product_local_image_store_mobile.dart'
    if (dart.library.html) 'product_local_image_store_web.dart' as impl;

/// Saves the picked image into app-local storage and returns a file path.
///
/// On web this returns null (no app-local filesystem).
Future<String?> saveProductImageLocally(
  String productId,
  XFile picked,
) {
  return impl.saveProductImageLocallyImpl(productId, picked);
}

/// Deletes a previously saved local image path (best-effort).
Future<void> deleteLocalProductImage(String? localPath) {
  return impl.deleteLocalProductImageImpl(localPath);
}

