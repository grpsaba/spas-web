import 'package:flutter/material.dart';

class BackgroundTrackingControl extends StatelessWidget {
  const BackgroundTrackingControl({
    super.key,
    required this.value,
    required this.enabled,
    required this.saving,
    required this.onChanged,
    this.error,
  });

  final bool value;
  final bool enabled;
  final bool saving;
  final ValueChanged<bool> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                    'Autoriser le suivi GPS continu — tous les pays'),
                subtitle: Text(value
                    ? 'Autorisé pour les rôles en mode Géo.'
                    : 'Désactivé pour tous les pays.'),
                value: value,
                onChanged: enabled && !saving ? onChanged : null,
                secondary: saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded),
              ),
              const Text(
                  'Chaque pays conserve ses modes indépendants pour les superviseurs et les chefs de zone. Couper ce suivi n’empêche pas une mesure GPS au moment du pointage.'),
              const SizedBox(height: 8),
              const Text(
                  'Ce réglage autorise le suivi ; son fonctionnement réel dépend du téléphone, de ses autorisations et de la version mobile installée.',
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
              if (!enabled && error == null)
                const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                        'Modification réservée aux profils autorisés à gérer tous les pays.')),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error!,
                        style: const TextStyle(color: Colors.red))),
            ],
          ),
        ),
      );
}
