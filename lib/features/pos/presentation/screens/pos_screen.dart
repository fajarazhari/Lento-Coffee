import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/errors/failure.dart';
import '../../../inventory/data/repositories/inventory_repository.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../../../transactions/data/models/order_model.dart';
import '../../../transactions/data/repositories/order_repository.dart';
import '../../../transactions/presentation/providers/orders_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';

import '../../../auth/data/models/app_user_model.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../shift/presentation/providers/shift_provider.dart';

const _categories = ['All', 'Coffee', 'Non Coffee', 'Tea', 'Pastry'];

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
    if (product.status == ProductStatus.soldOut) return;
    showDialog(
      context: context,
      builder: (ctx) => _ProductOptionsDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Guard for Owner ──
    final user = demoUserNotifier.value;
    if (user != null && user.role == UserRole.owner) {
      return const _OwnerPosDashboard();
    }

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
                if (item.size != 'Reguler' || item.temperature != 'Hot')
                  Text('${item.size} • ${item.temperature}', style: const TextStyle(fontSize: 10, color: AppColors.coffeeMuted)),
                if (item.addons.isNotEmpty)
                  Text('+ ${item.addons.join(", ")}', style: const TextStyle(fontSize: 10, color: AppColors.goldBrown)),
                if (item.notes.isNotEmpty)
                  Text('Catatan: ${item.notes}', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.coffeeMuted)),
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
    final user = demoUserNotifier.value;
    final shift = ref.read(activeShiftProvider).valueOrNull;
    final cart = widget.cart;

    // Bangun OrderModel dari CartState
    final order = OrderModel(
      id:           '',
      orderNumber:  cart.orderNumber,
      cashierId:    user?.id ?? 'demo',
      cashierName:  user?.name ?? 'Demo Cashier',
      shiftId:      shift?.id ?? '', // INJECT SHIFT ID HERE
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
          items:      cart.items,
        );

        // 3. Kurangi stok inventory sesuai resep (non-blocking)
        ref.read(inventoryRepositoryProvider).deductOrderStock(
          orderId: orderId,
          items:   cart.items,
        );

        // 4. Bersihkan cart dan tutup dialog checkout
        ref.read(cartNotifierProvider.notifier).clear();
        if (!mounted) return;
        Navigator.of(context).pop(); // Tutup dialog checkout
        
        // 5. Tampilkan dialog sukses dengan opsi Cetak Struk
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _SuccessCheckoutDialog(orderNumber: cart.orderNumber),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Guard for Owner ──
    final user = demoUserNotifier.value;
    if (user != null && user.role == UserRole.owner) {
      return Scaffold(
        backgroundColor: AppColors.warmCream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_rounded, size: 64, color: AppColors.notificationBadge),
              const SizedBox(height: 16),
              const Text('Akses Ditolak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.coffeeBrown)),
              const SizedBox(height: 8),
              const Text('Fungsi POS Checkout hanya diperbolehkan untuk akun Kasir.', style: TextStyle(color: AppColors.coffeeMuted)),
            ],
          ),
        ),
      );
    }

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

// ─── Owner POS Dashboard (Brochure View) ──────────────────────────────────────
class _OwnerPosDashboard extends ConsumerWidget {
  const _OwnerPosDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(activeProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Digital Menu Brochure (Owner)', 
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeBrown)),
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.coffeeBrown)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('Belum ada menu yang didaftarkan.'));
          }

          // Real Analytics Parsing (Bestsellers)
          final activeProds = products.where((p) => p.status == ProductStatus.active).toList();
          activeProds.sort((a, b) => b.salesCount.compareTo(a.salesCount));
          final bestSellers = activeProds.take(4).toList();

          final lowStockProducts = products.where((p) => p.status == ProductStatus.soldOut).toList();
          final lowStockIngredients = ref.watch(lowStockIngredientsProvider).valueOrNull ?? [];
          final highlightItem = activeProds.isNotEmpty ? activeProds.first : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Section (Menu Sorotan)
                if (highlightItem != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.coffeeDark, AppColors.coffeeBrown.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: AppColors.coffeeBrown.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: AppColors.goldBrown, borderRadius: BorderRadius.circular(20)),
                                child: const Text('Menu Spesial Hari Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                              ),
                              const SizedBox(height: 16),
                              Text(highlightItem.name, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 8),
                              Text(highlightItem.description.isEmpty ? 'Kopi dengan perpaduan biji pilihan nusantara, disangrai sempurna untuk menemani harimu.' : highlightItem.description,
                                style: const TextStyle(color: AppColors.warmCream, fontSize: 16, height: 1.5)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Container(
                          width: 160, height: 160,
                          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(highlightItem.emoji, style: const TextStyle(fontSize: 80)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],

                // 2. Best Sellers Section
                if (bestSellers.isNotEmpty) ...[
                  const Text('Menu Favorit Pelanggan 🔥', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.coffeeDark)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: bestSellers.length,
                      itemBuilder: (context, index) {
                        final p = bestSellers[index];
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.emoji, style: const TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeDark)),
                              const SizedBox(height: 4),
                              Text(CurrencyFormatter.format(p.basePrice), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.coffeeMuted)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 48),
                ],

                // 3. Low Stock / Sold Out Warnings
                if (lowStockProducts.isNotEmpty || lowStockIngredients.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.notificationBadge, size: 28),
                      const SizedBox(width: 8),
                      const Text('Peringatan Stok & Sold Out', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.coffeeDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16, runSpacing: 16,
                    children: [
                      ...lowStockProducts.map((p) => Container(
                        width: 250,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.notificationBadge.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.notificationBadge.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Text(p.emoji, style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.notificationBadge)),
                                  const SizedBox(height: 4),
                                  const Text('Status: Sold Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.coffeeDark)),
                                ],
                              ),
                            )
                          ],
                        ),
                      )),
                      ...lowStockIngredients.map((i) => Container(
                        width: 250,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.statusOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.statusOrange.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, color: AppColors.statusOrange, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.statusOrange)),
                                  const SizedBox(height: 4),
                                  Text('Sisa: ${i.currentStock} ${i.unit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.coffeeDark)),
                                ],
                              ),
                            )
                          ],
                        ),
                      )),
                    ],
                  )
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Success Checkout Dialog ─────────────────────────────────────────────────
class _SuccessCheckoutDialog extends StatelessWidget {
  const _SuccessCheckoutDialog({required this.orderNumber});
  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.statusGreen, size: 80),
            const SizedBox(height: 16),
            const Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.coffeeDark)),
            const SizedBox(height: 8),
            Text('Order $orderNumber telah diteruskan ke dapur (KDS).', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.coffeeMuted)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulasi mencetak struk berhasil.')));
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Pesanan Baru', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeBrown)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Options Dialog (Phase 1) ─────────────────────────────────────────
class _ProductOptionsDialog extends ConsumerStatefulWidget {
  const _ProductOptionsDialog({required this.product});
  final ProductModel product;

