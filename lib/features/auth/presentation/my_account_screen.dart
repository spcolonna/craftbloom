import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/utils/currency_formatter.dart';
import 'package:craftbloom/features/auth/data/auth_repository.dart';
import 'package:craftbloom/features/orders/data/order_repository.dart';
import 'package:craftbloom/features/orders/data/order_model.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';
import 'package:craftbloom/shared/widgets/order_status_badge.dart';

class MyAccountScreen extends ConsumerWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return userAsync.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppErrorWidget(message: e.toString()),
      data: (user) {
        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Para ver tu cuenta debés iniciar sesión.'),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(AppStrings.login),
                ),
              ],
            ),
          );
        }

        final ordersAsync = ref.watch(userOrdersProvider(user.id));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.md),
                // Header perfil
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppColors.primary,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
                              Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                              if (user.phone.isNotEmpty)
                                Text(user.phone, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text(AppStrings.logout),
                          onPressed: () async {
                            await ref.read(authRepositoryProvider).signOut();
                            if (context.mounted) context.go('/');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                Text(AppStrings.myOrders, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSizes.md),
                ordersAsync.when(
                  loading: () => const AppLoading(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (orders) {
                    if (orders.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.xxl),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: AppColors.textDisabled),
                              const SizedBox(height: AppSizes.md),
                              Text(AppStrings.noOrders, style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: AppSizes.lg),
                              ElevatedButton(
                                onPressed: () => context.go('/pedido/nuevo'),
                                child: const Text(AppStrings.newOrder),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      separatorBuilder: (_, i) => const SizedBox(height: AppSizes.sm),
                      itemBuilder: (context, i) => _OrderTile(order: orders[i]),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusConfig = AppConfig.orderStatusConfig[order.status.value];
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (statusConfig?.color ?? AppColors.textDisabled).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Icon(
            statusConfig?.icon ?? Icons.receipt_outlined,
            color: statusConfig?.color ?? AppColors.textDisabled,
          ),
        ),
        title: Text(
          order.orderCode,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            OrderStatusBadge(status: order.status),
            if (order.totalPrice != null)
              Text(
                CurrencyFormatter.format(order.totalPrice!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/pedido/${order.orderCode}'),
      ),
    );
  }
}
