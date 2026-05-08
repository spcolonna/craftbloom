import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/currency_formatter.dart';
import 'package:craftbloom/features/auth/data/auth_repository.dart';
import 'package:craftbloom/features/orders/data/order_model.dart';
import 'package:craftbloom/features/orders/data/order_repository.dart';
import 'package:craftbloom/shared/providers/firebase_providers.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';
import 'package:craftbloom/shared/widgets/order_status_badge.dart';
import 'package:craftbloom/shared/widgets/page_header.dart';

class OrderStatusScreen extends ConsumerWidget {
  final String orderCode;
  const OrderStatusScreen({super.key, required this.orderCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByCodeProvider(orderCode));

    return Scaffold(
      body: orderAsync.when(
        loading: () => const AppLoading(message: 'Buscando tu pedido...'),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (order) {
          if (order == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 72, color: AppColors.textDisabled),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'No encontramos el pedido "$orderCode".',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'Verificá que el código sea correcto.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.xl),
                    ElevatedButton(
                      onPressed: () => context.go('/pedido/seguimiento'),
                      child: const Text('Intentar de nuevo'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _OrderStatusContent(order: order, orderCode: orderCode);
        },
      ),
    );
  }
}

class _OrderStatusContent extends StatelessWidget {
  final OrderModel order;
  final String orderCode;
  const _OrderStatusContent({required this.order, required this.orderCode});

  @override
  Widget build(BuildContext context) {
    final statusConfig = AppConfig.orderStatusConfig[order.status.value];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxFormWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Pedido $orderCode',
                actions: [
                  Builder(
                    builder: (ctx) => TextButton.icon(
                      onPressed: () => ctx.go('/pedido/seguimiento'),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Volver'),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.lg, 0, AppSizes.lg, AppSizes.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            // Card de estado principal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  children: [
                    Icon(
                      statusConfig?.icon ?? Icons.receipt_outlined,
                      size: 64,
                      color: statusConfig?.color ?? AppColors.textDisabled,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      order.orderCode,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    OrderStatusBadge(status: order.status, large: true),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      statusConfig?.description ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.md),
                    // Compartir código
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copiar código'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(160, AppSizes.buttonHeightSm),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.orderCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(AppStrings.copied)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Detalle del pedido
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detalle del pedido', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    _InfoRow('Cliente', order.customerName),
                    _InfoRow('Email', order.customerEmail),
                    _InfoRow('Teléfono', order.customerPhone),
                    _InfoRow(
                      'Entrega',
                      order.deliveryType == DeliveryType.pickup ? '🏪 Retiro en persona' : '📦 Envío a domicilio',
                    ),
                    if (order.shippingAddress != null)
                      _InfoRow('Dirección', order.shippingAddress!.fullAddress),
                    _InfoRow(
                      'Pago',
                      switch (order.paymentMethod) {
                        PaymentMethod.transfer => AppStrings.bankTransfer,
                        PaymentMethod.cash => AppStrings.cashOnDelivery,
                        PaymentMethod.mercadopago => AppStrings.mercadoPago,
                      },
                    ),
                    if (order.totalPrice != null)
                      _InfoRow('Total', CurrencyFormatter.format(order.totalPrice!)),
                    _InfoRow('Fecha del pedido', dateFormat.format(order.createdAt)),
                    if (order.notes.isNotEmpty) _InfoRow('Notas', order.notes),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Comprobante de pago
            if (order.status == OrderStatus.awaitingPayment &&
                order.paymentMethod != PaymentMethod.cash) ...[
              _PaymentProofCard(order: order),
              const SizedBox(height: AppSizes.md),
            ],

            // CTA para calificar pedido completado
            if (order.status == OrderStatus.completed)
              _RateOrderCard(order: order),

            if (order.status == OrderStatus.completed)
              const SizedBox(height: AppSizes.md),

            // Historial de estados
            if (order.statusHistory.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.orderHistory, style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      ...order.statusHistory.reversed.map(
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
                      ),
                    ],
                  ),
                ),
              ),
            ],          // if statusHistory
                  ],    // Padding > Column children
                ),      // Padding > Column
              ),        // Padding
            ],          // outer Column children
          ),            // outer Column
        ),              // ConstrainedBox
      ),                // Center
    );
  }
}

