import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/agent/providers/agent_bulk_manage_provider.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/services/department.dart';
import 'package:spas_web/services/loading.dart';

class AgentBulkManagePage extends StatelessWidget {
  const AgentBulkManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AgentBulkManageProvider>(
      create: (_) => AgentBulkManageProvider()..initialize(),
      child: const _AgentBulkManageView(),
    );
  }
}

class _AgentBulkManageView extends StatefulWidget {
  const _AgentBulkManageView();

  @override
  State<_AgentBulkManageView> createState() => _AgentBulkManageViewState();
}

class _AgentBulkManageViewState extends State<_AgentBulkManageView> {
  bool get _canDelete =>
      AuthService.currentManager?.profil?.getModule(ModuleName.AGENT)?.delete ??
      false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentBulkManageProvider>(
      builder: (context, provider, _) {
        return PageModel(
          pageIndex: 3,
          title: 'Gestion groupée des agents',
          child: RefreshIndicator(
            onRefresh: provider.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroCard(context, provider),
                      const SizedBox(height: 20),
                      _buildModeSelector(context, provider),
                      const SizedBox(height: 20),
                      _buildFilterPanel(context, provider),
                      const SizedBox(height: 20),
                      _buildSelectionToolbar(context, provider),
                      const SizedBox(height: 20),
                      if (provider.mode == AgentBulkManageMode.update)
                        _buildBulkUpdatePanel(context, provider)
                      else
                        _buildBulkDeletePanel(context, provider),
                      const SizedBox(height: 20),
                      _buildBody(context, provider),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showProcessingDialog({
    required BuildContext context,
    required String Function() messageBuilder,
    required Future<void> Function() operation,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Loading(
                    size: 56,
                    inline: true,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Traitement en cours',
                    style:
                        Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF152033),
                            ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    messageBuilder(),
                    style:
                        Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF667085),
                              height: 1.45,
                            ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Merci de patienter pendant l’exécution de l’opération.',
                    style:
                        Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF98A2B3),
                            ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      await operation();
    } finally {
      if (mounted) {
        navigator.pop();
      }
    }
  }

  Future<void> _runBulkUpdate(
    BuildContext context,
    AgentBulkManageProvider provider,
  ) async {
    await _showProcessingDialog(
      context: context,
      messageBuilder: () => provider.submitMessage,
      operation: provider.applyBulkUpdate,
    );
  }

  Widget _buildIntroCard(
    BuildContext context,
    AgentBulkManageProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        spacing: 24,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mettre à jour ou supprimer plusieurs agents à la fois',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF152033),
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cette page te permet de sélectionner un ensemble d’agents, de corriger rapidement des champs répétitifs comme le numéro de téléphone, le type, le département, le statut ou le nom, puis d’appliquer la mise à jour en une seule opération. La suppression groupée est aussi disponible.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF667085),
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoChip(
                      label: provider.mode == AgentBulkManageMode.update
                          ? 'Mode : mise à jour groupée'
                          : 'Mode : suppression groupée',
                    ),
                    _InfoChip(
                      label:
                          '${provider.selectedCount} agent${provider.selectedCount > 1 ? 's' : ''} sélectionné${provider.selectedCount > 1 ? 's' : ''}',
                    ),
                    _InfoChip(
                      label:
                          '${provider.visibleCount} visible${provider.visibleCount > 1 ? 's' : ''}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.go('/agents'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour à la liste'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(
    BuildContext context,
    AgentBulkManageProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          _ModeCard(
            title: 'Mise à jour groupée',
            subtitle:
                'Modifier rapidement des dizaines d’agents sans les ouvrir un à un.',
            icon: Icons.edit_note_rounded,
            active: provider.mode == AgentBulkManageMode.update,
            enabled: true,
            onTap: () => provider.setMode(AgentBulkManageMode.update),
          ),
          _ModeCard(
            title: 'Suppression groupée',
            subtitle:
                'Retirer plusieurs agents sélectionnés en une seule opération.',
            icon: Icons.delete_sweep_rounded,
            active: provider.mode == AgentBulkManageMode.delete,
            enabled: _canDelete,
            onTap: _canDelete
                ? () => provider.setMode(AgentBulkManageMode.delete)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(
    BuildContext context,
    AgentBulkManageProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Text(
            'Filtres de sélection',
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
                items: AgentBulkManageProvider.typeOptions
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
                label: 'Statut : ${provider.selectedStatusLabel}',
              ),
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

  Widget _buildSelectionToolbar(
    BuildContext context,
    AgentBulkManageProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _CountPill(
            label:
                '${provider.loadedCount} agent${provider.loadedCount > 1 ? 's' : ''} chargé${provider.loadedCount > 1 ? 's' : ''}',
          ),
          _CountPill(
            label:
                '${provider.visibleCount} visible${provider.visibleCount > 1 ? 's' : ''}',
          ),
          _CountPill(
            label:
                '${provider.selectedCount} sélectionné${provider.selectedCount > 1 ? 's' : ''}',
          ),
          FilledButton.tonalIcon(
            onPressed: provider.visibleAgents.isEmpty
                ? null
                : provider.selectAllVisible,
            icon: const Icon(Icons.done_all_rounded),
            label: const Text('Tout sélectionner'),
          ),
          OutlinedButton.icon(
            onPressed: provider.hasSelection ? provider.clearSelection : null,
            icon: const Icon(Icons.remove_done_rounded),
            label: const Text('Tout désélectionner'),
          ),
          OutlinedButton.icon(
            onPressed: provider.visibleAgents.isEmpty
                ? null
                : provider.selectOnlyVisible,
            icon: const Icon(Icons.filter_alt_rounded),
            label: const Text('Sélectionner visibles'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkUpdatePanel(
    BuildContext context,
    AgentBulkManageProvider provider,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Champs à mettre à jour',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF152033),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Coche uniquement les champs que tu veux remplacer pour les agents sélectionnés.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _UpdateFieldCard(
                title: 'Téléphone',
                enabled: provider.replacePhone,
                onChanged: provider.setReplacePhone,
                child: TextField(
                  controller: provider.phoneController,
                  decoration: _inputDecoration(
                    'Nouveau téléphone',
                    Icons.phone_rounded,
                  ),
                ),
              ),
              _UpdateFieldCard(
                title: 'Email',
                enabled: provider.replaceEmail,
                onChanged: provider.setReplaceEmail,
                child: TextField(
                  controller: provider.emailController,
                  decoration: _inputDecoration(
                    'Nouvel email (facultatif)',
                    Icons.email_rounded,
                  ),
                ),
              ),
              _UpdateFieldCard(
                title: 'Département',
                enabled: provider.replaceDepartment,
                onChanged: provider.setReplaceDepartment,
                child: StreamBuilder(
                  stream: DepartmentService().all(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const _DisabledInputPlaceholder(
                        label: 'Département de remplacement',
                        value: 'Chargement...',
                        icon: Icons.apartment_rounded,
                      );
                    }

                    final data = (snapshot.data?.docs ?? [])
                        .map((e) => e.data())
                        .whereType<Map>()
                        .map((e) =>
                            Department.fromJson(Map<String, dynamic>.from(e)))
                        .toList()
                      ..sort(
                        (a, b) => a.label
                            .toLowerCase()
                            .compareTo(b.label.toLowerCase()),
                      );

                    return DropdownButtonFormField<Department>(
                      initialValue: provider.bulkDepartment,
                      items: data
                          .map(
                            (department) => DropdownMenuItem<Department>(
                              value: department,
                              child: Text(department.label),
                            ),
                          )
                          .toList(),
                      onChanged: provider.replaceDepartment
                          ? provider.setBulkDepartment
                          : null,
                      decoration: _inputDecoration(
                        'Département de remplacement',
                        Icons.apartment_rounded,
                      ),
                    );
                  },
                ),
              ),
              _UpdateFieldCard(
                title: 'Type d’agent',
                enabled: provider.replaceAgentType,
                onChanged: provider.setReplaceAgentType,
                child: DropdownButtonFormField<AgentType>(
                  initialValue: provider.bulkAgentType,
                  items: [
                    DropdownMenuItem(
                      value: AgentType(label: 'FIXE'),
                      child: const Text('FIXE'),
                    ),
                    DropdownMenuItem(
                      value: AgentType(label: 'POINT ZERO'),
                      child: const Text('POINT ZERO'),
                    ),
                    DropdownMenuItem(
                      value: AgentType(label: 'RONDIER'),
                      child: const Text('RONDIER'),
                    ),
                  ],
                  onChanged: provider.replaceAgentType
                      ? provider.setBulkAgentType
                      : null,
                  decoration: _inputDecoration(
                    'Type de remplacement',
                    Icons.badge_rounded,
                  ),
                ),
              ),
              _UpdateFieldCard(
                title: 'Statut',
                enabled: provider.replaceStatus,
                onChanged: provider.setReplaceStatus,
                child: DropdownButtonFormField<bool>(
                  initialValue: provider.bulkActif,
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Actif'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Inactif'),
                    ),
                  ],
                  onChanged:
                      provider.replaceStatus ? provider.setBulkStatus : null,
                  decoration: _inputDecoration(
                    'Statut de remplacement',
                    Icons.toggle_on_rounded,
                  ),
                ),
              ),
              _UpdateFieldCard(
                title: 'Nom / numérotation',
                enabled: provider.replaceLastNamePrefix,
                onChanged: provider.setReplaceLastNamePrefix,
                child: Column(
                  children: [
                    TextField(
                      controller: provider.lastNamePrefixController,
                      decoration: _inputDecoration(
                        'Préfixe du nom (ex: N°)',
                        Icons.edit_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: provider.preserveExistingNumbering,
                      onChanged: provider.replaceLastNamePrefix
                          ? provider.setPreserveExistingNumbering
                          : null,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Conserver le numéro déjà présent'),
                      subtitle: const Text(
                        'Si activé, le nouveau texte remplace seulement le préfixe et garde le numéro existant.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: provider.selectedCount == 0 || provider.isSubmitting
                  ? null
                  : () => _runBulkUpdate(context, provider),
              icon: provider.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                provider.isSubmitting
                    ? 'Traitement en cours...'
                    : 'Appliquer la mise à jour',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkDeletePanel(
    BuildContext context,
    AgentBulkManageProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF7B5BD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suppression groupée',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB42318),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'La suppression retirera définitivement les agents sélectionnés. Vérifie bien la sélection avant de continuer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB42318),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          _CountPill(
            label:
                '${provider.selectedCount} agent${provider.selectedCount > 1 ? 's' : ''} prêt${provider.selectedCount > 1 ? 's' : ''} à être supprimé${provider.selectedCount > 1 ? 's' : ''}',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            onPressed: provider.selectedCount == 0 || provider.isSubmitting
                ? null
                : () => _confirmDelete(context, provider),
            icon: provider.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_forever_rounded),
            label: Text(
              provider.isSubmitting
                  ? 'Suppression en cours...'
                  : 'Supprimer la sélection',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AgentBulkManageProvider provider) {
    if (provider.errorMessage != null) {
      return _MessageCard(
        icon: Icons.error_outline_rounded,
        title: 'Erreur',
        subtitle: provider.errorMessage!,
        actionLabel: 'Réessayer',
        onPressed: provider.loadAgentsFromFirebase,
      );
    }

    if (provider.isLoadingAgents || provider.isLoadingDepartments) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Loading(
            size: 56,
            inline: true,
          ),
        ),
      );
    }

    if (provider.loadedAgents.isEmpty) {
      return _MessageCard(
        icon: Icons.inventory_2_outlined,
        title: 'Aucun agent chargé',
        subtitle:
            'Aucun agent ne correspond aux filtres actuels. Ajuste les filtres ou recharge la liste.',
        actionLabel: 'Actualiser',
        onPressed: provider.loadAgentsFromFirebase,
      );
    }

    if (provider.visibleAgents.isEmpty) {
      return _MessageCard(
        icon: Icons.filter_alt_off_rounded,
        title: 'Aucun résultat',
        subtitle:
            'Aucun agent ne correspond à la recherche actuelle. Réinitialise les filtres ou modifie la recherche.',
        actionLabel: 'Réinitialiser',
        onPressed: provider.resetFilters,
      );
    }

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
                  'Agents concernés',
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
                    '${provider.visibleAgents.length} ligne${provider.visibleAgents.length > 1 ? 's' : ''} affichée${provider.visibleAgents.length > 1 ? 's' : ''}',
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            itemCount: provider.visibleAgents.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final agent = provider.visibleAgents[index];
              final isSelected = provider.selectedCodes.contains(agent.code);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => provider.toggleSelection(agent),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  '${agent.firstName} ${agent.lastName}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TagCell(
                        label: agent.code,
                        backgroundColor: const Color(0xFFEAF2FF),
                        foregroundColor: const Color(0xFF1D4ED8),
                      ),
                      _TagCell(
                        label: agent.department?.label ?? 'Non défini',
                        backgroundColor: const Color(0xFFF2F4F7),
                        foregroundColor: const Color(0xFF344054),
                      ),
                      _TagCell(
                        label: agent.typeAgent?.label ?? 'Non défini',
                        backgroundColor: const Color(0xFFFFF1E8),
                        foregroundColor: const Color(0xFFB54708),
                      ),
                      _TagCell(
                        label: agent.actif == true ? 'Actif' : 'Inactif',
                        backgroundColor: agent.actif == true
                            ? const Color(0xFFEAFBF1)
                            : const Color(0xFFFFF4F4),
                        foregroundColor: agent.actif == true
                            ? const Color(0xFF067647)
                            : const Color(0xFFB42318),
                      ),
                    ],
                  ),
                ),
                secondary: SizedBox(
                  width: 280,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        agent.phone.isEmpty ? '—' : agent.phone,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF344054),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agent.site?.name ?? 'Aucun site',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF667085),
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AgentBulkManageProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Tu es sur le point de supprimer ${provider.selectedCount} agent${provider.selectedCount > 1 ? 's' : ''}. Cette action est définitive.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!context.mounted) return;

      await _showProcessingDialog(
        context: context,
        messageBuilder: () => provider.submitMessage,
        operation: provider.applyBulkDelete,
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
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
        borderSide: const BorderSide(
          color: Color(0xFF1D4ED8),
          width: 1.5,
        ),
      ),
      prefixIcon: Icon(icon),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        active ? Theme.of(context).primaryColor : const Color(0xFFE7ECF3);
    final backgroundColor = active
        ? Theme.of(context).primaryColor.withValues(alpha: 0.06)
        : Colors.white;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: active ? 1.6 : 1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: enabled
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.12)
                    : const Color(0xFFF2F4F7),
                child: Icon(
                  icon,
                  color: enabled
                      ? Theme.of(context).primaryColor
                      : const Color(0xFF98A2B3),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF152033),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateFieldCard extends StatelessWidget {
  const _UpdateFieldCard({
    required this.title,
    required this.enabled,
    required this.onChanged,
    required this.child,
  });

  final String title;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: enabled,
            onChanged: (value) => onChanged(value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: !enabled,
            child: Opacity(
              opacity: enabled ? 1 : 0.55,
              child: child,
            ),
          ),
        ],
      ),
    );
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
  final Future<void> Function(T?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged == null
            ? null
            : (value) {
                onChanged!(value);
              },
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

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

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD0D7E2)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF344054),
              fontWeight: FontWeight.w600,
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

class _DisabledInputPlaceholder extends StatelessWidget {
  const _DisabledInputPlaceholder({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
            ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
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
