import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/presentation/screens/auth_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/pos/presentation/screens/pos_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';
import '../features/products/presentation/screens/products_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/shift/presentation/screens/shift_screen.dart';
import '../features/kitchen/presentation/screens/kds_screen.dart';
import '../features/customer_display/presentation/screens/customer_board_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../shared/widgets/pos_shell.dart';

part 'router.g.dart';

// ─── Shell routes (pages that live inside the sidebar layout) ────────────────
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.auth,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // ── Demo mode guard ────────────────────────────────────────────────────
      // Checks demoRoleNotifier (set when user taps a role button on AuthScreen).
      // Once Firebase is configured, replace this with:
      //   final authState = ref.watch(authStateChangesProvider);
      //   final isLoggedIn = authState.valueOrNull != null;
      final isLoggedIn = demoRoleNotifier.value.isNotEmpty;
      final goingToAuth = state.matchedLocation == AppRoutes.auth;

      if (!isLoggedIn && !goingToAuth) return AppRoutes.auth;
      // Don't redirect away from auth if not logged in — let the user log in
      return null;
    },
    routes: [
      // ── Auth (no shell) ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),

      // ── Customer Board (full-screen, no sidebar) ─────────────────────────
      GoRoute(
        path: AppRoutes.customerBoard,
        name: 'customer_board',
        builder: (context, state) => const CustomerBoardScreen(),
      ),

      // ── Main POS Shell (with collapsible sidebar) ─────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => PosShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.pos,
            name: 'pos',
            builder: (context, state) => const PosScreen(),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            name: 'transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: AppRoutes.products,
            name: 'products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            name: 'inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.shift,
            name: 'shift',
            builder: (context, state) => const ShiftScreen(),
          ),
          GoRoute(
            path: AppRoutes.kds,
            name: 'kds',
            builder: (context, state) => const KdsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

// ─── Route constants ─────────────────────────────────────────────────────────
abstract class AppRoutes {
  static const String auth = '/auth';
  static const String pos = '/pos';
  static const String transactions = '/transactions';
  static const String products = '/products';
  static const String inventory = '/inventory';
  static const String reports = '/reports';
  static const String shift = '/shift';
  static const String kds = '/kds';
  static const String customerBoard = '/customer-board';
  static const String settings = '/settings';
}
