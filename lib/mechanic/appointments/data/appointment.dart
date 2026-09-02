import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// randevuTarihi stores only a calendar date (see [Appointment.appointmentDate]'s
/// own doc comment — real time-of-day lives separately in randevu_zamani),
/// but Firestore's Timestamp is always a specific instant, not a pure date.
/// This anchors that date to noon UTC rather than midnight, so that
/// converting back to a reader's local time (as Timestamp.toDate() always
/// does) can't shift the calendar date to the day before or after — as
/// long as the reader's UTC offset is within ±11:59 of UTC. That holds for
/// every timezone actually in use (UTC-12 to UTC+14 exist on paper, but
/// this app is Turkey-only today, fixed at UTC+3 with no DST since 2016 —
/// nowhere near that edge). If this app ever needs to serve a location at
/// UTC+12 or beyond, this assumption stops holding and needs revisiting.
const appointmentDateAnchorHourUtc = 12;

/// Status of an appointment across its lifecycle, from an accepted request
/// through to completion. Distinct from the customer-facing AppointmentStatus
/// in dummy_appointment.dart, which belongs to an unrelated screen and must
/// not be affected by changes here.
///
/// [timeProposed] is the negotiation state: one side (see [Appointment.sonTeklifEden])
/// has proposed a new date/time (see [Appointment.teklifEdilenTarih]/
/// [Appointment.teklifEdilenSaat]) and the other side hasn't responded yet.
/// randevuTarihi/randevu_zamani (appointmentDate/appointmentTime) are NOT
/// touched while in this state — only accepting a proposal moves the teklif
/// fields into the real date/time.
enum AppointmentStatus { pending, timeProposed, accepted, inProgress, completed, cancelled, declined }

extension AppointmentStatusPresentation on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.pending => 'Beklemede',
    AppointmentStatus.timeProposed => 'Saat Teklif Edildi',
    AppointmentStatus.accepted => 'Onaylandı',
    AppointmentStatus.inProgress => 'Devam Ediyor',
    AppointmentStatus.completed => 'Tamamlandı',
    AppointmentStatus.cancelled => 'İptal Edildi',
    AppointmentStatus.declined => 'Reddedildi',
  };

  Color get color => switch (this) {
    AppointmentStatus.pending => Colors.orange.shade700,
    AppointmentStatus.timeProposed => Colors.purple.shade700,
    AppointmentStatus.accepted => Colors.green.shade700,
    AppointmentStatus.inProgress => Colors.blue.shade700,
    AppointmentStatus.completed => Colors.blue.shade700,
    AppointmentStatus.cancelled => Colors.red.shade700,
    AppointmentStatus.declined => Colors.red.shade700,
  };
}

/// A complete appointment record — backed by the real production Firestore
/// collection `randevular` (see [fromFirestore]/[toFirestore] for the exact
/// Turkish field mapping). Every Dart-side field below keeps its original
/// English name; only the Firestore read/write mapping is Turkish, matching
/// the real, already-populated schema rather than the app's earlier
/// (unused-in-production) English one.
class Appointment {
  const Appointment({
    required this.appointmentId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleModel,
    required this.licensePlate,
    required this.serviceType,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.estimatedDuration,
    required this.customerNote,
    required this.status,
    required this.createdAt,
    required this.distance,
    this.businessId = '',
    this.preferredTimeRangeLabel = '',
    this.kvkkAccepted = false,
    this.kvkkAcceptedAt,
    this.tamamlanmaDurumu = 'beklemede',
    this.ustaTamamlamaTarihi,
    this.musteriOnayTarihi,
    this.musteriYorumu,
    this.musteriPuani,
    this.sonTeklifEden,
    this.teklifEdilenTarih,
    this.teklifEdilenSaat,
  });

  final String appointmentId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String vehicleModel;
  final String licensePlate;
  final String serviceType;

  /// Calendar date only (year/month/day) — time-of-day lives in
  /// [appointmentTime].
  final DateTime appointmentDate;
  final TimeOfDay appointmentTime;
  final Duration estimatedDuration;
  final String customerNote;
  final AppointmentStatus status;
  final DateTime createdAt;

  /// Not part of the required field set — kept because
  /// MechanicAppointmentDetailsPage's customer card already displays how
  /// far the customer is, and the existing UI must not change.
  final String distance;

