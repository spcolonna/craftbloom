import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> imageUrls;
  final double price;
  final String priceUnit;
  final bool isActive;
  final List<String> tags;
  final int viewCount;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrls,
    required this.price,
    required this.priceUnit,
    required this.isActive,
    required this.tags,
    required this.viewCount,
    required this.createdAt,
  });

  String get firstImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'imageUrls': imageUrls,
        'price': price,
        'priceUnit': priceUnit,
        'isActive': isActive,
        'tags': tags,
        'viewCount': viewCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ProductModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      priceUnit: data['priceUnit'] as String? ?? 'por unidad',
      isActive: data['isActive'] as bool? ?? true,
      tags: List<String>.from(data['tags'] as List? ?? []),
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    List<String>? imageUrls,
    double? price,
    String? priceUnit,
    bool? isActive,
    List<String>? tags,
    int? viewCount,
    DateTime? createdAt,
  }) =>
      ProductModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        imageUrls: imageUrls ?? this.imageUrls,
        price: price ?? this.price,
        priceUnit: priceUnit ?? this.priceUnit,
        isActive: isActive ?? this.isActive,
        tags: tags ?? this.tags,
        viewCount: viewCount ?? this.viewCount,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, name, price, isActive, viewCount];
}

class PackageModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String occasion;
  final List<String> imageUrls;
  final double price;
  final String priceUnit;
  final List<String> items;
  final bool isActive;
  final int viewCount;
  final DateTime createdAt;

  const PackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.occasion,
    required this.imageUrls,
    required this.price,
    required this.priceUnit,
    required this.items,
    required this.isActive,
    required this.viewCount,
    required this.createdAt,
  });

  String get firstImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'occasion': occasion,
        'imageUrls': imageUrls,
        'price': price,
        'priceUnit': priceUnit,
        'items': items,
        'isActive': isActive,
        'viewCount': viewCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory PackageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackageModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      occasion: data['occasion'] as String? ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      priceUnit: data['priceUnit'] as String? ?? 'por pack',
      items: List<String>.from(data['items'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  PackageModel copyWith({
    String? id,
    String? name,
    String? description,
    String? occasion,
    List<String>? imageUrls,
    double? price,
    String? priceUnit,
    List<String>? items,
    bool? isActive,
    int? viewCount,
    DateTime? createdAt,
  }) =>
      PackageModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        occasion: occasion ?? this.occasion,
        imageUrls: imageUrls ?? this.imageUrls,
        price: price ?? this.price,
        priceUnit: priceUnit ?? this.priceUnit,
        items: items ?? this.items,
        isActive: isActive ?? this.isActive,
        viewCount: viewCount ?? this.viewCount,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, name, price, isActive, viewCount];
}
