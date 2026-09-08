import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/mock_data.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../../utils/firebase_instances.dart';
import '../../widgets/booking/section_label.dart';
import '../../widgets/common/premium_surface.dart';
import '../appointments/data/appointment_repository.dart';
import 'data/mechanic_profile.dart';
import 'data/mechanic_profile_repository.dart';

/// "Profile" tab for the mechanic module — shows the signed-in mechanic's
/// real business profile, read from mechanicAccounts/{uid} via
/// MechanicProfileRepository. Previously a structure-only placeholder
/// (SizedBox.shrink()); this is that placeholder's first real content, not
/// a redesign of anything that already worked.
///
/// Fields the real Firestore document doesn't have yet (older accounts
/// registered before phone/address/isVerified/rating were added at
/// registration) fall back to the matching MockData catalog entry, kept
/// available as a temporary source until every account has real data of
/// its own — see _mergedField below.
class MechanicProfileScreen extends StatefulWidget {
  const MechanicProfileScreen({super.key});

  @override
  State<MechanicProfileScreen> createState() => _MechanicProfileScreenState();
}

class _MechanicProfileScreenState extends State<MechanicProfileScreen> {
  bool _loading = true;
  MechanicProfile? _profile;
  var _uploadingCoverPhoto = false;
  int? _uploadingGalleryIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = firebaseAuthInstance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final profile = await MechanicProfileRepository().fetchProfile(uid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Mechanic? _fallbackMechanic(String businessId) {
    for (final mechanic in MockData.allMechanics) {
      if (mechanicChatId(mechanic.name) == businessId) return mechanic;
    }
    return null;
  }

  // Real Firebase Storage upload — this is a user-visible action the
  // mechanic explicitly triggered (unlike e.g. MechanicDetailPage's
  // fire-and-forget view-count recording), so it shows a real loading
  // state (_uploadingCoverPhoto) and a real error message on failure
  // rather than running silently. After a successful upload, re-runs
  // _load() rather than patching _profile locally, so the photo shown is
  // always exactly what Firestore actually has, not an optimistic guess.
  Future<void> _pickAndUploadCoverPhoto() async {
    final profile = _profile;
    if (profile == null || _uploadingCoverPhoto) return;

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (error) {
      debugPrint('MECHANIC PROFILE COVER PHOTO PICK ERROR: $error');
      return;
    }
    if (picked == null || !mounted) return;

    // Lets the mechanic reposition/zoom before upload, locked to the same
    // ~16:9 shape as the cover photo container itself (see
    // _ProfileHeader._coverPhotoHeight) so the crop the mechanic sees
    // matches what customers will actually see, rather than uploading
    // whatever raw framing the gallery photo happened to have.
    final CroppedFile? cropped;
    try {
      cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Kapak Fotoğrafını Kırp',
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Kapak Fotoğrafını Kırp',
            aspectRatioLockEnabled: true,
          ),
          WebUiSettings(context: context),
        ],
      );
    } catch (error) {
      debugPrint('MECHANIC PROFILE COVER PHOTO CROP ERROR: $error');
      return;
    }
    if (cropped == null || !mounted) return;

    setState(() => _uploadingCoverPhoto = true);
    try {
      final bytes = await cropped.readAsBytes();
      await MechanicProfileRepository().uploadCoverPhoto(
        uid: profile.uid,
        bytes: bytes,
      );
      await _load();
    } catch (error) {
      debugPrint('MECHANIC PROFILE COVER PHOTO UPLOAD ERROR: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kapak fotoğrafı yüklenemedi. Lütfen tekrar deneyin.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingCoverPhoto = false);
    }
  }

  // Same shape as _pickAndUploadCoverPhoto above (pick -> crop -> upload,
  // real loading state, real error SnackBar, re-runs _load() rather than
  // patching state locally) — the two real differences are the 1:1 crop
  // ratio (gallery thumbnails render small/square, unlike the full-width
  // 16:9 cover) and [index], since this is one of 3 independently
  // addressable slots rather than a single fixed photo. Also the handler
  // for tapping an already-filled slot (replace) — there is no separate
  // "replace" method; uploading to an occupied [index] just overwrites it,
  // same as the cover photo's own upload-always-overwrites behavior.
  Future<void> _pickAndUploadGalleryPhoto(int index) async {
    final profile = _profile;
    if (profile == null || _uploadingGalleryIndex != null) return;

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (error) {
      debugPrint('MECHANIC PROFILE GALLERY PHOTO PICK ERROR: $error');
      return;
    }
    if (picked == null || !mounted) return;

    final CroppedFile? cropped;
    try {
      cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fotoğrafı Kırp',
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Fotoğrafı Kırp', aspectRatioLockEnabled: true),
          WebUiSettings(context: context),
        ],
      );
    } catch (error) {
      debugPrint('MECHANIC PROFILE GALLERY PHOTO CROP ERROR: $error');
      return;
    }
    if (cropped == null || !mounted) return;

    setState(() => _uploadingGalleryIndex = index);
    try {
      final bytes = await cropped.readAsBytes();
      await MechanicProfileRepository().uploadGalleryPhoto(
        uid: profile.uid,
        index: index,
        bytes: bytes,
      );
      await _load();
    } catch (error) {
      debugPrint('MECHANIC PROFILE GALLERY PHOTO UPLOAD ERROR: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf yüklenemedi. Lütfen tekrar deneyin.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingGalleryIndex = null);
    }
  }

  Future<void> _removeGalleryPhoto(int index) async {
    final profile = _profile;
    if (profile == null || _uploadingGalleryIndex != null) return;

    setState(() => _uploadingGalleryIndex = index);
    try {
      await MechanicProfileRepository().removeGalleryPhoto(
        uid: profile.uid,
        index: index,
      );
      await _load();
    } catch (error) {
      debugPrint('MECHANIC PROFILE GALLERY PHOTO REMOVE ERROR: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf silinemedi. Lütfen tekrar deneyin.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingGalleryIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _profile == null
            ? const _NoProfileState()
            : _ProfileBody(
                profile: _profile!,
                fallback: _fallbackMechanic(_profile!.businessId),
                isUploadingCoverPhoto: _uploadingCoverPhoto,
                onPickCoverPhoto: _pickAndUploadCoverPhoto,
                uploadingGalleryIndex: _uploadingGalleryIndex,
                onTapGallerySlot: _pickAndUploadGalleryPhoto,
                onRemoveGalleryPhoto: _removeGalleryPhoto,
              ),
      ),
    );
  }
}

