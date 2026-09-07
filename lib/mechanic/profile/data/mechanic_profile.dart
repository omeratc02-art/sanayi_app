/// A signed-in mechanic's own real business profile, read from
/// `mechanicAccounts/{uid}` — the same document [resolveMyBusinessId] and
/// the security rules already use, just with the fuller field set a real
/// profile screen needs (see MechanicProfileRepository). Deliberately a
/// separate, small model rather than reusing models/mechanic.dart's
/// [Mechanic]: that class is shaped for the customer-facing catalog
/// (distance, price range, categories, ...), most of which doesn't apply
/// to "a mechanic viewing/managing their own account".
class MechanicProfile {
  const MechanicProfile({
    required this.uid,
    required this.businessId,
    required this.businessName,
    required this.email,
    this.phone,
    this.address,
    this.isVerified = false,
    this.rating,
    this.reviewCount,
    this.hizmetler = const [],
    this.coverPhotoUrl,
  });

  /// Firebase Auth UID — same as the mechanicAccounts/{uid} document id.
  final String uid;

  /// The stable per-business slug (mechanicChatId(businessName)) — same id
  /// already used by chats/{chatId} and the appointments businessId field.
  final String businessId;

  final String businessName;
  final String email;

  /// Present only for accounts registered after this field was added, or
  /// once the mechanic edits their profile — older accounts simply don't
  /// have it yet, hence nullable rather than defaulted to ''.
  final String? phone;
  final String? address;

  final bool isVerified;

  /// Nullable rather than defaulted to 0 — a missing rating means "no
  /// rating recorded on this account yet", which is different from a real
  /// 0.0 rating and shouldn't be displayed the same way.
  final double? rating;
  final int? reviewCount;

  /// Structured sub-services this business offers (e.g. ['Motor', 'Fren
  /// Sistemi']) — the same real `hizmetler` field
  /// mechanic_login_page.dart's registration/claim flow already writes to
  /// this exact document (see models/mechanic.dart's own [Mechanic.hizmetler]
  /// for the customer-facing counterpart of this same field). Empty, not
  /// null, for an account that hasn't set any yet — a real "nothing listed"
  /// state, not "unknown".
  final List<String> hizmetler;

  /// Real Firebase Storage download URL for this business's uploaded cover
  /// photo (see MechanicProfileRepository.uploadCoverPhoto — one file at
  /// mechanic_covers/{businessId}/cover.jpg, this field always points at
  /// its current download URL). Null means "no photo uploaded yet", a real
  /// state to render a fallback for, never a broken-image placeholder.
  final String? coverPhotoUrl;

  factory MechanicProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    final rating = data['rating'];
    return MechanicProfile(
      uid: uid,
      businessId: data['businessId'] as String? ?? '',
      businessName: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      address: data['address'] as String?,
      isVerified: data['isVerified'] as bool? ?? false,
      rating: rating is num ? rating.toDouble() : null,
      reviewCount: data['reviewCount'] as int?,
      hizmetler: (data['hizmetler'] as List<dynamic>?)?.whereType<String>().toList() ?? const [],
      coverPhotoUrl: data['coverPhotoUrl'] as String?,
    );
  }
}
