import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole {
  customer,
  worker,
  admin;

  String get value => name;
  static UserRole fromValue(String v) => switch (v) {
        'admin' => admin,
        'worker' => worker,
        _ => customer,
      };
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String? instagramHandle;
  final UserRole role;
  final List<String> orderIds;
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    this.instagramHandle,
    required this.role,
    required this.orderIds,
    this.fcmToken,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isWorker => role == UserRole.worker || role == UserRole.admin;

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'phone': phone,
        'instagramHandle': instagramHandle,
        'role': role.value,
        'orderIds': orderIds,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      instagramHandle: data['instagramHandle'] as String?,
      role: UserRole.fromValue(data['role'] as String? ?? 'customer'),
      orderIds: List<String>.from(data['orderIds'] as List? ?? []),
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? instagramHandle,
    UserRole? role,
    List<String>? orderIds,
    String? fcmToken,
    DateTime? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        instagramHandle: instagramHandle ?? this.instagramHandle,
        role: role ?? this.role,
        orderIds: orderIds ?? this.orderIds,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, email, role, orderIds];
}
