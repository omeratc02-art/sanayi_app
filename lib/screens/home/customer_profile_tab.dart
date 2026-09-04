import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../admin/admin_approval_screen.dart';
import '../../admin/data/admin_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_instances.dart';

/// Minimal "Profil" tab — lets an already-signed-in customer view/update
/// their Firebase Auth displayName, the same field new registrations set
/// (see LoginPage's "Ad Soyad" field) and mechanic-side chat notifications
/// read (see ChatRepository.sendMessage/ChatSummary.customerDisplayName).
/// Exists so an existing account (created before that field was collected
/// at registration) has a way to set it without deleting/recreating the
/// account. Replaces what used to be a PlaceholderTab for this one tab;
/// guests (no signed-in user) see a neutral message instead, since there's
/// no account to edit.
class CustomerProfileTab extends StatefulWidget {
  const CustomerProfileTab({super.key});

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
  late final _nameController = TextEditingController(
    text: firebaseAuthInstance.currentUser?.displayName ?? '',
  );

  var _isSaving = false;
  String? _message;

  String? _versionLabel;

  // Hidden admin entry point: 6 taps on the version label within ~2s of
  // the first tap opens AdminApprovalScreen, but only for a signed-in
  // admin (see AdminRepository.isCurrentUserAdmin / firestore.rules'
  // admins/{uid} doc) — anyone else's taps do nothing visible at all, by
  // design, so this isn't discoverable as an admin feature from the UI.
  static const _adminTapThreshold = 6;
  static const _adminTapWindow = Duration(seconds: 2);
  int _versionTapCount = 0;
  DateTime? _firstVersionTapAt;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _versionLabel = 'v${info.version}');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleVersionTap() async {
    final now = DateTime.now();
    if (_firstVersionTapAt == null || now.difference(_firstVersionTapAt!) > _adminTapWindow) {
      _firstVersionTapAt = now;
      _versionTapCount = 1;
      return;
    }
    _versionTapCount++;
    if (_versionTapCount < _adminTapThreshold) return;

    _versionTapCount = 0;
    _firstVersionTapAt = null;

    final isAdmin = await AdminRepository().isCurrentUserAdmin();
    if (!mounted || !isAdmin) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminApprovalScreen()));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _message = 'Lütfen ad soyad girin.');
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await firebaseAuthInstance.currentUser?.updateProfile(displayName: name);
      // Refreshes the cached currentUser so the new displayName is
      // immediately available elsewhere in this session (e.g. the very
      // next chat message sent), not just after a future sign-in.
      await firebaseAuthInstance.currentUser?.reload();
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _message = 'Ad soyad güncellendi.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _message = 'Güncellenemedi: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = firebaseAuthInstance.currentUser != null;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: isSignedIn
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ad Soyad',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(hintText: 'Ad Soyad'),
                        ),
                        const SizedBox(height: 12),
                        if (_message != null) ...[
                          Text(_message!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          const SizedBox(height: 12),
                        ],
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Kaydet'),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Ad soyad güncellemek için giriş yapmalısınız.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                      ),
                    ),
                  ),
          ),
          if (_versionLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: _handleVersionTap,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  _versionLabel!,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
