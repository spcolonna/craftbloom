import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:craftbloom/core/config/reviews_config.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/features/reviews/data/review_model.dart';
import 'package:craftbloom/shared/providers/firebase_providers.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';

final _allReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ReviewModel.fromDoc).toList());
});

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  bool _showPendingOnly = true;

  Future<void> _approve(ReviewModel review) async {
    await ref.read(firestoreProvider).collection('reviews').doc(review.id).update({'isApproved': true});
  }

  Future<void> _delete(ReviewModel review) async {
    await ref.read(firestoreProvider).collection('reviews').doc(review.id).delete();
  }

  Future<void> _seedMockReviews() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cargar reseñas de muestra'),
        content: Text(
          'Se van a agregar ${ReviewsConfig.featured.length} reseñas de muestra '
          'ya aprobadas. Las reseñas reales existentes no se tocan.\n\n¿Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cargar')),
        ],
      ),
    );
    if (confirm != true) return;

    final db = ref.read(firestoreProvider);
    final batch = db.batch();
    for (final mock in ReviewsConfig.featured) {
      final doc = db.collection('reviews').doc();
      batch.set(doc, {
        'userId': null,
        'customerName': mock.customerName,
        'rating': mock.rating,
        'comment': mock.comment,
        'isApproved': true,
        'createdAt': Timestamp.now(),
      });
    }
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ReviewsConfig.featured.length} reseñas cargadas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(_allReviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reviewsManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_outlined),
            tooltip: 'Cargar reseñas de muestra',
            onPressed: _seedMockReviews,
          ),
          Row(
            children: [
              const Text('Solo pendientes'),
              Switch(
                value: _showPendingOnly,
                onChanged: (v) => setState(() => _showPendingOnly = v),
              ),
              const SizedBox(width: AppSizes.sm),
            ],
          ),
        ],
      ),
      body: reviewsAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (reviews) {
          final filtered = _showPendingOnly ? reviews.where((r) => !r.isApproved).toList() : reviews;
          if (filtered.isEmpty) {
            return Center(
              child: Text(_showPendingOnly ? 'No hay reviews pendientes.' : 'No hay reviews.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (context, i) => _AdminReviewCard(
              review: filtered[i],
              onApprove: () => _approve(filtered[i]),
              onDelete: () => _delete(filtered[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AdminReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onApprove, onDelete;

  const _AdminReviewCard({required this.review, required this.onApprove, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(review.customerName[0].toUpperCase()),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.customerName, style: Theme.of(context).textTheme.titleLarge),
                      Text(DateFormat('dd/MM/yyyy').format(review.createdAt), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: review.isApproved ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    review.isApproved ? 'Publicada' : 'Pendiente',
                    style: TextStyle(
                      color: review.isApproved ? AppColors.success : AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: List.generate(
                5,
                (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, size: 16, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(review.comment),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                if (!review.isApproved) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(AppStrings.approveReview),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, AppSizes.buttonHeightSm),
                      ),
                      onPressed: onApprove,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                ],
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(0, AppSizes.buttonHeightSm),
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
