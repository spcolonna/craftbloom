import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/config/packs_config.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/currency_formatter.dart';
import 'package:craftbloom/core/utils/validators.dart';
import 'package:craftbloom/features/auth/data/auth_repository.dart';
import 'package:craftbloom/features/orders/data/cart_notifier.dart';
import 'package:craftbloom/features/orders/data/order_model.dart';
import 'package:craftbloom/features/orders/data/order_repository.dart';
import 'package:craftbloom/features/shop/data/shop_repository.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';
import 'package:craftbloom/shared/widgets/page_header.dart';
import 'package:craftbloom/shared/widgets/smart_image.dart';

class NewOrderScreen extends ConsumerStatefulWidget {
  final String? preselectedPackId;
  const NewOrderScreen({super.key, this.preselectedPackId});

  @override
  ConsumerState<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends ConsumerState<NewOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _aptCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();

  DeliveryType _delivery = DeliveryType.pickup;
  PaymentMethod _payment = PaymentMethod.transfer;
  final List<XFile> _images = [];
  bool _loading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPackId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pack = PacksConfig.all
            .where((p) => p.id == widget.preselectedPackId)
            .firstOrNull;
        if (pack != null) {
          ref
              .read(cartProvider.notifier)
              .addOrIncrement(
                CartItem(
                  id: pack.id,
                  name: pack.name,
                  unitPrice: pack.basePrice ?? 0,
                  priceUnit: pack.priceUnit,
                  imageUrl: pack.imagePath,
                  isPackage: true,
                ),
              );
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _igCtrl,
      _notesCtrl,
      _streetCtrl,
      _numberCtrl,
      _aptCtrl,
      _cityCtrl,
      _deptCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= AppConfig.maxImagesPerOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo ${AppConfig.maxImagesPerOrder} imágenes.'),
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      limit: AppConfig.maxImagesPerOrder - _images.length,
    );
    if (picked.isNotEmpty) setState(() => _images.addAll(picked));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 1);
      return;
    }
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserModelProvider).value;
      final cart = ref.read(cartProvider);

      ShippingAddress? address;
      if (_delivery == DeliveryType.delivery) {
        address = ShippingAddress(
          street: _streetCtrl.text.trim(),
          number: _numberCtrl.text.trim(),
          apartment: _aptCtrl.text.trim().isEmpty ? null : _aptCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          department: _deptCtrl.text.trim(),
        );
      }

      final items = cart
          .map(
            (ci) => OrderItem(
              productId: ci.id,
              name: ci.name,
              quantity: ci.quantity,
              specs: '',
              isPackage: ci.isPackage,
            ),
          )
          .toList();

      List<File> files = [];
      if (!kIsWeb) {
        files = _images.map((x) => File(x.path)).toList();
      }

      final order = await ref
          .read(orderRepositoryProvider)
          .createOrder(
            customerName: _nameCtrl.text.trim(),
            customerEmail: _emailCtrl.text.trim(),
            customerPhone: _phoneCtrl.text.trim(),
            instagramHandle: _igCtrl.text.trim().isEmpty
                ? null
                : _igCtrl.text.trim(),
            userId: user?.id,
            items: items,
            deliveryType: _delivery,
            shippingAddress: address,
            paymentMethod: _payment,
            notes: _notesCtrl.text.trim(),
            imageFiles: files,
          );

      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        context.go('/pedido/${order.orderCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Pedido enviado! Tu código es ${order.orderCode}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar el pedido: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotif = ref.read(cartProvider.notifier);
    final cartEmpty = cart.isEmpty;
    final isWide =
        MediaQuery.of(context).size.width >= AppSizes.tabletBreakpoint;

    final formContent = SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxFormWidth),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(
                  title: 'Nuevo Pedido',
                  subtitle: 'Armá tu carrito y completá tus datos.',
                ),
                Stepper(
                  physics: const NeverScrollableScrollPhysics(),
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep == 0 && cartEmpty) return;
                    if (_currentStep < 2) {
                      setState(() => _currentStep++);
                    } else {
                      _submit();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) setState(() => _currentStep--);
                  },
                  controlsBuilder: (context, details) {
                    final isStep0 = _currentStep == 0;
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSizes.md),
                      child: Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: [
                          ElevatedButton(
                            onPressed: (isStep0 && cartEmpty) || _loading
                                ? null
                                : details.onStepContinue,
                            child: _loading && _currentStep == 2
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : isStep0
                                ? cartEmpty
                                      ? const Text('Agregá algo al carrito')
                                      : Text(
                                          '${cartNotif.itemCount} ${cartNotif.itemCount == 1 ? 'item' : 'items'}'
                                          ' · ${CurrencyFormatter.format(cartNotif.total)}'
                                          '  →  Continuar',
                                        )
                                : Text(
                                    _currentStep == 2
                                        ? AppStrings.submitOrder
                                        : AppStrings.next,
                                  ),
                          ),
                          if (_currentStep > 0)
                            OutlinedButton(
                              onPressed: details.onStepCancel,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(
                                  0,
                                  AppSizes.buttonHeight,
                                ),
                              ),
                              child: const Text(AppStrings.back),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('¿Qué necesitás?'),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.indexed,
                      content: _StepCatalog(cart: cart),
                    ),
                    Step(
                      title: const Text('Tus datos'),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1
                          ? StepState.complete
                          : StepState.indexed,
                      content: _StepContactData(
                        nameCtrl: _nameCtrl,
                        emailCtrl: _emailCtrl,
                        phoneCtrl: _phoneCtrl,
                        igCtrl: _igCtrl,
                      ),
                    ),
                    Step(
                      title: const Text('Entrega, pago y notas'),
                      isActive: _currentStep >= 2,
                      content: _StepDeliveryPaymentNotes(
                        delivery: _delivery,
                        payment: _payment,
                        streetCtrl: _streetCtrl,
                        numberCtrl: _numberCtrl,
                        aptCtrl: _aptCtrl,
                        cityCtrl: _cityCtrl,
                        deptCtrl: _deptCtrl,
                        notesCtrl: _notesCtrl,
                        images: _images,
                        onDeliveryChanged: (v) => setState(() => _delivery = v),
                        onPaymentChanged: (v) => setState(() => _payment = v),
                        onPickImages: _pickImages,
                        onRemoveImage: (i) =>
                            setState(() => _images.removeAt(i)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xxl),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: formContent),
                SizedBox(
                  width: 300,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSizes.xl,
                      AppSizes.lg,
                      AppSizes.xl,
                    ),
                    child: _CartSidebar(),
                  ),
                ),
              ],
            )
          : formContent,
    );
  }
}

