import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/currency_formatter.dart';
import 'package:craftbloom/features/orders/data/order_model.dart';
import 'package:craftbloom/features/orders/data/order_repository.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';
import 'package:craftbloom/shared/widgets/order_status_badge.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  OrderStatus? _statusFilter;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersProvider(_statusFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.ordersManagement),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por código, nombre o email...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtro por estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
                ...OrderStatus.values.map(
                  (status) {
                    final cfg = AppConfig.orderStatusConfig[status.value];
                    return Padding(
                      padding: const EdgeInsets.only(left: AppSizes.sm),
                      child: FilterChip(
                        label: Text(cfg?.label ?? status.value),
                        selected: _statusFilter == status,
                        selectedColor: (cfg?.color ?? AppColors.primary).withValues(alpha: 0.2),
                        onSelected: (_) => setState(() => _statusFilter = _statusFilter == status ? null : status),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const AppLoading(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (orders) {
                final filtered = _search.isEmpty
                    ? orders
                    : orders.where((o) =>
                        o.orderCode.toLowerCase().contains(_search) ||
                        o.customerName.toLowerCase().contains(_search) ||
                        o.customerEmail.toLowerCase().contains(_search)).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No hay pedidos con esos filtros.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.md),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, i) => _AdminOrderTile(order: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOrderTile extends StatelessWidget {
  final OrderModel order;
  const _AdminOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM HH:mm');
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
        title: Row(
          children: [
            Text(order.orderCode, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: AppSizes.sm),
            OrderStatusBadge(status: order.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(order.customerName),
            Text(order.customerEmail, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (order.totalPrice != null)
              Text(CurrencyFormatter.format(order.totalPrice!), style: Theme.of(context).textTheme.titleLarge),
            Text(dateFormat.format(order.createdAt), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        onTap: () => context.go('/admin/pedidos/${order.id}'),
      ),
    );
  }
}
