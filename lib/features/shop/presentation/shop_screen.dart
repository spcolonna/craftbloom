import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/config/packs_config.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/currency_formatter.dart';
import 'package:craftbloom/features/shop/data/product_model.dart';
import 'package:craftbloom/features/shop/data/shop_repository.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';
import 'package:craftbloom/shared/widgets/featured_reviews_carousel.dart';
import 'package:craftbloom/shared/widgets/smart_image.dart';

class ShopScreen extends ConsumerStatefulWidget {
  final bool showHome;
  const ShopScreen({super.key, this.showHome = false});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _selectedCategory;
  String? _selectedOccasion;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          if (widget.showHome) _HeroSliver(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: AppSizes.lg),
                if (widget.showHome)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Nuestros productos', style: Theme.of(context).textTheme.headlineMedium),
                        TextButton(onPressed: () => context.go('/shop'), child: const Text('Ver todo')),
                      ],
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TabBar(
                        controller: _tabs,
                        tabs: const [
                          Tab(text: 'Productos'),
                          Tab(text: 'Paquetes'),
                        ],
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textSecondary,
                        dividerColor: Colors.transparent,
                        splashBorderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.showHome)
            _ConfigPacksGrid(limit: 6)
          else
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ProductsTab(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (c) => setState(() => _selectedCategory = c),
                  ),
                  _PackagesTab(
                    selectedOccasion: _selectedOccasion,
                    onOccasionChanged: (o) => setState(() => _selectedOccasion = o),
                  ),
                ],
              ),
            ),
          if (widget.showHome) ...[
            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xxl)),
            _PackagesSection(),
            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xxl)),
            const SliverToBoxAdapter(child: FeaturedReviewsCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xxl)),
          ],
        ],
      ),
    );
  }
}