  /// The stable per-business id (mechanicChatId(name), same as chats and
  /// mechanicAccounts.businessId) this appointment belongs to. Defaults to
  /// '' so the existing dummy schedule below (never written to or read
  /// from Firestore) doesn't need one — only real customer requests and
  /// the mechanic screen's own businessId-filtered query rely on it.
  final String businessId;

  /// The customer's originally requested arrival window (e.g. "15:00 –
  /// 17:00", or "İlk Müsait Saat" for no preference) — kept as its own
  /// field, separate from [appointmentTime], which only ever holds a real
  /// specific time once the mechanic sets one (via "Başka Saat Öner" or
  /// accepting outright). Never overwritten by that process — this stays
  /// the customer's original request for the whole lifecycle of the
  /// document. Defaults to '' for the same reason as [businessId] above.
  final String preferredTimeRangeLabel;

  /// Whether the customer accepted the KVKK Aydınlatma Metni at request
  /// submission time — set once by AppointmentRequestStore._persistToFirestore
  /// and never changed afterward.
  final bool kvkkAccepted;

  /// When [kvkkAccepted] was recorded — null if consent was never given.
  final DateTime? kvkkAcceptedAt;

  /// Completion-verification status, layered on top of [status]/durum —
  /// one of "beklemede" | "usta_onayladi_bekleniyor" |
  /// "dogrulanmis_tamamlandi" | "anlasmazlik". Never transitions
  /// automatically: "usta_onayladi_bekleniyor" only ever advances via an
  /// explicit customer action (see AppointmentRepository.markCustomerVerified
  /// /markCustomerDisputed). No timer, Cloud Function, or scheduled job
  /// anywhere in this codebase moves this forward on its own.
  final String tamamlanmaDurumu;

  /// When the mechanic marked the job complete — null until then.
  final DateTime? ustaTamamlamaTarihi;

  /// When the customer verified or disputed completion — null until then.
  final DateTime? musteriOnayTarihi;

  /// Optional customer comment left alongside verification.
  final String? musteriYorumu;

  /// Optional 1-5 customer rating left alongside verification.
  final int? musteriPuani;

  /// Who made the most recent time proposal — 'usta' | 'musteri' — only
  /// meaningful while [status] is [AppointmentStatus.timeProposed]. Lets
  /// each side's UI tell "your turn to respond" from "waiting on the other
  /// side" without a separate field. Null once a proposal is accepted (see
  /// AppointmentRepository.acceptTimeProposal, which clears it).
  final String? sonTeklifEden;

  /// The proposed new date/time awaiting a response — [appointmentDate]/
  /// [appointmentTime] are NOT touched until this proposal is accepted, so
  /// the current confirmed time (if any) stays intact throughout the
  /// negotiation. Both null together, or both set together.
  final DateTime? teklifEdilenTarih;
  final TimeOfDay? teklifEdilenSaat;

  /// [appointmentDate] and [appointmentTime] combined into one instant —
  /// used for calendar positioning and time formatting.
  DateTime get start => DateTime(
    appointmentDate.year,
    appointmentDate.month,
    appointmentDate.day,
    appointmentTime.hour,
    appointmentTime.minute,
  );

