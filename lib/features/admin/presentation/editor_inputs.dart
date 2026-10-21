import 'package:flutter/material.dart';

class EditorInputs {
  EditorInputs(this.values, this.onChanged);
  final Map<String, dynamic> values;
  final VoidCallback onChanged;
  Widget text(
    String key,
    String label, {
    bool optional = false,
    bool number = false,
    int? max,
  }) => TextFormField(
    initialValue: values[key]?.toString() ?? '',
    decoration: InputDecoration(labelText: label),
    keyboardType: number ? TextInputType.number : TextInputType.text,
    validator: (value) {
      if (optional && (value == null || value.trim().isEmpty)) return null;
      if (value == null || value.trim().isEmpty) return 'Enter $label';
      if (number &&
          (int.tryParse(value) == null ||
              int.parse(value) < (key == 'jerseyNo' ? 0 : 1) ||
              int.parse(value) > (max ?? 999))) {
        return 'Enter a valid number';
      }
      if (key == 'logoUrl' &&
          value.isNotEmpty &&
          !(Uri.tryParse(value)?.isScheme('https') ?? false)) {
        return 'Use an HTTPS image URL';
      }
      return null;
    },
    onSaved: (value) =>
        values[key] = number ? int.parse(value!) : value!.trim(),
  );
  Widget select(
    String key,
    String label,
    Map<String, String> options, {
    bool optional = false,
  }) {
    final current = options.containsKey(values[key])
        ? values[key] as String?
        : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('$key/${values[key]}/${options.keys.join()}'),
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      validator: (value) => !optional && value == null ? 'Select $label' : null,
      onChanged: (value) {
        values[key] = value;
        if (key == 'tournamentId') {
          values.remove('teamAId');
          values.remove('teamBId');
          values.remove('tossWinner');
        }
        if (key == 'teamAId' || key == 'teamBId') values.remove('tossWinner');
        onChanged();
      },
    );
  }
}
