import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'data/appointment.dart';
import 'mechanic_appointment_details_page.dart';

/// Simple weekly calendar for the Appointments screen's "Tüm Randevular"
/// (All Appointments) tab — replaces the separate "Yaklaşan"/"Geçmiş"
/// tabs. Dates run horizontally (the week containing today), hours run
/// vertically on the left, and appointments are small colored blocks
/// showing only the service name — tapping one opens the existing
/// MechanicAppointmentDetailsPage; no details are shown inline. Dummy data
/// only (see data/calendar_appointment.dart) — no Firestore wired up yet.
class AppointmentCalendarView extends StatefulWidget {
  const AppointmentCalendarView({super.key, required this.selectedDate, required this.appointments, this.onSlotSelected});

  /// Which day is "active" — determines which week is shown (the Mon–Sun
  /// week containing this date) and which day header is highlighted.
  /// Defaults to today from the caller; updates when a date is picked via
  /// the Appointments screen's calendar icon.
  final DateTime selectedDate;

  /// The full schedule to render, owned by the caller
  /// (MechanicAppointmentsScreen) so that accepting a pending request can
  /// add to it.
  final List<Appointment> appointments;

  /// When non-null, every empty (unoccupied) hour cell becomes tappable —
  /// used by "Başka Saat Öner" to let the mechanic pick an alternative
  /// time directly on this same calendar. Null (the default) reproduces
  /// the original "Tüm Randevular" tab exactly: no empty-cell taps, and
  /// days with zero appointments still show the empty-state message
  /// instead of a bare grid.
  final ValueChanged<DateTime>? onSlotSelected;

  @override
  State<AppointmentCalendarView> createState() => _AppointmentCalendarViewState();
}

class _AppointmentCalendarViewState extends State<AppointmentCalendarView> {
  static const _startHour = 9;
  static const _endHour = 19;
  static const _hourHeight = 56.0;
  static const _hourColumnWidth = 44.0;
  static const _dayColumnWidth = 104.0;

