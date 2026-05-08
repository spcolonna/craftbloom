import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/utils/currency_formatter.dart';
import 'package:craftbloom/features/orders/data/order_model.dart';
import 'package:craftbloom/features/orders/data/order_repository.dart';
import 'package:craftbloom/shared/widgets/app_loading.dart';

enum _DateFilter { week, month, quarter, all }

class AdminMetricsScreen extends ConsumerStatefulWidget {
  const AdminMetricsScreen({super.key});

  @override
  ConsumerState<AdminMetricsScreen> createState() => _AdminMetricsScreenState();
}

class _AdminMetricsScreenState extends ConsumerState<AdminMetricsScreen> {
  _DateFilter _filter = _DateFilter.month;

  DateTime get _from => switch (_filter) {
        _DateFilter.week => DateTime.now().subtract(const Duration(days: 7)),
        _DateFilter.month => DateTime.now().subtract(const Duration(days: 30)),
        _DateFilter.quarter => DateTime.now().subtract(const Duration(days: 90)),
        _DateFilter.all => DateTime(2000),
      };

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.metrics),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.md),
            child: DropdownButton<_DateFilter>(
              value: _filter,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: _DateFilter.week, child: Text('Últimos 7 días')),
                DropdownMenuItem(value: _DateFilter.month, child: Text('Últimos 30 días')),
                DropdownMenuItem(value: _DateFilter.quarter, child: Text('Últimos 90 días')),
                DropdownMenuItem(value: _DateFilter.all, child: Text('Todo el tiempo')),
              ],
              onChanged: (v) => setState(() => _filter = v!),
            ),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (allOrders) {
          final orders = allOrders.where((o) => o.createdAt.isAfter(_from)).toList();

          final completed = orders.where((o) => o.status == OrderStatus.completed).toList();
          final cancelled = orders.where((o) => o.status == OrderStatus.cancelled).length;
          final totalRevenue = completed.fold(0.0, (s, o) => s + (o.totalPrice ?? 0));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                  childAspectRatio: 1.4,
                  mainAxisSpacing: AppSizes.md,
                  crossAxisSpacing: AppSizes.md,
                  children: [
                    _KpiCard(label: AppStrings.totalSales, value: orders.length.toString(), icon: Icons.receipt_long_outlined, color: AppColors.secondary),
                    _KpiCard(label: AppStrings.completedOrders, value: completed.length.toString(), icon: Icons.done_all, color: AppColors.statusCompleted),
                    _KpiCard(label: AppStrings.cancelledOrders, value: cancelled.toString(), icon: Icons.block, color: AppColors.statusCancelled),
                    _KpiCard(label: AppStrings.totalRevenue, value: CurrencyFormatter.formatCompact(totalRevenue), icon: Icons.attach_money, color: AppColors.accent),
                  ],
                ),
                const SizedBox(height: AppSizes.xl),

                // Gráfica: pedidos por estado (torta)
                _ChartSection(
                  title: 'Pedidos por estado',
                  child: SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieSections(orders),
                        centerSpaceRadius: 50,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Gráfica: pedidos por día (barras)
                _ChartSection(
                  title: 'Pedidos por día',
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        barGroups: _buildBarGroups(orders),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Gráfica: revenue acumulado (línea)
                if (completed.isNotEmpty)
                  _ChartSection(
                    title: 'Ingresos acumulados (${AppConfig.currencyCode})',
                    child: SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [_buildRevenueLineBar(completed)],
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50)),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<OrderModel> orders) {
    final counts = <OrderStatus, int>{};
    for (final order in orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    if (counts.isEmpty) return [];
    return counts.entries.map((e) {
      final pct = (e.value / orders.length * 100);
      final cfg = AppConfig.orderStatusConfig[e.key.value];
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${pct.toStringAsFixed(0)}%',
        color: cfg?.color ?? AppColors.textDisabled,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarGroups(List<OrderModel> orders) {
    final byDay = <int, int>{};
    for (final order in orders) {
      final day = order.createdAt.difference(_from).inDays;
      byDay[day] = (byDay[day] ?? 0) + 1;
    }
    return byDay.entries
        .map((e) => BarChartGroupData(
              x: e.key,
              barRods: [BarChartRodData(toY: e.value.toDouble(), color: AppColors.primary, width: 6, borderRadius: BorderRadius.circular(4))],
            ))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  LineChartBarData _buildRevenueLineBar(List<OrderModel> completed) {
    completed.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    double cumulative = 0;
    final spots = <FlSpot>[];
    for (var i = 0; i < completed.length; i++) {
      cumulative += completed[i].totalPrice ?? 0;
      spots.add(FlSpot(i.toDouble(), cumulative));
    }
    return LineChartBarData(
      spots: spots,
      color: AppColors.accent,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: AppColors.accent.withValues(alpha: 0.1)),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSizes.md),
        Card(child: Padding(padding: const EdgeInsets.all(AppSizes.md), child: child)),
      ],
    );
  }
}

