import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ────────────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Hive (Offline cache) ────────────────────────────────────────────────────
  await Hive.initFlutter();
  // Register Hive adapters here as you generate them:
  // Hive.registerAdapter(CartItemModelAdapter());

  // ── Run App ─────────────────────────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: LentoCoffeeApp(),
    ),
  );
}
