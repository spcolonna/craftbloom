import 'dart:async';
import 'package:flutter/material.dart';
import 'package:craftbloom/core/config/reviews_config.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';

class FeaturedReviewsCarousel extends StatefulWidget {
  const FeaturedReviewsCarousel({super.key});

  @override
  State<FeaturedReviewsCarousel> createState() => _FeaturedReviewsCarouselState();
}

class _FeaturedReviewsCarouselState extends State<FeaturedReviewsCarousel> {
  late final PageController _pageCtrl;
  late final Timer _timer;
  int _current = 0;

  final _reviews = ReviewsConfig.carousel;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.88);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _reviews.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Row(
            children: [
              Text('Lo que dicen nuestros clientes', style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              Row(children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: AppColors.accent))),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _reviews.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              final review = _reviews[i];
              return _ReviewSlide(review: review, active: i == _current);
            },
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _reviews.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _current ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _current ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewSlide extends StatelessWidget {
  final MockReview review;
  final bool active;
  const _ReviewSlide({required this.review, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Card(
          elevation: active ? 4 : 1,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        review.customerName[0].toUpperCase(),
                        style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review.customerName, style: Theme.of(context).textTheme.titleLarge),
                          Text(review.occasion, style: Theme.of(context).textTheme.bodySmall),
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
                Expanded(
                  child: Text(
                    review.comment,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
