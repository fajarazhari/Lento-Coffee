import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/app_user_model.dart';
import '../providers/auth_provider.dart';

// ── Simple demo session notifier (no Firebase) ────────────────────────────────
final demoUserNotifier = ValueNotifier<AppUserModel?>(null);

// Mock Users for Demo
final List<AppUserModel> mockUsers = [
  const AppUserModel(
    id: 'cashier_1',
    name: 'Budi (Pagi)',
    email: 'budi@lento.com',
    role: UserRole.cashier,
    themeColor: '#4CAF50', // Green
  ),
  const AppUserModel(
    id: 'cashier_2',
    name: 'Siti (Siang)',
    email: 'siti@lento.com',
    role: UserRole.cashier,
    themeColor: '#FF9800', // Orange
  ),
  const AppUserModel(
    id: 'owner_1',
    name: 'Fajar (Owner)',
    email: 'fajar@lento.com',
    role: UserRole.owner,
    themeColor: '#D32F2F', // Red
  ),
  const AppUserModel(
    id: 'barista_1',
    name: 'Dimas (Barista)',
    email: 'dimas@lento.com',
    role: UserRole.barista,
    themeColor: '#795548', // Brown
  ),
];

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  void _enterDemoMode(AppUserModel user) {
    demoUserNotifier.value = user;
    if (user.role == UserRole.barista) {
      context.go(AppRoutes.kds);
    } else {
      context.go(AppRoutes.pos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo ────────────────────────────────────────────────
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.coffeeBrown,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.coffee_rounded,
                        color: AppColors.goldBrown, size: 40),
                  ),
                  const SizedBox(height: 24),
                  const Text('LENTO COFFEE',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900,
                      color: AppColors.coffeeBrown, letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Select your profile to continue (Demo Mode)',
                    style: TextStyle(
                      fontSize: 14, color: AppColors.coffeeMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── User Selection ──────────────────────────────────────
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: mockUsers.length,
                    itemBuilder: (context, index) {
                      final user = mockUsers[index];
                      return _UserCard(
                        user: user,
                        onTap: () => _enterDemoMode(user),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});
  final AppUserModel user;
  final VoidCallback onTap;

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(user.themeColor);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                user.initials,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.coffeeDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.role.name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: AppColors.coffeeMuted,
                    ),
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