// ── Hero para Home ────────────────────────────────────────────────────
class _HeroSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.secondaryLight, AppColors.background],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl, horizontal: AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size = (MediaQuery.of(context).size.width * 0.65).clamp(200.0, 320.0);
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 32,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(AppConfig.logoAsset, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  AppConfig.tagline,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (ctx) => ElevatedButton(
                        onPressed: () => ctx.go('/pedido/nuevo'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(160, AppSizes.buttonHeight)),
                        child: const Text(AppStrings.newOrder),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Builder(
                      builder: (ctx) => OutlinedButton(
                        onPressed: () => ctx.go('/shop'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(160, AppSizes.buttonHeight),
                          backgroundColor: Colors.white.withValues(alpha: 0.82),
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                        ),
                        child: const Text('Ver tienda'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Grid de productos ─────────────────────────────────────────────────
class _ProductsGrid extends ConsumerWidget {
  final String? category;
  const _ProductsGrid({this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(category));
    return productsAsync.when(
      loading: () => const SliverToBoxAdapter(child: AppLoading()),
      error: (e, _) => SliverToBoxAdapter(child: AppErrorWidget(message: e.toString())),
      data: (products) {
        if (products.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(AppSizes.xxl),
              child: Text(AppStrings.noProductsFound),
            )),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.all(AppSizes.md),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ProductCard(product: products[i]),
              childCount: products.length,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: AppSizes.productCardWidth + AppSizes.md,
              mainAxisExtent: AppSizes.productCardHeight,
              crossAxisSpacing: AppSizes.md,
              mainAxisSpacing: AppSizes.md,
            ),
          ),
        );
      },
    );
  }
}

// ── Tab de productos con filtros ──────────────────────────────────────
class _ProductsTab extends ConsumerWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  const _ProductsTab({this.selectedCategory, required this.onCategoryChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
            child: Row(
              children: [
                FilterChip(
                  label: const Text(AppStrings.allCategories),
                  selected: selectedCategory == null,
                  onSelected: (_) => onCategoryChanged(null),
                ),
                ...AppConfig.productCategories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(left: AppSizes.sm),
                    child: FilterChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (_) => onCategoryChanged(selectedCategory == cat ? null : cat),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _ProductsGrid(category: selectedCategory),
      ],
    );
  }
}

// ── Tab de paquetes ───────────────────────────────────────────────────
class _PackagesTab extends ConsumerWidget {
  final String? selectedOccasion;
  final ValueChanged<String?> onOccasionChanged;

  const _PackagesTab({this.selectedOccasion, required this.onOccasionChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesProvider(null));

    return packagesAsync.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (allPacks) {
        final occasions = allPacks.map((p) => p.occasion).toSet().toList();
        final packs = selectedOccasion == null
            ? allPacks
            : allPacks.where((p) => p.occasion == selectedOccasion).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todas'),
                      selected: selectedOccasion == null,
                      onSelected: (_) => onOccasionChanged(null),
                    ),
                    ...occasions.map(
                      (occ) => Padding(
                        padding: const EdgeInsets.only(left: AppSizes.sm),
                        child: FilterChip(
                          label: Text(occ),
                          selected: selectedOccasion == occ,
                          onSelected: (_) => onOccasionChanged(selectedOccasion == occ ? null : occ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (packs.isEmpty)
              const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(AppSizes.xxl),
                  child: Text('No hay paquetes todavía.'),
                )),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.md),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _PackageCard(package: packs[i]),
                    childCount: packs.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: AppSizes.productCardWidth + AppSizes.md,
                    mainAxisExtent: AppSizes.productCardHeight,
                    crossAxisSpacing: AppSizes.md,
                    mainAxisSpacing: AppSizes.md,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Sección de paquetes en Home (carrusel horizontal, Firestore) ──────
class _PackagesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesProvider(null));
    return SliverToBoxAdapter(
      child: packagesAsync.when(
        loading: () => const SizedBox(height: AppSizes.productCardHeight, child: AppLoading()),
        error: (e, _) => const SizedBox.shrink(),
        data: (packs) {
          if (packs.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paquetes para eventos', style: Theme.of(context).textTheme.headlineMedium),
                    Builder(
                      builder: (ctx) => TextButton(
                        onPressed: () => ctx.go('/shop'),
                        child: const Text('Ver todo'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              SizedBox(
                height: AppSizes.productCardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  itemCount: packs.length,
                  separatorBuilder: (_, i) => const SizedBox(width: AppSizes.md),
                  itemBuilder: (context, i) => SizedBox(
                    width: AppSizes.productCardWidth,
                    child: _PackageCard(package: packs[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Grid de paquetes en Home (Firestore) ──────────────────────────────
class _ConfigPacksGrid extends ConsumerWidget {
  final int? limit;
  const _ConfigPacksGrid({this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packagesProvider(null));
    return packagesAsync.when(
      loading: () => const SliverToBoxAdapter(child: AppLoading()),
      error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (allPacks) {
        final packs = limit != null ? allPacks.take(limit!).toList() : allPacks;
        if (packs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverPadding(
          padding: const EdgeInsets.all(AppSizes.md),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _PackageCard(package: packs[i]),
              childCount: packs.length,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: AppSizes.productCardWidth + AppSizes.md,
              mainAxisExtent: AppSizes.productCardHeight,
              crossAxisSpacing: AppSizes.md,
              mainAxisSpacing: AppSizes.md,
            ),
          ),
        );
      },
    );
  }
}

// ── Card de paquete (Firestore) ───────────────────────────────────────
class _PackageCard extends StatelessWidget {
  final PackageModel package;
  const _PackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final entry = PacksConfig.all.where((e) => e.id == package.id).firstOrNull;
    final badge = entry?.badge;
    final priceText = package.price > 0
        ? '${AppStrings.priceFrom} ${CurrencyFormatter.format(package.price)}'
        : package.priceUnit;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/shop/${package.id}?pack=true'),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SmartImage(url: package.firstImageUrl),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          package.occasion,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                badge,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(package.name, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      priceText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card de producto ──────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/shop/${product.id}'),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SmartImage(
                  url: product.firstImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        Text(
                          '${AppStrings.priceFrom} ${CurrencyFormatter.format(product.price)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        Text(product.priceUnit, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

