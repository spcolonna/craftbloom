import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/theme/seasonal_theme.dart';
import 'package:craftbloom/features/settings/data/settings_repository.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= AppSizes.tabletBreakpoint;
    return isWide ? _WideAdminLayout(child: child) : _NarrowAdminLayout(child: child);
  }
}

const _adminNavItems = [
  (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', path: '/admin'),
  (icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Pedidos', path: '/admin/pedidos'),
  (icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Productos', path: '/admin/productos'),
  (icon: Icons.star_outline, activeIcon: Icons.star, label: 'Reviews', path: '/admin/reviews'),
  (icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Métricas', path: '/admin/metricas'),
];

class _WideAdminLayout extends StatelessWidget {
  final Widget child;
  const _WideAdminLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.surface,
            selectedIndex: _locationToIndex(location),
            onDestinationSelected: (i) => context.go(_adminNavItems[i].path),
            leading: Column(
              children: [
                const SizedBox(height: AppSizes.md),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/'),
                  tooltip: 'Ir a la tienda',
                ),
                const SizedBox(height: AppSizes.sm),
                const _ThemeSwitcherButton(),
                const SizedBox(height: AppSizes.sm),
              ],
            ),
            extended: true,
            minExtendedWidth: 200,
            destinations: _adminNavItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon, color: AppColors.primary),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NarrowAdminLayout extends StatelessWidget {
  final Widget child;
  const _NarrowAdminLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        leading: IconButton(
          icon: const Icon(Icons.storefront_outlined),
          onPressed: () => context.go('/'),
          tooltip: 'Ir a la tienda',
        ),
        actions: const [
          _ThemeSwitcherButton(),
          SizedBox(width: AppSizes.sm),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _locationToIndex(location),
        onTap: (i) => context.go(_adminNavItems[i].path),
        items: _adminNavItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

int _locationToIndex(String location) {
  for (var i = 0; i < _adminNavItems.length; i++) {
    final path = _adminNavItems[i].path;
    if (i == 0 ? location == path : location.startsWith(path)) return i;
  }
  return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón + panel de cambio de tema
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeSwitcherButton extends ConsumerWidget {
  const _ThemeSwitcherButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(seasonalThemeProvider).value ?? SeasonalTheme.normal;
    return IconButton(
      icon: Text(current.emoji, style: const TextStyle(fontSize: 22)),
      tooltip: 'Cambiar tema estacional',
      onPressed: () => _showPanel(context, ref, current),
    );
  }

  void _showPanel(BuildContext context, WidgetRef ref, SeasonalTheme current) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _ThemePanel(current: current, ref: ref),
    );
  }
}

class _ThemePanel extends StatelessWidget {
  final SeasonalTheme current;
  final WidgetRef ref;
  const _ThemePanel({required this.current, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tema estacional', style: Theme.of(context).textTheme.titleLarge),
          Text(
            'Se aplica a todos los visitantes en tiempo real',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.lg),
          ...SeasonalTheme.values.map(
            (theme) => _ThemeOption(
              theme: theme,
              isSelected: theme == current,
              onTap: () {
                ref.read(settingsRepositoryProvider).setSeasonalTheme(theme);
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final SeasonalTheme theme;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  static const _previews = <SeasonalTheme, List<Color>>{
    SeasonalTheme.normal:     [Color(0xFFE8A0BF), Color(0xFFBA90C6), Color(0xFFCFA05A)],
    SeasonalTheme.christmas:  [Color(0xFFCC2936), Color(0xFF2D6A2D), Color(0xFFFFD700)],
    SeasonalTheme.halloween:  [Color(0xFFFF6B00), Color(0xFF7B2FBE), Color(0xFF1A0A2E)],
    SeasonalTheme.valentines: [Color(0xFFE91E63), Color(0xFFFF6090), Color(0xFFFFD700)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _previews[theme]!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      leading: Text(theme.emoji, style: const TextStyle(fontSize: 28)),
      title: Text(theme.label, style: Theme.of(context).textTheme.titleLarge),
      subtitle: Row(
        children: colors
            .map((c) => Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(right: 4, top: 4),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                  ),
                ))
            .toList(),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primary)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      tileColor: isSelected ? AppColors.primaryLight.withValues(alpha: 0.15) : null,
      onTap: onTap,
    );
  }
}
