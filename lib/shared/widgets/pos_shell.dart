import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/models/app_user_model.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/shift/presentation/providers/shift_provider.dart';
import '../../shared/widgets/lento_button.dart';

/// Shell widget that wraps all pages requiring the sidebar + top bar.
/// Mirrors the CollapsibleSidebar + TopBar from MainActivity.kt.
class PosShell extends ConsumerStatefulWidget {
  const PosShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PosShell> createState() => _PosShellState();
}

class _PosShellState extends ConsumerState<PosShell> {
  bool _sidebarExpanded = true;
  final _sidebarWidth    = 240.0;
  final _sidebarCollapsed = 72.0;

  static const _navItems = [
    (label: 'Dashboard POS',       icon: Icons.dashboard_rounded,         route: AppRoutes.pos),
    (label: 'Transactions',        icon: Icons.receipt_long_rounded,       route: AppRoutes.transactions),
    (label: 'Products & Menu',     icon: Icons.restaurant_menu_rounded,    route: AppRoutes.products),
    (label: 'Inventory',           icon: Icons.inventory_2_rounded,        route: AppRoutes.inventory),
    (label: 'Sales Reports',       icon: Icons.analytics_rounded,          route: AppRoutes.reports),
    (label: 'Shift Karyawan',      icon: Icons.badge_rounded,              route: AppRoutes.shift),
    (label: 'KDS & Barista Queue', icon: Icons.local_cafe_rounded,         route: AppRoutes.kds),
    (label: 'Customer Display',    icon: Icons.tv_rounded,                 route: AppRoutes.customerBoard),
    (label: 'Settings',            icon: Icons.settings_rounded,           route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final user = demoUserNotifier.value;
    
    // We only watch shift state if it's a cashier
    final isCashier = user != null && user.role == UserRole.cashier;
    final hasShift = isCashier ? ref.watch(activeShiftProvider).valueOrNull != null : true;
    
    final bool showGuard = isCashier && !hasShift && currentLocation != AppRoutes.shift;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Column(
        children: [
          // ── Top Bar ──────────────────────────────────────────────────────
          _TopBar(
            isSidebarExpanded: _sidebarExpanded,
            isCashier: isCashier,
            hasShift: hasShift,
            onToggleSidebar: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
          ),
          // ── Body (Sidebar + Content) ──────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Animated sidebar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _sidebarExpanded ? _sidebarWidth : _sidebarCollapsed,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: _Sidebar(
                    isExpanded: _sidebarExpanded,
                    currentRoute: currentLocation,
                    items: user?.role == UserRole.barista 
                        ? _navItems.where((i) => i.route == AppRoutes.kds || i.route == AppRoutes.settings).toList()
                        : _navItems,
                    onTap: (route) => context.go(route),
                  ),
                ),
                // Page content with Guard
                Expanded(
                  child: Stack(
                    children: [
                      widget.child,
                      if (showGuard)
                        Container(
                          color: AppColors.coffeeDark.withOpacity(0.9),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_person_rounded, size: 72, color: AppColors.goldBrown),
                              const SizedBox(height: 24),
                              const Text('Akses Dibatasi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.pureWhite)),
                              const SizedBox(height: 8),
                              const Text('Anda wajib membuka laci (Shift) sebelum dapat menggunakan menu ini.',
                                style: TextStyle(color: AppColors.warmCream, fontSize: 16)),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.goldBrown,
                                  foregroundColor: AppColors.coffeeDark,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Buka Shift Sekarang', style: TextStyle(fontWeight: FontWeight.w800)),
                                onPressed: () => context.go(AppRoutes.shift),
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isSidebarExpanded,
    required this.isCashier,
    required this.hasShift,
    required this.onToggleSidebar,
  });

  final bool isSidebarExpanded;
  final bool isCashier;
  final bool hasShift;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: AppColors.pureWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Hamburger
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: AppColors.coffeeBrown,
            onPressed: onToggleSidebar,
          ),
          const SizedBox(width: 8),
          // Logo
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.coffeeBrown,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.coffee_rounded, color: AppColors.goldBrown, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'LENTO COFFEE',
            style: const TextStyle(
              color: AppColors.coffeeBrown,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // Clock
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (_, __) {
              final now = DateTime.now();
              final time = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
              return Text(
                time,
                style: const TextStyle(
                  color: AppColors.coffeeDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            color: AppColors.coffeeBrown,
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          // Logout Button
          Container(
            decoration: BoxDecoration(
              color: AppColors.statusOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.statusOrange),
              tooltip: 'Keluar (Logout)',
              onPressed: () {
                if (isCashier && hasShift) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Anda tidak bisa keluar. Harap tutup shift terlebih dahulu.'),
                      backgroundColor: AppColors.statusOrange,
                    ),
                  );
                  return;
                }
                demoUserNotifier.value = null;
                context.go(AppRoutes.auth);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.isExpanded,
    required this.currentRoute,
    required this.items,
    required this.onTap,
  });

  final bool isExpanded;
  final String currentRoute;
  final List<({String label, IconData icon, String route})> items;
  final void Function(String route) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pureWhite,
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...items.map((item) {
            final isActive = currentRoute == item.route ||
                (item.route == AppRoutes.pos && currentRoute == '/');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTap(item.route),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 46,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.coffeeBrown : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isExpanded
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 22,
                                  color: isActive
                                      ? AppColors.warmCream
                                      : AppColors.coffeeBrown.withAlpha(150),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isActive
                                          ? AppColors.warmCream
                                          : AppColors.coffeeDark.withAlpha(200),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Icon(
                              item.icon,
                              size: 22,
                              color: isActive
                                  ? AppColors.warmCream
                                  : AppColors.coffeeBrown.withAlpha(150),
                            ),
                          ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
