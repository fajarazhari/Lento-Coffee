import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../inventory/data/models/ingredient_model.dart';
import '../../../inventory/data/models/recipe_model.dart';
import '../../../inventory/data/repositories/inventory_repository.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../providers/products_provider.dart';

// ─── Emoji presets per kategori ───────────────────────────────────────────────
const _emojiPresets = {
  'Coffee':     ['☕','🍫','🧊','⏳','🥛','🌊'],
  'Non Coffee': ['🍫','🍦','🍮','🍓','🥤','🧃'],
  'Tea':        ['🍵','🫖','🌸','💜','🍃','🌿'],
  'Pastry':     ['🥐','🍌','🧁','🍰','🥧','🎂'],
  'Add On':     ['⚡','🌾','🍦','🍮','🧂','💧'],
};

const _allCategories = ['All', 'Coffee', 'Non Coffee', 'Tea', 'Pastry', 'Add On'];
const _formCategories = ['Coffee', 'Non Coffee', 'Tea', 'Pastry', 'Add On'];

// ─── Screen ───────────────────────────────────────────────────────────────────
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});
  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _ProductFormDialog(
        initialCategory: _selectedCategory == 'All' ? 'Coffee' : _selectedCategory,
      ),
    );
  }

  void _openEditDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk?',
          style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${product.emoji} ${product.name}',
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.coffeeDark)),
            const SizedBox(height: 8),
            const Text('Produk yang dihapus tidak bisa dikembalikan.',
              style: TextStyle(color: AppColors.coffeeMuted, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(productRepositoryProvider).deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} dihapus'),
            backgroundColor: AppColors.statusRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus(ProductModel product) async {
    final next = product.status == ProductStatus.active
        ? ProductStatus.soldOut
        : ProductStatus.active;
    await ref.read(productRepositoryProvider).setStatus(product.id, next);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Row(
        children: [
          // ── LEFT: Category sidebar ─────────────────────────────────────────
          Container(
            width: 200,
            color: AppColors.pureWhite,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.borderColor)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.restaurant_menu_rounded,
                        color: AppColors.coffeeBrown, size: 20),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text('Produk & Menu',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: AppColors.coffeeDark)),
                    ),
                  ]),
                ),
                // Stats per category
                Expanded(
                  child: productsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => const SizedBox(),
                    data: (products) {
                      return ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: _allCategories.map((cat) {
                          final count = cat == 'All'
                              ? products.length
                              : products
                                  .where((p) => p.category.label == cat)
                                  .length;
                          final isActive = _selectedCategory == cat;
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.coffeeBrown
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _categoryEmoji(cat),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(cat,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isActive
                                            ? Colors.white
                                            : AppColors.coffeeDark)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.white.withAlpha(50)
                                          : AppColors.warmCream,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('$count',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isActive
                                            ? Colors.white
                                            : AppColors.coffeeMuted)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                // Add button at bottom of sidebar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openAddDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Menu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coffeeBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── RIGHT: Product grid ────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  color: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _selectedCategory == 'All'
                              ? 'Semua Menu'
                              : _selectedCategory,
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: AppColors.coffeeDark),
                        ),
                      ),
                      const Spacer(),
                      // Search
                      SizedBox(
                        width: 240,
                        height: 38,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Cari menu...',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(
                                Icons.search_rounded, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 16),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    })
                                : null,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Product grid
                Expanded(
                  child: productsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.coffeeBrown)),
                    error: (e, _) => Center(
                      child: Text('Error: $e',
                        style:
                            const TextStyle(color: AppColors.statusRed))),
                    data: (products) {
                      final filtered = products.where((p) {
                        final matchCat = _selectedCategory == 'All' ||
                            p.category.label == _selectedCategory;
                        final matchSearch = _searchQuery.isEmpty ||
                            p.name.toLowerCase().contains(
                                _searchQuery.toLowerCase());
                        return matchCat && matchSearch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fastfood_rounded,
                                  color: AppColors.borderColor, size: 56),
                              const SizedBox(height: 12),
                              Text(
                                products.isEmpty
                                    ? 'Belum ada menu.\nKlik "Tambah Menu" untuk mulai.'
                                    : 'Tidak ada menu di kategori ini.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.coffeeMuted,
                                  fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisExtent: 200,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _ProductManageCard(
                          product: filtered[i],
                          onEdit: () => _openEditDialog(filtered[i]),
                          onDelete: () => _confirmDelete(filtered[i]),
                          onToggleStatus: () =>
                              _toggleStatus(filtered[i]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String cat) => switch (cat) {
    'All'        => '🍽️',
    'Coffee'     => '☕',
    'Non Coffee' => '🥤',
    'Tea'        => '🍵',
    'Pastry'     => '🥐',
    'Add On'     => '⚡',
    _            => '📦',
  };
}

// ─── Product Management Card ──────────────────────────────────────────────────
class _ProductManageCard extends StatefulWidget {
  const _ProductManageCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  @override
  State<_ProductManageCard> createState() => _ProductManageCardState();
}

class _ProductManageCardState extends State<_ProductManageCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSoldOut = widget.product.status == ProductStatus.soldOut;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? AppColors.coffeeBrown
                : isSoldOut
                    ? AppColors.statusRed.withAlpha(80)
                    : AppColors.borderColor,
            width: _hovered ? 2 : 1,
          ),
          boxShadow: _hovered
              ? [BoxShadow(
                  color: AppColors.coffeeBrown.withAlpha(40),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: emoji + status badge
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isSoldOut
                          ? AppColors.warmCream.withAlpha(180)
                          : AppColors.warmCream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.product.emoji,
                        style: TextStyle(
                          fontSize: 26,
                          color: isSoldOut ? null : null,
                        )),
                  ),
                  const Spacer(),
                  // Status toggle chip — shows all 3 states
                  GestureDetector(
                    onTap: widget.onToggleStatus,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.product.status == ProductStatus.hidden
                            ? AppColors.coffeeMuted.withAlpha(30)
                            : isSoldOut
                                ? AppColors.statusRed.withAlpha(30)
                                : AppColors.statusGreen.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.product.status == ProductStatus.hidden
                              ? AppColors.coffeeMuted.withAlpha(100)
                              : isSoldOut
                                  ? AppColors.statusRed.withAlpha(100)
                                  : AppColors.statusGreen.withAlpha(100),
                        ),
                      ),
                      child: Text(
                        widget.product.status == ProductStatus.hidden
                            ? 'HIDDEN'
                            : isSoldOut ? 'HABIS' : 'AKTIF',
                        style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w900,
                          color: widget.product.status == ProductStatus.hidden
                              ? AppColors.coffeeMuted
                              : isSoldOut
                                  ? AppColors.statusRed
                                  : AppColors.statusGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Name + category
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: isSoldOut
                          ? AppColors.coffeeMuted
                          : AppColors.coffeeDark)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warmCream,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(widget.product.category.label,
                      style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.coffeeBrown)),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Price + actions
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 8, 10),
              child: Row(
                children: [
                  Text(
                    CurrencyFormatter.format(widget.product.basePrice),
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900,
                      color: AppColors.coffeeBrown),
                  ),
                  const Spacer(),
                  // Edit button
                  _ActionIconBtn(
                    icon: Icons.edit_rounded,
                    color: AppColors.statusBlue,
                    tooltip: 'Edit',
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 2),
                  // Delete button
                  _ActionIconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.statusRed,
                    tooltip: 'Hapus',
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  const _ActionIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ─── Provider: ingredients for recipe tab ─────────────────────────────────────
final _allIngredientsProvider = StreamProvider<List<IngredientModel>>((ref) {
  return ref.watch(inventoryRepositoryProvider).watchIngredients();
});

// ─── Helper: mutable recipe row ───────────────────────────────────────────────
class _RecipeEntry {
  _RecipeEntry({required this.ingredientName, double qty = 0, required this.unit})
      : qtyCtrl = TextEditingController(
            text: qty == 0 ? '' : qty.toStringAsFixed(qty % 1 == 0 ? 0 : 1));

  String ingredientName;
  String unit;
  final TextEditingController qtyCtrl;

  void dispose() => qtyCtrl.dispose();
}

// ─── Add / Edit Dialog ────────────────────────────────────────────────────────
class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog({this.product, this.initialCategory = 'Coffee'});

  final ProductModel? product;
  final String initialCategory;

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog>
    with SingleTickerProviderStateMixin {
  // Info tab
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _emojiCtrl;
  late String _category;
  late ProductStatus _status;
  bool _saving = false;

  // Tab
  late TabController _tabController;

  // Recipe tab
  final List<_RecipeEntry> _recipeItems = [];
  bool _recipeLoaded = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final p = widget.product;
    _nameCtrl  = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.basePrice.toStringAsFixed(0) : '');
    _descCtrl  = TextEditingController(text: p?.description ?? '');
    _emojiCtrl = TextEditingController(text: p?.emoji ?? '☕');
    _category  = p?.category.label ?? widget.initialCategory;
    _status    = p?.status ?? ProductStatus.active;
    if (_isEdit) {
      _loadRecipe();
    } else {
      _recipeLoaded = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _emojiCtrl.dispose();
    for (final e in _recipeItems) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    final slug = _slugify(widget.product!.name);
    final snap = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(slug)
        .get();
    if (!mounted) return;
    if (snap.exists) {
      final recipe = RecipeModel.fromFirestore(snap);
      setState(() {
        _recipeItems.addAll(recipe.ingredients.map((ri) => _RecipeEntry(
              ingredientName: ri.ingredientName,
              qty: ri.quantity,
              unit: ri.unit,
            )));
      });
    }
    setState(() => _recipeLoaded = true);
  }

  static String _slugify(String name) =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');

  Future<void> _save() async {
    if (_formKey.currentState?.validate() == false) {
      _tabController.animateTo(0);
      return;
    }
    // If form is unmounted (in background tab), do a manual basic check
    if (_nameCtrl.text.trim().isEmpty) {
      _tabController.animateTo(0);
      return;
    }
    setState(() => _saving = true);

    final repo = ref.read(productRepositoryProvider);
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0;
    final productName = _nameCtrl.text.trim();
    final emoji = _emojiCtrl.text.trim().isEmpty ? '☕' : _emojiCtrl.text.trim();

    if (_isEdit) {
      final updated = ProductModel(
        id:          widget.product!.id,
        name:        productName,
        description: _descCtrl.text.trim(),
        category:    ProductCategoryX.fromString(_category),
        basePrice:   price,
        emoji:       emoji,
        status:      _status,
        sortOrder:   widget.product!.sortOrder,
      );
      await repo.updateProduct(updated);
    } else {
      final newProduct = ProductModel(
        id:          '',
        name:        productName,
        description: _descCtrl.text.trim(),
        category:    ProductCategoryX.fromString(_category),
        basePrice:   price,
        emoji:       emoji,
        status:      _status,
        sortOrder:   999,
      );
      final result = await repo.createProduct(newProduct);
      if (mounted && result.isLeft()) {
        result.fold(
          (f) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${f.message}'),
              backgroundColor: AppColors.statusRed,
              behavior: SnackBarBehavior.floating,
            ),
          ),
          (_) {},
        );
        setState(() => _saving = false);
        return;
      }
    }

    // Save recipe to Firestore
    final validItems = _recipeItems.where((e) =>
        e.ingredientName.isNotEmpty &&
        (double.tryParse(e.qtyCtrl.text) ?? 0) > 0).toList();

    if (validItems.isNotEmpty) {
      final slug = _slugify(productName);
      await FirebaseFirestore.instance.collection('recipes').doc(slug).set({
        'productName': productName,
        'ingredients': validItems.map((e) => {
          'ingredientName': e.ingredientName,
          'quantity': double.tryParse(e.qtyCtrl.text) ?? 0,
          'unit': e.unit,
        }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Text(_isEdit
              ? '$productName diperbarui${validItems.isNotEmpty ? ' + resep disimpan ✅' : ''}'
              : '$emoji $productName ditambahkan ke menu!'),
        ]),
        backgroundColor: AppColors.statusGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = _emojiPresets[_category] ?? ['☕'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 520,
        height: 620,
        child: Column(
          children: [
            // ── Header + TabBar ────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: AppColors.coffeeBrown,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                  child: Row(children: [
                    Text(
                      _isEdit ? '✏️  Edit Menu' : '➕  Tambah Menu Baru',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ]),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.goldBrown,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  tabs: [
                    const Tab(
                        icon: Icon(Icons.info_outline_rounded, size: 15),
                        text: 'Info Menu'),
                    Tab(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.science_outlined, size: 15),
                        const SizedBox(width: 6),
                        const Text('Resep & Bahan'),
                        if (_recipeItems.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.goldBrown,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${_recipeItems.length}',
                                style: const TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ]),
                    ),
                  ],
                ),
              ]),
            ),

            // ── Tab content ────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Info
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FormLabel('Kategori'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _category,
                            decoration: _inputDeco('Pilih kategori'),
                            items: _formCategories.map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(children: [
                                Text(_catEmoji(c),
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(c),
                              ]),
                            )).toList(),
                            onChanged: (v) => setState(() {
                              _category = v!;
                              if (!_isEdit) {
                                _emojiCtrl.text = (_emojiPresets[v] ?? ['☕']).first;
                              }
                            }),
                          ),
                          const SizedBox(height: 14),
                          _FormLabel('Nama Menu *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: _inputDeco('Contoh: Matcha Latte With Stick'),
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? 'Nama tidak boleh kosong' : null,
                          ),
                          const SizedBox(height: 14),
                          _FormLabel('Emoji'),
                          const SizedBox(height: 6),
                          Row(children: [
                            SizedBox(
                              width: 90,
                              child: TextFormField(
                                controller: _emojiCtrl,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 24),
                                decoration: _inputDeco('').copyWith(isDense: true),
                                maxLength: 4,
                                buildCounter: (_, {required currentLength,
                                    required isFocused, required maxLength}) => null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                spacing: 8, runSpacing: 8,
                                children: presets.map((e) => GestureDetector(
                                  onTap: () => setState(() => _emojiCtrl.text = e),
                                  child: Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: _emojiCtrl.text == e
                                          ? AppColors.coffeeBrown : AppColors.warmCream,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _emojiCtrl.text == e
                                            ? AppColors.coffeeBrown : AppColors.borderColor),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(e, style: const TextStyle(fontSize: 20)),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          _FormLabel('Harga (Rp) *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _inputDeco('Contoh: 38000'),
                            validator: (v) {
                              final price = double.tryParse(v ?? '');
                              if (price == null || price <= 0) {
                                return 'Masukkan harga yang valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _FormLabel('Deskripsi'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 2,
                            decoration: _inputDeco(
                                'Contoh: Matcha premium dengan stick crunchy'),
                          ),
                          const SizedBox(height: 14),
                          _FormLabel('Status'),
                          const SizedBox(height: 6),
                          Row(children: [
                            _StatusChip(
                              label: 'Aktif',
                              icon: Icons.check_circle_rounded,
                              color: AppColors.statusGreen,
                              isSelected: _status == ProductStatus.active,
                              onTap: () => setState(() => _status = ProductStatus.active),
                            ),
                            const SizedBox(width: 10),
                            _StatusChip(
                              label: 'Habis',
                              icon: Icons.remove_circle_rounded,
                              color: AppColors.statusRed,
                              isSelected: _status == ProductStatus.soldOut,
                              onTap: () => setState(() => _status = ProductStatus.soldOut),
                            ),
                            const SizedBox(width: 10),
                            _StatusChip(
                              label: 'Sembunyikan',
                              icon: Icons.visibility_off_rounded,
                              color: AppColors.coffeeMuted,
                              isSelected: _status == ProductStatus.hidden,
                              onTap: () => setState(() => _status = ProductStatus.hidden),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          // Tip: go to recipe tab
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.statusGreen.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.statusGreen.withAlpha(60)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.science_outlined,
                                  size: 14, color: AppColors.statusGreen),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Buka tab "Resep & Bahan" untuk mengatur bahan baku yang otomatis dikurangi saat menu ini dipesan.',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.statusGreen),
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab 2: Recipe editor
                  _RecipeTab(
                    recipeItems: _recipeItems,
                    recipeLoaded: _recipeLoaded,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderColor)),
              ),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(
                            _isEdit ? Icons.save_rounded : Icons.add_rounded,
                            size: 18),
                    label: Text(_saving
                        ? 'Menyimpan...'
                        : _isEdit ? 'Simpan Perubahan' : 'Tambah ke Menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coffeeBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _catEmoji(String cat) => switch (cat) {
    'Coffee'     => '☕',
    'Non Coffee' => '🥤',
    'Tea'        => '🍵',
    'Pastry'     => '🥐',
    'Add On'     => '⚡',
    _            => '📦',
  };

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.borderColor, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    isDense: true,
  );
}

// ─── Recipe Tab ───────────────────────────────────────────────────────────────
class _RecipeTab extends ConsumerStatefulWidget {
  const _RecipeTab({
    required this.recipeItems,
    required this.recipeLoaded,
    required this.onChanged,
  });
  final List<_RecipeEntry> recipeItems;
  final bool recipeLoaded;
  final VoidCallback onChanged;

  @override
  ConsumerState<_RecipeTab> createState() => _RecipeTabState();
}

class _RecipeTabState extends ConsumerState<_RecipeTab> {
  String? _selectedName;

  void _addEntry(List<IngredientModel> all) {
    if (_selectedName == null) return;
    final ing = all.firstWhere((i) => i.name == _selectedName,
        orElse: () => all.first);
    widget.recipeItems.add(
        _RecipeEntry(ingredientName: ing.name, unit: ing.unit));
    setState(() => _selectedName = null);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final ingsAsync = ref.watch(_allIngredientsProvider);

    if (!widget.recipeLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.coffeeBrown));
    }

    return ingsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.coffeeBrown)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        final added = widget.recipeItems.map((e) => e.ingredientName).toSet();
        final available = all.where((i) => !added.contains(i.name)).toList();

        return Column(children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warmCream,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 13, color: AppColors.coffeeMuted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bahan di sini dikurangi otomatis dari inventaris saat produk ini dibayar.',
                  style: TextStyle(fontSize: 11, color: AppColors.coffeeMuted),
                ),
              ),
            ]),
          ),

          // List items
          Expanded(
            child: widget.recipeItems.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.science_outlined,
                          size: 48, color: AppColors.borderColor),
                      const SizedBox(height: 10),
                      const Text('Belum ada bahan dalam resep',
                          style: TextStyle(
                              color: AppColors.coffeeMuted, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('Tambah bahan di bawah',
                          style: TextStyle(
                              color: AppColors.borderColor, fontSize: 11)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    itemCount: widget.recipeItems.length,
                    itemBuilder: (_, i) {
                      final entry = widget.recipeItems[i];
                      return _RecipeItemRow(
                        entry: entry,
                        onRemove: () {
                          entry.dispose();
                          widget.recipeItems.removeAt(i);
                          setState(() {});
                          widget.onChanged();
                        },
                      );
                    },
                  ),
          ),

          // Add ingredient row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: all.isEmpty
                ? const Text(
                    'Belum ada bahan baku. Tambah dulu di menu Inventaris.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.coffeeMuted, fontSize: 12),
                  )
                : Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedName,
                        hint: const Text('Pilih bahan baku...',
                            style: TextStyle(fontSize: 12)),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        items: available.map((i) => DropdownMenuItem(
                          value: i.name,
                          child: Text(
                            '${i.emoji} ${i.name} (${i.unit})',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedName = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedName == null
                          ? null
                          : () => _addEntry(all),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Tambah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coffeeBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ]),
          ),
        ]);
      },
    );
  }
}

// ─── One recipe ingredient row ────────────────────────────────────────────────
class _RecipeItemRow extends StatelessWidget {
  const _RecipeItemRow({required this.entry, required this.onRemove});
  final _RecipeEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warmCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(entry.ingredientName,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.coffeeDark)),
        ),
        SizedBox(
          width: 72,
          child: TextField(
            controller: entry.qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: AppColors.coffeeDark),
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(entry.unit,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.coffeeMuted)),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline_rounded,
              size: 18, color: AppColors.statusRed),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ]),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
      style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.coffeeDark));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : AppColors.warmCream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: isSelected ? color : AppColors.coffeeMuted),
          const SizedBox(width: 5),
          Text(label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: isSelected ? color : AppColors.coffeeMuted)),
        ]),
      ),
    );
  }
}
