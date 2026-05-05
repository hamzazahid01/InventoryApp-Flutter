import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../models/sale_record.dart';
import 'product_local_image_store.dart';
import 'product_storage_upload.dart';

/// Result for operations where image upload is optional.
///
/// - [imageUrl] is set only if upload succeeded.
/// - [imageError] is set only if an image was provided but upload failed.
typedef ProductImageResult = ({
  String? imageUrl,
  String? localImagePath,
  String? imageError,
});

/// Firestore + Storage backing for inventory.
///
/// Deploy rules before production ([firestore.rules] / [storage.rules] templates
/// live in `/firebase`; tighten to [request.auth != null] when you add sign-in.)
class FirebaseService {
  FirebaseService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ??
            (() {
              final bucket = Firebase.app().options.storageBucket?.trim();
              if (bucket == null || bucket.isEmpty) {
                debugPrint(
                  'Firebase Storage bucket is empty in FirebaseOptions; using default instance.',
                );
                return FirebaseStorage.instance;
              }
              // Force bucket selection to avoid accidental mismatches from stale
              // native config or default app resolution.
              final gs = bucket.startsWith('gs://') ? bucket : 'gs://$bucket';
              debugPrint('Firebase Storage instanceFor bucket=$gs');
              return FirebaseStorage.instanceFor(bucket: gs);
            })();

  static const productsCollection = 'products';
  static const salesCollection = 'sales';

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _db.collection(productsCollection);

  CollectionReference<Map<String, dynamic>> get _salesRef =>
      _db.collection(salesCollection);

  // --- Real-time streams ---

