import 'package:cloud_firestore/cloud_firestore.dart';

/// One row on [AdminApprovalScreen] — a raw mechanicAccounts document plus
/// its real Firestore document id, so a verification toggle can write back
/// to the exact same doc it was read from. Deliberately separate from
/// models/mechanic.dart's [Mechanic] (which has no document-id field at
/// all, since customer-facing screens never need to write back) rather than
/// extending that shared model for this one admin-only need.
class AdminMechanicRow {
  const AdminMechanicRow({
    required this.id,
    required this.businessId,
    required this.name,
    required this.hizmetTuru,
    required this.phone,
    required this.isVerified,
  });

  /// The mechanicAccounts document id — a signed-in mechanic's own Firebase
  /// Auth UID for accounts created through registration, or an
  /// auto-generated id for accounts created by an admin bulk-upload script.
  /// Either way, this is what AdminRepository.setMechanicVerified writes to.
  final String id;

  /// The `businessId` field — NOT always equal to [id]. Real registrations
  /// (mechanic_login_page.dart) key the document by the mechanic's Firebase
  /// Auth UID but store a separately-derived businessId
  /// (mechanicChatId(name)) as a field; only the bulk-upload script's rows
  /// happen to set both to the same value. This is what
  /// MechanicDirectoryRepository.fetchByBusinessId — the same lookup
  /// CustomerConversationPage already uses to open MechanicDetailPage —
  /// actually queries on, so it has to be kept distinct from [id].
  final String businessId;

  final String name;

  /// 'tamir' | 'ekspertiz' | 'sigorta' | null — null for older/incomplete
  /// accounts, shown as-is rather than guessing a value.
  final String? hizmetTuru;

  final String phone;
  final bool isVerified;

  factory AdminMechanicRow.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AdminMechanicRow(
      id: doc.id,
      businessId: data['businessId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      hizmetTuru: data['hizmetTürü'] as String?,
      phone: data['phone'] as String? ?? '',
      isVerified: data['isVerified'] as bool? ?? false,
    );
  }
}
