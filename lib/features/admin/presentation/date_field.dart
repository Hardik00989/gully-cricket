import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.includeTime = false,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool includeTime;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    icon: const Icon(Icons.calendar_today_outlined),
    label: Text(
      '$label: ${DateFormat(includeTime ? 'd MMM y, h:mm a' : 'd MMM y').format(value)}',
    ),
    onPressed: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date == null || !context.mounted) return;
      if (!includeTime) {
        onChanged(date);
        return;
      }
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(value),
      );
      if (time != null) {
        onChanged(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      }
    },
  );
}
