import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  received,
  accepted,
  rejected,
  awaitingPayment,
  processing,
  paused,
  ready,
  shipped,
  completed,
  cancelled;

  String get value => switch (this) {
        pending => 'pending',
        received => 'received',
        accepted => 'accepted',
        rejected => 'rejected',
        awaitingPayment => 'awaiting_payment',
        processing => 'processing',
        paused => 'paused',
        ready => 'ready',
        shipped => 'shipped',
        completed => 'completed',
        cancelled => 'cancelled',
      };

  static OrderStatus fromValue(String value) => switch (value) {
        'received' => received,
        'accepted' => accepted,
        'rejected' => rejected,
        'awaiting_payment' => awaitingPayment,
        'processing' => processing,
        'paused' => paused,
        'ready' => ready,
        'shipped' => shipped,
        'completed' => completed,
        'cancelled' => cancelled,
        _ => pending,
      };
}

enum DeliveryType {
  pickup,
  delivery;

  String get value => name;
  static DeliveryType fromValue(String v) =>
      v == 'delivery' ? delivery : pickup;
}

enum PaymentMethod {
  transfer,
  mercadopago,
  cash;

  String get value => name;
  static PaymentMethod fromValue(String v) => switch (v) {
        'mercadopago' => mercadopago,
        'cash' => cash,
        _ => transfer,
      };
}

enum PaymentStatus {
  pending,
  confirmed,
  failed;

  String get value => name;
  static PaymentStatus fromValue(String v) => switch (v) {
        'confirmed' => confirmed,
        'failed' => failed,
        _ => pending,
      };
}

class OrderItem extends Equatable {
  final String productId;
  final String name;
  final int quantity;
  final String specs;
  final double? unitPrice;
  final bool isPackage;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.specs,
    this.unitPrice,
    this.isPackage = false,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
        'specs': specs,
        'unitPrice': unitPrice,
        'isPackage': isPackage,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        specs: map['specs'] as String? ?? '',
        unitPrice: (map['unitPrice'] as num?)?.toDouble(),
        isPackage: map['isPackage'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [productId, name, quantity, specs, unitPrice, isPackage];
}

class StatusChange extends Equatable {
  final OrderStatus status;
  final DateTime timestamp;
  final String? adminId;
  final String? note;

  const StatusChange({
    required this.status,
    required this.timestamp,
    this.adminId,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'status': status.value,
        'timestamp': Timestamp.fromDate(timestamp),
        'adminId': adminId,
        'note': note,
      };

  factory StatusChange.fromMap(Map<String, dynamic> map) => StatusChange(
        status: OrderStatus.fromValue(map['status'] as String? ?? 'pending'),
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        adminId: map['adminId'] as String?,
        note: map['note'] as String?,
      );

  @override
  List<Object?> get props => [status, timestamp, adminId, note];
}

class ShippingAddress extends Equatable {
  final String street;
  final String number;
  final String? apartment;
  final String city;
  final String department;

  const ShippingAddress({
    required this.street,
    required this.number,
    this.apartment,
    required this.city,
    required this.department,
  });

  Map<String, dynamic> toMap() => {
        'street': street,
        'number': number,
        'apartment': apartment,
        'city': city,
        'department': department,
      };

  factory ShippingAddress.fromMap(Map<String, dynamic> map) => ShippingAddress(
        street: map['street'] as String? ?? '',
        number: map['number'] as String? ?? '',
        apartment: map['apartment'] as String?,
        city: map['city'] as String? ?? '',
        department: map['department'] as String? ?? '',
      );

  String get fullAddress =>
      '$street $number${apartment != null ? ', Apto $apartment' : ''}, $city, $department';

