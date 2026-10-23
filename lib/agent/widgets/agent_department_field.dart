import 'package:flutter/material.dart';

import '../../model.dart';

/// Legacy and canonical Firestore documents can describe the same department.
class AgentDepartmentField extends StatelessWidget {
  const AgentDepartmentField({
    super.key,
    required this.departments,
    required this.departmentId,
    required this.onChanged,
    required this.onSaved,
  });

  final Iterable<Department> departments;
  final String? departmentId;
  final ValueChanged<Department> onChanged;
  final ValueChanged<Department> onSaved;

  @override
  Widget build(BuildContext context) {
    final byId = <String, Department>{};
    for (final department in departments) {
      final id = normalizeDepartmentId(department.id);
      if (id.isEmpty) continue;
      // Prefer the canonical document, regardless of snapshot ordering.
      if (!byId.containsKey(id) || department.documentId == id) {
        byId[id] = department;
      }
    }
    final id = normalizeDepartmentId(departmentId);
    final selectedId = byId.containsKey(id) ? id : null;

    return DropdownButtonFormField<String>(
      // Reconcile the form state if a snapshot removes the current option.
      key: ValueKey(selectedId),
      initialValue: selectedId,
      hint: const Text('Département'),
      decoration: const InputDecoration(
        hintText: 'Département',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.apartment),
      ),
      isExpanded: true,
      validator: (value) =>
          byId.containsKey(value) ? null : 'Département obligatoire',
      items: byId.entries
          .map((entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value.label),
              ))
          .toList(),
      onChanged: (value) {
        final department = byId[value];
        if (department != null) onChanged(department);
      },
      onSaved: (value) {
        final department = byId[value];
        if (department != null) onSaved(department);
      },
    );
  }
}
