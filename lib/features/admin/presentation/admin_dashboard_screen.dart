import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/currency_formatter.dart';
import 'package:craftbloom/features/orders/data/order_model.dart';
import 'package:craftbloom/features/orders/data/order_repository.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';
import 'package:craftbloom/shared/widgets/order_status_badge.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrdersAsync = ref.watch(allOrdersProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.adminDashboard)),
      body: allOrdersAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (orders) {
          final pending = orders.where((o) => o.status == OrderStatus.pending).length;
          final processing = orders.where((o) => o.status == OrderStatus.processing).length;
          final completed = orders.where((o) => o.status == OrderStatus.completed).length;
          final totalRevenue = orders
              .where((o) => o.status == OrderStatus.completed && o.totalPrice != null)
              .fold(0.0, (sum, o) => sum + o.totalPrice!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Métricas clave
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                  childAspectRatio: 1.4,
                  mainAxisSpacing: AppSizes.md,
                  crossAxisSpacing: AppSizes.md,
                  children: [
                    _MetricCard(
                      title: AppStrings.pendingOrders,
                      value: pending.toString(),
                      icon: Icons.schedule_outlined,
                      color: AppColors.statusPending,
                      onTap: () => context.go('/admin/pedidos'),
                    ),
                    _MetricCard(
                      title: 'Procesándose',
                      value: processing.toString(),
                      icon: Icons.precision_manufacturing_outlined,
                      color: AppColors.statusProcessing,
                      onTap: () => context.go('/admin/pedidos'),
                    ),
                    _MetricCard(
                      title: AppStrings.completedOrders,
                      value: completed.toString(),
                      icon: Icons.done_all,
                      color: AppColors.statusCompleted,
                      onTap: () => context.go('/admin/metricas'),
                    ),
                    _MetricCard(
                      title: AppStrings.totalRevenue,
                      value: CurrencyFormatter.formatCompact(totalRevenue),
                      icon: Icons.attach_money,
                      color: AppColors.accent,
                      onTap: () => context.go('/admin/metricas'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xl),

                // Acciones rápidas
                Text('Acciones rápidas', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSizes.md),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    _QuickAction(label: 'Ver pedidos', icon: Icons.receipt_long_outlined, onTap: () => context.go('/admin/pedidos')),
                    _QuickAction(label: 'Agregar producto', icon: Icons.add_box_outlined, onTap: () => context.go('/admin/productos/nuevo')),
                    _QuickAction(label: 'Reviews pendientes', icon: Icons.rate_review_outlined, onTap: () => context.go('/admin/reviews')),
                    _QuickAction(label: 'Ver métricas', icon: Icons.bar_chart_outlined, onTap: () => context.go('/admin/metricas')),
                  ],
                ),
                const SizedBox(height: AppSizes.xl),

                // Últimos pedidos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Últimos pedidos', style: Theme.of(context).textTheme.headlineSmall),
                    TextButton(onPressed: () => context.go('/admin/pedidos'), child: const Text('Ver todos')),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                ...orders.take(5).map((order) => _RecentOrderTile(order: order)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: AppSizes.iconLg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: color)),
                  Text(title, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppSizes.buttonHeightSm),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final OrderModel order;
  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        leading: OrderStatusBadge(status: order.status),
        title: Text(order.orderCode, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text(order.customerName),
        trailing: order.totalPrice != null
            ? Text(CurrencyFormatter.format(order.totalPrice!))
            : null,
        onTap: () => context.go('/admin/pedidos/${order.id}'),
      ),
    );
  }
}
