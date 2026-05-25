import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/lento_button.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../data/models/shift_model.dart';
import '../providers/shift_provider.dart';

class ShiftScreen extends ConsumerWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftAsync = ref.watch(activeShiftProvider);
    final demoUser = demoUserNotifier.value;

    if (demoUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.warmCream,
        body: Center(child: Text('Harap login terlebih dahulu.')),
      );
    }

    if (demoUser.role == UserRole.owner) {
      return Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: AppBar(
          title: const Text('Monitor Shift Kasir (Owner)', 
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeBrown)),
          backgroundColor: AppColors.pureWhite,
          elevation: 0,
        ),
        body: const _OwnerMonitoringDashboard(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Manajemen Shift Kasir', 
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.coffeeBrown)),
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: shiftAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.coffeeBrown)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (shift) {
          if (shift == null) {
            return _OpenShiftForm();
          }
          return _ActiveShiftDashboard(shift: shift);
        },
      ),
    );
  }
}

final ownerShiftDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class _OwnerMonitoringDashboard extends ConsumerWidget {
  const _OwnerMonitoringDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(ownerShiftDateProvider);
    final shiftsAsync = ref.watch(shiftsByDateProvider(selectedDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Text('Riwayat Shift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.coffeeDark)),
              const Spacer(),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(primary: AppColors.coffeeBrown),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    ref.read(ownerShiftDateProvider.notifier).state = date;
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.coffeeBrown),
                      const SizedBox(width: 8),
                      Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.coffeeDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: shiftsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.coffeeBrown)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (shifts) {
              final cashierShifts = shifts.where((s) => !s.cashierId.contains('owner')).toList();
              if (cashierShifts.isEmpty) {
                return const Center(child: Text('Tidak ada riwayat shift pada tanggal ini.', style: TextStyle(color: AppColors.coffeeMuted)));
              }
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: cashierShifts.length,
                itemBuilder: (context, index) {
                  final shift = cashierShifts[index];
                  final isClosed = shift.status == ShiftStatus.closed;
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isClosed ? AppColors.coffeeMuted : AppColors.goldBrown,
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(shift.cashierName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                    Text(isClosed ? 'Selesai: ${_formatTime(shift.closedAt!)}' : 'Aktif sejak ${_formatTime(shift.openedAt)}', style: TextStyle(color: isClosed ? AppColors.statusRed : AppColors.statusGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const Spacer(),
                          _buildRow('Modal Awal', shift.openingCash),
                          const SizedBox(height: 8),
                          _buildRow('Omzet Tunai', shift.totalCashRevenue, isBold: true, color: AppColors.statusGreen),
                          const SizedBox(height: 8),
                          _buildRow('Kas Masuk', shift.cashIn),
                          const SizedBox(height: 8),
                          _buildRow('Kas Keluar', shift.cashOut),
                          if (isClosed) ...[
                            const Divider(height: 16),
                            _buildRow('Setor Fisik', shift.closingCash ?? 0, isBold: true, color: AppColors.coffeeBrown),
                            if ((shift.difference ?? 0) != 0) ...[
                              const SizedBox(height: 4),
                              _buildRow('Selisih', shift.difference ?? 0, color: (shift.difference ?? 0) < 0 ? AppColors.statusRed : AppColors.statusGreen),
                            ]
                          ]
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.coffeeMuted)),
        Text(CurrencyFormatter.format(amount), style: TextStyle(
          fontSize: 14, 
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          color: color ?? AppColors.coffeeDark,
        )),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}

class _OpenShiftForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OpenShiftForm> createState() => _OpenShiftFormState();
}

class _OpenShiftFormState extends ConsumerState<_OpenShiftForm> {
  final _cashController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    final amount = double.tryParse(_cashController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount < 0) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(shiftNotifierProvider.notifier).openShift(amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift berhasil dibuka!'), backgroundColor: AppColors.statusGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.notificationBadge),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = demoUserNotifier.value!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_rounded, size: 64, color: AppColors.goldBrown),
                const SizedBox(height: 16),
                Text('Halo, ${user.name}!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.coffeeDark)),
                const SizedBox(height: 8),
                const Text('Anda belum membuka shift. Silakan masukkan modal awal (uang tunai di laci) untuk memulai shift.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.coffeeMuted)),
                const SizedBox(height: 32),
                
                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Modal Awal (Rp)',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: LentoButton(
                    label: 'Buka Shift Sekarang',
                    icon: Icons.play_arrow_rounded,
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveShiftDashboard extends ConsumerWidget {
  const _ActiveShiftDashboard({required this.shift});
  final ShiftModel shift;

  void _showPettyCashDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => _PettyCashDialog(shift: shift));
  }

  void _showCloseShiftDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => _CloseShiftDialog(shift: shift));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shift Aktif: ${shift.name}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.coffeeDark)),
                  const SizedBox(height: 4),
                  Text('Kasir: ${shift.cashierName} • Dibuka: ${_formatTime(shift.openedAt)}',
                    style: const TextStyle(fontSize: 14, color: AppColors.coffeeMuted, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                    label: const Text('Petty Cash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pureWhite,
                      foregroundColor: AppColors.coffeeBrown,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.borderColor),
                    ),
                    onPressed: () => _showPettyCashDialog(context, ref),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('Tutup Shift'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.notificationBadge,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () => _showCloseShiftDialog(context, ref),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          
          // Cards Row 1
          Row(
            children: [
              _buildStatCard('Modal Awal', shift.openingCash, Icons.payments_rounded, AppColors.statusBlue),
              const SizedBox(width: 16),
              _buildStatCard('Omzet Tunai', shift.totalCashRevenue, Icons.attach_money_rounded, AppColors.statusGreen),
              const SizedBox(width: 16),
              _buildStatCard('Omzet Non-Tunai', shift.totalNonCashRevenue, Icons.credit_card_rounded, AppColors.statusOrange),
            ],
          ),
          const SizedBox(height: 16),
          // Cards Row 2
          Row(
            children: [
              _buildStatCard('Uang Masuk', shift.cashIn, Icons.add_circle_outline_rounded, AppColors.goldBrown),
              const SizedBox(width: 16),
              _buildStatCard('Uang Keluar', shift.cashOut, Icons.remove_circle_outline_rounded, AppColors.notificationBadge),
              const SizedBox(width: 16),
              Expanded(child: SizedBox()), // spacer to match 3 columns
            ],
          ),
          const SizedBox(height: 32),
          
          // Expected Cash
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.coffeeDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Uang Fisik Seharusnya (Expected Cash)',
                  style: TextStyle(color: AppColors.warmCream, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(CurrencyFormatter.format(shift.expectedCash),
                  style: const TextStyle(color: AppColors.goldBrown, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.coffeeMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(CurrencyFormatter.format(amount), 
                    style: const TextStyle(color: AppColors.coffeeDark, fontWeight: FontWeight.w800, fontSize: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}

// ── Petty Cash Dialog ────────────────────────────────────────────────────────
class _PettyCashDialog extends ConsumerStatefulWidget {
  const _PettyCashDialog({required this.shift});
  final ShiftModel shift;
  @override
  ConsumerState<_PettyCashDialog> createState() => _PettyCashDialogState();
}
class _PettyCashDialogState extends ConsumerState<_PettyCashDialog> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  CashTransactionType _type = CashTransactionType.cashOut;
  bool _isLoading = false;

  void _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount <= 0 || _reasonController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(shiftNotifierProvider.notifier).addPettyCash(
        widget.shift.id, amount, _type, _reasonController.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Catat Kas Masuk/Keluar'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<CashTransactionType>(
              value: _type,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Tipe'),
              items: CashTransactionType.values.where((e) => e != CashTransactionType.adjustment).map((e) {
                return DropdownMenuItem(value: e, child: Text(e.label));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _type = v); },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Keterangan (mis: Beli Es Batu)', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.coffeeBrown, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Simpan'),
        ),
      ],
    );
  }
}

// ── Close Shift Dialog ───────────────────────────────────────────────────────
class _CloseShiftDialog extends ConsumerStatefulWidget {
  const _CloseShiftDialog({required this.shift});
  final ShiftModel shift;
  @override
  ConsumerState<_CloseShiftDialog> createState() => _CloseShiftDialogState();
}
class _CloseShiftDialogState extends ConsumerState<_CloseShiftDialog> {
  final _actualCashController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    final actual = double.tryParse(_actualCashController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() => _isLoading = true);
    try {
      await ref.read(shiftNotifierProvider.notifier).closeShift(
        widget.shift.id, actual, widget.shift.expectedCash);
      if (mounted) Navigator.pop(context); // Close dialog
      // Will auto redirect to open shift UI
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tutup Shift'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.goldBrown),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility_off_rounded, color: AppColors.goldBrown),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Blind Close Aktif: Masukkan jumlah uang fisik secara jujur. Hitungan sistem disembunyikan.',
                      style: TextStyle(color: AppColors.coffeeDark, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Total Uang Fisik di Laci:'),
            const SizedBox(height: 8),
            TextField(
              controller: _actualCashController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState((){}), // trigger rebuild for button state
              decoration: const InputDecoration(labelText: 'Uang Fisik Aktual (Rp)', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _actualCashController.text.isEmpty || _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.notificationBadge, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Akhiri Shift'),
        ),
      ],
    );
  }
}
