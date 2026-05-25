import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/data/models/order_model.dart';
import '../../../transactions/presentation/providers/orders_provider.dart';

class KdsScreen extends ConsumerWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use kdsOrdersProvider so DONE column is also populated
    final ordersAsync = ref.watch(kdsOrdersProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            height: 64,
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.local_cafe_rounded,
                    color: AppColors.goldBrown, size: 24),
                const SizedBox(width: 12),
                const Text('Kitchen Display System',
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w800, letterSpacing: 1)),
                const Spacer(),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (_, __) {
                    final t = DateTime.now();
                    return Text(
                      '${t.hour.toString().padLeft(2,'0')}:'
                      '${t.minute.toString().padLeft(2,'0')}:'
                      '${t.second.toString().padLeft(2,'0')}',
                      style: const TextStyle(color: Colors.white70,
                          fontSize: 15, fontWeight: FontWeight.w700,
                          fontFamily: 'monospace'),
                    );
                  },
                ),
                const SizedBox(width: 24),
                ordersAsync.when(
                  data: (orders) => _HeaderStat(
                    label: 'Active',
                    value: orders
                        .where((o) => o.kdsStatus != KdsStatus.done)
                        .length
                        .toString(),
                    color: AppColors.statusOrange,
                  ),
                  loading: () => const _HeaderStat(
                      label: 'Active', value: '-',
                      color: AppColors.statusOrange),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
          // ── Kanban Board ─────────────────────────────────────────────────────
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.goldBrown)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.red))),
              data: (orders) {
                final newOrders =
                    orders.where((o) => o.kdsStatus == KdsStatus.newOrder).toList();
                final brewingOrders =
                    orders.where((o) => o.kdsStatus == KdsStatus.brewing).toList();
                final readyOrders =
                    orders.where((o) => o.kdsStatus == KdsStatus.ready).toList();
                // Sort DONE: terbaru (completedAt) paling atas
                final doneOrders = orders
                    .where((o) => o.kdsStatus == KdsStatus.done)
                    .toList()
                  ..sort((a, b) =>
                      (b.completedAt ?? b.createdAt)
                          .compareTo(a.completedAt ?? a.createdAt));

                return Row(
                  children: [
                    _KdsColumn(title: 'NEW',     color: const Color(0xFFEF5350),
                        orders: newOrders,     nextStatus: KdsStatus.brewing,  now: now),
                    _KdsColumn(title: 'BREWING', color: const Color(0xFFFF9800),
                        orders: brewingOrders, nextStatus: KdsStatus.ready,    now: now),
                    _KdsColumn(title: 'READY',   color: const Color(0xFF4CAF50),
                        orders: readyOrders,   nextStatus: KdsStatus.done,     now: now),
                    _KdsColumn(title: 'DONE',    color: const Color(0xFF78909C),
                        orders: doneOrders,    nextStatus: null,               now: now),
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

// ── Column ───────────────────────────────────────────────────────────────────
class _KdsColumn extends StatelessWidget {
  const _KdsColumn({
    required this.title,
    required this.color,
    required this.orders,
    required this.nextStatus,
    required this.now,
  });
  final String title;
  final Color color;
  final List<OrderModel> orders;
  final KdsStatus? nextStatus;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3460).withAlpha(180),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80), width: 1.5),
        ),
        child: Column(
          children: [
            // Column header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(title,
                    style: TextStyle(color: color, fontSize: 13,
                        fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withAlpha(60),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${orders.length}',
                      style: TextStyle(color: color, fontSize: 12,
                          fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            // Cards
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              color: color.withAlpha(80), size: 40),
                          const SizedBox(height: 8),
                          Text('Kosong',
                            style: TextStyle(
                                color: color.withAlpha(100), fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: orders.length,
                      itemBuilder: (_, i) => _KdsCard(
                        order: orders[i],
                        columnColor: color,
                        nextStatus: nextStatus,
                        now: now,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _KdsCard extends ConsumerWidget {
  const _KdsCard({
    required this.order,
    required this.columnColor,
    required this.nextStatus,
    required this.now,
  });
  final OrderModel order;
  final Color columnColor;
  final KdsStatus? nextStatus;
  final DateTime now;

  String _elapsed() {
    final diff = now.difference(order.createdAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
    }
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  Color _elapsedColor() {
    final mins = now.difference(order.createdAt).inMinutes;
    if (mins >= 10) return AppColors.statusRed;
    if (mins >= 5) return AppColors.statusOrange;
    return AppColors.statusGreen;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: order.isPriority
              ? AppColors.statusRed
              : columnColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: columnColor.withAlpha(25),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                if (order.isPriority)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.star_rounded, color: AppColors.statusRed, size: 16),
                  ),
                Text(order.orderNumber,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w900)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: order.orderType == OrderType.dineIn ? AppColors.statusBlue.withAlpha(60) : AppColors.statusOrange.withAlpha(60),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.orderType == OrderType.dineIn ? 'DINE IN' : 'TAKE AWAY',
                    style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: order.orderType == OrderType.dineIn ? AppColors.statusBlue : AppColors.statusOrange,
                    ),
                  ),
                ),
                if (nextStatus == KdsStatus.brewing) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ref.read(kdsActionsNotifierProvider.notifier).togglePriority(order.id, !order.isPriority),
                    child: Icon(order.isPriority ? Icons.star_rounded : Icons.star_border_rounded, color: order.isPriority ? AppColors.statusRed : Colors.white38, size: 20),
                  ),
                ],
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.customerName.isNotEmpty)
                  Text(order.customerName,
                    style: const TextStyle(
                      color: AppColors.goldBrown, fontSize: 14,
                      fontWeight: FontWeight.w800)),
                if (order.orderType == OrderType.dineIn)
                  Text('Meja ${order.tableNumber}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
                if (order.items.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.quantity}x', style: const TextStyle(color: AppColors.goldBrown, fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              if (item.size != 'Reguler' || item.temperature != 'Hot')
                                Text('${item.size} • ${item.temperature}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                              if (item.addons.isNotEmpty)
                                Text('+ ${item.addons.join(", ")}', style: const TextStyle(color: AppColors.goldBrown, fontSize: 13, fontWeight: FontWeight.w700)),
                              if (item.notes.isNotEmpty)
                                Text('Note: ${item.notes}', style: const TextStyle(color: AppColors.statusOrange, fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ]),
                  )),
                ] else
                  Text(CurrencyFormatter.format(order.total), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                
                if (order.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.statusOrange.withAlpha(40), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.statusOrange.withAlpha(100))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.statusOrange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(order.notes, style: const TextStyle(color: AppColors.statusOrange, fontSize: 13, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: _elapsedColor()),
                    const SizedBox(width: 4),
                    Text(_elapsed(),
                      style: TextStyle(
                        color: _elapsedColor(), fontSize: 11,
                        fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (nextStatus == null) // This means it's in DONE column
                      GestureDetector(
                        onTap: () => ref.read(kdsActionsNotifierProvider.notifier).advance(order.id, KdsStatus.ready),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: columnColor.withAlpha(100))),
                          child: Row(
                            children: [
                              Icon(Icons.undo_rounded, color: columnColor, size: 12),
                              const SizedBox(width: 4),
                              Text('REVERT', style: TextStyle(color: columnColor, fontSize: 10, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => ref.read(kdsActionsNotifierProvider.notifier).advance(order.id, nextStatus!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: columnColor, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            nextStatus == KdsStatus.brewing ? 'START' :
                            nextStatus == KdsStatus.ready   ? 'READY' : 'DONE',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header Stat ───────────────────────────────────────────────────────────────
class _HeaderStat extends StatelessWidget {
  const _HeaderStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 9,
                fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
