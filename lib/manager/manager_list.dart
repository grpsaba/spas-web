import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/loading.dart';
import '../services/manager.dart';

class ManagerList extends StatefulWidget {
  ManagerList({super.key});

  @override
  State<ManagerList> createState() => _ManagerListState();
}

class _ManagerListState extends State<ManagerList> {
  final ManagerService _service = ManagerService();
  final TextEditingController _rowsController = TextEditingController();
  String _keyword = "";
  int rowParPage = 10;
  final int defauldRowParPage = 10;

  @override
  void initState() {
    super.initState();
    _rowsController.text = defauldRowParPage.toString();
  }

  @override
  void dispose() {
    _rowsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _service.all(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Loading(
              size: 64,
              inline: true,
            ),
          );
        }

        final docs = snapshot.data?.docs
            .map((e) => jsonDecode(jsonEncode(e.data())))
            .toList();
        final managers = docs?.map((e) => Manager.fromJson(e)).toList() ??
            <Manager>[];
        managers.sort((a, b) {
          final lastNameCompare = a.lastName.compareTo(b.lastName);
          return lastNameCompare != 0
              ? lastNameCompare
              : a.firstName.compareTo(b.firstName);
        });

        final filteredManagers = _filterManagers(managers);
        final profileCount = managers
            .map((manager) => manager.profil?.name ?? '')
            .where((profile) => profile.isNotEmpty)
            .toSet()
            .length;
        final activeCount =
            managers.where((manager) => manager.actif == true).length;
        final inactiveCount = managers.length - activeCount;
        return Column(
          children: [
            _ManagerToolbar(
              total: managers.length,
              visible: filteredManagers.length,
              profileCount: profileCount,
              activeCount: activeCount,
              inactiveCount: inactiveCount,
              onSearch: (value) {
                setState(() {
                  _keyword = value;
                });
              },
              onAdd: AuthService.currentManager!.profil!
                      .getModule(ModuleName.MANAGER)!
                      .add
                  ? _goToAddManager
                  : null,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _ManagerTableCard(
                managers: filteredManagers,
                rowsPerPage: rowParPage,
                rowsController: _rowsController,
                onIncreaseRows: () {
                  setState(() {
                    rowParPage += 1;
                    _rowsController.text = rowParPage.toString();
                  });
                },
                onDecreaseRows: () {
                  setState(() {
                    rowParPage = rowParPage <= defauldRowParPage
                        ? defauldRowParPage
                        : rowParPage - 1;
                    _rowsController.text = rowParPage.toString();
                  });
                },
                onEdit: (manager) => context.go('/users/add', extra: manager),
                onToggleStatus: _toggleManagerStatus,
              ),
            ),
          ],
        );
      },
    );
  }

  List<Manager> _filterManagers(List<Manager> managers) {
    final keyword = _keyword.trim().toLowerCase();
    if (keyword.isEmpty) return managers;

    return managers.where((manager) {
      final values = [
        manager.firstName,
        manager.lastName,
        manager.email,
        manager.phone,
        manager.poste,
        manager.profil?.name ?? '',
        manager.actif ? 'actif' : 'inactif',
        manager.hasTenantId ? manager.tenantId : 'non affecte',
      ];
      return values.any((value) => value.toLowerCase().contains(keyword));
    }).toList();
  }

  void _goToAddManager() {
    final manager = Manager(
      poste: '',
      firstName: '',
      lastName: '',
      phone: '',
      email: '',
      profil: null,
      UID: '',
      token: '',
    );
    context.go('/users/add', extra: manager);
  }

  Future<void> _toggleManagerStatus(Manager manager) async {
    if (manager.UID == AuthService.currentManager?.UID) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de desactiver le compte connecte'),
        ),
      );
      return;
    }

    try {
      await _service.toggleStatus(manager);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action impossible: $error')),
      );
    }
  }
}

class _ManagerToolbar extends StatelessWidget {
  const _ManagerToolbar({
    required this.total,
    required this.visible,
    required this.profileCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.onSearch,
    required this.onAdd,
  });

  final int total;
  final int visible;
  final int profileCount;
  final int activeCount;
  final int inactiveCount;
  final ValueChanged<String> onSearch;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: HugeIcons.strokeRoundedUserGroup,
                label: 'Utilisateurs',
                value: total.toString(),
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                label: 'PC actifs',
                value: activeCount.toString(),
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: HugeIcons.strokeRoundedCancelCircle,
                label: 'PC inactifs',
                value: inactiveCount.toString(),
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: HugeIcons.strokeRoundedShieldUser,
                label: 'Profils',
                value: profileCount.toString(),
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SearchField(
                hintText: 'Rechercher un utilisateur',
                onChanged: onSearch,
              ),
            ),
            const SizedBox(width: 12),
            _CountPill(
              icon: HugeIcons.strokeRoundedFilter,
              label: '$visible affiches',
            ),
            const SizedBox(width: 12),
            if (onAdd != null)
              _PrimaryActionButton(
                tooltip: 'Ajouter un utilisateur',
                icon: HugeIcons.strokeRoundedUserAdd01,
                label: 'Ajouter',
                onPressed: onAdd!,
              ),
          ],
        ),
      ],
    );
  }
}

