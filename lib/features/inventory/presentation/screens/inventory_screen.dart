import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/ingredient_model.dart';
import '../../data/repositories/inventory_repository.dart';

// ─── Providers ────────────────────────────────────────────────────────────────
final ingredientsProvider =
    StreamProvider<List<IngredientModel>>((ref) {
  return ref.watch(inventoryRepositoryProvider).watchIngredients();
});

// ─── Category config ──────────────────────────────────────────────────────────
const _invCategories = [
  'Semua',
  'Kopi',
  'Susu & Dairy',
  'Sirup & Perisa',
  'Teh & Herbal',
  'Pastry & Bakery',
  'Es & Air',
  'Lainnya',
];

String _catEmoji(String cat) => switch (cat) {
  'Semua'         => '📦',
  'Kopi'          => '☕',
  'Susu & Dairy'  => '🥛',
  'Sirup & Perisa'=> '🍯',
  'Teh & Herbal'  => '🍵',
  'Pastry & Bakery'=> '🥐',
  'Es & Air'      => '🧊',
  'Lainnya'       => '🔧',
  _               => '📦',
};

// ─── Screen ───────────────────────────────────────────────────────────────────
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _selectedCategory = 'Semua';
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
      builder: (_) => _IngredientFormDialog(
        initialCategory:
            _selectedCategory == 'Semua' ? 'Kopi' : _selectedCategory,
      ),
    );
  }

  void _openEditDialog(IngredientModel ingredient) {
    showDialog(
      context: context,
      builder: (_) => _IngredientFormDialog(ingredient: ingredient),
    );
  }

  void _openRestockDialog(IngredientModel ingredient) {
    showDialog(
      context: context,
      builder: (_) => _RestockDialog(ingredient: ingredient),
    );
  }

  Future<void> _confirmDelete(IngredientModel ingredient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Bahan Baku?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          '${ingredient.emoji} ${ingredient.name}\n\nData stok akan dihapus permanen.',
          style: const TextStyle(color: AppColors.coffeeMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
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
      await ref
          .read(inventoryRepositoryProvider)
          .deleteIngredient(ingredient.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Row(
        children: [
          // ── LEFT: Category sidebar ────────────────────────────────────────
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
                  child: const Row(children: [
                    Icon(Icons.inventory_2_rounded,
                        color: AppColors.coffeeBrown, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text('Inventaris',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: AppColors.coffeeDark)),
                    ),
                  ]),
                ),
                // Alert: low stock summary
                ingredientsAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (list) {
                    final low = list.where((i) => i.isLowStock).length;
                    if (low == 0) return const SizedBox();
                    return Container(
                      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.statusRed.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.statusRed.withAlpha(80)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.warning_rounded,
                            color: AppColors.statusRed, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('$low bahan stok menipis',
                            style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppColors.statusRed)),
                        ),
                      ]),
                    );
                  },
                ),
                // Category list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _invCategories.map((cat) {
                      final count = ingredientsAsync.when(
                        loading: () => 0,
                        error: (_, __) => 0,
                        data: (list) => cat == 'Semua'
                            ? list.length
                            : list
                                .where((i) => i.category == cat)
                                .length,
                      );
                      final isActive = _selectedCategory == cat;
                      return InkWell(
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.coffeeBrown
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            Text(_catEmoji(cat),
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.coffeeDark)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withAlpha(50)
                                    : AppColors.warmCream,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('$count',
                                style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w800,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.coffeeMuted)),
                            ),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Tambah bahan button
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openAddDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Bahan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coffeeBrown,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── RIGHT: Ingredient list ────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Header bar
                Container(
                  height: 64,
                  color: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    Flexible(
                      child: Text(
                        _selectedCategory == 'Semua'
                            ? 'Semua Bahan Baku'
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
                          hintText: 'Cari bahan...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 18),
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
                  ]),
                ),
                const Divider(height: 1),
                // Column headers
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  color: AppColors.warmCream,
                  child: const Row(children: [
                    SizedBox(width: 40),
                    Expanded(flex: 3, child: _ColHeader('Nama Bahan')),
                    Expanded(flex: 2, child: _ColHeader('Kategori')),
                    Expanded(flex: 2, child: _ColHeader('Stok Saat Ini')),
                    Expanded(flex: 2, child: _ColHeader('Stok Min.')),
                    Expanded(flex: 2, child: _ColHeader('Satuan')),
                    Expanded(flex: 2, child: _ColHeader('Status')),
                    SizedBox(width: 120, child: _ColHeader('Aksi')),
                  ]),
                ),
                const Divider(height: 1),
                // Ingredient rows
                Expanded(
                  child: ingredientsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.coffeeBrown)),
                    error: (e, _) => Center(
                      child: Text('Error: $e',
                        style: const TextStyle(
                            color: AppColors.statusRed))),
                    data: (all) {
                      final filtered = all.where((i) {
                        final matchCat = _selectedCategory == 'Semua' ||
                            i.category == _selectedCategory;
                        final matchSearch = _searchQuery.isEmpty ||
                            i.name.toLowerCase().contains(
                                _searchQuery.toLowerCase());
                        return matchCat && matchSearch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  color: AppColors.borderColor, size: 56),
                              const SizedBox(height: 12),
                              Text(
                                all.isEmpty
                                    ? 'Belum ada data bahan baku.\nKlik "Tambah Bahan" atau seed data di Settings.'
                                    : 'Tidak ada bahan di kategori ini.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.coffeeMuted,
                                  fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) => _IngredientRow(
                          ingredient: filtered[i],
                          onEdit: () => _openEditDialog(filtered[i]),
                          onDelete: () => _confirmDelete(filtered[i]),
                          onRestock: () =>
                              _openRestockDialog(filtered[i]),
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
}

// ─── Column header ─────────────────────────────────────────────────────────────
class _ColHeader extends StatelessWidget {
  const _ColHeader(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
    style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w800,
      color: AppColors.coffeeMuted,
      letterSpacing: 0.5));
}

// ─── Ingredient Row ────────────────────────────────────────────────────────────
class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.onEdit,
    required this.onDelete,
    required this.onRestock,
  });
  final IngredientModel ingredient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final isLow = ingredient.isLowStock;
    final isOut = ingredient.isOutOfStock;

    Color statusColor;
    String statusLabel;
    if (isOut) {
      statusColor = AppColors.statusRed;
      statusLabel = 'HABIS';
    } else if (isLow) {
      statusColor = AppColors.statusOrange;
      statusLabel = 'MENIPIS';
    } else {
      statusColor = AppColors.statusGreen;
      statusLabel = 'AMAN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: isOut
          ? AppColors.statusRed.withAlpha(8)
          : isLow
              ? AppColors.statusOrange.withAlpha(8)
              : AppColors.pureWhite,
      child: Row(children: [
        // Emoji
        SizedBox(
          width: 40,
          child: Text(ingredient.emoji,
              style: const TextStyle(fontSize: 22)),
        ),
        // Name
        Expanded(
          flex: 3,
          child: Text(ingredient.name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.coffeeDark)),
        ),
        // Category
        Expanded(
          flex: 2,
          child: Text(ingredient.category,
            style: const TextStyle(
              fontSize: 12, color: AppColors.coffeeMuted)),
        ),
        // Current stock
        Expanded(
          flex: 2,
          child: Text(
            '${ingredient.currentStock.toStringAsFixed(ingredient.currentStock % 1 == 0 ? 0 : 1)} ${ingredient.unit}',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: isOut
                  ? AppColors.statusRed
                  : isLow
                      ? AppColors.statusOrange
                      : AppColors.coffeeDark),
          ),
        ),
        // Min stock
        Expanded(
          flex: 2,
          child: Text(
            '${ingredient.minimumStock.toStringAsFixed(0)} ${ingredient.unit}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.coffeeMuted)),
        ),
        // Unit
        Expanded(
          flex: 2,
          child: Text(ingredient.unit,
            style: const TextStyle(
                fontSize: 12, color: AppColors.coffeeMuted)),
        ),
        // Status badge
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: statusColor.withAlpha(80)),
            ),
            child: Text(statusLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w900,
                color: statusColor, letterSpacing: 0.5)),
          ),
        ),
        // Actions
        SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Restock
              _RowBtn(
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.statusGreen,
                tooltip: 'Tambah Stok',
                onTap: onRestock,
              ),
              // Edit
              _RowBtn(
                icon: Icons.edit_rounded,
                color: AppColors.statusBlue,
                tooltip: 'Edit',
                onTap: onEdit,
              ),
              // Delete
              _RowBtn(
                icon: Icons.delete_outline_rounded,
                color: AppColors.statusRed,
                tooltip: 'Hapus',
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _RowBtn extends StatelessWidget {
  const _RowBtn({
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
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, size: 18, color: color),
    tooltip: tooltip,
    padding: const EdgeInsets.all(4),
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
  );
}

// ─── Restock Dialog ────────────────────────────────────────────────────────────
class _RestockDialog extends ConsumerStatefulWidget {
  const _RestockDialog({required this.ingredient});
  final IngredientModel ingredient;
  @override
  ConsumerState<_RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends ConsumerState<_RestockDialog> {
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = double.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) return;
    setState(() => _saving = true);

    final result = await ref.read(inventoryRepositoryProvider).restock(
      ingredient: widget.ingredient,
      quantity: qty,
      notes: _notesCtrl.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
      result.fold(
        (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${f.message}'),
            backgroundColor: AppColors.statusRed,
            behavior: SnackBarBehavior.floating,
          ),
        ),
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('+${qty.toStringAsFixed(0)} ${widget.ingredient.unit} ${widget.ingredient.name} ditambahkan'),
            ]),
            backgroundColor: AppColors.statusGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.statusGreen,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                Text(widget.ingredient.emoji,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tambah Stok',
                        style: TextStyle(
                          color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w800)),
                      Text(widget.ingredient.name,
                        style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current stock info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warmCream,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Stok saat ini:',
                            style: TextStyle(
                              fontSize: 12, color: AppColors.coffeeMuted)),
                          Text(
                            '${widget.ingredient.currentStock.toStringAsFixed(0)} ${widget.ingredient.unit}',
                            style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800,
                              color: AppColors.coffeeDark)),
                        ]),
                  ),
                  const SizedBox(height: 16),
                  // Quantity input
                  const Text('Jumlah yang ditambahkan *',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.coffeeDark)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.]'))
                    ],
                    decoration: InputDecoration(
                      hintText: 'Contoh: 1000',
                      suffixText: widget.ingredient.unit,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes
                  const Text('Catatan (opsional)',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.coffeeDark)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Misal: Restock dari supplier X',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
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
                        : const Icon(Icons.add_circle_rounded, size: 18),
                    label: Text(_saving ? 'Menyimpan...' : 'Tambah Stok'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusGreen,
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
}

// ─── Add / Edit Ingredient Dialog ──────────────────────────────────────────────
class _IngredientFormDialog extends ConsumerStatefulWidget {
  const _IngredientFormDialog(
      {this.ingredient, this.initialCategory = 'Kopi'});
  final IngredientModel? ingredient;
  final String initialCategory;

  @override
  ConsumerState<_IngredientFormDialog> createState() =>
      _IngredientFormDialogState();
}

class _IngredientFormDialogState
    extends ConsumerState<_IngredientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _emojiCtrl;
  late String _category;
  late String _unit;
  bool _saving = false;

  bool get _isEdit => widget.ingredient != null;

  final _units = ['g', 'ml', 'unit', 'kg', 'L', 'butir', 'lembar'];
  final _formCategories = [
    'Kopi', 'Susu & Dairy', 'Sirup & Perisa',
    'Teh & Herbal', 'Pastry & Bakery', 'Es & Air', 'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final i = widget.ingredient;
    _nameCtrl  = TextEditingController(text: i?.name ?? '');
    _stockCtrl = TextEditingController(
        text: i != null ? i.currentStock.toStringAsFixed(0) : '');
    _minCtrl   = TextEditingController(
        text: i != null ? i.minimumStock.toStringAsFixed(0) : '');
    _emojiCtrl = TextEditingController(text: i?.emoji ?? '📦');
    _category  = i?.category ?? widget.initialCategory;
    _unit      = i?.unit ?? 'g';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _stockCtrl.dispose();
    _minCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = ref.read(inventoryRepositoryProvider);
    final stock = double.tryParse(_stockCtrl.text) ?? 0;
    final minStock = double.tryParse(_minCtrl.text) ?? 0;
    final emoji = _emojiCtrl.text.trim().isEmpty ? '📦' : _emojiCtrl.text.trim();

    if (_isEdit) {
      final updated = IngredientModel(
        id:           widget.ingredient!.id,
        name:         _nameCtrl.text.trim(),
        category:     _category,
        unit:         _unit,
        currentStock: stock,
        minimumStock: minStock,
        emoji:        emoji,
      );
      await repo.updateIngredient(updated);
    } else {
      final newIng = IngredientModel(
        id:           '',
        name:         _nameCtrl.text.trim(),
        category:     _category,
        unit:         _unit,
        currentStock: stock,
        minimumStock: minStock,
        emoji:        emoji,
      );
      await repo.createIngredient(newIng);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Text(_isEdit
              ? '${_nameCtrl.text} diperbarui'
              : '${emoji} ${_nameCtrl.text} ditambahkan!'),
        ]),
        backgroundColor: AppColors.statusGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.coffeeBrown,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                Text(
                  _isEdit ? '✏️  Edit Bahan' : '➕  Tambah Bahan Baku',
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
            // Form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + Emoji row
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FLabel('Kategori'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _category,
                                decoration: _deco('Pilih kategori'),
                                items: _formCategories
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Row(children: [
                                            Text(_catEmoji(c),
                                                style: const TextStyle(fontSize: 14)),
                                            const SizedBox(width: 6),
                                            Text(c,
                                                style: const TextStyle(fontSize: 13),
                                                overflow: TextOverflow.ellipsis),
                                          ]),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _category = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FLabel('Emoji'),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 72,
                              child: TextFormField(
                                controller: _emojiCtrl,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 24),
                                decoration: _deco(''),
                                maxLength: 4,
                                buildCounter: (_, {required currentLength,
                                    required isFocused,
                                    required maxLength}) => null,
                              ),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 16),
                      // Name
                      const _FLabel('Nama Bahan Baku *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _deco('Contoh: Susu Segar'),
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true)
                                ? 'Nama tidak boleh kosong'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      // Stock + unit
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FLabel('Stok Awal *'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _stockCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d.]'))
                                ],
                                decoration: _deco('0'),
                                validator: (v) =>
                                    double.tryParse(v ?? '') == null
                                        ? 'Masukkan angka'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FLabel('Satuan *'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _unit,
                                decoration: _deco(''),
                                items: _units
                                    .map((u) => DropdownMenuItem(
                                        value: u, child: Text(u)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _unit = v!),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      // Min stock
                      const _FLabel('Stok Minimum (alert threshold) *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _minCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'))
                        ],
                        decoration: _deco(
                            'Contoh: 200 → alert jika stok ≤ 200'),
                        validator: (v) =>
                            double.tryParse(v ?? '') == null
                                ? 'Masukkan angka'
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
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
                            _isEdit
                                ? Icons.save_rounded
                                : Icons.add_rounded,
                            size: 18),
                    label: Text(_saving
                        ? 'Menyimpan...'
                        : _isEdit
                            ? 'Simpan Perubahan'
                            : 'Tambah Bahan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coffeeBrown,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
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

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle:
        const TextStyle(color: AppColors.borderColor, fontSize: 13),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    isDense: true,
  );
}

class _FLabel extends StatelessWidget {
  const _FLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: AppColors.coffeeDark));
}