class _NoProfileState extends StatelessWidget {
  const _NoProfileState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.store_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Usta hesabı bulunamadı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Profilinizi görüntülemek için usta hesabınızla giriş yapmalısınız.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.fallback,
    required this.isUploadingCoverPhoto,
    required this.onPickCoverPhoto,
    required this.uploadingGalleryIndex,
    required this.onTapGallerySlot,
    required this.onRemoveGalleryPhoto,
  });

  final MechanicProfile profile;

  /// The matching MockData catalog entry, if any — used only to fill in
  /// fields this specific account's real document doesn't have yet.
  final Mechanic? fallback;

  final bool isUploadingCoverPhoto;
  final VoidCallback onPickCoverPhoto;

  final int? uploadingGalleryIndex;
  final void Function(int index) onTapGallerySlot;
  final void Function(int index) onRemoveGalleryPhoto;

  String? _mergedField(String? real, String? fallbackValue) =>
      (real == null || real.isEmpty) ? fallbackValue : real;

  @override
  Widget build(BuildContext context) {
    final phone = _mergedField(profile.phone, fallback?.phone);
    final address = _mergedField(profile.address, fallback?.address);
    final rating = profile.rating ?? fallback?.rating;
    final reviewCount = profile.reviewCount ?? fallback?.reviewCount;
    final isVerified = profile.isVerified || (fallback?.isVerified ?? false);
    final services = profile.hizmetler.isNotEmpty
        ? profile.hizmetler
        : (fallback?.hizmetler ?? const <String>[]);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ProfileHeader(
          businessName: profile.businessName,
          address: address,
          isVerified: isVerified,
          coverPhotoUrl: profile.coverPhotoUrl,
          isUploadingCoverPhoto: isUploadingCoverPhoto,
          onPickCoverPhoto: onPickCoverPhoto,
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GalleryPhotosSection(
                galleryPhotoUrls: profile.galleryPhotoUrls,
                uploadingIndex: uploadingGalleryIndex,
                onTapSlot: onTapGallerySlot,
                onRemoveSlot: onRemoveGalleryPhoto,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _StatsCard(
                businessId: profile.businessId,
                rating: rating,
                reviewCount: reviewCount,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SectionLabel(text: 'İletişim Bilgileri'),
              const SizedBox(height: AppSpacing.md),
              if (phone != null && phone.isNotEmpty) ...[
                _ContactCard(
                  icon: Icons.phone_outlined,
                  label: 'Telefon Numarası',
                  value: phone,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              // profile.email is a required field — always real and present,
              // unlike phone/address which can be genuinely unset on older
              // accounts.
              _ContactCard(
                icon: Icons.email_outlined,
                label: 'E-posta',
                value: profile.email,
              ),
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _ContactCard(
                  icon: Icons.location_on_outlined,
                  label: 'Adres',
                  value: address,
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              const SectionLabel(text: 'İşletme Hakkında'),
              const SizedBox(height: AppSpacing.md),
              _AboutCard(
                text: businessAboutText(
                  businessName: profile.businessName,
                  address: address,
                  hizmetler: services,
                ),
              ),
              if (services.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                _ServiceChipsSection(services: services),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Builds a natural Turkish "İşletme Hakkında" sentence purely from real
/// fields already on [MechanicProfile] (or its MockData fallback) —
/// businessName, a city parsed best-effort from the free-text [address]
/// (its last comma-separated segment), and [hizmetler]. There is no
/// free-text description field anywhere in this account's Firestore
/// document, so this is deliberately template-composed rather than
/// reading/displaying one — every word here traces back to a real field,
/// nothing is a hardcoded example. Public (not private) so it's directly
/// unit-testable without pumping the whole widget tree.
String businessAboutText({
  required String businessName,
  required String? address,
  required List<String> hizmetler,
}) {
  final city = _cityFromAddress(address);
  final locationClause = city == null ? '' : "$city'da ";
  final buffer = StringBuffer(
    '$businessName, ${locationClause}hizmet veren bir özel servistir.',
  );
  if (hizmetler.isNotEmpty) {
    buffer.write(' ${_naturalList(hizmetler)} hizmetleri sunmaktadır.');
  }
  return buffer.toString();
}

/// Best-effort city extraction from a free-text address like "Test Sanayi
/// Sitesi, Konya" — the last non-empty comma-separated segment. Null (not
/// a guess) when there's no address at all, so [businessAboutText] can
/// omit the location clause gracefully instead of writing "'da" with
/// nothing before it.
String? _cityFromAddress(String? address) {
  if (address == null || address.trim().isEmpty) return null;
  final last = address.split(',').last.trim();
  return last.isEmpty ? null : last;
}

/// "Motor, Fren Sistemi ve Klima" — real Turkish list phrasing (comma
/// between all but the last two items, "ve" between the last two) rather
/// than a flat comma join.
String _naturalList(List<String> items) {
  if (items.length == 1) return items.first;
  return '${items.sublist(0, items.length - 1).join(', ')} ve ${items.last}';
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 20,
              color: AppColors.turquoise,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cover header — either the mechanic's own real uploaded photo (see
/// MechanicProfileRepository.uploadCoverPhoto/coverPhotoUrl), or, when
/// none has been uploaded yet, the same gradient-with-icon fallback this
/// screen always used before this feature existed (a real "no photo yet"
/// state, never a fabricated stock photo — see this class's own history
/// for that established "no fabricated photo" convention). Either variant
/// shows the real isVerified badge (reusing this app's own established
/// "Doğrulanmış Servis" wording, same as the top bar/MechanicDetailPage)
/// and a small camera button that triggers the real upload flow — visible
/// in both states, since uploading the *first* photo has to start from
/// the fallback state.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.businessName,
    required this.address,
    required this.isVerified,
    required this.coverPhotoUrl,
    required this.isUploadingCoverPhoto,
    required this.onPickCoverPhoto,
  });

  final String businessName;
  final String? address;
  final bool isVerified;
  final String? coverPhotoUrl;
  final bool isUploadingCoverPhoto;
  final VoidCallback onPickCoverPhoto;

  static const _coverGradient = LinearGradient(
    colors: [AppColors.turquoise, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _coverPhotoHeight = 200.0;
  static const _avatarSize = 72.0;
  static const _editButtonSize = 36.0;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = coverPhotoUrl != null && coverPhotoUrl!.isNotEmpty;
    return hasPhoto
        ? _buildWithPhoto(coverPhotoUrl!)
        : _buildGradientFallback();
  }

  Widget _editButton() {
    return GestureDetector(
      onTap: isUploadingCoverPhoto ? null : onPickCoverPhoto,
      child: Container(
        width: _editButtonSize,
        height: _editButtonSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isUploadingCoverPhoto
            ? const Padding(
                padding: EdgeInsets.all(9),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.turquoise,
                ),
              )
            : const Icon(
                Icons.camera_alt_outlined,
                size: 18,
                color: AppColors.turquoise,
              ),
      ),
    );
  }

  Widget _buildGradientFallback() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        gradient: _coverGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                businessName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (address != null && address!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (isVerified) ...[
                const SizedBox(height: AppSpacing.sm),
                const _VerifiedBadge(onGradient: true),
              ],
            ],
          ),
          Positioned(right: 0, bottom: 0, child: _editButton()),
        ],
      ),
    );
  }

  Widget _buildWithPhoto(String url) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: _coverPhotoHeight,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                // A shop's identifying content (signage, storefront) tends
                // to sit near the top of the photo — centering the crop
                // was cutting it off, so anchor the crop to the top instead.
                alignment: Alignment.topCenter,
                // Falls back to a plain neutral block (not a broken-image
                // icon, not a stock photo) if the real URL fails to load —
                // logged so a real failure is diagnosable, same convention
                // as this file's other *_ERROR debugPrints.
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('MECHANIC PROFILE COVER PHOTO LOAD ERROR: $error');
                  return Container(color: AppColors.divider);
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.divider,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                _avatarSize / 2 + AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (address != null && address!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isVerified) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const _VerifiedBadge(onGradient: false),
                  ],
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: AppSpacing.xl,
          top: _coverPhotoHeight - _avatarSize / 2,
          child: Container(
            width: _avatarSize,
            height: _avatarSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.lg,
          top: _coverPhotoHeight - _editButtonSize - AppSpacing.md,
          child: _editButton(),
        ),
      ],
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.onGradient});

  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = onGradient
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.scheduleTodayBackground;
    final foregroundColor = onGradient ? Colors.white : AppColors.turquoise;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            'Doğrulanmış Servis',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Up to 3 additional real photos beyond the cover photo (see
/// MechanicProfile.galleryPhotoUrls/MechanicProfileRepository.uploadGalleryPhoto)
/// — always exactly 3 slots shown here (unlike the customer-facing gallery
/// strip on MechanicDetailPage, which shows only real photos and nothing
/// for empty ones): this is the mechanic's own management view, where an
/// empty slot is itself a real, actionable "add a photo here" affordance,
/// not something to hide.
class _GalleryPhotosSection extends StatelessWidget {
  const _GalleryPhotosSection({
    required this.galleryPhotoUrls,
    required this.uploadingIndex,
    required this.onTapSlot,
    required this.onRemoveSlot,
  });

  /// Always exactly 3 entries — see MechanicProfile.galleryPhotoUrls.
  final List<String?> galleryPhotoUrls;

  final int? uploadingIndex;
  final void Function(int index) onTapSlot;
  final void Function(int index) onRemoveSlot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(text: 'Fotoğraflar'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i != 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GalleryPhotoSlot(
                  url: galleryPhotoUrls[i],
                  isUploading: uploadingIndex == i,
                  onTap: () => onTapSlot(i),
                  onRemove: () => onRemoveSlot(i),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// One 1:1 gallery slot — either a real uploaded photo (tap to replace,
/// small "x" badge to remove) or, when empty, a dashed-border "add a
/// photo" tile (tap to upload). Both variants trigger the same
/// pick-then-crop-then-upload flow one level up
/// (MechanicProfileScreen._pickAndUploadGalleryPhoto) — uploading to an
/// already-filled slot simply overwrites it, so there's no separate
/// "replace" code path to keep in sync with "add".
class _GalleryPhotoSlot extends StatelessWidget {
  const _GalleryPhotoSlot({
    required this.url,
    required this.isUploading,
    required this.onTap,
    required this.onRemove,
  });

  final String? url;
  final bool isUploading;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = url != null && url!.isNotEmpty;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: isUploading ? null : onTap,
            child: hasPhoto ? _photoTile(url!) : _emptyTile(),
          ),
          if (isUploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          // The remove "x" — NOT AppColors.emergency/red: that color is
          // reserved exclusively for the roadside-help emergency card
          // elsewhere in this app (see app_theme.dart's own doc comment on
          // AppColors.emergency), so this uses a neutral dark scrim
          // instead, same as common photo-picker remove affordances.
          if (hasPhoto && !isUploading)
            Positioned(
              right: 4,
              top: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoTile(String url) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        // Same "log, plain neutral fallback, never a fabricated photo"
        // convention as _ProfileHeader's own cover-photo Image.network.
        errorBuilder: (context, error, stackTrace) {
          debugPrint('MECHANIC PROFILE GALLERY PHOTO LOAD ERROR: $error');
          return Container(color: AppColors.divider);
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.divider,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        },
      ),
    );
  }

  Widget _emptyTile() {
    return CustomPaint(
      painter: const _DashedBorderPainter(
        color: AppColors.divider,
        radius: AppRadius.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 22,
              color: AppColors.turquoise,
            ),
            SizedBox(height: 2),
            Text(
              'Fotoğraf Ekle',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.turquoise,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dashed rounded-rect border — Flutter's BoxDecoration/Border only
/// support solid strokes, and this is a small, purely decorative need
/// (the empty gallery slot's "add a photo here" affordance), not
/// justification for a new package dependency on top of image_cropper.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _dashWidth = 5.0;
  static const _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + _dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Tamamlanan İş / Tekrar Eden Müşteri / Değerlendirme — the same three
/// real data sources the previous layout already used
/// (AppointmentRepository.fetchVerifiedCompletedCount,
/// MechanicProfileRepository.fetchRepeatCustomerCount, profile.rating/
/// reviewCount with the same MockData fallback), just combined into one
/// horizontal card instead of three stacked rows.
class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.businessId,
    required this.rating,
    required this.reviewCount,
  });

  final String businessId;
  final double? rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.lg,
      ),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FutureBuilder<int>(
              // Same call/data source as before — only the layout changed.
              future: AppointmentRepository().fetchVerifiedCompletedCount(
                businessId,
              ),
              builder: (context, snapshot) {
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                return _StatColumn(
                  icon: Icons.verified_outlined,
                  value: isLoading ? '...' : '${snapshot.data ?? 0}',
                  label: 'Tamamlanan İş',
                  color: AppColors.turquoise,
                );
              },
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
          Expanded(
            child: FutureBuilder<int?>(
              // Same call/data source as before — only the layout changed.
              future: MechanicProfileRepository().fetchRepeatCustomerCount(
                businessId,
              ),
              builder: (context, snapshot) {
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                return _StatColumn(
                  icon: Icons.repeat_rounded,
                  value: isLoading ? '...' : '${snapshot.data ?? 0}',
                  label: 'Tekrar Eden Müşteri',
                  color: AppColors.primary,
                );
              },
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
          Expanded(
            child: _StatColumn(
              icon: Icons.star_rounded,
              // '—' (never a fabricated 0.0) when there's no real rating
              // yet — same convention already used elsewhere in this app
              // for a missing rating.
              value: rating != null ? rating!.toStringAsFixed(1) : '—',
              label: reviewCount != null
                  ? 'Değerlendirme ($reviewCount)'
                  : 'Değerlendirme',
              color: AppColors.rating,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.turquoise),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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

/// Compact rounded chips for [MechanicProfile.hizmetler]/[Mechanic.hizmetler]
/// — the same real, already-written Firestore field
/// mechanic_login_page.dart's registration/claim flow sets, just newly
/// exposed on MechanicProfile ([MechanicProfile.fromFirestore]) and
/// rendered here; no new query, no new collection. Capped so a business
/// with many services stays scannable — "Tümünü Gör" expands in place
/// (this screen has no dedicated "all services" page to navigate to, and
/// this redesign must not touch navigation).
class _ServiceChipsSection extends StatefulWidget {
  const _ServiceChipsSection({required this.services});

  final List<String> services;

  @override
  State<_ServiceChipsSection> createState() => _ServiceChipsSectionState();
}

class _ServiceChipsSectionState extends State<_ServiceChipsSection> {
  static const _collapsedCount = 6;

  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.services.length > _collapsedCount;
    final visibleServices = _expanded
        ? widget.services
        : widget.services.take(_collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel(text: 'Hizmetler')),
            if (!_expanded && hasMore)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Text(
                  'Tümünü Gör (${widget.services.length})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final service in visibleServices) _ServiceChip(label: service),
          ],
        ),
      ],
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.scheduleTodayBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.turquoise,
        ),
      ),
    );
  }
}
