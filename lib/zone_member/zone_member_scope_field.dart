import 'package:flutter/material.dart';

import '../model.dart';

class ZoneMemberScopeField extends StatelessWidget {
  const ZoneMemberScopeField({
    super.key,
    required this.departmentId,
    required this.scope,
    required this.onChanged,
  });

  final String? departmentId;
  final String scope;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSecurity = normalizeDepartmentId(departmentId) == 'security';
    return DropdownButtonFormField<String>(
      key: ValueKey('$departmentId:$scope'),
      initialValue: scope,
      decoration: const InputDecoration(
        labelText: 'Périmètre des sites',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.public),
      ),
      items: [
        const DropdownMenuItem(
          value: ZoneMemberScope.assigned,
          child: Text('Zone assignée'),
        ),
        // Keep malformed existing assignments visible so validation can explain
        // the problem without silently granting or downgrading access.
        if (isSecurity || scope == ZoneMemberScope.global)
          DropdownMenuItem(
            value: ZoneMemberScope.global,
            enabled: isSecurity,
            child: const Text('Toutes les zones · Sécurité'),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      validator: (value) => value == ZoneMemberScope.global && !isSecurity
          ? 'Le périmètre global est réservé à la Sécurité'
          : null,
    );
  }
}