  Stream<List<Product>> watchProducts() {
    return _productsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_productFromDoc).toList());
  }

  Stream<List<SaleRecord>> watchSales() {
    return _salesRef
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_saleFromDoc).toList());
  }

  String? _readOptionalString(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final s = v.trim();
      return s.isEmpty ? null : s;
    }
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  Product _productFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Product(
      id: d.id,
      name: m['name'] as String? ?? '',
      price: (m['price'] as num?)?.toDouble() ?? 0,
      stock: (m['stock'] as num?)?.toInt() ?? 0,
      sold: (m['sold'] as num?)?.toInt() ?? 0,
      category: _readOptionalString(m['category']),
      imageUrl: _readOptionalString(m['imageUrl']),
      localImagePath: _readOptionalString(m['localImagePath']),
      createdAt: _readDate(m['createdAt']),
    );
  }

  SaleRecord _saleFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return SaleRecord(
      id: d.id,
      productId: m['productId'] as String? ?? '',
      productName: m['productName'] as String? ?? '',
      quantity: (m['quantity'] as num?)?.toInt() ?? 0,
      totalPrice: (m['totalPrice'] as num?)?.toDouble() ?? 0,
      dateTime: _readDate(m['dateTime']),
    );
  }

  DateTime _readDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> _productWriteMap(Product p) {
    return {
      'name': p.name,
      'price': p.price,
      'stock': p.stock,
      'sold': p.sold,
      'createdAt': Timestamp.fromDate(p.createdAt),
      if (p.category != null && p.category!.trim().isNotEmpty)
        'category': p.category!.trim(),
      if (p.imageUrl != null && p.imageUrl!.trim().isNotEmpty)
        'imageUrl': p.imageUrl!.trim(),
      if (p.localImagePath != null && p.localImagePath!.trim().isNotEmpty)
        'localImagePath': p.localImagePath!.trim(),
    };
  }

  String _contentTypeForFile(XFile file) {
    final n = file.name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  /// One cover per SKU path: `products/{uniqueId}.jpg` — upload is fully awaited,
  /// then URL is retrieved. Returns `null` on failure so callers can save without blocking.
  Future<ProductImageResult> _uploadCoverDownloadUrlOrNull(
    String uniqueId,
    XFile file,
  ) async {
    try {
      final ref = _storage.ref().child('products/$uniqueId.jpg');
      final meta = SettableMetadata(contentType: _contentTypeForFile(file));
      debugPrint('Uploading to bucket=${ref.bucket} path=${ref.fullPath}');
      final snap = await uploadProductCover(ref, file, meta);
      // Use snapshot ref to avoid any timing/race edge cases.
      final url = await snap.ref.getDownloadURL();
      debugPrint('Image uploaded OK: ${snap.ref.fullPath}');
      return (imageUrl: url, localImagePath: null, imageError: null);
    } on FirebaseException catch (e, st) {
      debugPrint('Product image upload failed ($uniqueId): ${e.code} ${e.message}');
      debugPrintStack(stackTrace: st);
      return (
        imageUrl: null,
        localImagePath: null,
        imageError: '${e.code}: ${e.message ?? 'Firebase error'}',
      );
    } catch (e, st) {
      debugPrint('Product image upload failed ($uniqueId): $e');
      debugPrintStack(stackTrace: st);
      return (imageUrl: null, localImagePath: null, imageError: e.toString());
    }
  }

  Future<void> _deleteObjectIfUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      await _storage.refFromURL(url.trim()).delete();
    } catch (e) {
      debugPrint('Storage delete skipped: $e');
    }
  }

  /// If [image] is set: uploads first (awaited), then saves Firestore doc with optional [imageUrl].
  /// Upload failure yields `imageUrl == null`; product save still succeeds.
  Future<({String productId, String? imageUrl, String? imageError})> createProduct({
    required String name,
    required double price,
    required int stock,
    String? category,
    XFile? image,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final cat = category?.trim();

    String? imageUrl;
    String? localImagePath;
    String? imageError;
    if (image != null) {
      final res = await _uploadCoverDownloadUrlOrNull(id, image);
      imageUrl = res.imageUrl;
      imageError = res.imageError;
      if (imageUrl == null) {
        localImagePath = await saveProductImageLocally(id, image);
      }
    }

    final p = Product(
      id: id,
      name: name.trim(),
      price: price,
      stock: stock,
      sold: 0,
      category: (cat == null || cat.isEmpty) ? null : cat,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      createdAt: now,
    );

    await _productsRef.doc(id).set(_productWriteMap(p));
    return (productId: id, imageUrl: imageUrl, imageError: imageError);
  }

  /// Field updates plus optional image swap. New image uploads first when present,
  /// then a single Firestore update (no overlapping image writes).
  Future<void> updateProduct(
    Product updated, {
    XFile? newImage,
    bool removeImage = false,
  }) async {
    final doc = _productsRef.doc(updated.id);
    final previousUrl = updated.imageUrl?.trim();
    final previousLocal = updated.localImagePath?.trim();

    var touchImageField = false;
    String? nextUrl = previousUrl;
    String? nextLocal = previousLocal;

    if (removeImage && newImage == null) {
      touchImageField = true;
      nextUrl = null;
      nextLocal = null;
      await _deleteObjectIfUrl(previousUrl);
      await deleteLocalProductImage(previousLocal);
    } else if (newImage != null) {
      final res = await _uploadCoverDownloadUrlOrNull(updated.id, newImage);
      final uploaded = res.imageUrl;
      if (uploaded != null && uploaded.isNotEmpty) {
        touchImageField = true;
        if (previousUrl != null &&
            previousUrl.isNotEmpty &&
            previousUrl != uploaded) {
          await _deleteObjectIfUrl(previousUrl);
        }
        nextUrl = uploaded;
        nextLocal = null;
        await deleteLocalProductImage(previousLocal);
      } else {
        // Remote upload failed; keep app working by storing locally.
        touchImageField = true;
        nextUrl = null;
        nextLocal = await saveProductImageLocally(updated.id, newImage);
      }
    }

    final map = <String, dynamic>{
      'name': updated.name.trim(),
      'price': updated.price,
      'stock': updated.stock,
      'sold': updated.sold,
    };
    final cat = updated.category?.trim();
    if (cat != null && cat.isNotEmpty) {
      map['category'] = cat;
    } else {
      map['category'] = FieldValue.delete();
    }

    if (touchImageField) {
      if (nextUrl != null && nextUrl.isNotEmpty) {
        map['imageUrl'] = nextUrl;
      } else {
        map['imageUrl'] = FieldValue.delete();
      }
      if (nextLocal != null && nextLocal.isNotEmpty) {
        map['localImagePath'] = nextLocal;
      } else {
        map['localImagePath'] = FieldValue.delete();
      }
    }

    await doc.update(map);
  }

  Future<void> deleteProduct(String id) async {
    final snap = await _productsRef.doc(id).get();
    final data = snap.data();
    final imageUrl = data?['imageUrl'] as String?;
    final localImagePath = data?['localImagePath'] as String?;
    await _deleteObjectIfUrl(imageUrl);
    await deleteLocalProductImage(localImagePath);

    await _deleteSalesForProduct(id);
    await _productsRef.doc(id).delete();
  }

  Future<String?> sellProduct({
    required String productId,
    required int quantity,
  }) async {
    if (quantity < 1) return 'Quantity must be at least 1.';
    try {
      await _db.runTransaction((txn) async {
        final ref = _productsRef.doc(productId);
        final snap = await txn.get(ref);
        if (!snap.exists) {
          throw StateError('Product not found.');
        }
        final m = snap.data()!;
        final stock = (m['stock'] as num).toInt();
        final sold = (m['sold'] as num).toInt();
        final price = (m['price'] as num).toDouble();
        final name = m['name'] as String? ?? '';
        if (stock < quantity) {
          throw StateError('Not enough stock available.');
        }
        txn.update(ref, {
          'stock': stock - quantity,
          'sold': sold + quantity,
        });

        final saleRef = _salesRef.doc(_uuid.v4());
        txn.set(saleRef, {
          'productId': productId,
          'productName': name,
          'quantity': quantity,
          'totalPrice': price * quantity,
          'dateTime': Timestamp.fromDate(DateTime.now()),
        });
      });
      return null;
    } on StateError catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> undoSale(String saleId) async {
    try {
      await _db.runTransaction((txn) async {
        final saleRef = _salesRef.doc(saleId);
        final saleSnap = await txn.get(saleRef);
        if (!saleSnap.exists) {
          throw StateError('Sale not found.');
        }
        final sm = saleSnap.data()!;
        final productId = sm['productId'] as String? ?? '';
        final qty = (sm['quantity'] as num).toInt();

        final prodRef = _productsRef.doc(productId);
        final prodSnap = await txn.get(prodRef);
        if (!prodSnap.exists) {
          throw StateError(
            'Product was removed from inventory. Undo not available.',
          );
        }
        final pm = prodSnap.data()!;
        final stock = (pm['stock'] as num).toInt();
        final sold = (pm['sold'] as num).toInt();
        if (sold < qty) {
          throw StateError('Data mismatch; cannot undo safely.');
        }
        txn.delete(saleRef);
        txn.update(prodRef, {
          'stock': stock + qty,
          'sold': sold - qty,
        });
      });
      return null;
    } on StateError catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> resetAllFirestoreData() async {
    // Best-effort cleanup of remote/local product images before deleting docs.
    await _cleanupAllProductImages();
    await _deleteAllDocs(_salesRef);
    await _deleteAllDocs(_productsRef);
  }

  Future<void> deleteSalesInRange({
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) async {
    final from = Timestamp.fromDate(fromInclusive);
    final to = Timestamp.fromDate(toExclusive);
    final q = _salesRef
        .where('dateTime', isGreaterThanOrEqualTo: from)
        .where('dateTime', isLessThan: to);
    await _deleteAllDocsInQuery(q);
  }

  Future<void> deleteAllSales() async {
    await _deleteAllDocs(_salesRef);
  }

  Future<void> _cleanupAllProductImages() async {
    Query<Map<String, dynamic>> q =
        _productsRef.orderBy('createdAt', descending: false).limit(200);
    QueryDocumentSnapshot<Map<String, dynamic>>? last;
    while (true) {
      final snap = await (last == null ? q : q.startAfterDocument(last)).get();
      if (snap.docs.isEmpty) break;
      for (final d in snap.docs) {
        final data = d.data();
        final imageUrl = data['imageUrl'] as String?;
        final localImagePath = data['localImagePath'] as String?;
        await _deleteObjectIfUrl(imageUrl);
        await deleteLocalProductImage(localImagePath);
      }
      last = snap.docs.last;
      if (snap.docs.length < 200) break;
    }
  }

  Future<void> _deleteSalesForProduct(String productId) async {
    Query<Map<String, dynamic>> q =
        _salesRef.where('productId', isEqualTo: productId);
    await _deleteAllDocsInQuery(q);
  }

  Future<void> _deleteAllDocs(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    await _deleteAllDocsInQuery(col as Query<Map<String, dynamic>>);
  }

  Future<void> _deleteAllDocsInQuery(Query<Map<String, dynamic>> q) async {
    while (true) {
      final snap = await q.limit(500).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }
}
