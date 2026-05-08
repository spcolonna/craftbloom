import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/utils/currency_formatter.dart';
import 'package:craftbloom/features/orders/data/cart_notifier.dart';
import 'package:craftbloom/features/shop/data/shop_repository.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';
import 'package:craftbloom/shared/widgets/page_header.dart';
import 'package:craftbloom/shared/widgets/smart_image.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  final bool isPackage;
  const ProductDetailScreen({super.key, required this.itemId, this.isPackage = false});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isPackage) {
        ref.read(shopRepositoryProvider).incrementPackageView(widget.itemId);
      } else {
        ref.read(shopRepositoryProvider).incrementProductView(widget.itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPackage) {
      final packAsync = ref.watch(packageProvider(widget.itemId));
      return packAsync.when(
        loading: () => const Scaffold(body: AppLoading()),
        error: (e, _) => Scaffold(body: AppErrorWidget(message: e.toString())),
        data: (pack) {
          if (pack == null) return const Scaffold(body: Center(child: Text('Paquete no encontrado.')));
          return _DetailScaffold(
            itemId: pack.id,
            itemName: pack.name,
            firstImageUrl: pack.firstImageUrl,
            isPackage: true,
            name: pack.name,
            description: pack.description,
            price: pack.price,
            priceUnit: pack.priceUnit,
            imageUrls: pack.imageUrls,
            imageIndex: _imageIndex,
            onImageChanged: (i) => setState(() => _imageIndex = i),
            badge: pack.occasion,
            details: pack.items.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Qué incluye?', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSizes.sm),
                      ...pack.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
          );
        },
      );
    }

    final productAsync = ref.watch(productProvider(widget.itemId));
    return productAsync.when(
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorWidget(message: e.toString())),
      data: (product) {
        if (product == null) return const Scaffold(body: Center(child: Text('Producto no encontrado.')));
        return _DetailScaffold(
          itemId: product.id,
          itemName: product.name,
          firstImageUrl: product.firstImageUrl,
          isPackage: false,
          name: product.name,
          description: product.description,
          price: product.price,
          priceUnit: product.priceUnit,
          imageUrls: product.imageUrls,
          imageIndex: _imageIndex,
          onImageChanged: (i) => setState(() => _imageIndex = i),
          badge: product.category,
        );
      },
    );
  }
}

class _DetailScaffold extends ConsumerWidget {
  final String itemId, itemName, firstImageUrl;
  final bool isPackage;
  final String name, description, priceUnit;
  final double price;
  final List<String> imageUrls;
  final int imageIndex;
  final ValueChanged<int> onImageChanged;
  final String? badge;
  final Widget? details;

  const _DetailScaffold({
    required this.itemId,
    required this.itemName,
    required this.firstImageUrl,
    required this.isPackage,
    required this.name,
    required this.description,
    required this.price,
    required this.priceUnit,
    required this.imageUrls,
    required this.imageIndex,
    required this.onImageChanged,
    this.badge,
    this.details,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final existing = cart.where((i) => i.id == itemId).firstOrNull;
    final qty = existing?.quantity ?? 0;
    final isWide = MediaQuery.of(context).size.width >= AppSizes.tabletBreakpoint;

    final cartAction = _CartAction(
      qty: qty,
      onAdd: () => ref.read(cartProvider.notifier).addOrIncrement(CartItem(
        id: itemId,
        name: itemName,
        unitPrice: price,
        priceUnit: priceUnit,
        imageUrl: firstImageUrl,
        isPackage: isPackage,
      )),
      onDecrement: () => ref.read(cartProvider.notifier).decrement(itemId),
      onGoToCart: () => context.go('/pedido/nuevo'),
      price: price,
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(title: name),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.xxl),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _ImageGallery(imageUrls: imageUrls, index: imageIndex, onChanged: onImageChanged)),
                            const SizedBox(width: AppSizes.xl),
                            Expanded(flex: 4, child: _InfoSection(name: name, description: description, price: price, priceUnit: priceUnit, badge: badge, details: details, action: cartAction)),
                          ],
                        )
                      : Column(
                          children: [
                            _ImageGallery(imageUrls: imageUrls, index: imageIndex, onChanged: onImageChanged),
                            const SizedBox(height: AppSizes.md),
                            _InfoSection(name: name, description: description, price: price, priceUnit: priceUnit, badge: badge, details: details, action: cartAction),
                          ],
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

class _ImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final int index;
  final ValueChanged<int> onChanged;

  const _ImageGallery({required this.imageUrls, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Center(child: Icon(Icons.image_not_supported_outlined, size: 64, color: AppColors.textDisabled)),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: SmartImage(
            url: imageUrls[index],
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (imageUrls.length > 1) ...[
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (_, i) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => onChanged(i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: SmartImage(
                    url: imageUrls[i],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String name, description, priceUnit;
  final double price;
  final String? badge;
  final Widget? details;
  final Widget? action;

  const _InfoSection({
    required this.name,
    required this.description,
    required this.price,
    required this.priceUnit,
    this.badge,
    this.details,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(badge!, style: TextStyle(color: AppColors.secondaryDark, fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: AppSizes.sm),
        Text(name, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppSizes.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              CurrencyFormatter.format(price),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(priceUnit, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        if (action != null) ...[
          action!,
          const SizedBox(height: AppSizes.lg),
        ],
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
        if (details != null) ...[
          const SizedBox(height: AppSizes.lg),
          details!,
        ],
      ],
    );
  }
}

class _CartAction extends StatelessWidget {
  final int qty;
  final double price;
  final VoidCallback onAdd;
  final VoidCallback onDecrement;
  final VoidCallback onGoToCart;

  const _CartAction({
    required this.qty,
    required this.price,
    required this.onAdd,
    required this.onDecrement,
    required this.onGoToCart,
  });

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          icon: const Icon(Icons.add_shopping_cart_outlined),
          label: const Text('Agregar al carrito'),
          onPressed: onAdd,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleButton(icon: Icons.remove, onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$qty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
        ),
        _CircleButton(icon: Icons.add, onTap: onAdd),
        const SizedBox(width: AppSizes.md),
        OutlinedButton.icon(
          icon: const Icon(Icons.shopping_cart_outlined, size: 16),
          label: Text('Ver carrito · ${CurrencyFormatter.format(price * qty)}'),
          onPressed: onGoToCart,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppSizes.buttonHeightSm),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