  /// Reads a real `randevular/{id}` document — see the Turkish field names
  /// inline below. [documentId] is used as a fallback for [appointmentId]
  /// when a document has no `randevu_kimliği` field of its own (or it
  /// doesn't match the document's real id).
  factory Appointment.fromFirestore(Map<String, dynamic> data, String documentId) {
    final customerNote = (data['müşteriNotu'] ?? data['müşteri Notu']) as String? ?? '';
    // TEMP DEBUG — remove after root-causing the service-label mismatch.
    debugPrint(
      'TRACE fromFirestore doc=$documentId hizmetTürü=${data['hizmetTürü']} '
      'işletme_kimliği=${data['işletme_kimliği']} randevuTarihi=${data['randevuTarihi']} '
      'randevu_zamani=${data['randevu_zamani']}',
    );
    return Appointment(
      appointmentId: data['randevu_kimliği'] as String? ?? documentId,
      customerId: data['müşteri_kimliği'] as String? ?? '',
      customerName: data['müşteriAdı'] as String? ?? '',
      customerPhone: data['müşteriTelefonu'] as String? ?? '',
      vehicleModel: data['araçModeli'] as String? ?? '',
      licensePlate: data['plaka'] as String? ?? '',
      serviceType: data['hizmetTürü'] as String? ?? '',
      appointmentDate: _parseFirestoreDate(data['randevuTarihi']) ?? DateTime.now(),
      appointmentTime: _parseTimeOfDay(data['randevu_zamani']),
      estimatedDuration: _parseDurationMinutes(data['tahminiSüreDakika']),
      customerNote: customerNote,
      status: _statusFromDurum(data['durum'] as String?),
      createdAt: _parseFirestoreDate(data['oluşturulma_tarihi']) ?? DateTime.now(),
      distance: _formatDistance(data['mesafe']),
      businessId: data['işletme_kimliği'] as String? ?? '',
      preferredTimeRangeLabel: _extractPreferredWindow(customerNote),
      kvkkAccepted: data['kvkkOnaylandi'] as bool? ?? false,
      kvkkAcceptedAt: _parseFirestoreDate(data['kvkkOnayTarihi']),
      tamamlanmaDurumu: data['tamamlanmaDurumu'] as String? ?? 'beklemede',
      ustaTamamlamaTarihi: _parseFirestoreDate(data['ustaTamamlamaTarihi']),
      musteriOnayTarihi: _parseFirestoreDate(data['musteriOnayTarihi']),
      musteriYorumu: data['musteriYorumu'] as String?,
      musteriPuani: (data['musteriPuani'] as num?)?.toInt(),
      sonTeklifEden: data['sonTeklifEden'] as String?,
      teklifEdilenTarih: _parseFirestoreDate(data['teklifEdilenTarih']),
      teklifEdilenSaat: _parseNullableTimeOfDay(data['teklifEdilenSaat']),
    );
  }

  /// Writes back to the same Turkish `randevular` schema [fromFirestore]
  /// reads — the exact inverse mapping, field for field. [preferredTimeRangeLabel]
  /// has no dedicated real field (see its own doc comment) so it isn't
  /// re-serialized here; it's only ever embedded into [customerNote] once,
  /// at request-submission time (see AppointmentRequestStore._persistToFirestore).
  Map<String, dynamic> toFirestore() => {
    'randevu_kimliği': appointmentId,
    'müşteri_kimliği': customerId,
    'müşteriAdı': customerName,
    'müşteriTelefonu': customerPhone,
    'araçModeli': vehicleModel,
    'plaka': licensePlate,
    'hizmetTürü': serviceType,
    'randevuTarihi': Timestamp.fromDate(
      DateTime.utc(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        appointmentDateAnchorHourUtc,
      ),
    ),
    'randevu_zamani': formatTimeOfDayString(appointmentTime),
    'tahminiSüreDakika': estimatedDuration.inMinutes,
    'müşteriNotu': customerNote,
    'durum': _durumFromStatus(status),
    'oluşturulma_tarihi': Timestamp.fromDate(createdAt),
    'mesafe': distance,
    'işletme_kimliği': businessId,
    'kvkkOnaylandi': kvkkAccepted,
    'kvkkOnayTarihi': kvkkAcceptedAt != null ? Timestamp.fromDate(kvkkAcceptedAt!) : null,
    'tamamlanmaDurumu': tamamlanmaDurumu,
    'ustaTamamlamaTarihi': ustaTamamlamaTarihi != null ? Timestamp.fromDate(ustaTamamlamaTarihi!) : null,
    'musteriOnayTarihi': musteriOnayTarihi != null ? Timestamp.fromDate(musteriOnayTarihi!) : null,
    'musteriYorumu': musteriYorumu,
    'musteriPuani': musteriPuani,
    'sonTeklifEden': sonTeklifEden,
    'teklifEdilenTarih': teklifEdilenTarih != null
        ? Timestamp.fromDate(
            DateTime.utc(
              teklifEdilenTarih!.year,
              teklifEdilenTarih!.month,
              teklifEdilenTarih!.day,
              appointmentDateAnchorHourUtc,
            ),
          )
        : null,
    'teklifEdilenSaat': teklifEdilenSaat != null ? formatTimeOfDayString(teklifEdilenSaat!) : null,
  };
}

