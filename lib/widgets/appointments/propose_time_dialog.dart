import 'package:flutter/material.dart';

/// Native Material date + time pickers, chained into one real (date, time)
/// pick — shared by both sides' "propose a new time" actions (the
/// customer's counter-proposal, the mechanic's initial/counter proposal)
/// so there's one picker implementation, not two. Returns null if the user
/// cancels either step.
Future<(DateTime, TimeOfDay)?> pickProposedDateTime(
  BuildContext context, {
  DateTime? initialDate,
  TimeOfDay? initialTime,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // Direct text entry, not the calendar grid/dial — faster for proposing a
  // specific already-known date/time than paging through a calendar.
  final date = await showDatePicker(
    context: context,
    initialDate: initialDate != null && !initialDate.isBefore(today) ? initialDate : today,
    firstDate: today,
    lastDate: today.add(const Duration(days: 365)),
    initialEntryMode: DatePickerEntryMode.input,
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: initialTime ?? const TimeOfDay(hour: 9, minute: 0),
    initialEntryMode: TimePickerEntryMode.input,
  );
  if (time == null) return null;

  return (date, time);
}
