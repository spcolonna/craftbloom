import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftbloom/core/config/packs_config.dart';
import 'package:craftbloom/core/config/products_config.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/currency_formatter.dart';
import 'package:craftbloom/features/shop/data/product_model.dart';
import 'package:craftbloom/features/shop/data/shop_repository.dart';
import 'package:craftbloom/shared/providers/firebase_providers.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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

  Future<void> _seedCatalog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cargar catálogo de muestra'),
        content: Text(
          'Se van a cargar ${PacksConfig.all.length} packs y ${ProductsConfig.all.length} productos '
          'desde la configuración. Los existentes no se modifican.\n\n¿Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cargar')),
        ],
      ),
    );
    if (confirm != true) return;

    final db = ref.read(firestoreProvider);
    final now = Timestamp.now();
    final batch = db.batch();

    for (final pack in PacksConfig.all) {
      batch.set(
        db.collection('packages').doc(pack.id),
        {...pack.toFirestoreMap(), 'createdAt': now, 'updatedAt': now},
        SetOptions(merge: true),
      );
    }

    for (final product in ProductsConfig.all) {
      batch.set(
        db.collection('products').doc(product.id),
        {...product.toFirestoreMap(), 'createdAt': now, 'updatedAt': now},
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          '${PacksConfig.all.length} packs y ${ProductsConfig.all.length} productos cargados.',
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.productsManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_outlined),
            tooltip: 'Cargar catálogo de muestra',
            onPressed: _seedCatalog,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Productos'), Tab(text: 'Paquetes')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        onPressed: () => context.go('/admin/productos/nuevo'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ProductsList(),
          _PackagesList(),
        ],
      ),
    );
  }
}

class _ProductsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);
    return productsAsync.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (products) {
        if (products.isEmpty) return const Center(child: Text('No hay productos todavía.'));
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: products.length,
          separatorBuilder: (_, i) => const SizedBox(height: AppSizes.sm),
          itemBuilder: (context, i) => _ProductTile(product: products[i]),
        );
      },
    );
  }
}

class _PackagesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(adminPackagesProvider);
    return packagesAsync.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (packages) {
        if (packages.isEmpty) return const Center(child: Text('No hay paquetes todavía.'));
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.md),
          itemCount: packages.length,
          separatorBuilder: (_, i) => const SizedBox(height: AppSizes.sm),
          itemBuilder: (context, i) => _PackageTile(package: packages[i]),
        );
      },
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final ProductModel product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: product.isActive ? 1.0 : 0.5,
      child: Card(
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: product.firstImageUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: product.firstImageUrl, width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56, height: 56,
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    child: const Icon(Icons.image_outlined, color: AppColors.primary),
                  ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(product.name, style: Theme.of(context).textTheme.titleLarge)),
              if (!product.isActive)
                Container(
                  margin: const EdgeInsets.only(left: AppSizes.xs),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text('Deshabilitado', style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.category, style: Theme.of(context).textTheme.bodySmall),
              Text(CurrencyFormatter.format(product.price)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: product.isActive,
                onChanged: (v) async {
                  await ref.read(shopRepositoryProvider).saveProduct(
                    product.copyWith(isActive: v), [],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.go('/admin/productos/${product.id}/editar'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar producto'),
                      content: Text('¿Eliminar "${product.name}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await ref.read(shopRepositoryProvider).deleteProduct(product.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageTile extends ConsumerWidget {
  final PackageModel package;
  const _PackageTile({required this.package});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: package.isActive ? 1.0 : 0.5,
      child: Card(
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: package.firstImageUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: package.firstImageUrl, width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56, height: 56,
                    color: AppColors.secondaryLight.withValues(alpha: 0.3),
                    child: const Icon(Icons.celebration_outlined, color: AppColors.secondary),
                  ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(package.name, style: Theme.of(context).textTheme.titleLarge)),
              if (!package.isActive)
                Container(
                  margin: const EdgeInsets.only(left: AppSizes.xs),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text('Deshabilitado', style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(package.occasion, style: Theme.of(context).textTheme.bodySmall),
              Text(CurrencyFormatter.format(package.price)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: package.isActive,
                onChanged: (v) async {
                  await ref.read(shopRepositoryProvider).savePackage(
                    package.copyWith(isActive: v), [],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.go('/admin/productos/${package.id}/editar?pack=true'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar paquete'),
                      content: Text('¿Eliminar "${package.name}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await ref.read(shopRepositoryProvider).deletePackage(package.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
