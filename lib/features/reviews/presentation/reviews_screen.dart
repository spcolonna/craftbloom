import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/validators.dart';
import 'package:craftbloom/features/auth/data/auth_repository.dart';
import 'package:craftbloom/features/reviews/data/review_model.dart';
import 'package:craftbloom/shared/providers/firebase_providers.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';
import 'package:craftbloom/shared/widgets/page_header.dart';
import 'package:intl/intl.dart';

final _approvedReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('reviews')
      .where('isApproved', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ReviewModel.fromDoc).toList());
});

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(_approvedReviewsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(title: AppStrings.reviews),
                // Encabezado con rating promedio
              reviewsAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (reviews) {
                  if (reviews.isEmpty) return const SizedBox();
                  final avg = reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(avg.toStringAsFixed(1), style: Theme.of(context).textTheme.displayMedium),
                          const SizedBox(width: AppSizes.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(5, (i) => Icon(
                                  i < avg.round() ? Icons.star : Icons.star_border,
                                  color: AppColors.accent,
                                  size: 20,
                                )),
                              ),
                              Text('${reviews.length} opiniones'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSizes.lg),

              // Botón escribir opinión
              if (!_showForm)
                ElevatedButton.icon(
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text(AppStrings.writeReview),
                  onPressed: () => setState(() => _showForm = true),
                ),
              if (_showForm)
                _ReviewForm(onCancel: () => setState(() => _showForm = false)),

              const SizedBox(height: AppSizes.xl),

              // Lista de reviews
              reviewsAsync.when(
                loading: () => const AppLoading(),
                error: (e, _) => AppErrorWidget(message: e.toString()),
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.xxl),
                        child: Text(AppStrings.noReviews, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                    itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

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
                  child: Text(review.customerName[0].toUpperCase(), style: TextStyle(color: AppColors.primaryDark)),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.customerName, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        DateFormat('dd/MM/yyyy').format(review.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      color: AppColors.accent,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(review.comment),
          ],
        ),
      ),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  const _ReviewForm({required this.onCancel});

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  int _rating = 5;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserModelProvider).value;
    if (user != null) _nameCtrl.text = user.name;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserModelProvider).value;
      final db = ref.read(firestoreProvider);
      await db.collection('reviews').add({
        'userId': user?.id,
        'customerName': _nameCtrl.text.trim(),
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
        'isApproved': false,
        'createdAt': Timestamp.now(),
      });
      if (mounted) {
        widget.onCancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias por tu opinión! La publicaremos cuando la revisemos.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la opinión. Intentá de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.writeReview, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tu nombre'),
                validator: (v) => Validators.required(v, 'El nombre'),
              ),
              const SizedBox(height: AppSizes.md),
              Text(AppStrings.yourRating, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: AppColors.accent,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: AppStrings.yourComment, alignLabelWithHint: true),
                validator: (v) => Validators.minLength(v, 10, 'El comentario'),
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text(AppStrings.submitReview),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
