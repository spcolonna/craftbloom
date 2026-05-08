import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:craftbloom/features/orders/data/order_model.dart';
import 'package:craftbloom/core/utils/order_code_generator.dart';
import 'package:craftbloom/core/utils/firebase_logger.dart';
import 'package:craftbloom/shared/providers/firebase_providers.dart';

class OrderRepository {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  OrderRepository({required FirebaseFirestore db, required FirebaseStorage storage})
      : _db = db,
        _storage = storage;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');

  Future<String> _generateUniqueCode() async {
    String code;
    bool exists;
    do {
      code = OrderCodeGenerator.generate();
      final query = await _orders.where('orderCode', isEqualTo: code).limit(1).get();
      exists = query.docs.isNotEmpty;
    } while (exists);
    return code;
  }

  Future<List<String>> uploadOrderImages(String orderId, List<File> files) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final ref = _storage.ref('orders/$orderId/image_$i.jpg');
      await ref.putFile(files[i]);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<String> uploadPaymentProof(String orderId, XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final ref = _storage.ref('payment_proofs/$orderId/proof.$ext');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _orders.doc(orderId).update({
      'paymentProofUrl': url,
      'updatedAt': Timestamp.now(),
    });
    return url;
  }

  Future<OrderModel> createOrder({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? instagramHandle,
    String? userId,
    required List<OrderItem> items,
    required DeliveryType deliveryType,
    ShippingAddress? shippingAddress,
    required PaymentMethod paymentMethod,
    required String notes,
    List<File> imageFiles = const [],
  }) async {
    final code = await _generateUniqueCode();
    final docRef = _orders.doc();

    List<String> imageUrls = [];
    if (imageFiles.isNotEmpty) {
      imageUrls = await uploadOrderImages(docRef.id, imageFiles);
    }

    final now = DateTime.now();
    final order = OrderModel(
      id: docRef.id,
      orderCode: code,
      userId: userId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      instagramHandle: instagramHandle,
      items: items,
      imageUrls: imageUrls,
      status: OrderStatus.pending,
      deliveryType: deliveryType,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      paymentStatus: PaymentStatus.pending,
      notes: notes,
      adminNotes: '',
      statusHistory: [
        StatusChange(
          status: OrderStatus.pending,
          timestamp: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(order.toMap());

    // Asociar pedido al usuario si está logueado
    if (userId != null) {
      await _db.collection('users').doc(userId).update({
        'orderIds': FieldValue.arrayUnion([docRef.id]),
      });
    }

    return order;
  }

  Future<OrderModel?> getOrderByCode(String code) async {
    final query = await _orders
        .where('orderCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return OrderModel.fromDoc(query.docs.first);
  }

  Stream<OrderModel?> watchOrderByCode(String code) {
    return _orders
        .where('orderCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : OrderModel.fromDoc(snap.docs.first))
        .handleError((e, st) => logFirebaseError('watchOrderByCode', e, st as StackTrace));
  }

  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromDoc).toList())
        .handleError((e, st) => logFirebaseError('watchUserOrders', e, st as StackTrace));
  }

  Stream<List<OrderModel>> watchAllOrders({OrderStatus? statusFilter}) {
    Query<Map<String, dynamic>> query = _orders.orderBy('createdAt', descending: true);
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.value);
    }
    return query
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromDoc).toList())
        .handleError((e, st) => logFirebaseError('watchAllOrders', e, st as StackTrace));
  }

  Stream<OrderModel?> watchOrder(String orderId) {
    return _orders
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromDoc(doc) : null)
        .handleError((e, st) => logFirebaseError('watchOrder', e, st as StackTrace));
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? adminId,
    String? note,
  }) async {
    final change = StatusChange(
      status: newStatus,
      timestamp: DateTime.now(),
      adminId: adminId,
      note: note,
    );
    await _orders.doc(orderId).update({
      'status': newStatus.value,
      'updatedAt': Timestamp.now(),
      'statusHistory': FieldValue.arrayUnion([change.toMap()]),
    });
  }

  Future<void> updateAdminNotes(String orderId, String notes) async {
    await _orders.doc(orderId).update({
      'adminNotes': notes,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateMercadoPagoId(String orderId, String mpId) async {
    await _orders.doc(orderId).update({'mercadoPagoId': mpId});
  }

  Future<void> confirmPayment(String orderId) async {
    await _orders.doc(orderId).update({
      'paymentStatus': 'confirmed',
      'updatedAt': Timestamp.now(),
    });
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(
    db: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final orderByCodeProvider = StreamProvider.family<OrderModel?, String>((ref, code) {
  return ref.watch(orderRepositoryProvider).watchOrderByCode(code);
});

final orderProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).watchOrder(orderId);
});

final userOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  return ref.watch(orderRepositoryProvider).watchUserOrders(userId);
});

final allOrdersProvider = StreamProvider.family<List<OrderModel>, OrderStatus?>((ref, status) {
  return ref.watch(orderRepositoryProvider).watchAllOrders(statusFilter: status);
});