  // Only meaningful in slot-selection mode (widget.onSlotSelected != null)
  // — how many weeks forward from today the "Başka Saat Öner" strip's
  // left/right arrows have paged. 0 = starts today; never negative, so the
  // strip can never page back before today.
  var _weekOffsetFromToday = 0;

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  List<DateTime> _weekDates() {
    // "Başka Saat Öner" (onSlotSelected != null) must never offer a past
    // date to suggest to the customer, so its strip starts at today (plus
    // _weekOffsetFromToday full weeks) and runs forward — not the Mon–Sun
    // calendar week used by the normal "Tüm Randevular" view below.
    if (widget.onSlotSelected != null) {
      final today = _dateOnly(DateTime.now());
      final start = today.add(Duration(days: _weekOffsetFromToday * 7));
      return List.generate(7, (i) => start.add(Duration(days: i)));
    }
    final selected = _dateOnly(widget.selectedDate);
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  void _goToPreviousWeek() {
    if (_weekOffsetFromToday <= 0) return;
    setState(() => _weekOffsetFromToday--);
  }

  void _goToNextWeek() {
    setState(() => _weekOffsetFromToday++);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _dateOnly(widget.selectedDate);
    final weekDates = _weekDates();
    final hourCount = _endHour - _startHour;
    final selectedDayHasAppointments = widget.appointments.any((a) => _dateOnly(a.start) == selected);
    // In slot-selection mode every hour is potentially selectable, even on
    // an otherwise-empty day, so the grid must render instead of falling
    // back to the "no appointments" empty state.
    final showGrid = selectedDayHasAppointments || widget.onSlotSelected != null;
    final isSlotSelectionMode = widget.onSlotSelected != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _hourColumnWidth,
            child: Column(
              children: [
                const SizedBox(height: _DayHeaderCell.height),
                for (var hour = _startHour; hour < _endHour; hour++)
                  SizedBox(
                    height: _hourHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: showGrid
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Outer margin + gap to the strip are equal (16px)
                      // on both sides, so the arrows sit outside the strip
                      // — never overlapping the first/last date and never
                      // touching the screen edge — and stay symmetrical.
                      if (isSlotSelectionMode) ...[
                        const SizedBox(width: 16),
                        SizedBox(
                          height: _DayHeaderCell.height,
                          child: Center(
                            child: _WeekNavButton(
                              icon: Icons.chevron_left,
                              onPressed: _weekOffsetFromToday > 0 ? _goToPreviousWeek : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final date in weekDates)
                                SizedBox(
                                  width: _dayColumnWidth,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _DayHeaderCell(date: date, isSelected: date == selected),
                                      SizedBox(
                                        // +1: the inner Column below sums to
                                        // exactly hourCount * _hourHeight with
                                        // zero slack, which is a zero-margin fit
                                        // prone to a sub-pixel RenderFlex
                                        // overflow. This buffer pixel is not
                                        // visible.
                                        height: hourCount * _hourHeight + 1,
                                        child: Stack(
                                          children: [
                                            Column(
                                              children: [
                                                for (var hour = _startHour; hour < _endHour; hour++)
                                                  Container(
                                                    height: _hourHeight,
                                                    decoration: const BoxDecoration(
                                                      border: Border(top: BorderSide(color: AppColors.divider)),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            for (final appointment in widget.appointments)
                                              if (_dateOnly(appointment.start) == date)
                                                _positionedBlock(appointment),
                                            if (isSlotSelectionMode)
                                              for (var hour = _startHour; hour < _endHour; hour++)
                                                if (!_isHourOccupied(date, hour))
                                                  _positionedSlotTap(date, hour),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (isSlotSelectionMode) ...[
                        const SizedBox(width: 16),
                        SizedBox(
                          height: _DayHeaderCell.height,
                          child: Center(
                            child: _WeekNavButton(icon: Icons.chevron_right, onPressed: _goToNextWeek),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final date in weekDates)
                              SizedBox(
                                width: _dayColumnWidth,
                                child: _DayHeaderCell(date: date, isSelected: date == selected),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: hourCount * _hourHeight,
                        child: const _EmptyScheduleState(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _positionedBlock(Appointment appointment) {
    final minutesFromStart = (appointment.start.hour - _startHour) * 60 + appointment.start.minute;
    final top = (minutesFromStart / 60) * _hourHeight;
    final height = (appointment.estimatedDuration.inMinutes / 60) * _hourHeight;
    return Positioned(
      top: top,
      left: 2,
      right: 2,
      // Each block must fit three fixed-size, readable lines
      // (service/vehicle/time) regardless of the appointment's actual
      // duration — see _AppointmentBlock for the exact line-height budget
      // this minimum is sized against. Also guards against a degenerate
      // (very short or zero) duration ever producing a negative height,
      // which Positioned cannot lay out.
      height: height - 2 < 58 ? 58 : height - 2,
      // In slot-selection mode (onSlotSelected != null), existing
      // appointments stay visible but aren't navigable — only empty slots
      // are selectable.
      child: _AppointmentBlock(appointment: appointment, tappable: widget.onSlotSelected == null),
    );
  }

  bool _isHourOccupied(DateTime date, int hour) {
    final slotStart = DateTime(date.year, date.month, date.day, hour);
    final slotEnd = slotStart.add(const Duration(hours: 1));
    return widget.appointments.any((appointment) {
      if (appointment.status == AppointmentStatus.cancelled) return false;
      final appointmentEnd = appointment.start.add(appointment.estimatedDuration);
      return appointment.start.isBefore(slotEnd) && appointmentEnd.isAfter(slotStart);
    });
  }

  Widget _positionedSlotTap(DateTime date, int hour) {
    return Positioned(
      top: (hour - _startHour) * _hourHeight,
      left: 0,
      right: 0,
      height: _hourHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onSlotSelected!(DateTime(date.year, date.month, date.day, hour)),
        ),
      ),
    );
  }
}

/// Circular week-navigation arrow for the "Başka Saat Öner" date strip —
/// white 40x40 circle with a light border and a subtle shadow, overlaid
/// right on the strip's own edge (see the Positioned usage above) rather
/// than placed at the screen edge. Turns solid turquoise with a white icon
/// while hovered/pressed; disabled (at the "today" boundary) just dims the
/// icon.
class _WeekNavButton extends StatefulWidget {
  const _WeekNavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_WeekNavButton> createState() => _WeekNavButtonState();
}

class _WeekNavButtonState extends State<_WeekNavButton> {
  static const _iconColor = Color(0xFF4B5563);
  static const _borderColor = Color(0xFFD1D5DB);

  var _isActive = false;

  void _setActive(bool value) {
    if (_isActive == value) return;
    setState(() => _isActive = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final showAccent = enabled && _isActive;

    return MouseRegion(
      onEnter: enabled ? (_) => _setActive(true) : null,
      onExit: enabled ? (_) => _setActive(false) : null,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _setActive(true) : null,
        onTapUp: enabled ? (_) => _setActive(false) : null,
        onTapCancel: enabled ? () => _setActive(false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: showAccent ? AppColors.turquoise : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: showAccent ? AppColors.turquoise : _borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 20,
              color: !enabled
                  ? _iconColor.withValues(alpha: 0.35)
                  : showAccent
                  ? Colors.white
                  : _iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the hourly grid when the selected day has zero
/// appointments — the week's day headers stay visible above this so the
/// user can still see/pick another date.
class _EmptyScheduleState extends StatelessWidget {
  const _EmptyScheduleState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Bu gün için randevu yok',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Başka bir tarih seçebilirsiniz.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Day-column header — weekday abbreviation + day number, highlighted when
/// it's the selected day (defaults to today; updates when a date is picked
/// via the Appointments screen's calendar icon).
class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({required this.date, required this.isSelected});

  final DateTime date;
  final bool isSelected;

  static const height = 48.0;
  static const _weekdayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const _monthLabels = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  @override
  Widget build(BuildContext context) {
    // A fixed-height SizedBox would throw a RenderFlex overflow if this
    // Column's content ever needs more vertical room than `height` — e.g.
    // under larger accessibility text scaling. ConstrainedBox with only a
    // minHeight keeps the same visual size in the normal case (content
    // already fits comfortably within `height`) but lets the column grow
    // instead of erroring if it doesn't.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: height),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _weekdayLabels[date.weekday - 1],
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.turquoise : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${date.day.toString().padLeft(2, '0')} ${_monthLabels[date.month - 1]}',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status → thin left-bar color, per the calendar's own color key (distinct
/// from AppointmentStatusPresentation's colors, which belong to the older,
/// currently-unused AppointmentCard).
extension _StatusBarColor on AppointmentStatus {
  Color get barColor => switch (this) {
    AppointmentStatus.accepted => Colors.green.shade600,
    AppointmentStatus.pending => Colors.yellow.shade800,
    AppointmentStatus.inProgress => Colors.blue.shade400,
    AppointmentStatus.completed => Colors.blue.shade600,
    AppointmentStatus.cancelled => AppColors.emergency,
    // Never actually rendered on the calendar — declined "appointments"
    // are filtered out before reaching _appointments (see
    // MechanicAppointmentsScreen._loadAppointments) — but the switch must
    // stay exhaustive.
    AppointmentStatus.declined => AppColors.emergency,
  };
}

/// A single appointment block: service name, vehicle model, and time, with
/// a thin status-colored bar on the left. Tapping opens the existing
/// MechanicAppointmentDetailsPage; nothing else is shown inline. When
/// [tappable] is false (slot-selection mode), the block stays visible but
/// doesn't navigate anywhere.
class _AppointmentBlock extends StatelessWidget {
  const _AppointmentBlock({required this.appointment, required this.tappable});

  final Appointment appointment;
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    final barColor = appointment.status.barColor;
    final time =
        '${appointment.start.hour.toString().padLeft(2, '0')}:${appointment.start.minute.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: tappable
            ? () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MechanicAppointmentDetailsPage(appointment: appointment)),
              )
            : null,
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          alignment: Alignment.topLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
              Expanded(
                // No FittedBox/shrink-to-fit here on purpose: each Text
                // below has an explicit `height` line-height multiplier,
                // so its layout size is deterministic (fontSize × height),
                // not dependent on the font's own metrics. _positionedBlock
                // gives every block at least enough room for this exact
                // budget (~15 + ~14.7 + ~14.7 + padding ≈ 52px, with a
                // 58px floor), so these three lines can never overflow.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.serviceType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${appointment.vehicleBrand} ${appointment.vehicleModel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.25, color: AppColors.textSecondary),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Color(0xFF616161)),
                        const SizedBox(width: 2),
                        Text(
                          time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
