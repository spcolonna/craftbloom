import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:craftbloom/features/auth/data/auth_repository.dart';
import 'package:craftbloom/features/auth/presentation/login_screen.dart';
import 'package:craftbloom/features/auth/presentation/register_screen.dart';
import 'package:craftbloom/features/auth/presentation/my_account_screen.dart';
import 'package:craftbloom/features/orders/presentation/new_order_screen.dart';
import 'package:craftbloom/features/orders/presentation/track_order_screen.dart';
import 'package:craftbloom/features/orders/presentation/order_status_screen.dart';
import 'package:craftbloom/features/shop/presentation/shop_screen.dart';
import 'package:craftbloom/features/shop/presentation/product_detail_screen.dart';
import 'package:craftbloom/features/reviews/presentation/reviews_screen.dart';
import 'package:craftbloom/features/contact/presentation/contact_screen.dart';
import 'package:craftbloom/features/admin/presentation/admin_shell.dart';
import 'package:craftbloom/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:craftbloom/features/admin/orders/admin_orders_screen.dart';
import 'package:craftbloom/features/admin/orders/admin_order_detail_screen.dart';
import 'package:craftbloom/features/admin/products/admin_products_screen.dart';
import 'package:craftbloom/features/admin/products/admin_product_form_screen.dart';
import 'package:craftbloom/features/admin/reviews/admin_reviews_screen.dart';
import 'package:craftbloom/features/admin/metrics/admin_metrics_screen.dart';
import 'package:craftbloom/shared/widgets/main_shell.dart';

// Notifier que avisa al GoRouter cuando el estado de auth cambia,
// sin causar que appRouterProvider se reconstruya.
class _AuthNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();
final _adminShellKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier();

  // ref.listen no reconstruye este provider — solo dispara el callback.
  ref.listen<AsyncValue<dynamic>>(
    currentUserModelProvider,
    (_, _) => authNotifier.notify(),
  );

  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    // GoRouter llama a redirect cada vez que authNotifier notifica,
    // sin recrear el router ni sus GlobalKeys.
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(currentUserModelProvider);
      final user = authState.value;
      final isLoggedIn = user != null;
      final isAdmin = user?.isWorker ?? false;

      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/registro';

      if (isAdminRoute && !isLoggedIn) return '/login';
      if (isAdminRoute && !isAdmin) return '/';
      if (isAuthRoute && isLoggedIn) return '/mi-cuenta';
      return null;
    },
    routes: [
      // ── Shell principal (público) ─────────────
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ShopScreen(showHome: true),
          ),
          GoRoute(
            path: '/shop',
            builder: (context, state) => const ShopScreen(),
          ),
          GoRoute(
            path: '/shop/:id',
            builder: (context, state) => ProductDetailScreen(
              itemId: state.pathParameters['id']!,
              isPackage: state.uri.queryParameters['pack'] == 'true',
            ),
          ),
          GoRoute(
            path: '/pedido/nuevo',
            builder: (context, state) => const NewOrderScreen(),
          ),
          GoRoute(
            path: '/pedido/seguimiento',
            builder: (context, state) => const TrackOrderScreen(),
          ),
          GoRoute(
            path: '/pedido/:code',
            builder: (context, state) => OrderStatusScreen(
              orderCode: state.pathParameters['code']!,
            ),
          ),
          GoRoute(
            path: '/opiniones',
            builder: (context, state) => const ReviewsScreen(),
          ),
          GoRoute(
            path: '/contacto',
            builder: (context, state) => const ContactScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/registro',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/mi-cuenta',
            builder: (context, state) => const MyAccountScreen(),
          ),
        ],
      ),

      // ── Shell admin ───────────────────────────
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/pedidos',
            builder: (context, state) => const AdminOrdersScreen(),
          ),
          GoRoute(
            path: '/admin/pedidos/:id',
            builder: (context, state) => AdminOrderDetailScreen(
              orderId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/admin/productos',
            builder: (context, state) => const AdminProductsScreen(),
          ),
          GoRoute(
            path: '/admin/productos/nuevo',
            builder: (context, state) => const AdminProductFormScreen(),
          ),
          GoRoute(
            path: '/admin/productos/:id/editar',
            builder: (context, state) => AdminProductFormScreen(
              productId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/admin/reviews',
            builder: (context, state) => const AdminReviewsScreen(),
          ),
          GoRoute(
            path: '/admin/metricas',
            builder: (context, state) => const AdminMetricsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('404', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Página no encontrada'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