class _ManagerTableCard extends StatelessWidget {
  const _ManagerTableCard({
    required this.managers,
    required this.rowsPerPage,
    required this.rowsController,
    required this.onIncreaseRows,
    required this.onDecreaseRows,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final List<Manager> managers;
  final int rowsPerPage;
  final TextEditingController rowsController;
  final VoidCallback onIncreaseRows;
  final VoidCallback onDecreaseRows;
  final ValueChanged<Manager> onEdit;
  final Future<void> Function(Manager) onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = math.max(constraints.maxWidth, 1280.0);

            return SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: PaginatedDataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    horizontalMargin: 20,
                    columnSpacing: 34,
                    rowsPerPage: rowsPerPage,
                    showFirstLastButtons: true,
                    showEmptyRows: false,
                    header: _TableHeader(
                      icon: HugeIcons.strokeRoundedUserList,
                      title: 'Liste des utilisateurs',
                    ),
                    actions: [
                      RowPerPageWidget(
                        controller: rowsController,
                        incremente: onIncreaseRows,
                        decremente: onDecreaseRows,
                      ),
                    ],
                    columns: const [
                      DataColumn(label: Text('Utilisateur')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Telephone')),
                      DataColumn(label: Text('Poste')),
                      DataColumn(label: Text('Profil')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Pays')),
                      DataColumn(label: Text('')),
                    ],
                    source: _ManagerDataSource(
                      context: context,
                      data: managers,
                      onEdit: onEdit,
                      onToggleStatus: onToggleStatus,
                      managerLoged: AuthService.currentManager!,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ManagerDataSource extends DataTableSource {
  _ManagerDataSource({
    required this.context,
    required this.data,
    required this.onEdit,
    required this.onToggleStatus,
    required this.managerLoged,
  });

  final BuildContext context;
  final List<Manager> data;
  final ValueChanged<Manager> onEdit;
  final Future<void> Function(Manager) onToggleStatus;
  final Manager managerLoged;

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) {
      return null;
    }

    final manager = data[index];
    final module = managerLoged.profil!.getModule(ModuleName.MANAGER)!;
    final canEdit = module.add;
    final canToggle = module.validation && manager.UID != managerLoged.UID;
    final hasActions = canEdit || canToggle;

    return DataRow(
      cells: [
        DataCell(_UserIdentity(manager: manager)),
        DataCell(Text(manager.email)),
        DataCell(Text(manager.phone)),
        DataCell(Text(manager.poste)),
        DataCell(_SoftChip(
          label: manager.profil?.name ?? 'Aucun profil',
          color: manager.profil == null
              ? const Color(0xFFDC2626)
              : Theme.of(context).primaryColor,
        )),
        DataCell(_StatusChip(active: manager.actif)),
        DataCell(Text(
          manager.hasTenantId ? manager.tenantId.toUpperCase() : 'Non affecte',
        )),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: hasActions
                ? PopupMenuButton<String>(
                    tooltip: 'Actions',
                    icon: const Icon(
                      HugeIcons.strokeRoundedMoreVertical,
                      size: 20,
                    ),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        onEdit(manager);
                      } else if (value == 'toggle') {
                        await onToggleStatus(manager);
                      }
                    },
                    itemBuilder: (context) => [
                      if (canEdit)
                        const PopupMenuItem(
                          value: 'edit',
                          child: _MenuItemLabel(
                            icon: HugeIcons.strokeRoundedEdit02,
                            label: 'Modifier',
                          ),
                        ),
                      if (canToggle)
                        PopupMenuItem(
                          value: 'toggle',
                          child: _MenuItemLabel(
                            icon: manager.actif
                                ? HugeIcons.strokeRoundedCancelCircle
                                : HugeIcons.strokeRoundedCheckmarkCircle01,
                            label: manager.actif ? 'Desactiver' : 'Activer',
                            destructive: manager.actif,
                          ),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}

class _UserIdentity extends StatelessWidget {
  const _UserIdentity({required this.manager});

  final Manager manager;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(manager);

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            initials,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${manager.firstName} ${manager.lastName}'.trim(),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              manager.UID.isEmpty ? 'Nouveau compte' : manager.UID,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _initials(Manager manager) {
    final first = manager.firstName.trim();
    final last = manager.lastName.trim();
    final parts = [first, last].where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'PC';
    return parts
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        prefixIcon: const Icon(
          HugeIcons.strokeRoundedSearch01,
          size: 20,
          color: Color(0xFF64748B),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF059669) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active
                ? HugeIcons.strokeRoundedCheckmarkCircle01
                : HugeIcons.strokeRoundedCancelCircle,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Actif' : 'Inactif',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemLabel extends StatelessWidget {
  const _MenuItemLabel({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFDC2626) : const Color(0xFF334155);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
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
