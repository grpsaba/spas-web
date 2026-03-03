import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/search_textField.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../rowperPageWidget.dart';
import '../services/agent.dart';
import '../services/loading.dart';
import '../services/site.dart';
import '../services/supervisor.dart';

class SupervisorList extends StatefulWidget {
  const SupervisorList({
    super.key,
  });

  @override
  State<SupervisorList> createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SupervisorList> {
  final SupervisorService _service = SupervisorService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  int rowParPage = 0;
  int defauldRowParPage = 10;

  @override
  void initState() {
    super.initState();
    rowParPage = defauldRowParPage;
    _texController.text = defauldRowParPage.toString();
  }

  @override
  void dispose() {
    _texController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAddSupervisor = AuthService.currentManager!.profil!
        .getModule(ModuleName.SUPERVISEUR)!
        .add;

    return PageModel(
      pageIndex: 4,
      title: "Gestion des superviseurs",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder(
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
                    .toList() ??
                [];
            final data = docs
                .map((e) => Supervisor.fromJson(e as Map<String, dynamic>))
                .toList();

            final total = data.length;
            final active = data.where((s) => s.actif == true).length;
            final inactive = total - active;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCard(context, total, active, inactive),
                const SizedBox(height: 12),
                _buildToolbarCard(context, canAddSupervisor),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(28),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      cardTheme: Theme.of(context).cardTheme.copyWith(
                            margin: EdgeInsets.zero,
                            color: Colors.white,
                          ),
                    ),
                    child: PaginatedDataTable(
                      header: _buildTableHeader(context),
                      actions: [
                        RowPerPageWidget(
                          controller: _texController,
                          incremente: () {
                            setState(() {
                              rowParPage += 1;
                              _texController.text = rowParPage.toString();
                            });
                          },
                          decremente: () {
                            setState(() {
                              rowParPage = rowParPage <= defauldRowParPage
                                  ? defauldRowParPage
                                  : rowParPage - 1;
                              _texController.text = rowParPage.toString();
                            });
                          },
                        ),
                      ],
                      rowsPerPage: rowParPage,
                      showFirstLastButtons: true,
                      showCheckboxColumn: false,
                      horizontalMargin: 16,
                      columnSpacing: 18,
                      headingRowHeight: 54,
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 72,
                      columns: [
                        DataColumn(label: _buildColumnLabel(context, "Prénom")),
                        DataColumn(label: _buildColumnLabel(context, "Nom")),
                        DataColumn(label: _buildColumnLabel(context, "Contact")),
                        DataColumn(label: _buildColumnLabel(context, "Email")),
                        DataColumn(
                          label: _buildColumnLabel(context, "Sites"),
                          numeric: true,
                        ),
                        DataColumn(
                          label: _buildColumnLabel(context, "Agents"),
                          numeric: true,
                        ),
                        DataColumn(label: _buildColumnLabel(context, "Position")),
                        DataColumn(label: _buildColumnLabel(context, "Statut")),
                        DataColumn(label: _buildColumnLabel(context, "Action")),
                      ],
                      source: _DataSource(
                        context: context,
                        keyword: _keyword,
                        data: data,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.groups_outlined, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          "Liste des superviseurs",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildToolbarCard(BuildContext context, bool canAddSupervisor) {
    final searchWidth = MediaQuery.of(context).size.width > 1200 ? 320.0 : 250.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor.withAlpha(28)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: searchWidth,
            child: SearchTextField(
              onSearch: (value) {
                setState(() {
                  _keyword = value;
                });
              },
              onPress: () {},
            ),
          ),
          if (canAddSupervisor)
            _buildToolbarButton(
              label: 'Ajouter',
              icon: Icons.add,
              color: Colors.green,
              onPressed: () {
                final supervisor = Supervisor(
                  code: '',
                  firstName: '',
                  lastName: '',
                  phone: '',
                  email: '',
                  tracking: false,
                  UID: '',
                  token: '',
                  latlng: null,
                  actif: false,
                  department: null,
                );
                context.go('/superviseurs/add', extra: supervisor);
              },
            ),
          _buildToolbarButton(
            label: 'Positions',
            icon: Icons.location_on,
            color: Colors.redAccent,
            onPressed: () {
              context.go('/superviseurs/locationtracker');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, int total, int active, int inactive) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withAlpha(16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withAlpha(36)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildStatPill('Total', total, Colors.blue),
          _buildStatPill('Actifs', active, Colors.green),
          _buildStatPill('Inactifs', inactive, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildColumnLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

class _DataSource extends DataTableSource {
  final List<Supervisor> data;
  final String keyword;
  final BuildContext context;

  _DataSource({
    required this.context,
    required this.data,
    required this.keyword,
  });

  List<Supervisor> get _visibleData {
    final query = keyword.trim().toLowerCase();
    return data.where((supervisor) {
      if (query.isEmpty) return true;
      return supervisor.firstName.toLowerCase().contains(query) ||
          supervisor.lastName.toLowerCase().contains(query) ||
          supervisor.code.toLowerCase().contains(query) ||
          supervisor.phone.toLowerCase().contains(query);
    }).toList();
  }

  @override
  DataRow? getRow(int index) {
    final visibleData = _visibleData;

    if (index >= visibleData.length) {
      return const DataRow(cells: [
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
        DataCell(Text("")),
      ]);
    }

    final supervisor = visibleData[index];

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Theme.of(context).primaryColor.withAlpha(18);
        }
        return index.isEven ? Colors.white : const Color(0xFFF9FAFC);
      }),
      onSelectChanged: (_) {
        context.go('/superviseurs/detail', extra: supervisor);
      },
      cells: [
        DataCell(
          Text(
            supervisor.firstName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () {
            context.go('/superviseurs/detail', extra: supervisor);
          },
        ),
        DataCell(
          Text(
            supervisor.lastName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () {
            context.go('/superviseurs/detail', extra: supervisor);
          },
        ),
        DataCell(Text(supervisor.phone)),
        DataCell(Text(supervisor.email)),
        DataCell(nbSite(supervisor)),
        DataCell(nbAgent(supervisor)),
        DataCell(
          Text(
            "${supervisor.latlng?.lat ?? ""} ; ${supervisor.latlng?.lng ?? ""}",
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          SuperviseurStatut(
            superviseur: supervisor,
          ),
        ),
        DataCell(
          Row(
            children: [
              if (supervisor.actif == true)
                Tooltip(
                  message: 'Modifier',
                  child: IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      context.go('/superviseurs/add', extra: supervisor);
                    },
                  ),
                ),
              Tooltip(
                message: 'Historique position',
                child: IconButton(
                  icon: const Icon(
                    Icons.location_history,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    context.go('/superviseurs/location', extra: supervisor);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _visibleData.length;

  @override
  int get selectedRowCount => 0;

  Widget nbAgent(Supervisor supervisor) {
    return FutureBuilder<List<Agent>>(
      future: AgentService().allBySupervisor(supervisor.UID),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return _metricBadge(
          value: snapshot.data!.length.toString(),
          color: Colors.indigo,
        );
      },
    );
  }

  Widget nbSite(Supervisor supervisor) {
    return FutureBuilder<List<Site>>(
      future: SiteService().allBySupervisor(supervisor),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        return _metricBadge(
          value: snapshot.data!.length.toString(),
          color: Colors.teal,
        );
      },
    );
  }

  Widget _metricBadge({required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SuperviseurStatut extends StatefulWidget {
  const SuperviseurStatut({
    super.key,
    required this.superviseur,
  });
  final Supervisor superviseur;

  @override
  State<SuperviseurStatut> createState() => _SuperviseurStatutState();
}

class _SuperviseurStatutState extends State<SuperviseurStatut> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final canUpdate = AuthService.currentManager!.profil!
        .getModule(ModuleName.SUPERVISEUR)!
        .validation;
    final isActive = widget.superviseur.actif == true;

    if (_updating) {
      return Loading(size: 28, inline: false);
    }

    return InkWell(
      onTap: canUpdate ? actifInactifAgent : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isActive ? 'Actif' : 'Inactif',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void actifInactifAgent() {
    setState(() {
      _updating = true;
    });
    widget.superviseur.actif = widget.superviseur.actif == true ? false : true;
    SupervisorService().update(widget.superviseur).then((value) {
      setState(() {
        _updating = false;
      });
    }).onError((error, stackTrace) {
      setState(() {
        _updating = false;
      });
    });
  }
}
