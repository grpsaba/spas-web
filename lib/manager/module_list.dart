import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/profil.dart';

class ModuleList extends StatefulWidget {
  ModuleList({super.key, required this.profil});

  Profil profil;

  @override
  State<ModuleList> createState() => _ModuleListState();
}

class _ModuleListState extends State<ModuleList> {
  List<Module> _completeModules(List<Module> existingModules) {
    return ModuleName.values.map((moduleName) {
      return existingModules.firstWhere(
        (module) => module.moduleName == moduleName,
        orElse: () => Module(
          moduleName: moduleName,
          add: false,
          delete: false,
          validation: false,
          view: false,
          print: false,
          generBadge: false,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: FutureBuilder(
        future: ProfilService().one(widget.profil.name),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Loading(size: 48, inline: true),
            );
          }

          final profil = snapshot.data;
          if (profil == null) {
            return const Center(
              child: Text(
                'Profil introuvable',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            );
          }

          final modules = _completeModules(profil.modules);
          profil.modules = modules;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PermissionHeader(
                profileName: profil.name,
                moduleCount: modules.length,
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: modules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final module = modules[index];

                    return _ModulePermissionRow(
                      module: module,
                      onChanged: () {
                        ProfilService().update(profil).then((_) {
                          setState(() {});
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PermissionHeader extends StatelessWidget {
  const _PermissionHeader({
    required this.profileName,
    required this.moduleCount,
  });

  final String profileName;
  final int moduleCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              HugeIcons.strokeRoundedShieldUser,
              color: Theme.of(context).primaryColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$moduleCount modules de permission',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModulePermissionRow extends StatelessWidget {
  const _ModulePermissionRow({
    required this.module,
    required this.onChanged,
  });

  final Module module;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(
              _moduleIcon(module.moduleName),
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 210,
            child: Text(
              _moduleLabel(module.moduleName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PermissionToggle(
                  label: 'Voir',
                  value: module.view,
                  onChanged: (value) {
                    module.view = value;
                    onChanged();
                  },
                ),
                _PermissionToggle(
                  label: 'Ajouter',
                  value: module.add,
                  onChanged: (value) {
                    module.add = value;
                    onChanged();
                  },
                ),
                _PermissionToggle(
                  label: 'Valider',
                  value: module.validation,
                  onChanged: (value) {
                    module.validation = value;
                    onChanged();
                  },
                ),
                _PermissionToggle(
                  label: 'Supprimer',
                  value: module.delete,
                  onChanged: (value) {
                    module.delete = value;
                    onChanged();
                  },
                ),
                _PermissionToggle(
                  label: 'Exporter',
                  value: module.print,
                  onChanged: (value) {
                    module.print = value;
                    onChanged();
                  },
                ),
                _PermissionToggle(
                  label: 'QR',
                  value: module.generBadge,
                  onChanged: (value) {
                    module.generBadge = value;
                    onChanged();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionToggle extends StatelessWidget {
  const _PermissionToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? color.withOpacity(0.35) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value
                  ? HugeIcons.strokeRoundedCheckmarkCircle01
                  : HugeIcons.strokeRoundedCancelCircle,
              size: 15,
              color: value ? color : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? color : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _moduleIcon(ModuleName moduleName) {
  switch (moduleName) {
    case ModuleName.TABLEAU_DE_BORD:
      return HugeIcons.strokeRoundedDashboardSquare01;
    case ModuleName.AGENT:
      return HugeIcons.strokeRoundedUserGroup;
    case ModuleName.SUPERVISEUR:
      return HugeIcons.strokeRoundedManager;
    case ModuleName.SITE:
      return HugeIcons.strokeRoundedBuilding03;
    case ModuleName.TOOL:
      return HugeIcons.strokeRoundedTools;
    case ModuleName.NOTE:
      return HugeIcons.strokeRoundedNoteEdit;
    case ModuleName.MANAGER:
      return HugeIcons.strokeRoundedComputerUser;
    case ModuleName.CATEGORIE_TOOL:
      return HugeIcons.strokeRoundedPackageSearch;
    case ModuleName.DEPARTMENT:
      return HugeIcons.strokeRoundedOffice;
    case ModuleName.AGENT_TYPE:
      return HugeIcons.strokeRoundedUserIdVerification;
    case ModuleName.ZONE:
      return HugeIcons.strokeRoundedMapsCircle01;
    case ModuleName.ZONE_MEMBER:
      return HugeIcons.strokeRoundedLocationUser01;
    case ModuleName.POINTAGE_SITE:
      return HugeIcons.strokeRoundedCheckList;
    case ModuleName.POINTAGE_AGENT:
      return HugeIcons.strokeRoundedUserCheck01;
    case ModuleName.POINTAGE_RONDIER:
      return HugeIcons.strokeRoundedRoute03;
    case ModuleName.POINTAGE_TOOL:
      return HugeIcons.strokeRoundedTools;
    case ModuleName.POINTAGE_ZONE:
      return HugeIcons.strokeRoundedMapsLocation01;
    case ModuleName.ERROR_LOG:
      return HugeIcons.strokeRoundedAlertCircle;
    case ModuleName.MOBILE_CONFIG:
      return HugeIcons.strokeRoundedMobileSecurity;
  }
}

String _moduleLabel(ModuleName moduleName) {
  switch (moduleName) {
    case ModuleName.TABLEAU_DE_BORD:
      return 'Tableau de bord';
    case ModuleName.AGENT:
      return 'Agents';
    case ModuleName.SUPERVISEUR:
      return 'Superviseurs';
    case ModuleName.SITE:
      return 'Sites';
    case ModuleName.TOOL:
      return 'Materiaux';
    case ModuleName.NOTE:
      return 'Notes';
    case ModuleName.MANAGER:
      return 'PC';
    case ModuleName.CATEGORIE_TOOL:
      return 'Categories materiel';
    case ModuleName.DEPARTMENT:
      return 'Departements';
    case ModuleName.AGENT_TYPE:
      return 'Types agents';
    case ModuleName.ZONE:
      return 'Zones';
    case ModuleName.ZONE_MEMBER:
      return 'Chefs de zone';
    case ModuleName.POINTAGE_SITE:
      return 'Pointage sites';
    case ModuleName.POINTAGE_AGENT:
      return 'Pointage agents';
    case ModuleName.POINTAGE_RONDIER:
      return 'Pointage rondiers';
    case ModuleName.POINTAGE_TOOL:
      return 'Pointage materiaux';
    case ModuleName.POINTAGE_ZONE:
      return 'Pointage zones';
    case ModuleName.ERROR_LOG:
      return 'Journal erreurs';
    case ModuleName.MOBILE_CONFIG:
      return 'Configuration mobile';
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
