import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Seeds Firestore with initial Lento Coffee data.
/// Call once from the login screen.
class SeedService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedAll(BuildContext context) async {
    try {
      await _seedSettings();
      await _seedProducts();
      await _seedIngredients();
      await _seedRecipes();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Data awal (produk + inventaris + resep) berhasil diisi!'),
            ]),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding data: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  // ── Settings ────────────────────────────────────────────────────────────────
  static Future<void> _seedSettings() async {
    await _db.collection('settings').doc('global').set({
      'storeName': 'Lento Coffee',
      'branchName': 'Main Branch',
      'phone': '+62-21-1234567',
      'address': 'Jl. Sudirman No. 1, Jakarta Selatan',
      'timezone': 'Asia/Jakarta',
      'currency': 'IDR',
      'language': 'id',
      'taxRate': 0.10,
      'serviceChargeRate': 0.0,
      'openTime': '07:00',
      'closeTime': '22:00',
      'loyaltyPointsPerRupiah': 0.001,
      'receiptFooter': 'Terima kasih telah mengunjungi Lento Coffee!',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Products ────────────────────────────────────────────────────────────────
  static Future<void> _seedProducts() async {
    final products = [
      // Coffee
      _p('Espresso',         'Coffee',     28000, '☕', 'Double shot espresso', 0),
      _p('Americano',        'Coffee',     32000, '☕', 'Espresso + hot water', 1),
      _p('Cappuccino',       'Coffee',     38000, '☕', 'Espresso + steamed milk foam', 2),
      _p('Caffe Latte',      'Coffee',     38000, '🥛', 'Espresso + steamed milk', 3),
      _p('Flat White',       'Coffee',     40000, '☕', 'Double ristretto + microfoam', 4),
      _p('Mocha',            'Coffee',     42000, '🍫', 'Espresso + chocolate + milk', 5),
      _p('Cold Brew',        'Coffee',     45000, '🧊', '12-hour cold steeped coffee', 6),
      _p('Dalgona Coffee',   'Coffee',     43000, '☕', 'Whipped coffee over milk', 7),
      _p('Vietnamese Drip',  'Coffee',     35000, '☕', 'Slow drip with condensed milk', 8),
      _p('V60 Pour Over',    'Coffee',     50000, '⏳', 'Single origin manual brew', 9),
      // Non Coffee
      _p('Chocolate Milk',   'Non Coffee', 35000, '🍫', 'Rich chocolate blended milk', 10),
      _p('Vanilla Steamer',  'Non Coffee', 32000, '🍦', 'Warm vanilla infused milk', 11),
      _p('Caramel Latte',    'Non Coffee', 38000, '🍮', 'Caramel syrup + steamed milk', 12),
      _p('Strawberry Milk',  'Non Coffee', 35000, '🍓', 'Fresh strawberry blended', 13),
      // Tea
      _p('Matcha Latte',     'Tea',        42000, '🍵', 'Premium Japanese matcha', 14),
      _p('Earl Grey Latte',  'Tea',        38000, '🫖', 'Earl Grey + steamed milk', 15),
      _p('Jasmine Green Tea','Tea',        30000, '🌸', 'Fragrant jasmine green tea', 16),
      _p('Taro Milk Tea',    'Tea',        40000, '💜', 'Creamy taro bubble tea', 17),
      // Pastry
      _p('Croissant',        'Pastry',     28000, '🥐', 'Buttery French croissant', 18),
      _p('Banana Bread',     'Pastry',     32000, '🍌', 'Moist homemade banana bread', 19),
      _p('Chocolate Muffin', 'Pastry',     30000, '🧁', 'Double chocolate chip muffin', 20),
      _p('Cheese Cake',      'Pastry',     45000, '🍰', 'New York style cheesecake', 21),
      // Add On
      _p('Extra Shot',       'Add On',      8000, '⚡', 'Extra espresso shot', 22),
      _p('Oat Milk',         'Add On',     10000, '🌾', 'Substitute with oat milk', 23),
      _p('Vanilla Syrup',    'Add On',      6000, '🍦', 'Sweet vanilla flavoring', 24),
      _p('Caramel Drizzle',  'Add On',      6000, '🍮', 'Caramel sauce topping', 25),
    ];

    final batch = _db.batch();
    for (final p in products) {
      final ref = _db.collection('products').doc();
      batch.set(ref, p);
    }
    await batch.commit();
  }

  // ── Ingredients ─────────────────────────────────────────────────────────────
  static Future<void> _seedIngredients() async {
    final ingredients = [
      // Kopi
      _ing('Biji Espresso',       'Kopi',            'g',  5000, 500,  '☕'),
      _ing('Cold Brew Concentrate','Kopi',            'ml', 2000, 200,  '🧊'),
      // Susu & Dairy
      _ing('Susu Segar',          'Susu & Dairy',    'ml', 10000,1000, '🥛'),
      _ing('Susu Oat',            'Susu & Dairy',    'ml', 3000, 300,  '🌾'),
      _ing('Susu Kental Manis',   'Susu & Dairy',    'ml', 1000, 100,  '🍯'),
      _ing('Whipped Cream',       'Susu & Dairy',    'g',  500,  50,   '🍦'),
      // Sirup & Perisa
      _ing('Bubuk Kakao',         'Sirup & Perisa',  'g',  1000, 100,  '🍫'),
      _ing('Bubuk Matcha',        'Sirup & Perisa',  'g',  500,  50,   '🍵'),
      _ing('Bubuk Taro',          'Sirup & Perisa',  'g',  500,  50,   '💜'),
      _ing('Sirup Vanila',        'Sirup & Perisa',  'ml', 500,  50,   '🍦'),
      _ing('Sirup Karamel',       'Sirup & Perisa',  'ml', 500,  50,   '🍮'),
      _ing('Gula',                'Sirup & Perisa',  'g',  2000, 200,  '🍬'),
      // Teh & Herbal
      _ing('Teh Earl Grey',       'Teh & Herbal',    'g',  200,  20,   '🫖'),
      _ing('Teh Jasmine',         'Teh & Herbal',    'g',  200,  20,   '🌸'),
      // Pastry & Bakery
      _ing('Adonan Croissant',    'Pastry & Bakery', 'g',  3000, 300,  '🥐'),
      _ing('Mix Banana Bread',    'Pastry & Bakery', 'g',  2000, 200,  '🍌'),
      _ing('Mix Muffin Coklat',   'Pastry & Bakery', 'g',  2000, 200,  '🧁'),
      _ing('Cheesecake Base',     'Pastry & Bakery', 'g',  2000, 200,  '🍰'),
      // Es & Air
      _ing('Es Batu',             'Es & Air',        'g',  5000, 500,  '🧊'),
      _ing('Air Panas',           'Es & Air',        'ml', 10000,500,  '💧'),
      // Lainnya
      _ing('Stroberi',            'Lainnya',         'g',  500,  50,   '🍓'),
    ];

    // Use doc IDs = slugified names for easy recipe linking
    final batch = _db.batch();
    for (final ing in ingredients) {
      final slug = (ing['name'] as String)
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('&', 'dan');
      final ref = _db.collection('ingredients').doc(slug);
      batch.set(ref, ing);
    }
    await batch.commit();
  }

  // ── Recipes (per 1 serving) ──────────────────────────────────────────────────
  static Future<void> _seedRecipes() async {
    final recipes = <String, List<Map<String, dynamic>>>{
      // ── Coffee ──────────────────────────────────────────────────────────────
      'Espresso':        [_ri('Biji Espresso', 18, 'g')],
      'Americano':       [_ri('Biji Espresso', 18, 'g'), _ri('Air Panas', 200, 'ml')],
      'Cappuccino':      [_ri('Biji Espresso', 18, 'g'), _ri('Susu Segar', 150, 'ml')],
      'Caffe Latte':     [_ri('Biji Espresso', 18, 'g'), _ri('Susu Segar', 180, 'ml')],
      'Flat White':      [_ri('Biji Espresso', 22, 'g'), _ri('Susu Segar', 120, 'ml')],
      'Mocha':           [_ri('Biji Espresso', 18, 'g'), _ri('Bubuk Kakao', 15, 'g'), _ri('Susu Segar', 150, 'ml'), _ri('Es Batu', 100, 'g')],
      'Cold Brew':       [_ri('Cold Brew Concentrate', 100, 'ml'), _ri('Es Batu', 150, 'g')],
      'Dalgona Coffee':  [_ri('Biji Espresso', 18, 'g'), _ri('Susu Segar', 200, 'ml'), _ri('Gula', 15, 'g'), _ri('Es Batu', 100, 'g')],
      'Vietnamese Drip': [_ri('Biji Espresso', 20, 'g'), _ri('Susu Kental Manis', 30, 'ml'), _ri('Es Batu', 100, 'g')],
      'V60 Pour Over':   [_ri('Biji Espresso', 20, 'g'), _ri('Air Panas', 300, 'ml')],
      // ── Non Coffee ──────────────────────────────────────────────────────────
      'Chocolate Milk':  [_ri('Bubuk Kakao', 20, 'g'), _ri('Susu Segar', 200, 'ml'), _ri('Gula', 10, 'g')],
      'Vanilla Steamer': [_ri('Susu Segar', 200, 'ml'), _ri('Sirup Vanila', 20, 'ml')],
      'Caramel Latte':   [_ri('Susu Segar', 200, 'ml'), _ri('Sirup Karamel', 30, 'ml')],
      'Strawberry Milk': [_ri('Susu Segar', 200, 'ml'), _ri('Stroberi', 50, 'g'), _ri('Gula', 10, 'g')],
      // ── Tea ─────────────────────────────────────────────────────────────────
      'Matcha Latte':    [_ri('Bubuk Matcha', 8, 'g'), _ri('Susu Segar', 200, 'ml'), _ri('Gula', 10, 'g')],
      'Earl Grey Latte': [_ri('Teh Earl Grey', 5, 'g'), _ri('Susu Segar', 180, 'ml')],
      'Jasmine Green Tea':[_ri('Teh Jasmine', 5, 'g'), _ri('Air Panas', 250, 'ml'), _ri('Gula', 10, 'g')],
      'Taro Milk Tea':   [_ri('Bubuk Taro', 20, 'g'), _ri('Susu Segar', 200, 'ml'), _ri('Es Batu', 100, 'g')],
      // ── Pastry ──────────────────────────────────────────────────────────────
      'Croissant':       [_ri('Adonan Croissant', 120, 'g')],
      'Banana Bread':    [_ri('Mix Banana Bread', 150, 'g')],
      'Chocolate Muffin':[_ri('Mix Muffin Coklat', 120, 'g')],
      'Cheese Cake':     [_ri('Cheesecake Base', 180, 'g')],
      // ── Add On ──────────────────────────────────────────────────────────────
      'Extra Shot':      [_ri('Biji Espresso', 18, 'g')],
      'Oat Milk':        [_ri('Susu Oat', 200, 'ml')],
      'Vanilla Syrup':   [_ri('Sirup Vanila', 20, 'ml')],
      'Caramel Drizzle': [_ri('Sirup Karamel', 20, 'ml')],
    };

    // Doc ID = slugified product name for easy lookup
    final batch = _db.batch();
    for (final entry in recipes.entries) {
      final slug = entry.key.toLowerCase().replaceAll(' ', '_');
      final ref = _db.collection('recipes').doc(slug);
      batch.set(ref, {
        'productName': entry.key,
        'ingredients': entry.value,
        'updatedAt':   FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  static Map<String, dynamic> _p(
    String name, String category, int price,
    String emoji, String description, int sortOrder,
  ) => {
    'name': name, 'category': category, 'price': price.toDouble(),
    'emoji': emoji, 'description': description, 'sortOrder': sortOrder,
    'status': 'active', 'isAvailable': true,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static Map<String, dynamic> _ing(
    String name, String category, String unit,
    double stock, double minStock, String emoji,
  ) => {
    'name': name, 'category': category, 'unit': unit,
    'currentStock': stock, 'minimumStock': minStock, 'emoji': emoji,
    'costPerUnit': 0.0, 'updatedAt': FieldValue.serverTimestamp(),
  };

  static Map<String, dynamic> _ri(
      String name, double qty, String unit) => {
    'ingredientName': name, 'quantity': qty, 'unit': unit,
  };
}