const _turkishMonths = [
  'ocak', 'şubat', 'mart', 'nisan', 'mayıs', 'haziran',
  'temmuz', 'ağustos', 'eylül', 'ekim', 'kasım', 'aralık',
];
const _englishMonths = [
  'january', 'february', 'march', 'april', 'may', 'june',
  'july', 'august', 'september', 'october', 'november', 'december',
];

/// randevuTarihi/oluşturulma_tarihi have been observed as Firestore
/// Timestamps, but this defensively also accepts an ISO string or a
/// "15 Ağustos 2026" / "15 August 2026" free-text date, rather than
/// silently falling back to "now" for any format that isn't a Timestamp.
DateTime? _parseFirestoreDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is! String) return null;
  final iso = DateTime.tryParse(value);
  if (iso != null) return iso;
  final match = RegExp(r'^(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+(\d{4})$').firstMatch(value.trim());
  if (match == null) return null;
  final day = int.tryParse(match.group(1)!);
  final year = int.tryParse(match.group(3)!);
  final monthName = match.group(2)!.toLowerCase();
  final monthIndex = _turkishMonths.contains(monthName)
      ? _turkishMonths.indexOf(monthName)
      : _englishMonths.indexOf(monthName);
  if (day == null || year == null || monthIndex < 0) return null;
  return DateTime(year, monthIndex + 1, day);
}

/// randevu_zamani is a zero-padded "HH:mm" string (e.g. "09:00") — same
/// convention this app already writes. Malformed/missing values fall back
/// to the existing "no real time yet" sentinel (00:00) rather than
/// throwing.
TimeOfDay _parseTimeOfDay(dynamic value) {
  final parts = (value is String ? value : '').split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return const TimeOfDay(hour: 0, minute: 0);
  }
  return TimeOfDay(hour: hour, minute: minute);
}

