import 'package:flutter/material.dart';

import '../data/mechanic_directory_repository.dart';
import '../screens/mechanic_detail/mechanic_detail_page.dart';
import '../theme/app_theme.dart';
import '../widgets/common/premium_surface.dart';
import 'data/admin_mechanic_row.dart';
import 'data/admin_repository.dart';

/// Hidden admin screen — reached only via the 6-tap gesture on
/// CustomerProfileTab's version number (see _handleVersionTap there), and
/// only when the signed-in user's UID has an `admins/{uid}` Firestore doc.
/// Guards itself independently of that entry point (see [_AdminGate]) so a
/// non-admin who somehow reaches this route still sees "access denied"
/// instead of the mechanic list or a crash.
class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

enum _Gate { checking, denied, granted }

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final _repository = AdminRepository();
  // Same repository + fetchByBusinessId lookup CustomerConversationPage
  // already uses to open MechanicDetailPage — reused here rather than
  // inventing a second way to load mechanic detail data (see
  // _openMechanicDetail below).
  final _directoryRepository = MechanicDirectoryRepository();

  _Gate _gate = _Gate.checking;
  bool _isLoadingMechanics = false;
  List<AdminMechanicRow> _mechanics = [];
  String? _loadError;
  bool _isOpeningDetail = false;

  // Default true — "Onay Bekleyenler" first, since that's the actual task
  // this screen exists for; "Tümü" is one tap away.
  bool _showOnlyPending = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final isAdmin = await _repository.isCurrentUserAdmin();
    if (!mounted) return;
    if (!isAdmin) {
      setState(() => _gate = _Gate.denied);
      return;
    }
    setState(() => _gate = _Gate.granted);
    _loadMechanics();
  }

  Future<void> _loadMechanics() async {
    setState(() {
      _isLoadingMechanics = true;
      _loadError = null;
    });
    try {
      final mechanics = await _repository.fetchAllMechanicAccounts();
      if (!mounted) return;
      setState(() {
        _mechanics = mechanics;
        _isLoadingMechanics = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Ustalar yüklenemedi: $error';
        _isLoadingMechanics = false;
      });
    }
  }

  Future<void> _setVerified(AdminMechanicRow mechanic, bool isVerified) async {
    // Optimistic local update — the row list is only ever populated from a
    // real fetch, so replacing one entry in place keeps every other field
    // (name, phone, hizmetTürü) exactly as last read, matching the
    // repository's own update()-only write.
    final index = _mechanics.indexWhere((m) => m.id == mechanic.id);
    if (index == -1) return;
    final previous = _mechanics[index];
    setState(() {
      _mechanics[index] = AdminMechanicRow(
        id: previous.id,
        businessId: previous.businessId,
        name: previous.name,
        hizmetTuru: previous.hizmetTuru,
        phone: previous.phone,
        isVerified: isVerified,
      );
    });

    try {
      await _repository.setMechanicVerified(mechanic.id, isVerified);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isVerified ? '${previous.name} onaylandı.' : '${previous.name} onayı kaldırıldı.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      // Roll back the optimistic update on failure.
      setState(() => _mechanics[index] = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güncellenemedi: $error')),
      );
    }
  }

  List<AdminMechanicRow> get _visibleMechanics =>
      _showOnlyPending ? _mechanics.where((m) => !m.isVerified).toList() : _mechanics;

  // Opens the exact same customer-facing MechanicDetailPage, loaded the
  // exact same way CustomerConversationPage._resolveMechanic already does
  // (fetchByBusinessId + a null-safe error snackbar) — this admin screen's
  // AdminMechanicRow only carries a lean field subset for the list, not a
  // full Mechanic, so the real Mechanic is fetched fresh here rather than
  // fabricated from those few fields.
  Future<void> _openMechanicDetail(AdminMechanicRow row) async {
    if (_isOpeningDetail) return;
    setState(() => _isOpeningDetail = true);
    final mechanic = await _directoryRepository.fetchByBusinessId(row.businessId);
    if (!mounted) return;
    setState(() => _isOpeningDetail = false);

    if (mechanic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usta bilgileri alınamadı.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MechanicDetailPage(mechanic: mechanic)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Usta Onayları')),
      body: switch (_gate) {
        _Gate.checking => const Center(child: CircularProgressIndicator()),
        _Gate.denied => const _AccessDenied(),
        _Gate.granted => _MechanicList(
            isLoading: _isLoadingMechanics,
            loadError: _loadError,
            mechanics: _visibleMechanics,
            showOnlyPending: _showOnlyPending,
            onFilterChanged: (value) => setState(() => _showOnlyPending = value),
            onRetry: _loadMechanics,
            onToggleVerified: _setVerified,
            onOpenDetail: _openMechanicDetail,
          ),
      },
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Bu ekrana erişim yetkiniz yok.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MechanicList extends StatelessWidget {
  const _MechanicList({
    required this.isLoading,
    required this.loadError,
    required this.mechanics,
    required this.showOnlyPending,
    required this.onFilterChanged,
    required this.onRetry,
    required this.onToggleVerified,
    required this.onOpenDetail,
  });

  final bool isLoading;
  final String? loadError;
  final List<AdminMechanicRow> mechanics;
  final bool showOnlyPending;
  final ValueChanged<bool> onFilterChanged;
  final VoidCallback onRetry;
  final void Function(AdminMechanicRow mechanic, bool isVerified) onToggleVerified;
  final ValueChanged<AdminMechanicRow> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
          child: Row(
            children: [
              _FilterChip(
                label: 'Onay Bekleyenler',
                selected: showOnlyPending,
                onTap: () => onFilterChanged(true),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: 'Tümü',
                selected: !showOnlyPending,
                onTap: () => onFilterChanged(false),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : loadError != null
                  ? _ErrorState(message: loadError!, onRetry: onRetry)
                  : mechanics.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
                          itemCount: mechanics.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final mechanic = mechanics[index];
                            return _MechanicRow(
                              mechanic: mechanic,
                              onToggleVerified: (value) => onToggleVerified(mechanic, value),
                              onTap: () => onOpenDetail(mechanic),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.turquoise : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.turquoise : AppColors.divider),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MechanicRow extends StatelessWidget {
  const _MechanicRow({required this.mechanic, required this.onToggleVerified, required this.onTap});

  final AdminMechanicRow mechanic;
  final ValueChanged<bool> onToggleVerified;

  /// Opens MechanicDetailPage for this mechanic — wired below to only the
  /// info column, never the Switch (see the comment on that Row), so this
  /// never fires from a tap that was really meant to toggle verification.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      // No onTap here — PremiumSurface's own InkWell would cover the whole
      // card including the Switch, and a tap on the Switch would then be
      // ambiguous between two overlapping tap recognizers. Instead only the
      // info column below (a Row sibling of the Switch, so its hit area
      // never overlaps the Switch's own) is wrapped in its own InkWell.
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mechanic.name.isEmpty ? '(İsim yok)' : mechanic.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mechanic.hizmetTuru ?? 'Tür belirtilmemiş',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  if (mechanic.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      mechanic.phone,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mechanic.isVerified ? Icons.verified_rounded : Icons.remove_circle_outline_rounded,
                        size: 14,
                        color: mechanic.isVerified ? AppColors.verified : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mechanic.isVerified ? 'Onaylı' : 'Onaysız',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: mechanic.isVerified ? AppColors.verified : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Switch(
            value: mechanic.isVerified,
            onChanged: onToggleVerified,
            activeThumbColor: AppColors.turquoise,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Gösterilecek usta yok.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}
