import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/seed_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _activeSection = 'General';

  static const _sections = [
    ('General',             Icons.store_rounded),
    ('Employees',           Icons.people_rounded),
    ('Roles & Permissions', Icons.admin_panel_settings_rounded),
    ('POS Settings',        Icons.point_of_sale_rounded),
    ('Receipt',             Icons.receipt_long_rounded),
    ('Payments',            Icons.payment_rounded),
    ('Tax',                 Icons.percent_rounded),
    ('Appearance',          Icons.palette_rounded),
    ('Backup',              Icons.backup_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Row(
        children: [
          // ── LEFT SIDEBAR NAV ──────────────────────────────────────────────
          Container(
            width: 220,
            color: AppColors.pureWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.borderColor)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.settings_rounded,
                          color: AppColors.coffeeBrown, size: 20),
                      SizedBox(width: 8),
                      Text('Settings',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: AppColors.coffeeDark)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _sections.map((s) {
                      final isActive = _activeSection == s.$1;
                      return InkWell(
                        onTap: () => setState(() => _activeSection = s.$1),
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
                              Icon(s.$2,
                                size: 16,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.coffeeMuted),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(s.$1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.coffeeDark)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // ── RIGHT CONTENT ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top action bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: AppColors.pureWhite,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(_activeSection,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: AppColors.coffeeDark)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.save_rounded),
                        color: AppColors.coffeeBrown,
                        tooltip: 'Save Changes',
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        color: AppColors.coffeeLight,
                        tooltip: 'Reset',
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.backup_rounded),
                        color: AppColors.statusBlue,
                        tooltip: 'Backup',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildSection(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection() {
    return switch (_activeSection) {
      'General'   => _GeneralSection(),
      'Employees' => _EmployeesSection(),
      'Backup'    => _BackupSection(),
      _           => _PlaceholderSection(section: _activeSection),
    };
  }
}

// ── General Section ───────────────────────────────────────────────────────────
class _GeneralSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsCard(
          title: 'Store Identity',
          child: Column(children: [
            _FieldRow(label: 'Store Name',  hint: 'Lento Coffee'),
            _FieldRow(label: 'Branch Name', hint: 'Main Branch'),
            _FieldRow(label: 'Phone',       hint: '+62-21-1234567'),
            _FieldRow(label: 'Address',     hint: 'Jl. Sudirman No. 1, Jakarta'),
          ]),
        ),
        SizedBox(height: 16),
        _SettingsCard(
          title: 'Localization',
          child: Column(children: [
            _FieldRow(label: 'Timezone', hint: 'Asia/Jakarta'),
            _FieldRow(label: 'Currency', hint: 'IDR'),
            _FieldRow(label: 'Language', hint: 'Bahasa Indonesia'),
          ]),
        ),
      ],
    );
  }
}

// ── Employees Section ─────────────────────────────────────────────────────────
class _EmployeesSection extends StatelessWidget {
  static const _employees = [
    ('Admin', 'owner',   'admin@lentocoffee.com',  true),
    ('Budi',  'cashier', 'budi@lentocoffee.com',   true),
    ('Siti',  'barista', 'siti@lentocoffee.com',   true),
    ('Rudi',  'manager', 'rudi@lentocoffee.com',   false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Employee Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppColors.coffeeDark)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Add Employee'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coffeeBrown,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.email_rounded, size: 16),
              label: const Text('Invite'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.warmCream,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Row(children: [
                  SizedBox(width: 44),
                  Expanded(flex: 2, child: Text('Nama', style: _th)),
                  Expanded(flex: 3, child: Text('Email', style: _th)),
                  Expanded(flex: 1, child: Text('Role', style: _th)),
                  Expanded(flex: 1, child: Text('Status', style: _th)),
                  SizedBox(width: 80, child: Text('Actions', style: _th)),
                ]),
              ),
              const Divider(height: 1),
              ..._employees.map((emp) => Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.coffeeBrown.withAlpha(40),
                      child: Text(emp.$1[0],
                        style: const TextStyle(
                          color: AppColors.coffeeBrown,
                          fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(flex: 2,
                      child: Text(emp.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.coffeeDark))),
                    Expanded(flex: 3,
                      child: Text(emp.$3,
                        style: const TextStyle(
                          color: AppColors.coffeeMuted, fontSize: 13))),
                    Expanded(flex: 1, child: _RoleBadge(role: emp.$2)),
                    Expanded(flex: 1,
                      child: Row(children: [
                        Icon(
                          emp.$4 ? Icons.circle : Icons.circle_outlined,
                          size: 8,
                          color: emp.$4
                              ? AppColors.statusGreen
                              : AppColors.statusRed,
                        ),
                        const SizedBox(width: 4),
                        Text(emp.$4 ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: emp.$4
                                ? AppColors.statusGreen
                                : AppColors.statusRed)),
                      ])),
                    SizedBox(width: 80,
                      child: Row(children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          color: AppColors.coffeeBrown,
                          onPressed: () {},
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.delete_outline_rounded, size: 16),
                          color: AppColors.statusRed,
                          onPressed: () {},
                          tooltip: 'Hapus',
                        ),
                      ])),
                  ]),
                ),
                const Divider(height: 1),
              ])),
            ],
          ),
        ),
      ],
    );
  }
}

const _th = TextStyle(
  fontSize: 11, fontWeight: FontWeight.w800,
  color: AppColors.coffeeMuted, letterSpacing: 0.5);

// ── Backup Section ────────────────────────────────────────────────────────────
class _BackupSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsCard(
          title: 'Seed Data Awal',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Isi Firestore dengan 26 menu kopi Lento + pengaturan toko.\n'
                'Tekan tombol ini SATU KALI setelah pertama kali setup Firebase.',
                style: TextStyle(
                    color: AppColors.coffeeMuted, fontSize: 13, height: 1.5)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => SeedService.seedAll(context),
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text('Seed Data ke Firestore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coffeeBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SettingsCard(
          title: 'Export Data',
          child: Column(children: [
            _FieldRow(label: 'Format', hint: 'CSV / Excel'),
            _FieldRow(label: 'Tanggal', hint: 'Pilih rentang tanggal'),
          ]),
        ),
      ],
    );
  }
}

// ── Placeholder Section ───────────────────────────────────────────────────────
class _PlaceholderSection extends StatelessWidget {
  const _PlaceholderSection({required this.section});
  final String section;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_rounded,
              color: AppColors.borderColor, size: 48),
          const SizedBox(height: 12),
          Text('$section Settings',
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.coffeeMuted)),
          const SizedBox(height: 6),
          const Text('Coming soon',
            style: TextStyle(color: AppColors.borderColor)),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(title,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: AppColors.coffeeDark)),
          ),
          const Divider(),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.hint});
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        SizedBox(
          width: 140,
          child: Text(label,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.coffeeDark)),
        ),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12),
            ),
          ),
        ),
      ]),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'owner'   => AppColors.statusRed,
      'manager' => AppColors.statusOrange,
      'cashier' => AppColors.statusBlue,
      _         => AppColors.coffeeLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(role.toUpperCase(),
        style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
