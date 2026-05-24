import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../inventory/data/repositories/inventory_repository.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../transactions/data/models/order_model.dart';
import '../../../transactions/data/repositories/order_repository.dart';
import '../../../transactions/presentation/providers/orders_provider.dart';

const _categories = ['All', 'Coffee', 'Non Coffee', 'Tea', 'Pastry', 'Add On'];

// ─── POS Screen ───────────────────────────────────────────────────────────────
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtering sekarang dilakukan di dalam builder Firestore
  // lihat bagian Expanded > ref.watch(activeProductsProvider).when(...)  

  void _addToCart(ProductModel product) {
    // Guard: produk habis tidak bisa ditambah ke cart
    if (product.status == ProductStatus.soldOut) return;
    final item = OrderItemModel(
      id: IdGenerator.offlineId('item'),
      productId: product.id,
      productName: product.name,
      category: product.category.label,
      quantity: 1,
      unitPrice: product.basePrice,
      totalPrice: product.basePrice,
    );
    ref.read(cartNotifierProvider.notifier).addItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Row(
        children: [
          // ── LEFT: Product Grid ────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  color: AppColors.pureWhite,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Menu',
                            style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800,
                              color: AppColors.coffeeDark,
                            ),
                          ),
                          const Spacer(),
                          // Search
                          SizedBox(
                            width: 220,
                            height: 38,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'Search menu...',
                                hintStyle: const TextStyle(fontSize: 13),
                                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Category chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.coffeeBrown
                                        : AppColors.warmCream,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.coffeeBrown
                                          : AppColors.borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.pureWhite
                                          : AppColors.coffeeDark,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Product grid — live dari Firestore
                Expanded(
                  child: ref.watch(activeProductsProvider).when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.coffeeBrown)),
                    error: (e, _) => Center(
                      child: Text('Error load produk: $e',
                        style: const TextStyle(color: AppColors.statusRed))),
                    data: (allProducts) {
                      final filtered = allProducts.where((p) {
                        final matchCat = _selectedCategory == 'All' ||
                            p.category.label == _selectedCategory;
                        final matchSearch = _searchQuery.isEmpty ||
                            p.name.toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                        return matchCat && matchSearch;
                      }).toList();

                      return filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off_rounded,
                                      color: AppColors.borderColor, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    allProducts.isEmpty
                                        ? 'Belum ada produk.\nSeed data di Settings → Backup'
                                        : 'Tidak ada produk ditemukan',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.coffeeMuted,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                mainAxisExtent: 170,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final p = filtered[i];
                                return _ProductCard(
                                  product: p,
                                  onTap: () => _addToCart(p),
                                );
                              },
                            );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── RIGHT: Cart ───────────────────────────────────────────────────
          Container(
            width: 300,
            decoration: const BoxDecoration(
              color: AppColors.pureWhite,
              border: Border(left: BorderSide(color: AppColors.borderColor)),
            ),
            child: _CartPanel(cart: cart),
          ),
        ],
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  const _ProductCard({required this.product, required this.onTap});
  final ProductModel product;
  final VoidCallback onTap;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSoldOut = widget.product.status == ProductStatus.soldOut;
    // Only show hover effects when product is available
    final showHover = _hovered && !isSoldOut;

    return MouseRegion(
      cursor: isSoldOut
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        // Disable tap entirely when sold out
        onTap: isSoldOut ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: showHover ? AppColors.coffeeBrown : AppColors.pureWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSoldOut
                  ? AppColors.statusRed.withAlpha(60)
                  : showHover ? AppColors.coffeeBrown : AppColors.borderColor,
            ),
            boxShadow: showHover
                ? [BoxShadow(
                    color: AppColors.coffeeBrown.withAlpha(50),
                    blurRadius: 12, offset: const Offset(0, 4))]
                : [BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 4, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji / sold out badge
              Stack(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isSoldOut
                          ? AppColors.warmCream.withAlpha(150)
                          : showHover
                              ? AppColors.pureWhite.withAlpha(30)
                              : AppColors.warmCream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: isSoldOut ? 0.5 : 1.0,
                      child: Text(widget.product.emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  if (isSoldOut)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.statusRed.withAlpha(180),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text('HABIS',
                          style: TextStyle(
                            color: Colors.white, fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSoldOut
                      ? AppColors.coffeeMuted
                      : showHover ? AppColors.pureWhite : AppColors.coffeeDark,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSoldOut
                        ? 'Tidak tersedia'
                        : CurrencyFormatter.format(widget.product.basePrice),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSoldOut
                          ? AppColors.statusRed.withAlpha(180)
                          : showHover ? AppColors.goldBrown : AppColors.coffeeBrown,
                    ),
                  ),
                  // Hide + button when sold out
                  if (!isSoldOut)
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: showHover ? AppColors.goldBrown : AppColors.coffeeBrown,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 16),
                    )
                  else
                    const Icon(Icons.block_rounded,
                        color: AppColors.statusRed, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cart Panel ───────────────────────────────────────────────────────────────
class _CartPanel extends ConsumerStatefulWidget {
  const _CartPanel({required this.cart});
  final CartState cart;

  @override
  ConsumerState<_CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<_CartPanel> {
  final _customerController = TextEditingController();
  final _tableController = TextEditingController();
  OrderType _orderType = OrderType.dineIn;

  @override
  void dispose() {
    _customerController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  void _processPayment() {
    if (widget.cart.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => _PaymentDialog(cart: widget.cart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;

    return Column(
      children: [
        // Cart header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderColor)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_rounded,
                  color: AppColors.coffeeBrown, size: 20),
              const SizedBox(width: 8),
              const Text('Order',
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppColors.coffeeDark,
                ),
              ),
              const Spacer(),
              if (cart.itemCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.coffeeBrown,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${cart.itemCount} items',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => ref.read(cartNotifierProvider.notifier).clear(),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.statusRed, size: 18),
                ),
              ],
            ],
          ),
        ),

        // Order type + customer info
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Dine In / Take Away toggle
              Row(
                children: [
                  _TypeButton(
                    label: 'Dine In',
                    icon: Icons.table_restaurant_rounded,
                    isSelected: _orderType == OrderType.dineIn,
                    onTap: () {
                      setState(() => _orderType = OrderType.dineIn);
                      ref.read(cartNotifierProvider.notifier)
                          .updateOrderMeta(orderType: OrderType.dineIn);
                    },
                  ),
                  const SizedBox(width: 8),
                  _TypeButton(
                    label: 'Take Away',
                    icon: Icons.takeout_dining_rounded,
                    isSelected: _orderType == OrderType.takeAway,
                    onTap: () {
                      setState(() => _orderType = OrderType.takeAway);
                      ref.read(cartNotifierProvider.notifier)
                          .updateOrderMeta(orderType: OrderType.takeAway);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Customer name
              TextField(
                controller: _customerController,
                onChanged: (v) => ref.read(cartNotifierProvider.notifier)
                    .updateOrderMeta(customerName: v),
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
              ),
              if (_orderType == OrderType.dineIn) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _tableController,
                  onChanged: (v) => ref.read(cartNotifierProvider.notifier)
                      .updateOrderMeta(tableNumber: v),
                  decoration: const InputDecoration(
                    labelText: 'Table Number',
                    prefixIcon: Icon(Icons.table_bar_rounded, size: 18),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1),

        // Cart items
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 48, color: AppColors.borderColor),
                      const SizedBox(height: 8),
                      const Text('Cart is empty',
                        style: TextStyle(
                          color: AppColors.coffeeMuted, fontSize: 13)),
                      const Text('Tap a product to add',
                        style: TextStyle(
                          color: AppColors.borderColor, fontSize: 11)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return _CartItemRow(item: item);
                  },
                ),
        ),

        // Totals
        if (!cart.isEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TotalRow('Subtotal', CurrencyFormatter.format(cart.subtotal)),
                const SizedBox(height: 4),
                _TotalRow('Tax (10%)', CurrencyFormatter.format(cart.taxAmount)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                _TotalRow(
                  'TOTAL',
                  CurrencyFormatter.format(cart.total),
                  isBold: true,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _processPayment,
                    icon: const Icon(Icons.payment_rounded, size: 18),
                    label: Text(
                      'Pay ${CurrencyFormatter.format(cart.total)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coffeeBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Cart Item Row ─────────────────────────────────────────────────────────────
class _CartItemRow extends ConsumerWidget {
  const _CartItemRow({required this.item});
  final OrderItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warmCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.coffeeDark)),
                Text(CurrencyFormatter.format(item.unitPrice),
                  style: const TextStyle(
                    fontSize: 11, color: AppColors.coffeeBrown,
                    fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Qty control
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                onTap: () => ref.read(cartNotifierProvider.notifier)
                    .updateQuantity(item.id, item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14,
                    color: AppColors.coffeeDark)),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onTap: () => ref.read(cartNotifierProvider.notifier)
                    .updateQuantity(item.id, item.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Payment Dialog ────────────────────────────────────────────────────────────
class _PaymentDialog extends ConsumerStatefulWidget {
  const _PaymentDialog({required this.cart});
  final CartState cart;

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  PaymentMethod _method = PaymentMethod.cash;
  final _paidController = TextEditingController();
  double _paid = 0;
  bool _isLoading = false;

  double get _change => (_paid - widget.cart.total).clamp(0, double.infinity);
  bool get _canPay => !_isLoading && (_method != PaymentMethod.cash || _paid >= widget.cart.total);

  @override
  void initState() {
    super.initState();
    _paid = widget.cart.total;
    _paidController.text = widget.cart.total.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final repo = ref.read(orderRepositoryProvider);
    final cart = widget.cart;

    // Bangun OrderModel dari CartState
    final order = OrderModel(
      id:           '',
      orderNumber:  cart.orderNumber,
      cashierId:    'demo',
      cashierName:  'Demo Cashier',
      customerName: cart.customerName,
      tableNumber:  cart.tableNumber,
      orderType:    cart.orderType,
      status:       OrderStatus.draft,
      kdsStatus:    KdsStatus.newOrder,
      subtotal:     cart.subtotal,
      taxRate:      0.1,
      taxAmount:    cart.taxAmount,
      total:        cart.total,
      paymentMethod: _method,
      paidAmount:   _method == PaymentMethod.cash ? _paid : cart.total,
      changeDue:    _method == PaymentMethod.cash ? _change : 0,
      notes:        cart.notes,
      createdAt:    DateTime.now(),
      items:        cart.items,
    );

    // 1. Simpan ke Firestore
    final createResult = await repo.createDraftOrder(order);

    await createResult.fold(
      (failure) async {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pesanan: ${failure.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (orderId) async {
        // 2. Proses pembayaran → status=Paid, kdsStatus=NEW
        await repo.processPayment(
          orderId:    orderId,
          method:     _method,
          paidAmount: _method == PaymentMethod.cash ? _paid : cart.total,
          total:      cart.total,
        );

        // 3. Kurangi stok inventory sesuai resep (non-blocking)
        ref.read(inventoryRepositoryProvider).deductOrderStock(
          orderId: orderId,
          items:   cart.items,
        );

        // 3. Bersihkan cart dan tutup dialog
        ref.read(cartNotifierProvider.notifier).clear();
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Order ${cart.orderNumber} berhasil dibayar! Cek KDS 🍳')),
              ],
            ),
            backgroundColor: AppColors.statusGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: AppColors.coffeeDark)),
              const SizedBox(height: 16),

              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.coffeeBrown,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(CurrencyFormatter.format(widget.cart.total),
                      style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment method
              const Text('Payment Method',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.coffeeMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: PaymentMethod.values.map((m) {
                  final isSelected = _method == m;
                  return GestureDetector(
                    onTap: () => setState(() => _method = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.coffeeBrown : AppColors.warmCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.coffeeBrown : AppColors.borderColor),
                      ),
                      child: Text(m.label,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.coffeeDark)),
                    ),
                  );
                }).toList(),
              ),

              if (_method == PaymentMethod.cash) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _paidController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() =>
                      _paid = double.tryParse(v) ?? 0),
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid (Rp)',
                    prefixIcon: Icon(Icons.payments_rounded),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warmCream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Change',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(CurrencyFormatter.format(_change),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15,
                          color: AppColors.coffeeBrown)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _canPay ? _confirm : null,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 16),
                      label: Text(_isLoading ? 'Memproses...' : 'Konfirmasi Bayar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coffeeBrown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────
class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.coffeeBrown : AppColors.warmCream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.coffeeBrown : AppColors.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14,
                color: isSelected ? Colors.white : AppColors.coffeeMuted),
              const SizedBox(width: 4),
              Text(label,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.coffeeDark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: AppColors.warmCream,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Icon(icon, size: 14, color: AppColors.coffeeBrown),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.isBold = false});
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? AppColors.coffeeDark : AppColors.coffeeMuted,
          )),
        Text(value,
          style: TextStyle(
            fontSize: isBold ? 16 : 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isBold ? AppColors.coffeeBrown : AppColors.coffeeDark,
          )),
      ],
    );
  }
}
