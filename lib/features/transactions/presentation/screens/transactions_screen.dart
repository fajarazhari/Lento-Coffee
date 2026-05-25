import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_provider.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../data/repositories/order_repository.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
                if (demoUserNotifier.value?.role == UserRole.owner)
                  IconButton(
                    icon: const Icon(Icons.cleaning_services_rounded, color: AppColors.statusRed),
                    tooltip: 'Clean Demo Orders',
                    onPressed: () async {
                      final repo = ref.read(orderRepositoryProvider);
                      await repo.cleanDemoOrders();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo orders deleted')));
                    },
                  ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 240, height: 38,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Cari nomor order / nama...',
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
              data: (allOrders) {
                final orders = allOrders.where((o) {
                  final q = _searchQuery;
                  if (q.isEmpty) return true;
                  return o.orderNumber.toLowerCase().contains(q) || 
                         o.customerName.toLowerCase().contains(q);
                }).toList();

                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            color: AppColors.borderColor, size: 56),
                        SizedBox(height: 12),
                        Text('Belum ada transaksi / tidak ditemukan',
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
                  itemBuilder: (_, i) => InkWell(
                    onTap: () => _showOrderDetailDialog(context, orders[i]),
                    child: _OrderRow(order: orders[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => _OrderDetailDialog(order: order, parentRef: ref),
    );
  }
}

class _OrderDetailDialog extends StatefulWidget {
  const _OrderDetailDialog({required this.order, required this.parentRef});
  final OrderModel order;
  final WidgetRef parentRef;

  @override
  State<_OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<_OrderDetailDialog> {
  bool _isLoading = false;

  Future<void> _voidOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan (Void)?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini? Aksi ini akan mengubah status struk menjadi Cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tutup', style: TextStyle(color: AppColors.coffeeMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Batalkan', style: TextStyle(color: AppColors.statusRed, fontWeight: FontWeight.w800))),
        ],
      )
    );

    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    final repo = widget.parentRef.read(orderRepositoryProvider);
    final res = await repo.cancelOrder(widget.order.id, 'Void by Owner');

    if (!mounted) return;
    setState(() => _isLoading = false);

    res.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membatalkan: ${f.message}'))),
      (_) {
        Navigator.pop(context); // Close detail dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibatalkan.')));
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final isOwner = demoUserNotifier.value?.role == UserRole.owner;
    final canVoid = isOwner && o.status != OrderStatus.cancelled;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Struk Pesanan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.coffeeDark)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nomor Order:', style: TextStyle(color: AppColors.coffeeMuted)),
                Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kasir:', style: TextStyle(color: AppColors.coffeeMuted)),
                Text(o.cashierName, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Waktu:', style: TextStyle(color: AppColors.coffeeMuted)),
                Text('${o.createdAt.hour}:${o.createdAt.minute} - ${o.createdAt.day}/${o.createdAt.month}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Metode Pembayaran:', style: TextStyle(color: AppColors.coffeeMuted)),
                Text(o.paymentMethod.label, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const Divider(height: 32),
            const Text('Item Pesanan', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeDark)),
            const SizedBox(height: 12),
            ...o.items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text('${i.quantity}x', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeBrown)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (i.size.isNotEmpty || i.temperature.isNotEmpty)
                          Text('${i.size} • ${i.temperature}', style: const TextStyle(fontSize: 12, color: AppColors.coffeeMuted)),
                        if (i.addons.isNotEmpty)
                          Text(i.addons.join(', '), style: const TextStyle(fontSize: 12, color: AppColors.coffeeMuted)),
                      ],
                    ),
                  ),
                  Text(CurrencyFormatter.format(i.totalPrice), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            )),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.coffeeDark)),
                Text(CurrencyFormatter.format(o.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.statusGreen)),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldBrown,
                      foregroundColor: AppColors.coffeeDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Cetak Struk', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Mencetak Struk...'),
                          content: const Text('Simulasi cetak struk via thermal printer bluetooth berhasil.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK', style: TextStyle(color: AppColors.coffeeBrown)))
                          ],
                        )
                      );
                    },
                  ),
                ),
                if (canVoid) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.cancel_rounded),
                        label: const Text('Void Pesanan', style: TextStyle(fontWeight: FontWeight.w800)),
                        onPressed: _voidOrder,
                      ),
                  ),
                ]
              ],
            ),
          ],
        ),
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
