import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/agent/providers/agent_list_provider.dart';
import 'package:spas_web/pointage_redesign/models/pointage_exception.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/error_display.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../pdf/api/pdf_api.dart';
import '../services/agent.dart';
import '../services/export.dart';
import '../services/loading.dart';

class AgentList extends StatelessWidget {
  const AgentList({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AgentListProvider>(
      create: (_) => AgentListProvider()..initialize(),
      child: const _AgentListView(),
    );
  }
}

class _AgentListView extends StatelessWidget {
  const _AgentListView();

  Module? get _agentModule =>
      AuthService.currentManager?.profil?.getModule(ModuleName.AGENT);

  bool get _canAdd => _agentModule?.add ?? false;
  bool get _canPrint => _agentModule?.print ?? false;
  bool get _canGenerateBadge => _agentModule?.generBadge ?? false;
  bool get _canValidate => _agentModule?.validation ?? false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentListProvider>(
      builder: (context, provider, _) {
        return PageModel(
          pageIndex: 3,
          title: 'Gestion des agents',
          child: RefreshIndicator(
            onRefresh: provider.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, provider),
                  const SizedBox(height: 20),
                  _buildFilterPanel(context, provider),
                  const SizedBox(height: 20),
                  _buildBody(context, provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AgentListProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Liste des agents',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF152033),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                provider.resultText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF697586),
                    ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (_canAdd)
                _HeaderActionButton(
                  label: 'Ajouter',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () => _onAddAgent(context),
                ),
              if (_canAdd)
                _HeaderActionButton(
                  label: 'Importer',
                  icon: Icons.upload_file_rounded,
                  onPressed: () => context.go('/agents/import'),
                  outlined: true,
                ),
              if (_canAdd)
                _HeaderActionButton(
                  label: 'Création bulk',
                  icon: Icons.groups_rounded,
                  onPressed: () => context.go('/agents/bulk-create'),
                  outlined: true,
                ),
              if (_canAdd)
                _HeaderActionButton(
                  label: 'Gestion groupée',
                  icon: Icons.playlist_add_check_circle_rounded,
                  onPressed: () => context.go('/agents/bulk-manage'),
                  outlined: true,
                ),
              if (_canGenerateBadge)
                _HeaderActionButton(
                  label: 'QR / Badge',
                  icon: Icons.badge_rounded,
                  onPressed: () => context.go(
                    '/agents/badges',
                    extra: provider.exportableAgents,
                  ),
                  outlined: true,
                ),
              if (_canPrint)
                _HeaderActionButton(
                  label: 'Imprimer',
                  icon: Icons.print_rounded,
                  onPressed: provider.exportableAgents.isEmpty
                      ? null
                      : () async {
                          final document = await AgentListToPDF.export(
                              provider.exportableAgents);
                          PdfApi.openFile(document);
                        },
                  outlined: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, AgentListProvider provider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF152033),
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: provider.searchController,
                  onChanged: provider.setSearchQuery,
                  decoration: InputDecoration(
                    hintText:
                        'Rechercher par code, nom, téléphone, site, type...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD0D7E2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD0D7E2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              _FilterDropdown<bool?>(
                label: 'Statut',
                value: provider.selectedActif,
                items: const [
                  DropdownMenuItem<bool?>(
                    value: null,
                    child: Text('Tous'),
                  ),
                  DropdownMenuItem<bool?>(
                    value: true,
                    child: Text('Actifs'),
                  ),
                  DropdownMenuItem<bool?>(
                    value: false,
                    child: Text('Inactifs'),
                  ),
                ],
                onChanged: provider.setStatus,
              ),
              _FilterDropdown<String>(
                label: 'Type',
                value: provider.selectedType,
                items: AgentListProvider.typeOptions
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: provider.setType,
              ),
              _FilterDropdown<String>(
                label: 'Département',
                value: provider.selectedDepartment,
                items: provider.departmentOptions
                    .map(
                      (department) => DropdownMenuItem<String>(
                        value: department,
                        child: Text(department),
                      ),
                    )
                    .toList(),
                onChanged: provider.isLoadingDepartments
                    ? null
                    : provider.setDepartment,
              ),
              OutlinedButton.icon(
                onPressed: provider.resetFilters,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Réinitialiser'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActiveFilterChip(
                  label: 'Statut : ${provider.selectedStatusLabel}'),
              _ActiveFilterChip(label: 'Type : ${provider.selectedType}'),
              _ActiveFilterChip(
                label: 'Département : ${provider.selectedDepartment}',
              ),
              if (provider.searchQuery.trim().isNotEmpty)
                _ActiveFilterChip(
                  label: 'Recherche : ${provider.searchQuery.trim()}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AgentListProvider provider) {
    if (provider.isInitialLoading && provider.agents.isEmpty) {
      return SizedBox(
        height: 320,
        child: Center(
          child: Loading(
            size: 60,
            inline: true,
          ),
        ),
      );
    }

    if (provider.errorMessage != null && provider.agents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ErrorDisplay(
          exception: PointageException.query(),
          customMessage: provider.errorMessage!,
          onRetry: provider.refresh,
        ),
      );
    }

    if (provider.errorMessage != null &&
        provider.agents.isEmpty &&
        provider.isRefreshing) {
      return _AgentListMessageCard(
        icon: Icons.error_outline_rounded,
        title: 'Erreur de chargement',
        subtitle: provider.errorMessage!,
        actionLabel: 'Réessayer',
        onPressed: provider.loadInitialData,
      );
    }

    if (provider.agents.isEmpty) {
      return _AgentListMessageCard(
        icon: Icons.people_outline_rounded,
        title: 'Aucun agent disponible',
        subtitle: 'Aucun agent n’a encore été récupéré.',
        actionLabel: 'Actualiser',
        onPressed: provider.loadInitialData,
      );
    }

    if (provider.filteredAgents.isEmpty) {
      return _AgentListMessageCard(
        icon: Icons.filter_alt_off_rounded,
        title: 'Aucun résultat',
        subtitle:
            'Aucun agent ne correspond aux filtres sélectionnés. Réinitialise les filtres pour revenir à la liste complète.',
        actionLabel: 'Réinitialiser',
        onPressed: provider.resetFilters,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.isRefreshing) ...[
          const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: 12),
        ],
        if (provider.errorMessage != null) ...[
          ErrorDisplay(
            exception: PointageException.query(),
            customMessage: provider.errorMessage!,
            onRetry: provider.refresh,
            compact: true,
          ),
          const SizedBox(height: 12),
        ],
        _buildTableCard(context, provider),
        const SizedBox(height: 16),
        _buildFooterControls(context, provider),
      ],
    );
  }

  Widget _buildTableCard(BuildContext context, AgentListProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Tableau des agents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF152033),
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                  ),
                  child: Text(
                    '${provider.filteredAgents.length} ligne${provider.filteredAgents.length > 1 ? 's' : ''} affichée${provider.filteredAgents.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF475467),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth =
                  constraints.maxWidth.isFinite && constraints.maxWidth > 0
                      ? constraints.maxWidth
                      : MediaQuery.of(context).size.width;

              const tableMinWidth = 1400.0;
              final constrainedWidth =
                  viewportWidth > tableMinWidth ? viewportWidth : tableMinWidth;

              return ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: constrainedWidth,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        cardTheme: const CardThemeData(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: Colors.white,
                        ),
                      ),
                      child: PaginatedDataTable(
                        header: const SizedBox.shrink(),
                        showFirstLastButtons: true,
                        rowsPerPage: provider.rowsPerPage,
                        availableRowsPerPage: const <int>[10, 20, 30, 50, 100],
                        showEmptyRows: false,
                        onRowsPerPageChanged: (value) {
                          if (value != null) {
                            provider.setRowsPerPage(value);
                          }
                        },
                        columnSpacing: 28,
                        horizontalMargin: 18,
                        columns: const [
                          DataColumn(label: Text('Département')),
                          DataColumn(label: Text('Code')),
                          DataColumn(label: Text('Prénom')),
                          DataColumn(label: Text('Nom')),
                          DataColumn(label: Text('Contact')),
                          DataColumn(label: Text('Site')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Statut')),
                          DataColumn(label: Text('Actions')),
                        ],
                        source: _AgentDataSource(
                          context: context,
                          data: provider.filteredAgents,
                          canValidate: _canValidate,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooterControls(
      BuildContext context, AgentListProvider provider) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7ECF3)),
          ),
          child: Text(
            provider.loadedCountText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475467),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (provider.hasMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFEDF89)),
            ),
            child: Text(
              'La base contient encore d’autres agents. Utilise "Charger plus" pour compléter la liste.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB54708),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: provider.hasMore && !provider.isLoadingMore
              ? provider.loadMoreAgents
              : null,
          icon: provider.isLoadingMore
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more_rounded),
          label: Text(provider.hasMore ? 'Charger plus' : 'Tout est chargé'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  void _onAddAgent(BuildContext context) {
    final agent = Agent(
      docs: const [],
      typeAgent: null,
      code: '',
      firstName: '',
      lastName: '',
      phone: '',
      email: '',
      tracking: false,
      site: null,
      actif: false,
      department: null,
      contacts: const [],
      dateEmbauche: null,
      dateArret: null,
    );

    context.go('/agents/add', extra: agent);
  }
}

