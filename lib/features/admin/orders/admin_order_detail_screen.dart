import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/currency_formatter.dart';
import 'package:craftbloom/features/auth/data/auth_repository.dart';
import 'package:craftbloom/features/orders/data/order_model.dart';
import 'package:craftbloom/features/orders/data/order_repository.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';
import 'package:craftbloom/shared/widgets/order_status_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends ConsumerState<AdminOrderDetailScreen> {
  final _adminNotesCtrl = TextEditingController();
  bool _savingNotes = false;

  @override
  void dispose() {
    _adminNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _changeStatus(OrderModel order) async {
    final currentUser = ref.read(currentUserModelProvider).value;
    OrderStatus? selected;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.changeStatus, style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: AppSizes.sm),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: OrderStatus.values.map(
                    (status) {
                      final cfg = AppConfig.orderStatusConfig[status.value];
                      return ListTile(
                        leading: Icon(cfg?.icon, color: cfg?.color),
                        title: Text(cfg?.label ?? status.value),
                        selected: order.status == status,
                        selectedTileColor: cfg?.color.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                        onTap: () {
                          selected = status;
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && selected != order.status) {
      await ref.read(orderRepositoryProvider).updateOrderStatus(
            orderId: widget.orderId,
            newStatus: selected!,
            adminId: currentUser?.id,
          );
    }
  }

  Future<void> _saveNotes(String orderId) async {
    setState(() => _savingNotes = true);
    await ref.read(orderRepositoryProvider).updateAdminNotes(orderId, _adminNotesCtrl.text.trim());
    if (mounted) {
      setState(() => _savingNotes = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notas guardadas.')));
    }
  }

  Future<void> _contactViaWhatsApp(String phone, String orderCode) async {
    final msg = Uri.encodeComponent('Hola! Te contactamos por tu pedido $orderCode de ${AppConfig.businessName}.');
    final url = 'https://wa.me/${phone.replaceAll(RegExp(r'\D'), '')}?text=$msg';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactViaEmail(String email, String orderCode) async {
    final subject = Uri.encodeComponent('Tu pedido $orderCode - ${AppConfig.businessName}');
    final url = 'mailto:$email?subject=$subject';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider(widget.orderId));

    return orderAsync.when(
      loading: () => const Scaffold(body: AppLoading()),
      error: (e, _) => Scaffold(body: AppErrorWidget(message: e.toString())),
      data: (order) {
        if (order == null) {
          return const Scaffold(body: Center(child: Text('Pedido no encontrado.')));
        }

        if (_adminNotesCtrl.text.isEmpty && order.adminNotes.isNotEmpty) {
          _adminNotesCtrl.text = order.adminNotes;
        }

        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

        return Scaffold(
          appBar: AppBar(
            title: Text(order.orderCode),
            leading: BackButton(onPressed: () => context.go('/admin/pedidos')),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado actual
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estado actual', style: Theme.of(context).textTheme.bodySmall),
                                  const SizedBox(height: 4),
                                  OrderStatusBadge(status: order.status, large: true),
                                ],
                              ),
                            ),
                            if (order.totalPrice != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Total', style: Theme.of(context).textTheme.bodySmall),
                                  Text(CurrencyFormatter.format(order.totalPrice!), style: Theme.of(context).textTheme.headlineMedium),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text(AppStrings.changeStatus),
                            onPressed: () => _changeStatus(order),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Datos del cliente
                _Section(
                  title: 'Cliente',
                  child: Column(
                    children: [
                      _InfoRow2('Nombre', order.customerName),
                      _InfoRow2('Email', order.customerEmail),
                      _InfoRow2('Teléfono', order.customerPhone),
                      if (order.instagramHandle != null)
                        _InfoRow2('Instagram', order.instagramHandle!),
                      const SizedBox(height: AppSizes.md),
                      // Botones de contacto
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.chat_outlined, size: 18),
                              label: const Text('WhatsApp'),
                              style: OutlinedButton.styleFrom(minimumSize: const Size(0, AppSizes.buttonHeightSm)),
                              onPressed: () => _contactViaWhatsApp(order.customerPhone, order.orderCode),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.email_outlined, size: 18),
                              label: const Text('Email'),
                              style: OutlinedButton.styleFrom(minimumSize: const Size(0, AppSizes.buttonHeightSm)),
                              onPressed: () => _contactViaEmail(order.customerEmail, order.orderCode),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Detalles del pedido
                _Section(
                  title: 'Detalle del pedido',
                  child: Column(
                    children: [
                      _InfoRow2('Entrega', order.deliveryType == DeliveryType.pickup ? 'Retiro en persona' : 'Envío a domicilio'),
                      if (order.shippingAddress != null)
                        _InfoRow2('Dirección', order.shippingAddress!.fullAddress),
                      _InfoRow2('Pago', order.paymentMethod == PaymentMethod.transfer ? AppStrings.bankTransfer : AppStrings.mercadoPago),
                      _InfoRow2('Estado pago', order.paymentStatus.value),
                      _InfoRow2('Fecha', dateFormat.format(order.createdAt)),
                      if (order.notes.isNotEmpty) _InfoRow2('Notas del cliente', order.notes),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Imágenes
                if (order.imageUrls.isNotEmpty)
                  _Section(
                    title: 'Imágenes del cliente',
                    child: SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: order.imageUrls.length,
                        separatorBuilder: (_, i) => const SizedBox(width: AppSizes.sm),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          child: CachedNetworkImage(
                            imageUrl: order.imageUrls[i],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (order.imageUrls.isNotEmpty) const SizedBox(height: AppSizes.md),

                // Notas internas del admin
                _Section(
                  title: AppStrings.adminNotes,
                  child: Column(
                    children: [
                      TextField(
                        controller: _adminNotesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Notas internas (no visibles para el cliente)...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _savingNotes ? null : () => _saveNotes(widget.orderId),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(120, AppSizes.buttonHeightSm)),
                          child: _savingNotes
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text(AppStrings.save),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Historial de estados
                _Section(
                  title: AppStrings.orderHistory,
                  child: Column(
                    children: order.statusHistory.reversed.map(
                      (change) {
                        final cfg = AppConfig.orderStatusConfig[change.status.value];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(cfg?.icon, size: 18, color: cfg?.color),
                          title: Text(cfg?.label ?? change.status.value),
                          subtitle: change.note != null ? Text(change.note!) : null,
                          trailing: Text(
                            dateFormat.format(change.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow2 extends StatelessWidget {
  final String label, value;
  const _InfoRow2(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