  @override
  List<Object?> get props => [street, number, apartment, city, department];
}

class OrderModel extends Equatable {
  final String id;
  final String orderCode;
  final String? userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String? instagramHandle;
  final List<OrderItem> items;
  final List<String> imageUrls;
  final OrderStatus status;
  final DeliveryType deliveryType;
  final ShippingAddress? shippingAddress;
  final double? shippingCost;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? mercadoPagoId;
  final String notes;
  final String adminNotes;
  final double? totalPrice;
  final String? paymentProofUrl;
  final List<StatusChange> statusHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.orderCode,
    this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.instagramHandle,
    required this.items,
    required this.imageUrls,
    required this.status,
    required this.deliveryType,
    this.shippingAddress,
    this.shippingCost,
    required this.paymentMethod,
    required this.paymentStatus,
    this.mercadoPagoId,
    required this.notes,
    required this.adminNotes,
    this.totalPrice,
    this.paymentProofUrl,
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'orderCode': orderCode,
        'userId': userId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'instagramHandle': instagramHandle,
        'items': items.map((i) => i.toMap()).toList(),
        'imageUrls': imageUrls,
        'status': status.value,
        'deliveryType': deliveryType.value,
        'shippingAddress': shippingAddress?.toMap(),
        'shippingCost': shippingCost,
        'paymentMethod': paymentMethod.value,
        'paymentStatus': paymentStatus.value,
        'mercadoPagoId': mercadoPagoId,
        'notes': notes,
        'adminNotes': adminNotes,
        'totalPrice': totalPrice,
        'paymentProofUrl': paymentProofUrl,
        'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderCode: data['orderCode'] as String? ?? '',
      userId: data['userId'] as String?,
      customerName: data['customerName'] as String? ?? '',
      customerEmail: data['customerEmail'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      instagramHandle: data['instagramHandle'] as String?,
      items: (data['items'] as List<dynamic>?)
              ?.map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      status: OrderStatus.fromValue(data['status'] as String? ?? 'pending'),
      deliveryType: DeliveryType.fromValue(data['deliveryType'] as String? ?? 'pickup'),
      shippingAddress: data['shippingAddress'] != null
          ? ShippingAddress.fromMap(data['shippingAddress'] as Map<String, dynamic>)
          : null,
      shippingCost: (data['shippingCost'] as num?)?.toDouble(),
      paymentMethod: PaymentMethod.fromValue(data['paymentMethod'] as String? ?? 'transfer'),
      paymentStatus: PaymentStatus.fromValue(data['paymentStatus'] as String? ?? 'pending'),
      mercadoPagoId: data['mercadoPagoId'] as String?,
      notes: data['notes'] as String? ?? '',
      adminNotes: data['adminNotes'] as String? ?? '',
      totalPrice: (data['totalPrice'] as num?)?.toDouble(),
      paymentProofUrl: data['paymentProofUrl'] as String?,
      statusHistory: (data['statusHistory'] as List<dynamic>?)
              ?.map((s) => StatusChange.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  OrderModel copyWith({
    String? id,
    String? orderCode,
    String? userId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? instagramHandle,
    List<OrderItem>? items,
    List<String>? imageUrls,
    OrderStatus? status,
    DeliveryType? deliveryType,
    ShippingAddress? shippingAddress,
    double? shippingCost,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? mercadoPagoId,
    String? notes,
    String? adminNotes,
    double? totalPrice,
    String? paymentProofUrl,
    List<StatusChange>? statusHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      OrderModel(
        id: id ?? this.id,
        orderCode: orderCode ?? this.orderCode,
        userId: userId ?? this.userId,
        customerName: customerName ?? this.customerName,
        customerEmail: customerEmail ?? this.customerEmail,
        customerPhone: customerPhone ?? this.customerPhone,
        instagramHandle: instagramHandle ?? this.instagramHandle,
        items: items ?? this.items,
        imageUrls: imageUrls ?? this.imageUrls,
        status: status ?? this.status,
        deliveryType: deliveryType ?? this.deliveryType,
        shippingAddress: shippingAddress ?? this.shippingAddress,
        shippingCost: shippingCost ?? this.shippingCost,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        mercadoPagoId: mercadoPagoId ?? this.mercadoPagoId,
        notes: notes ?? this.notes,
        adminNotes: adminNotes ?? this.adminNotes,
        totalPrice: totalPrice ?? this.totalPrice,
        paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
        statusHistory: statusHistory ?? this.statusHistory,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [id, orderCode, status, updatedAt];
}
