import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/constants/app_colors.dart';
import 'package:craftbloom/core/constants/app_sizes.dart';
import 'package:craftbloom/core/constants/app_strings.dart';
import 'package:craftbloom/core/theme/seasonal_theme.dart';
import 'package:craftbloom/features/auth/data/auth_repository.dart';
import 'package:craftbloom/features/settings/data/settings_repository.dart';
import 'package:craftbloom/shared/widgets/seasonal_background.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= AppSizes.tabletBreakpoint;
    return isWide ? _WideLayout(child: child) : _NarrowLayout(child: child);
  }
}

// ── Layout desktop/tablet (navbar lateral o superior) ──────────────
class _WideLayout extends ConsumerWidget {
  final Widget child;
  const _WideLayout({required this.child});

  // Ancho máximo del contenido en desktop — cambiá este valor si querés
  // más o menos espacio (1280 es el estándar para sitios de e-commerce).
  static const double maxContentWidth = 1280;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(seasonalThemeProvider).value ?? SeasonalTheme.normal;
    return Scaffold(
      body: Column(
        children: [
          _TopNav(maxWidth: maxContentWidth),
          Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: SeasonalBackground(
              theme: season,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Layout móvil (bottom nav) ────────────────────────────────────────
class _NarrowLayout extends ConsumerWidget {
  final Widget child;
  const _NarrowLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final season = ref.watch(seasonalThemeProvider).value ?? SeasonalTheme.normal;
    int currentIndex = _locationToIndex(location);

    return Scaffold(
      appBar: _AppBar(),
      body: SeasonalBackground(theme: season, child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, 3),
        onTap: (i) => _onTap(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'Tienda'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Pedido'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }

  int _locationToIndex(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/shop')) return 1;
    if (location.startsWith('/pedido')) return 2;
    if (location == '/mi-cuenta' || location == '/login' || location == '/registro') return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/shop');
      case 2: context.go('/pedido/nuevo');
      case 3: context.go('/mi-cuenta');
    }
  }
}

// ── AppBar compartida ────────────────────────────────────────────────
class _AppBar extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).value;
    return AppBar(
      title: Text(AppConfig.businessName),
      actions: [
        if (user?.isWorker == true)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: AppStrings.navAdmin,
            onPressed: () => context.go('/admin'),
          ),
        const SizedBox(width: AppSizes.sm),
      ],
    );
  }
}

// ── Navbar superior para desktop ─────────────────────────────────────
class _TopNav extends ConsumerWidget {
  final double maxWidth;
  const _TopNav({required this.maxWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).value;
    return Container(
      height: AppSizes.appBarHeight,
      color: AppColors.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
            child: Row(
        children: [
          // Logo / nombre
          GestureDetector(
            onTap: () => context.go('/'),
            child: Text(
              AppConfig.businessName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const Spacer(),
          // Links
          ..._NavItem.items.map(
            (item) => _NavLink(label: item.label, path: item.path),
          ),
          const SizedBox(width: AppSizes.md),
          // Cuenta / login
          if (user == null)
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(AppStrings.login),
            )
          else
            Row(
              children: [
                if (user.isWorker)
                  TextButton.icon(
                    icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                    label: const Text(AppStrings.navAdmin),
                    onPressed: () => context.go('/admin'),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: Text(user.name.split(' ').first),
                  onPressed: () => context.go('/mi-cuenta'),
                ),
              ],
            ),
        ],
      ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String path;
  const _NavItem(this.label, this.path);

  static const items = [
    _NavItem(AppStrings.navHome, '/'),
    _NavItem(AppStrings.navShop, '/shop'),
    _NavItem(AppStrings.navNewOrder, '/pedido/nuevo'),
    _NavItem(AppStrings.navTrackOrder, '/pedido/seguimiento'),
    _NavItem(AppStrings.navReviews, '/opiniones'),
    _NavItem(AppStrings.navContact, '/contacto'),
  ];
}

class _NavLink extends StatelessWidget {
  final String label;
  final String path;
  const _NavLink({required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isActive = location == path || (path != '/' && location.startsWith(path));
    return TextButton(
      onPressed: () => context.go(path),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: isActive ? FontWeight.w700 : FontWeight.w400),
      ),
    );
  }
}
