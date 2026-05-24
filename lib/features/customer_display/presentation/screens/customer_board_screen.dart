import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../transactions/data/models/order_model.dart';
import '../../../transactions/presentation/providers/orders_provider.dart';

class CustomerBoardScreen extends ConsumerWidget {
  const CustomerBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(activeOrdersProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.coffeeDark,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            height: 80,
            color: const Color(0xFF2C1810),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.coffeeBrown,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.coffee_rounded,
                      color: AppColors.goldBrown, size: 26),
                ),
                const SizedBox(width: 14),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LENTO COFFEE',
                      style: TextStyle(
                        color: AppColors.goldBrown, fontSize: 22,
                        fontWeight: FontWeight.w900, letterSpacing: 3,
                      ),
                    ),
                    Text('Order Status Board',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (_, __) {
                    final t = DateTime.now();
                    return Text(
                      '${t.hour.toString().padLeft(2,'0')}:'
                      '${t.minute.toString().padLeft(2,'0')}:'
                      '${t.second.toString().padLeft(2,'0')}',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.w300, letterSpacing: 2,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.statusGreen.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.statusGreen),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle,
                          color: AppColors.statusGreen, size: 8),
                      SizedBox(width: 6),
                      Text('OPEN',
                        style: TextStyle(
                          color: AppColors.statusGreen, fontSize: 12,
                          fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.exit_to_app_rounded,
                      color: Colors.white38, size: 20),
                  tooltip: 'Kembali ke POS',
                  onPressed: () => context.go(AppRoutes.pos),
                ),
              ],
            ),
          ),
          // ── Main content ────────────────────────────────────────────────────
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.goldBrown)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.red))),
              data: (orders) {
                final preparing = orders
                    .where((o) =>
                        o.kdsStatus == KdsStatus.newOrder ||
                        o.kdsStatus == KdsStatus.brewing)
                    .toList();
                final ready = orders
                    .where((o) => o.kdsStatus == KdsStatus.ready)
                    .toList();

                return Row(
                  children: [
                    // LEFT: Now Preparing (65%)
                    Expanded(
                      flex: 65,
                      child: _PreparingPanel(
                          preparing: preparing, now: now),
                    ),
                    Container(width: 2,
                        color: AppColors.coffeeBrown.withAlpha(80)),
                    // RIGHT: Ready for Pickup (35%)
                    Expanded(
                      flex: 35,
                      child: _ReadyPanel(ready: ready),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preparing Panel ───────────────────────────────────────────────────────────
class _PreparingPanel extends StatelessWidget {
  const _PreparingPanel({required this.preparing, required this.now});
  final List<OrderModel> preparing;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C0F0A),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: AppColors.coffeeBrown.withAlpha(80)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.statusOrange, size: 22),
                const SizedBox(width: 10),
                const Text('SEDANG DISIAPKAN',
                  style: TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w900, letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text('${preparing.length} pesanan',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: preparing.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_empty_rounded,
                            color: Colors.white12, size: 56),
                        SizedBox(height: 12),
                        Text('Belum ada pesanan',
                          style: TextStyle(
                              color: Colors.white24, fontSize: 16)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisExtent: 150,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: preparing.length > 6 ? 6 : preparing.length,
                    itemBuilder: (_, i) {
                      final o = preparing[i];
                      return _PreparingCard(
                          order: o, isHighlighted: i == 0, now: now);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Ready Panel ───────────────────────────────────────────────────────────────
class _ReadyPanel extends StatelessWidget {
  const _ReadyPanel({required this.ready});
  final List<OrderModel> ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1F0D),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: AppColors.statusGreen.withAlpha(80)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.statusGreen, size: 22),
                const SizedBox(width: 10),
                const Text('SIAP DIAMBIL',
                  style: TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w900, letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text('${ready.length}',
                  style: const TextStyle(
                    color: AppColors.statusGreen,
                    fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Expanded(
            child: ready.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.coffee_outlined,
                            color: Colors.white12, size: 56),
                        SizedBox(height: 12),
                        Text('Belum ada pesanan siap',
                          style: TextStyle(
                              color: Colors.white24, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ready.length,
                    itemBuilder: (_, i) => _ReadyCard(order: ready[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Preparing Card ────────────────────────────────────────────────────────────
class _PreparingCard extends StatelessWidget {
  const _PreparingCard({
    required this.order,
    required this.isHighlighted,
    required this.now,
  });
  final OrderModel order;
  final bool isHighlighted;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final statusLabel = order.kdsStatus == KdsStatus.brewing
        ? 'DIPROSES'
        : 'MENUNGGU';
    final statusColor = order.kdsStatus == KdsStatus.brewing
        ? AppColors.statusOrange
        : const Color(0xFF90CAF9);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.coffeeBrown.withAlpha(60)
            : const Color(0xFF1A0E0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? AppColors.coffeeBrown : Colors.white12,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(order.orderNumber,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isHighlighted ? AppColors.goldBrown : Colors.white,
                    fontSize: isHighlighted ? 22 : 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withAlpha(100)),
                ),
                child: Text(statusLabel,
                  style: TextStyle(
                    color: statusColor, fontSize: 8,
                    fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          if (order.customerName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(order.customerName,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text(() {
                final diff = now.difference(order.createdAt);
                return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
              }(),
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ready Card ────────────────────────────────────────────────────────────────
class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusGreen.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.statusGreen.withAlpha(100), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.statusGreen, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.orderNumber,
                style: const TextStyle(
                  color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w900)),
              if (order.customerName.isNotEmpty)
                Text(order.customerName,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