  @override
  ConsumerState<_ProductOptionsDialog> createState() => _ProductOptionsDialogState();
}

class _ProductOptionsDialogState extends ConsumerState<_ProductOptionsDialog> {
  String _size = 'Reguler';
  String _temp = 'Hot';
  String _notes = '';
  final Set<ProductModel> _selectedAddons = {};
  int _quantity = 1;

  double get _totalPrice {
    double base = widget.product.basePrice;
    if (_size == 'Besar') base += 5000;
    for (final a in _selectedAddons) {
      base += a.basePrice;
    }
    return base * _quantity;
  }

  void _submit() {
    final addonsList = _selectedAddons.map((a) => a.name).toList();
    final unitPrice = _totalPrice / _quantity;

    final item = OrderItemModel(
      id: IdGenerator.offlineId('item'),
      productId: widget.product.id,
      productName: widget.product.name,
      category: widget.product.category.label,
      quantity: _quantity,
      unitPrice: unitPrice,
      totalPrice: _totalPrice,
      size: _size,
      temperature: _temp,
      addons: addonsList,
      notes: _notes,
    );
    ref.read(cartNotifierProvider.notifier).addItem(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(widget.product.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.coffeeDark)),
                      Text(CurrencyFormatter.format(widget.product.basePrice), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.goldBrown)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 32),
            
            // Suhu & Ukuran
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suhu', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeMuted)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Hot', 'Ice'].map((t) => Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _temp = t),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _temp == t ? AppColors.statusBlue : AppColors.warmCream,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _temp == t ? AppColors.statusBlue : AppColors.borderColor),
                              ),
                              alignment: Alignment.center,
                              child: Text(t, style: TextStyle(fontWeight: FontWeight.w700, color: _temp == t ? Colors.white : AppColors.coffeeDark)),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ukuran (+5K)', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeMuted)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Reguler', 'Besar'].map((s) => Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _size = s),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _size == s ? AppColors.goldBrown : AppColors.warmCream,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _size == s ? AppColors.goldBrown : AppColors.borderColor),
                              ),
                              alignment: Alignment.center,
                              child: Text(s, style: TextStyle(fontWeight: FontWeight.w700, color: _size == s ? AppColors.coffeeDark : AppColors.coffeeDark)),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Addons
            const Text('Ekstra Topping (Add-ons)', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeMuted)),
            const SizedBox(height: 8),
            productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Text('Gagal memuat add-ons.'),
              data: (products) {
                final addons = products.where((p) => p.category == ProductCategory.addon).toList();
                if (addons.isEmpty) return const Text('Tidak ada add-ons tersedia.', style: TextStyle(fontStyle: FontStyle.italic));
                
                return Wrap(
                  spacing: 8, runSpacing: 8,
                  children: addons.map((a) {
                    final isSel = _selectedAddons.contains(a);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSel) _selectedAddons.remove(a);
                          else _selectedAddons.add(a);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.coffeeBrown : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSel ? AppColors.coffeeBrown : AppColors.borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(a.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSel ? Colors.white : AppColors.coffeeDark)),
                            const SizedBox(width: 4),
                            Text('+${(a.basePrice / 1000).toStringAsFixed(0)}K', style: TextStyle(fontSize: 10, color: isSel ? Colors.white70 : AppColors.goldBrown)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Catatan
            const Text('Catatan Tambahan', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeMuted)),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => _notes = v,
              decoration: InputDecoration(
                hintText: 'Misal: Gula dipisah, es sedikit...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.borderColor),
                filled: true,
                fillColor: AppColors.warmCream,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 32),

            // Footer Submit
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.warmCream, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove_rounded), onPressed: () => setState(() { if (_quantity > 1) _quantity--; })),
                      Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => setState(() => _quantity++)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coffeeBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: Text('Tambah - ${CurrencyFormatter.format(_totalPrice)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