class _AgentDataSource extends DataTableSource {
  _AgentDataSource({
    required this.context,
    required this.data,
    required this.canValidate,
  });

  final BuildContext context;
  final List<Agent> data;
  final bool canValidate;

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= data.length) {
      return null;
    }

    final agent = data[index];

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          _TagCell(
            label: agent.department?.label ?? 'Non défini',
            backgroundColor: const Color(0xFFEAF2FF),
            foregroundColor: const Color(0xFF1D4ED8),
          ),
        ),
        DataCell(Text(agent.code)),
        DataCell(Text(agent.firstName)),
        DataCell(Text(agent.lastName)),
        DataCell(Text(agent.phone)),
        DataCell(
          Text(
            agent.site?.name ?? '—',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(
          _TagCell(
            label: agent.typeAgent?.label ?? 'Non défini',
            backgroundColor: const Color(0xFFFFF1E8),
            foregroundColor: const Color(0xFFB54708),
          ),
        ),
        DataCell(
          AgentStatut(
            agent: agent,
            canValidate: canValidate,
          ),
        ),
        DataCell(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: 'Modifier',
                onPressed: () {
                  context.go('/agents/add', extra: agent);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.file_present_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: 'Documents',
                onPressed: () {
                  context.go('/agents/documents', extra: agent);
                },
              ),
              if (agent.actif == true)
                OutlinedButton.icon(
                  onPressed: () {
                    CarteGenerator.generateCarteAgent(agent);
                  },
                  icon: const Icon(Icons.badge_rounded),
                  label: const Text('Badge'),
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
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}

class AgentStatut extends StatefulWidget {
  const AgentStatut({
    super.key,
    required this.agent,
    required this.canValidate,
  });

  final Agent agent;
  final bool canValidate;

  @override
  State<AgentStatut> createState() => _AgentStatutState();
}

class _AgentStatutState extends State<AgentStatut> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    if (_updating) {
      return Loading(size: 28, inline: false);
    }

    final isActive = widget.agent.actif ?? false;

    return InkWell(
      onTap: widget.canValidate ? _toggleAgentStatus : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE7F8EC) : const Color(0xFFFFE8EA),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? const Color(0xFFABEFC6) : const Color(0xFFF7B5BD),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 18,
              color:
                  isActive ? const Color(0xFF067647) : const Color(0xFFB42318),
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? 'Actif' : 'Inactif',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF067647)
                    : const Color(0xFFB42318),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAgentStatus() async {
    setState(() {
      _updating = true;
    });

    widget.agent.actif = !(widget.agent.actif ?? false);

    try {
      await AgentService().update(widget.agent);
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD0D7E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD0D7E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: child,
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      side: const BorderSide(color: Color(0xFFD0D7E2)),
      backgroundColor: Colors.white,
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF344054),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TagCell extends StatelessWidget {
  const _TagCell({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AgentListMessageCard extends StatelessWidget {
  const _AgentListMessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF152033),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF697586),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