/// Same "HH:mm" convention as [_parseTimeOfDay], but null (not the 00:00
/// sentinel) when absent or malformed — for teklifEdilenSaat, where "no
/// value" and "midnight" must stay distinguishable.
TimeOfDay? _parseNullableTimeOfDay(dynamic value) {
  if (value is! String) return null;
  final parts = value.split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

Duration _parseDurationMinutes(dynamic value) {
  if (value is num) return Duration(minutes: value.toInt());
  if (value is String) return Duration(minutes: int.tryParse(value) ?? 0);
  return Duration.zero;
}

/// mesafe has been observed only as a field name, not a confirmed type —
/// this accepts either a pre-formatted string (e.g. "3.2 km") or a bare
/// number (formatted here with a "km" suffix), and stays '' (genuinely
/// unavailable, never invented) when the field is absent.
String _formatDistance(dynamic value) {
  if (value == null) return '';
  if (value is num) return '${value.toStringAsFixed(1)} km';
  return value.toString();
}

String formatTimeOfDayString(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

/// Maps the real `durum` field (Turkish) to [AppointmentStatus]. Only
/// 'kabul edildi' has been verified against real production data — the
/// rest are the standard Turkish equivalents, used for display only. Any
/// unrecognized value (including whatever the real "awaiting decision"
/// string turns out to be) safely falls back to [AppointmentStatus.pending]
/// rather than being mis-categorized as already decided, so a real new
/// request is never silently hidden from "Yeni Talepler".
AppointmentStatus _statusFromDurum(String? durum) {
  switch (durum) {
    case 'kabul edildi':
      return AppointmentStatus.accepted;
    case 'reddedildi':
      return AppointmentStatus.declined;
    case 'iptal edildi':
      return AppointmentStatus.cancelled;
    case 'tamamlandı':
      return AppointmentStatus.completed;
    case 'devam ediyor':
      return AppointmentStatus.inProgress;
    case 'saat_teklif_edildi':
      return AppointmentStatus.timeProposed;
    default:
      return AppointmentStatus.pending;
  }
}

/// Inverse of [_statusFromDurum] — 'kabul edildi' (accepted) is the only
/// value confirmed against real data; the rest are this function's own
/// best-guess standard Turkish equivalents (see that function's doc
/// comment) and should be spot-checked against the real system once it's
/// possible to observe a mechanic-declined or newly-submitted document.
/// 'saat_teklif_edildi' (timeProposed) is this app's own new value, not a
/// guessed equivalent of anything — see AppointmentStatus.timeProposed.
String _durumFromStatus(AppointmentStatus status) => switch (status) {
  AppointmentStatus.accepted => 'kabul edildi',
  AppointmentStatus.declined => 'reddedildi',
  AppointmentStatus.cancelled => 'iptal edildi',
  AppointmentStatus.completed => 'tamamlandı',
  AppointmentStatus.inProgress => 'devam ediyor',
  AppointmentStatus.timeProposed => 'saat_teklif_edildi',
  AppointmentStatus.pending => 'beklemede',
};

final _preferredWindowPattern = RegExp(r'[Tt]ercih edilen saat aralığı\s*:\s*([^\n\r]+)');

/// Pulls the customer's originally preferred arrival window back out of
/// müşteriNotu (e.g. "Tercih edilen saat aralığı: 15:00 - 17:00") — real
/// data embeds it in the note text rather than a dedicated field. Never
/// confused with [Appointment.appointmentTime]/randevu_zamani, which is
/// the actual (possibly mechanic-set) appointment time, not a preference.
String _extractPreferredWindow(String note) => _preferredWindowPattern.firstMatch(note)?.group(1)?.trim() ?? '';

final _preferredTimeRangePattern = RegExp(r'^(\d{1,2}):(\d{2})\s*[–-]\s*(\d{1,2}):(\d{2})$');

/// Parses a preferred-window label like "15:00 - 17:00" (see
/// [_extractPreferredWindow]/[Appointment.preferredTimeRangeLabel]) into a
/// real (start time, duration) pair — the source of truth both
/// MechanicAppointmentsScreen's "Kabul Et" and MechanicRequestDetailsPage's
/// "Talebi Kabul Et" use to resolve a real appointment time for a request
/// that has no mechanic-proposed time of its own yet (see
/// Appointment.appointmentTime's "no time yet" sentinel). Returns null for
/// anything that isn't a real parseable window — "İlk Müsait Saat", an
/// empty label, or a malformed/degenerate range — so callers never invent a
/// time from no information.
({TimeOfDay start, Duration duration})? parsePreferredTimeRange(String label) {
  final match = _preferredTimeRangePattern.firstMatch(label.trim());
  if (match == null) return null;
  final startHour = int.parse(match.group(1)!);
  final startMinute = int.parse(match.group(2)!);
  final endHour = int.parse(match.group(3)!);
  final endMinute = int.parse(match.group(4)!);
  if (startHour > 23 || endHour > 23 || startMinute > 59 || endMinute > 59) return null;
  final startTotalMinutes = startHour * 60 + startMinute;
  final endTotalMinutes = endHour * 60 + endMinute;
  if (endTotalMinutes <= startTotalMinutes) return null;
  return (
    start: TimeOfDay(hour: startHour, minute: startMinute),
    duration: Duration(minutes: endTotalMinutes - startTotalMinutes),
  );
}

/// Dummy schedule spanning several days around "today" so the calendar has
/// something to show regardless of which date is selected.
List<Appointment> buildDummyAppointments() {
  final today = DateTime.now();
  DateTime dateOnly(int dayOffset) {
    final day = today.add(Duration(days: dayOffset));
    return DateTime(day.year, day.month, day.day);
  }

  return [
    Appointment(
      appointmentId: 'APT-2001',
      customerId: 'CUST-1001',
      customerName: 'Ahmet Yılmaz',
      customerPhone: '0532 111 22 33',
      vehicleModel: 'Renault Clio',
      licensePlate: '34 ABC 123',
      serviceType: 'Yağ Değişimi',
      appointmentDate: dateOnly(0),
      appointmentTime: const TimeOfDay(hour: 9, minute: 0),
      estimatedDuration: const Duration(minutes: 60),
      customerNote: 'Aracımda ayrıca hafif bir fren sesi var, kontrol edebilir misiniz?',
      status: AppointmentStatus.accepted,
      createdAt: today.subtract(const Duration(days: 2)),
      distance: '3.2 km',
    ),
    Appointment(
      appointmentId: 'APT-2002',
      customerId: 'CUST-2001',
      customerName: 'Mehmet Demir',
      customerPhone: '0532 123 45 67',
      vehicleModel: 'Toyota Corolla',
      licensePlate: '35 DEF 789',
      serviceType: 'Akü Değişimi',
      appointmentDate: dateOnly(0),
      appointmentTime: const TimeOfDay(hour: 11, minute: 30),
      estimatedDuration: const Duration(minutes: 45),
      customerNote: 'Sabahları araç bazen zor çalışıyor, kontrol edilmesini istiyorum.',
      status: AppointmentStatus.pending,
      createdAt: today.subtract(const Duration(days: 1)),
      distance: '2.1 km',
    ),
    Appointment(
      appointmentId: 'APT-2003',
      customerId: 'CUST-2002',
      customerName: 'Mehmet Usta',
      customerPhone: '0533 222 33 44',
      vehicleModel: 'Peugeot 208',
      licensePlate: '27 GHI 456',
      serviceType: 'Periyodik Bakım (10.000 km)',
      appointmentDate: dateOnly(1),
      appointmentTime: const TimeOfDay(hour: 10, minute: 0),
      estimatedDuration: const Duration(minutes: 90),
      customerNote: 'Uzun yol öncesi genel kontrol istiyorum.',
      status: AppointmentStatus.accepted,
      createdAt: today.subtract(const Duration(days: 3)),
      distance: '4.5 km',
    ),
    Appointment(
      appointmentId: 'APT-2004',
      customerId: 'CUST-2003',
      customerName: 'Ahmet Yıldız',
      customerPhone: '0534 333 44 55',
      vehicleModel: 'Renault Clio',
      licensePlate: '34 ABC 123',
      serviceType: 'Fren Balata Değişimi',
      appointmentDate: dateOnly(2),
      appointmentTime: const TimeOfDay(hour: 14, minute: 0),
      estimatedDuration: const Duration(minutes: 60),
      customerNote: 'Fren yaparken hafif titreme hissediyorum.',
      status: AppointmentStatus.cancelled,
      createdAt: today.subtract(const Duration(days: 4)),
      distance: '5.8 km',
    ),
    Appointment(
      appointmentId: 'APT-2005',
      customerId: 'CUST-2004',
      customerName: 'Emre Kaya',
      customerPhone: '0535 444 55 66',
      vehicleModel: 'Fiat Egea',
      licensePlate: '06 XYZ 456',
      serviceType: 'Lastik Değişimi',
      appointmentDate: dateOnly(3),
      appointmentTime: const TimeOfDay(hour: 9, minute: 30),
      estimatedDuration: const Duration(minutes: 30),
      customerNote: 'Kış lastiklerine geçiş yapılacak.',
      status: AppointmentStatus.pending,
      createdAt: today.subtract(const Duration(days: 1)),
      distance: '1.7 km',
    ),
    Appointment(
      appointmentId: 'APT-2006',
      customerId: 'CUST-1002',
      customerName: 'Elif Kaya',
      customerPhone: '0536 555 66 77',
      vehicleModel: 'Fiat Egea',
      licensePlate: '06 XYZ 456',
      serviceType: 'Fren Bakımı',
      appointmentDate: dateOnly(3),
      appointmentTime: const TimeOfDay(hour: 13, minute: 0),
      estimatedDuration: const Duration(minutes: 60),
      customerNote: 'Öğleden sonra müsaitim, sabah saatleri bana uygun değil.',
      status: AppointmentStatus.completed,
      createdAt: today.subtract(const Duration(days: 5)),
      distance: '5.8 km',
    ),
    Appointment(
      appointmentId: 'APT-2007',
      customerId: 'CUST-1001',
      customerName: 'Ahmet Yılmaz',
      customerPhone: '0532 111 22 33',
      vehicleModel: 'Renault Clio',
      licensePlate: '34 ABC 123',
      serviceType: 'Klima Bakımı',
      appointmentDate: dateOnly(5),
      appointmentTime: const TimeOfDay(hour: 15, minute: 30),
      estimatedDuration: const Duration(minutes: 45),
      customerNote: 'Klimadan garip bir koku geliyor.',
      status: AppointmentStatus.accepted,
      createdAt: today.subtract(const Duration(days: 2)),
      distance: '3.2 km',
    ),
  ];
}
