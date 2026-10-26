import 'package:flutter/material.dart';

import '../model.dart';
import 'zone_member_scope_field.dart';

/// Keeps the zone selector and its validation in sync with the site scope.
class ZoneMemberSiteScopeFields extends StatelessWidget {
  const ZoneMemberSiteScopeFields({
    super.key,
    required this.tenantId,
    required this.departmentId,
    required this.scope,
    required this.selectedZone,
    required this.zones,
    required this.onScopeChanged,
    required this.onZoneChanged,
  });

  final String? tenantId;
  final String? departmentId;
  final String scope;
  final Zone? selectedZone;
  final Stream<List<Zone>> zones;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<Zone?> onZoneChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Zone>>(
      stream: zones,
      builder: (context, snapshot) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ZoneMemberScopeField(
            departmentId: departmentId,
            scope: scope,
            onChanged: onScopeChanged,
          ),
          const SizedBox(height: 16),
          if (scope == ZoneMemberScope.global)
            const Text(
              'Accès aux sites Sécurité de toutes les zones du pays sélectionné. '
              'Aucune zone à choisir.',
            )
          else
            _buildZoneField(snapshot),
        ],
      ),
    );
  }

  Widget _buildZoneField(AsyncSnapshot<List<Zone>> snapshot) {
    final country = tenantId?.trim().toLowerCase();
    final options = (snapshot.data ?? <Zone>[])
        .where((zone) => zone.tenantId.trim().toLowerCase() == country)
        .toList();
    Zone? selected;
    for (final zone in options) {
      if (zone.codeZone == selectedZone?.codeZone &&
          zone.tenantId == selectedZone?.tenantId) {
        selected = zone;
        break;
      }
    }
    String? message;
    if (country == null || country.isEmpty) {
      message = 'Sélectionnez d’abord un pays.';
    } else if (snapshot.hasError) {
      message = 'Impossible de charger les zones. Rechargez la page.';
    } else if (!snapshot.hasData) {
      message = 'Chargement des zones…';
    } else if (options.isEmpty) {
      message = 'Aucune zone disponible pour ce pays.';
    }

    return DropdownButtonFormField<Zone>(
      key: ValueKey('zone:$country:${selected?.codeZone}:$message'),
      initialValue: message == null ? selected : null,
      isExpanded: true,
      hint: const Text('Choisir une zone'),
      disabledHint: const Text('Zone indisponible'),
      decoration: InputDecoration(
        labelText: 'Zone',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.location_city),
        helperText: message,
        helperMaxLines: 3,
      ),
      items: options
          .map((zone) => DropdownMenuItem(
                value: zone,
                child: Text(zone.name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: message == null ? onZoneChanged : null,
      validator: (value) => message != null || value == null
          ? 'Sélectionnez une zone disponible pour ce pays.'
          : null,
    );
  }
}
