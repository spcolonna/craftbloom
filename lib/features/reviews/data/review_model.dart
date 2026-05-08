import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String id;
  final String? userId;
  final String customerName;
  final int rating;
  final String comment;
  final String? imageUrl;
  final bool isApproved;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    this.userId,
    required this.customerName,
    required this.rating,
    required this.comment,
    this.imageUrl,
    required this.isApproved,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
        'imageUrl': imageUrl,
        'isApproved': isApproved,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ReviewModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      userId: data['userId'] as String?,
      customerName: data['customerName'] as String? ?? 'Anónimo',
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      comment: data['comment'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      isApproved: data['isApproved'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ReviewModel copyWith({bool? isApproved}) => ReviewModel(
        id: id,
        userId: userId,
        customerName: customerName,
        rating: rating,
        comment: comment,
        imageUrl: imageUrl,
        isApproved: isApproved ?? this.isApproved,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, rating, isApproved];
}
