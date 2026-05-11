import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:craftbloom/features/shop/data/product_model.dart';
import 'package:craftbloom/shared/providers/firebase_providers.dart';

class ShopRepository {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  ShopRepository({required FirebaseFirestore db, required FirebaseStorage storage})
      : _db = db,
        _storage = storage;

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _packages => _db.collection('packages');

  // ── Productos ─────────────────────────────────
  Stream<List<ProductModel>> watchProducts({String? category, bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = activeOnly
        ? _products.where('isActive', isEqualTo: true)
        : _products;
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProductModel.fromDoc).toList());
  }

  Stream<ProductModel?> watchProduct(String id) {
    return _products.doc(id).snapshots().map(
          (doc) => doc.exists ? ProductModel.fromDoc(doc) : null,
        );
  }

  Future<void> incrementProductView(String id) {
    return _products.doc(id).update({'viewCount': FieldValue.increment(1)});
  }

  Future<String> saveProduct(ProductModel product, List<XFile> newImages) async {
    final ref = product.id.isEmpty ? _products.doc() : _products.doc(product.id);

    List<String> imageUrls = List.from(product.imageUrls);
    if (newImages.isNotEmpty) {
      final uploaded = await _uploadImages('products/${ref.id}', newImages);
      imageUrls.addAll(uploaded);
    }

    final data = product.copyWith(id: ref.id, imageUrls: imageUrls).toMap();
    await ref.set(data);
    return ref.id;
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).update({'isActive': false});
  }

  // ── Paquetes ──────────────────────────────────
  Stream<List<PackageModel>> watchPackages({String? occasion, bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = activeOnly
        ? _packages.where('isActive', isEqualTo: true)
        : _packages;
    if (occasion != null && occasion.isNotEmpty) {
      query = query.where('occasion', isEqualTo: occasion);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PackageModel.fromDoc).toList());
  }

  Stream<PackageModel?> watchPackage(String id) {
    return _packages.doc(id).snapshots().map(
          (doc) => doc.exists ? PackageModel.fromDoc(doc) : null,
        );
  }

  Future<void> incrementPackageView(String id) {
    return _packages.doc(id).update({'viewCount': FieldValue.increment(1)});
  }

  Future<String> savePackage(PackageModel package, List<XFile> newImages) async {
    final ref = package.id.isEmpty ? _packages.doc() : _packages.doc(package.id);

    List<String> imageUrls = List.from(package.imageUrls);
    if (newImages.isNotEmpty) {
      final uploaded = await _uploadImages('packages/${ref.id}', newImages);
      imageUrls.addAll(uploaded);
    }

    final data = package.copyWith(id: ref.id, imageUrls: imageUrls).toMap();
    await ref.set(data);
    return ref.id;
  }

  Future<void> deletePackage(String id) async {
    await _packages.doc(id).update({'isActive': false});
  }

  String generateProductId() => _products.doc().id;
  String generatePackageId() => _packages.doc().id;

  // ── Imágenes ──────────────────────────────────
  Future<List<String>> uploadImages(String path, List<XFile> files) => _uploadImages(path, files);

  // ── Rankings ──────────────────────────────────
  Stream<List<ProductModel>> watchTopProducts({String orderBy = 'orderCount', int limit = 10}) {
    return _products
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ProductModel.fromDoc).toList());
  }

  Stream<List<PackageModel>> watchTopPackages({String orderBy = 'orderCount', int limit = 10}) {
    return _packages
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(PackageModel.fromDoc).toList());
  }

  // ── Privados ──────────────────────────────────
  Future<List<String>> _uploadImages(String path, List<XFile> files) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? _mimeFromName(file.name);
      final ext = _extFromMime(mime);

      final ref = _storage.ref('$path/image_${DateTime.now().millisecondsSinceEpoch}_$i.$ext');
      // putData corrompe bytes en Flutter web (bug WASM→JS); base64 es confiable en todas las plataformas
      await ref.putData(bytes, SettableMetadata(contentType: mime));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  String _mimeFromName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  String _extFromMime(String mime) => switch (mime) {
        'image/png' => 'png',
        'image/gif' => 'gif',
        'image/webp' => 'webp',
        'image/heic' || 'image/heif' => 'heic',
        _ => 'jpg',
      };
}

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(
    db: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final productsProvider = StreamProvider.family<List<ProductModel>, String?>((ref, category) {
  return ref.watch(shopRepositoryProvider).watchProducts(category: category);
});

final productProvider = StreamProvider.family<ProductModel?, String>((ref, id) {
  return ref.watch(shopRepositoryProvider).watchProduct(id);
});

final packagesProvider = StreamProvider.family<List<PackageModel>, String?>((ref, occasion) {
  return ref.watch(shopRepositoryProvider).watchPackages(occasion: occasion);
});

final packageProvider = StreamProvider.family<PackageModel?, String>((ref, id) {
  return ref.watch(shopRepositoryProvider).watchPackage(id);
});

// Admin: incluye productos/paquetes deshabilitados
final adminProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(shopRepositoryProvider).watchProducts(activeOnly: false);
});

final adminPackagesProvider = StreamProvider<List<PackageModel>>((ref) {
  return ref.watch(shopRepositoryProvider).watchPackages(activeOnly: false);
});

// Rankings para métricas
final topProductsByOrdersProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(shopRepositoryProvider).watchTopProducts(orderBy: 'orderCount');
});

final topProductsByViewsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(shopRepositoryProvider).watchTopProducts(orderBy: 'viewCount');
});

final topPackagesByOrdersProvider = StreamProvider<List<PackageModel>>((ref) {
  return ref.watch(shopRepositoryProvider).watchTopPackages(orderBy: 'orderCount');
});

final topPackagesByViewsProvider = StreamProvider<List<PackageModel>>((ref) {
  return ref.watch(shopRepositoryProvider).watchTopPackages(orderBy: 'viewCount');
});