// ── Comprobante de pago ───────────────────────────────────────────────
class _PaymentProofCard extends ConsumerStatefulWidget {
  final OrderModel order;
  const _PaymentProofCard({required this.order});

  @override
  ConsumerState<_PaymentProofCard> createState() => _PaymentProofCardState();
}

class _PaymentProofCardState extends ConsumerState<_PaymentProofCard> {
  bool _uploading = false;

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await ref.read(orderRepositoryProvider).uploadPaymentProof(widget.order.id, file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Comprobante enviado! Lo revisamos a la brevedad.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir el comprobante. Intentá de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alreadySent = widget.order.paymentProofUrl != null;

    return Card(
      color: alreadySent
          ? AppColors.success.withValues(alpha: 0.07)
          : AppColors.statusAwaitingPayment.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  alreadySent ? Icons.check_circle_outline : Icons.upload_file_outlined,
                  color: alreadySent ? AppColors.success : AppColors.statusAwaitingPayment,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  alreadySent ? 'Comprobante enviado' : 'Enviá tu comprobante de pago',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            if (alreadySent)
              Text(
                'Ya recibimos tu comprobante. Te avisamos cuando confirmemos el pago.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              if (widget.order.paymentMethod == PaymentMethod.transfer) ...[
                Text(
                  'Realizá la transferencia a:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSizes.xs),
                _ProofRow('Banco', AppConfig.bankName),
                _ProofRow('Titular', AppConfig.bankAccountHolder),
                _ProofRow('Tipo', AppConfig.bankAccountType),
                _ProofRow('N° de cuenta', AppConfig.bankAccountNumber, copyable: true),
                if (AppConfig.bankAlias.isNotEmpty)
                  _ProofRow('Alias', AppConfig.bankAlias, copyable: true),
                const SizedBox(height: AppSizes.sm),
              ],
              Text(
                'Una vez transferido, subí la foto o captura del comprobante:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSizes.sm),
              ElevatedButton.icon(
                icon: _uploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_outlined),
                label: Text(_uploading ? 'Subiendo...' : 'Subir comprobante'),
                onPressed: _uploading ? null : _pick,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _ProofRow(this.label, this.value, {this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copiado'), duration: Duration(seconds: 2)),
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

// ── Calificá tu pedido ────────────────────────────────────────────────
class _RateOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  const _RateOrderCard({required this.order});

  @override
  ConsumerState<_RateOrderCard> createState() => _RateOrderCardState();
}

class _RateOrderCardState extends ConsumerState<_RateOrderCard> {
  final _commentCtrl = TextEditingController();
  int _rating = 5;
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribí al menos un breve comentario.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserModelProvider).value;
      final db = ref.read(firestoreProvider);
      await db.collection('reviews').add({
        'userId': user?.id,
        'customerName': widget.order.customerName,
        'orderId': widget.order.id,
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
        'isApproved': false,
        'createdAt': Timestamp.now(),
      });
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
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
    if (_submitted) {
      return Card(
        color: AppColors.success.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Icon(Icons.favorite, color: AppColors.success),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  '¡Gracias por tu opinión! La publicaremos cuando la revisemos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_outline, color: AppColors.accent),
                const SizedBox(width: AppSizes.sm),
                Text('¿Cómo fue tu experiencia?', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Tu opinión nos ayuda a mejorar y a otros clientes a conocernos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: AppColors.accent,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Contanos cómo quedó tu pedido...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar opinión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            )),
          ),
        ],
      ),
    );
  }
}
