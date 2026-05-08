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
    final isNew = product.id.isEmpty;
    final ref = isNew ? _products.doc() : _products.doc(product.id);

    List<String> imageUrls = List.from(product.imageUrls);
    if (newImages.isNotEmpty) {
      final uploaded = await _uploadImages('products/${ref.id}', newImages);
      imageUrls.addAll(uploaded);
    }

    final data = product.copyWith(id: ref.id, imageUrls: imageUrls).toMap();
    if (isNew) {
      await ref.set(data);
    } else {
      await ref.update(data);
    }
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
    final isNew = package.id.isEmpty;
    final ref = isNew ? _packages.doc() : _packages.doc(package.id);

    List<String> imageUrls = List.from(package.imageUrls);
    if (newImages.isNotEmpty) {
      final uploaded = await _uploadImages('packages/${ref.id}', newImages);
      imageUrls.addAll(uploaded);
    }

    final data = package.copyWith(id: ref.id, imageUrls: imageUrls).toMap();
    if (isNew) {
      await ref.set(data);
    } else {
      await ref.update(data);
    }
    return ref.id;
  }

  Future<void> deletePackage(String id) async {
    await _packages.doc(id).update({'isActive': false});
  }

  // ── Privados ──────────────────────────────────
  Future<List<String>> _uploadImages(String path, List<XFile> files) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final bytes = await files[i].readAsBytes();
      final ref = _storage.ref('$path/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }
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