// ── Step 0: Catálogo con búsqueda y carrito ───────────────────────────
class _StepCatalog extends ConsumerStatefulWidget {
  final List<CartItem> cart;
  const _StepCatalog({required this.cart});

  @override
  ConsumerState<_StepCatalog> createState() => _StepCatalogState();
}

class _StepCatalogState extends ConsumerState<_StepCatalog> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _filter = 0; // 0=todos 1=packs 2=productos

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(packagesProvider(null));
    final productsAsync = ref.watch(productsProvider(null));

    final packages = packagesAsync.valueOrNull ?? [];
    final products = productsAsync.valueOrNull ?? [];
    final loading = packagesAsync.isLoading && productsAsync.isLoading;

    // Unificar en lista de _CatalogItem
    final all = [
      ...packages.map(
        (p) => _CatalogItem(
          id: p.id,
          name: p.name,
          price: p.price,
          priceUnit: p.priceUnit,
          imageUrl: p.firstImageUrl,
          label: p.occasion,
          isPackage: true,
        ),
      ),
      ...products.map(
        (p) => _CatalogItem(
          id: p.id,
          name: p.name,
          price: p.price,
          priceUnit: p.priceUnit,
          imageUrl: p.firstImageUrl,
          label: p.category,
          isPackage: false,
        ),
      ),
    ];

    final filtered = all.where((e) {
      final q = _query.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.label.toLowerCase().contains(q);
      final matchFilter =
          _filter == 0 ||
          (_filter == 1 && e.isPackage) ||
          (_filter == 2 && !e.isPackage);
      return matchSearch && matchFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buscador
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Buscar packs y productos...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: AppSizes.sm),

        // Filtros
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in {
                0: 'Todos',
                1: 'Paquetes',
                2: 'Productos',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.sm),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: _filter == entry.key,
                    onSelected: (_) => setState(() => _filter = entry.key),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.xl),
            child: AppLoading(),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
            child: Center(
              child: Text(
                _query.isNotEmpty
                    ? 'No encontramos resultados para "$_query".'
                    : 'No hay productos todavía.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...filtered.map((item) {
            final cartItem = widget.cart
                .where((c) => c.id == item.id)
                .firstOrNull;
            final qty = cartItem?.quantity ?? 0;
            return _CatalogRow(item: item, qty: qty);
          }),

        // Resumen del carrito en pantallas estrechas
        if (widget.cart.isNotEmpty &&
            MediaQuery.of(context).size.width < AppSizes.tabletBreakpoint) ...[
          const SizedBox(height: AppSizes.md),
          const Divider(),
          const SizedBox(height: AppSizes.sm),
          Text('En tu carrito:', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.sm),
          ...widget.cart.map((ci) {
            final notifier = ref.read(cartProvider.notifier);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${ci.quantity}× ${ci.name}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(ci.subtotal),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  InkWell(
                    onTap: () => notifier.remove(ci.id),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _CatalogItem {
  final String id, name, priceUnit, imageUrl, label;
  final double price;
  final bool isPackage;
  const _CatalogItem({
    required this.id,
    required this.name,
    required this.price,
    required this.priceUnit,
    required this.imageUrl,
    required this.label,
    required this.isPackage,
  });
}

class _CatalogRow extends ConsumerWidget {
  final _CatalogItem item;
  final int qty;
  const _CatalogRow({required this.item, required this.qty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final priceText = item.price > 0
        ? CurrencyFormatter.format(item.price)
        : 'A convenir';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: qty > 0
            ? AppColors.primaryLight.withValues(alpha: 0.12)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: qty > 0 ? AppColors.primary : AppColors.border,
          width: qty > 0 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: SmartImage(url: item.imageUrl, width: 52, height: 52),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      priceText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                      ),
                      child: Text(
                        item.label,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // Controles de cantidad
          if (qty == 0)
            FilledButton.tonal(
              onPressed: () => notifier.addOrIncrement(
                CartItem(
                  id: item.id,
                  name: item.name,
                  unitPrice: item.price,
                  priceUnit: item.priceUnit,
                  imageUrl: item.imageUrl,
                  isPackage: item.isPackage,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              ),
              child: const Text('Agregar'),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: () => notifier.decrement(item.id),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$qty',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: () => notifier.addOrIncrement(
                    CartItem(
                      id: item.id,
                      name: item.name,
                      unitPrice: item.price,
                      priceUnit: item.priceUnit,
                      imageUrl: item.imageUrl,
                      isPackage: item.isPackage,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

// ── Sidebar de carrito (pantallas anchas) ─────────────────────────────
class _CartSidebar extends ConsumerWidget {
  const _CartSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.xs),
              Text('Tu carrito', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          if (cart.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Text(
                'Todavía no agregaste nada.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else ...[
            ...cart.map(
              (ci) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ci.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: () => notifier.decrement(ci.id),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '${ci.quantity}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: () => notifier.addOrIncrement(
                                  CartItem(
                                    id: ci.id,
                                    name: ci.name,
                                    unitPrice: ci.unitPrice,
                                    priceUnit: ci.priceUnit,
                                    imageUrl: ci.imageUrl,
                                    isPackage: ci.isPackage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.format(ci.subtotal),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => notifier.remove(ci.id),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: AppSizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  CurrencyFormatter.format(notifier.total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step 1: Datos de contacto ─────────────────────────────────────────
class _StepContactData extends StatelessWidget {
  final TextEditingController nameCtrl, emailCtrl, phoneCtrl, igCtrl;
  const _StepContactData({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.igCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: AppStrings.customerName,
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) => Validators.required(v, 'El nombre'),
        ),
        const SizedBox(height: AppSizes.md),
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: AppStrings.customerEmail,
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: Validators.email,
        ),
        const SizedBox(height: AppSizes.md),
        TextFormField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: AppStrings.customerPhone,
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: Validators.phone,
        ),
        const SizedBox(height: AppSizes.md),
        TextFormField(
          controller: igCtrl,
          decoration: const InputDecoration(
            labelText: AppStrings.instagramHandle,
            prefixIcon: Icon(Icons.camera_alt_outlined),
            hintText: '@usuario',
          ),
        ),
      ],
    );
  }
}

// ── Step 2: Entrega + pago + notas + imágenes ─────────────────────────
class _StepDeliveryPaymentNotes extends StatelessWidget {
  final DeliveryType delivery;
  final PaymentMethod payment;
  final TextEditingController streetCtrl,
      numberCtrl,
      aptCtrl,
      cityCtrl,
      deptCtrl,
      notesCtrl;
  final List<XFile> images;
  final ValueChanged<DeliveryType> onDeliveryChanged;
  final ValueChanged<PaymentMethod> onPaymentChanged;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;

  const _StepDeliveryPaymentNotes({
    required this.delivery,
    required this.payment,
    required this.streetCtrl,
    required this.numberCtrl,
    required this.aptCtrl,
    required this.cityCtrl,
    required this.deptCtrl,
    required this.notesCtrl,
    required this.images,
    required this.onDeliveryChanged,
    required this.onPaymentChanged,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.deliveryType,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSizes.sm),
        _RadioOption<DeliveryType>(
          value: DeliveryType.pickup,
          groupValue: delivery,
          label: AppStrings.pickup,
          subtitle: 'Te indicamos el punto de encuentro.',
          icon: Icons.store_outlined,
          onChanged: onDeliveryChanged,
        ),
        _RadioOption<DeliveryType>(
          value: DeliveryType.delivery,
          groupValue: delivery,
          label: AppStrings.delivery,
          subtitle: 'Informanos tu dirección.',
          icon: Icons.local_shipping_outlined,
          onChanged: onDeliveryChanged,
        ),
        if (delivery == DeliveryType.delivery) ...[
          const SizedBox(height: AppSizes.md),
          Text(
            AppStrings.shippingAddress,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: streetCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.street,
                  ),
                  validator: (v) => Validators.required(v, 'La calle'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: TextFormField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.streetNumber,
                  ),
                  validator: (v) => Validators.required(v, 'El número'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          TextFormField(
            controller: aptCtrl,
            decoration: const InputDecoration(labelText: AppStrings.apartment),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: AppStrings.city),
                  validator: (v) => Validators.required(v, 'La ciudad'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: TextFormField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.department,
                  ),
                  validator: (v) => Validators.required(v, 'El departamento'),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSizes.xl),
        Text(
          AppStrings.paymentMethod,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSizes.sm),
        _RadioOption<PaymentMethod>(
          value: PaymentMethod.transfer,
          groupValue: payment,
          label: AppStrings.bankTransfer,
          subtitle: 'Transferís al número de cuenta y enviás el comprobante.',
          icon: Icons.account_balance_outlined,
          onChanged: onPaymentChanged,
        ),
        if (payment == PaymentMethod.transfer) const _BankDetailsCard(),
        _RadioOption<PaymentMethod>(
          value: PaymentMethod.cash,
          groupValue: payment,
          label: AppStrings.cashOnDelivery,
          subtitle: 'Pagás en efectivo cuando retirás o recibís tu pedido.',
          icon: Icons.payments_outlined,
          onChanged: onPaymentChanged,
        ),
        _RadioOption<PaymentMethod>(
          value: PaymentMethod.mercadopago,
          groupValue: payment,
          label: AppStrings.mercadoPago,
          subtitle: 'Pagá online con tarjeta o saldo MP.',
          icon: Icons.payment_outlined,
          onChanged: onPaymentChanged,
        ),

        const SizedBox(height: AppSizes.xl),
        TextFormField(
          controller: notesCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: AppStrings.orderNotes,
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 64),
              child: Icon(Icons.notes_outlined),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.lg),
        Text(
          AppStrings.uploadImages,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Subí imágenes de referencia (máx. ${AppConfig.maxImagesPerOrder}).',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSizes.md),
        if (images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, i) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: kIsWeb
                        ? Image.network(
                            images[i].path,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(images[i].path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemoveImage(i),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSizes.sm),
        OutlinedButton.icon(
          onPressed: images.length < AppConfig.maxImagesPerOrder
              ? onPickImages
              : null,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Agregar imágenes de referencia'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppSizes.buttonHeightSm),
          ),
        ),
      ],
    );
  }
}

class _RadioOption<T> extends StatelessWidget {
  final T value, groupValue;
  final String label, subtitle;
  final IconData icon;
  final ValueChanged<T> onChanged;

  const _RadioOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryLight.withValues(alpha: 0.3)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleLarge),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BankDetailsCard extends StatelessWidget {
  const _BankDetailsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.primaryDark),
              const SizedBox(width: AppSizes.xs),
              Text(
                'Datos para la transferencia',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          _BankRow('Banco', AppConfig.bankName),
          _BankRow('Titular', AppConfig.bankAccountHolder),
          _BankRow('Tipo de cuenta', AppConfig.bankAccountType),
          _BankRow('Número de cuenta', AppConfig.bankAccountNumber, copyable: true),
          if (AppConfig.bankAlias.isNotEmpty)
            _BankRow('Alias', AppConfig.bankAlias, copyable: true),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Una vez realizada la transferencia, subí el comprobante desde el seguimiento de tu pedido.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _BankRow(this.label, this.value, {this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copiado al portapapeles'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.copy, size: 14, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
