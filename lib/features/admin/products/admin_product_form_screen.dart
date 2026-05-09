import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/validators.dart';
import 'package:craftbloom/features/shop/data/product_model.dart';
import 'package:craftbloom/features/shop/data/shop_repository.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  final bool isPackage;

  const AdminProductFormScreen({
    super.key,
    this.productId,
    this.isPackage = false,
  });

  @override
  ConsumerState<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _priceUnitCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedOccasion;
  List<String> _existingImages = [];
  List<XFile> _newImages = [];
  List<TextEditingController> _itemCtrlList = [];
  bool _isActive = true;
  bool _isPackage = false;
  bool _initializing = false;
  bool _loading = false;

  // Preserved from existing record when editing
  int _viewCount = 0;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _isPackage = widget.isPackage;
    _priceUnitCtrl.text = _isPackage ? 'por pack' : 'por unidad';
    _itemCtrlList = [TextEditingController()];

    if (widget.productId != null) {
      _initializing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _priceUnitCtrl.dispose();
    for (final c in _itemCtrlList) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      if (_isPackage) {
        final pkg = await ref.read(packageProvider(widget.productId!).future);
        if (pkg != null && mounted) {
          final itemCtrls = pkg.items.isNotEmpty
              ? pkg.items.map((i) => TextEditingController(text: i)).toList()
              : [TextEditingController()];
          setState(() {
            _nameCtrl.text = pkg.name;
            _descCtrl.text = pkg.description;
            _priceCtrl.text = pkg.price % 1 == 0
                ? pkg.price.toInt().toString()
                : pkg.price.toString();
            _priceUnitCtrl.text = pkg.priceUnit;
            _selectedOccasion = pkg.occasion;
            _existingImages = List.from(pkg.imageUrls);
            _isActive = pkg.isActive;
            _viewCount = pkg.viewCount;
            _createdAt = pkg.createdAt;
            for (final c in _itemCtrlList) {
              c.dispose();
            }
            _itemCtrlList = itemCtrls;
            _initializing = false;
          });
        }
      } else {
        final product = await ref.read(productProvider(widget.productId!).future);
        if (product != null && mounted) {
          setState(() {
            _nameCtrl.text = product.name;
            _descCtrl.text = product.description;
            _priceCtrl.text = product.price % 1 == 0
                ? product.price.toInt().toString()
                : product.price.toString();
            _priceUnitCtrl.text = product.priceUnit;
            _selectedCategory = product.category;
            _existingImages = List.from(product.imageUrls);
            _isActive = product.isActive;
            _viewCount = product.viewCount;
            _createdAt = product.createdAt;
            _initializing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _initializing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) setState(() => _newImages.addAll(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
      final now = DateTime.now();

      if (_isPackage) {
        final package = PackageModel(
          id: widget.productId ?? '',
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          occasion: _selectedOccasion ?? AppConfig.packageOccasions.first,
          imageUrls: _existingImages,
          price: price,
          priceUnit: _priceUnitCtrl.text.trim(),
          items: _itemCtrlList.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
          isActive: _isActive,
          viewCount: _viewCount,
          createdAt: _createdAt ?? now,
        );
        await ref.read(shopRepositoryProvider).savePackage(package, _newImages);
      } else {
        final product = ProductModel(
          id: widget.productId ?? '',
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _selectedCategory ?? AppConfig.productCategories.first,
          imageUrls: _existingImages,
          price: price,
          priceUnit: _priceUnitCtrl.text.trim(),
          isActive: _isActive,
          tags: [],
          viewCount: _viewCount,
          createdAt: _createdAt ?? now,
        );
        await ref.read(shopRepositoryProvider).saveProduct(product, _newImages);
      }

      if (mounted) {
        context.go('/admin/productos');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.productId == null ? 'Producto creado.' : 'Producto actualizado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.productId == null;

    if (_initializing) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.editProduct),
          leading: BackButton(onPressed: () => context.go('/admin/productos')),
        ),
        body: const AppLoading(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? AppStrings.addProduct : AppStrings.editProduct),
        leading: BackButton(onPressed: () => context.go('/admin/productos')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxFormWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isNew)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Producto'), icon: Icon(Icons.inventory_2_outlined)),
                        ButtonSegment(value: true, label: Text('Paquete'), icon: Icon(Icons.celebration_outlined)),
                      ],
                      selected: {_isPackage},
                      onSelectionChanged: (s) => setState(() {
                        _isPackage = s.first;
                        _priceUnitCtrl.text = _isPackage ? 'por pack' : 'por unidad';
                      }),
                    ),
                  const SizedBox(height: AppSizes.md),

                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => Validators.required(v, 'El nombre'),
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripción', alignLabelWithHint: true),
                    validator: (v) => Validators.required(v, 'La descripción'),
                  ),
                  const SizedBox(height: AppSizes.md),

                  if (_isPackage)
                    DropdownButtonFormField<String>(
                      key: ValueKey('occasion_$_selectedOccasion'),
                      initialValue: _selectedOccasion,
                      decoration: const InputDecoration(labelText: 'Ocasión'),
                      items: AppConfig.packageOccasions
                          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedOccasion = v),
                    )
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey('category_$_selectedCategory'),
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: AppConfig.productCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                  const SizedBox(height: AppSizes.md),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Precio (${AppConfig.currencyCode})',
                            prefixText: '${AppConfig.currencySymbol} ',
                          ),
                          validator: (v) => Validators.required(v, 'El precio'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _priceUnitCtrl,
                          decoration: const InputDecoration(labelText: 'Unidad de precio'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),

                  if (_isPackage) ...[
                    Text('¿Qué incluye?', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSizes.sm),
                    ..._itemCtrlList.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: entry.value,
                                decoration: InputDecoration(labelText: 'Ítem ${entry.key + 1}'),
                              ),
                            ),
                            if (_itemCtrlList.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                                onPressed: () => setState(() {
                                  _itemCtrlList[entry.key].dispose();
                                  _itemCtrlList.removeAt(entry.key);
                                }),
                              ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar ítem'),
                      onPressed: () => setState(() => _itemCtrlList.add(TextEditingController())),
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],

                  Text('Imágenes', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSizes.sm),
                  if (_existingImages.isNotEmpty || _newImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._existingImages.map(
                            (url) => Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: AppSizes.sm),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                    child: CachedNetworkImage(imageUrl: url, width: 100, height: 100, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 4, right: 12,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _existingImages.remove(url)),
                                    child: Container(
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ..._newImages.map(
                            (x) => Padding(
                              padding: const EdgeInsets.only(right: AppSizes.sm),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                child: _XFilePreview(xfile: x),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSizes.sm),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Agregar imágenes'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, AppSizes.buttonHeightSm)),
                    onPressed: _pickImages,
                  ),
                  const SizedBox(height: AppSizes.md),

                  SwitchListTile(
                    title: const Text('Visible en la tienda'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(height: AppSizes.xl),

                  ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isNew ? AppStrings.addProduct : AppStrings.save),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _XFilePreview extends StatefulWidget {
  final XFile xfile;
  const _XFilePreview({required this.xfile});

  @override
  State<_XFilePreview> createState() => _XFilePreviewState();
}

class _XFilePreviewState extends State<_XFilePreview> {
  late final Future<dynamic> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.xfile.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _bytesFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        return Image.memory(snap.data!, width: 100, height: 100, fit: BoxFit.cover);
      },
    );
  }
}
