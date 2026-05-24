import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/router.dart';

/// Shell widget that wraps all pages requiring the sidebar + top bar.
/// Mirrors the CollapsibleSidebar + TopBar from MainActivity.kt.
class PosShell extends StatefulWidget {
  const PosShell({super.key, required this.child});
  final Widget child;

  @override
  State<PosShell> createState() => _PosShellState();
}

class _PosShellState extends State<PosShell> {
  bool _sidebarExpanded = true;
  final _sidebarWidth    = 240.0;
  final _sidebarCollapsed = 72.0;

  static const _navItems = [
    (label: 'Dashboard POS',       icon: Icons.dashboard_rounded,         route: AppRoutes.pos),
    (label: 'Transactions',        icon: Icons.receipt_long_rounded,       route: AppRoutes.transactions),
    (label: 'Products & Menu',     icon: Icons.restaurant_menu_rounded,    route: AppRoutes.products),
    (label: 'Inventory',           icon: Icons.inventory_2_rounded,        route: AppRoutes.inventory),
    (label: 'Sales Reports',       icon: Icons.analytics_rounded,          route: AppRoutes.reports),
    (label: 'Cashier Shift',       icon: Icons.badge_rounded,              route: AppRoutes.shift),
    (label: 'KDS & Barista Queue', icon: Icons.local_cafe_rounded,         route: AppRoutes.kds),
    (label: 'Customer Display',    icon: Icons.tv_rounded,                 route: AppRoutes.customerBoard),
    (label: 'Settings',            icon: Icons.settings_rounded,           route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Column(
        children: [
          // ── Top Bar ──────────────────────────────────────────────────────
          _TopBar(
            isSidebarExpanded: _sidebarExpanded,
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
                    items: _navItems,
                    onTap: (route) => context.go(route),
                  ),
                ),
                // Page content
                Expanded(child: widget.child),
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
    required this.onToggleSidebar,
  });

  final bool isSidebarExpanded;
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
