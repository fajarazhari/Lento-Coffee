import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // allOrdersProvider includes done/completed orders
    final ordersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                const Text('Transaction History',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.coffeeDark)),
                const Spacer(),
                SizedBox(
                  width: 240, height: 38,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table header
          Container(
            color: AppColors.warmCream,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: const Row(children: [
              SizedBox(width: 120, child: Text('Order #', style: _hStyle)),
              Expanded(flex: 2, child: Text('Customer', style: _hStyle)),
              Expanded(flex: 2, child: Text('Items', style: _hStyle)),
              Expanded(flex: 1, child: Text('Type', style: _hStyle)),
              Expanded(flex: 1, child: Text('Payment', style: _hStyle)),
              Expanded(flex: 1, child: Text('Status', style: _hStyle)),
              SizedBox(width: 110, child: Text('Total', style: _hStyle)),
              SizedBox(width: 70, child: Text('Time', style: _hStyle)),
            ]),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.coffeeBrown)),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            color: AppColors.borderColor, size: 56),
                        SizedBox(height: 12),
                        Text('Belum ada transaksi',
                          style: TextStyle(
                            color: AppColors.coffeeMuted, fontSize: 16)),
                        Text('Transaksi dari POS akan muncul di sini',
                          style: TextStyle(
                            color: AppColors.borderColor, fontSize: 12)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _OrderRow(order: orders[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _hStyle = TextStyle(
  fontSize: 11, fontWeight: FontWeight.w800,
  color: AppColors.coffeeMuted, letterSpacing: 0.5);

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.paid      => AppColors.statusBlue,
      OrderStatus.completed => AppColors.statusGreen,
      OrderStatus.cancelled => AppColors.statusRed,
      _                     => AppColors.coffeeMuted,
    };

    final elapsed = () {
      final diff = DateTime.now().difference(order.createdAt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }();

    return Container(
      color: AppColors.pureWhite,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(children: [
        SizedBox(
          width: 120,
          child: Text(order.orderNumber,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.coffeeBrown, fontSize: 13)),
        ),
        Expanded(flex: 2,
          child: Text(
            order.customerName.isEmpty ? 'Guest' : order.customerName,
            style: const TextStyle(color: AppColors.coffeeDark))),
        Expanded(flex: 2,
          child: Text(
            order.items.isEmpty
                ? '—'
                : order.items
                    .map((i) => '${i.quantity}x ${i.productName}')
                    .join(', '),
            style: const TextStyle(
                color: AppColors.coffeeMuted, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          )),
        Expanded(flex: 1,
          child: Row(children: [
            Icon(
              order.orderType == OrderType.dineIn
                  ? Icons.table_restaurant_rounded
                  : Icons.takeout_dining_rounded,
              size: 14, color: AppColors.coffeeMuted),
            const SizedBox(width: 4),
            Text(
              order.orderType == OrderType.dineIn
                  ? 'Dine In' : 'Take Away',
              style: const TextStyle(
                  color: AppColors.coffeeMuted, fontSize: 12)),
          ])),
        Expanded(flex: 1,
          child: Text(order.paymentMethod.label,
            style: const TextStyle(
                color: AppColors.coffeeDark, fontSize: 13))),
        Expanded(flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(order.status.label,
              style: TextStyle(
                color: statusColor, fontSize: 11,
                fontWeight: FontWeight.w700)),
          )),
        SizedBox(
          width: 110,
          child: Text(CurrencyFormatter.format(order.total),
            style: const TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.coffeeDark))),
        SizedBox(
          width: 70,
          child: Text(elapsed,
            style: const TextStyle(
                color: AppColors.coffeeMuted, fontSize: 11))),
      ]),
    );
  }
}
