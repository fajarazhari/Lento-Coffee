import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/seed_service.dart';
import '../../../../shared/widgets/lento_button.dart';
import '../providers/auth_provider.dart';

/// Authentication screen
/// DEMO MODE: Use the quick-access buttons below to enter without Firebase.
/// Replace with real Firebase auth once flutterfire configure is done.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Demo bypass (no Firebase needed) ──────────────────────────────────────
  void _enterDemoMode(String role) {
    // Store demo session in a simple way
    demoRoleNotifier.value = role;
    context.go(AppRoutes.pos);
  }

  // ── Real Firebase sign-in (use once Firebase is configured) ───────────────
  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    // Simulated delay — replace with real Firebase call after setup
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() { _isLoading = false; });
    _error = null;

    // TODO: Replace below with real Firebase auth:
    // final result = await ref.read(authNotifierProvider.notifier)
    //     .signIn(_emailController.text.trim(), _passwordController.text);
    // result.fold(
    //   (failure) => setState(() { _error = failure.message; _isLoading = false; }),
    //   (_) => context.go(AppRoutes.pos),
    // );

    // For now, accept any non-empty credentials:
    if (context.mounted) context.go(AppRoutes.pos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo ────────────────────────────────────────────────
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.coffeeBrown,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.coffee_rounded,
                        color: AppColors.goldBrown, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('LENTO COFFEE',
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: AppColors.coffeeBrown, letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Point of Sale System',
                    style: TextStyle(
                      fontSize: 13, color: AppColors.coffeeLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Demo Mode Quick Access ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warmCream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quick Access — Demo Mode',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.goldBrown,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _DemoRoleButton(
                              label: 'Owner',
                              color: AppColors.coffeeDark,
                              onTap: () => _enterDemoMode('owner'),
                            ),
                            const SizedBox(width: 8),
                            _DemoRoleButton(
                              label: 'Manager',
                              color: AppColors.coffeeBrown,
                              onTap: () => _enterDemoMode('manager'),
                            ),
                            const SizedBox(width: 8),
                            _DemoRoleButton(
                              label: 'Cashier',
                              color: AppColors.goldBrown,
                              onTap: () => _enterDemoMode('cashier'),
                            ),
                            const SizedBox(width: 8),
                            _DemoRoleButton(
                              label: 'Barista',
                              color: AppColors.coffeeLight,
                              onTap: () => _enterDemoMode('barista'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Divider ────────────────────────────────────────────
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or sign in with email',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.coffeeMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ]),

                  const SizedBox(height: 16),

                  // ── Email ──────────────────────────────────────────────
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Password ───────────────────────────────────────────
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onSubmitted: (_) => _signIn(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                      style: const TextStyle(
                        color: AppColors.notificationBadge, fontSize: 12)),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: LentoButton(
                      label: 'Sign In',
                      icon: Icons.login_rounded,
                      isLoading: _isLoading,
                      onPressed: _signIn,
                    ),
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

// ── Demo role quick-access button ─────────────────────────────────────────────
class _DemoRoleButton extends StatelessWidget {
  const _DemoRoleButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Simple demo session notifier (no Firebase) ────────────────────────────────
/// Holds the current demo role. Replace with real auth provider once Firebase is set up.
final demoRoleNotifier = ValueNotifier<String>('cashier');
