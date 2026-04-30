import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/agent/providers/agent_badge_provider.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/export.dart';
import 'package:spas_web/services/loading.dart';

class AgentBadgeGenerationPage extends StatelessWidget {
  const AgentBadgeGenerationPage({
    super.key,
    this.currentAgents = const <Agent>[],
  });

  final List<Agent> currentAgents;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AgentBadgeProvider>(
      create: (_) => AgentBadgeProvider()
        ..initialize(
          currentAgents: currentAgents,
          useCurrentList: currentAgents.isNotEmpty,
        ),
      child: _AgentBadgeGenerationView(currentAgents: currentAgents),
    );
  }
}

class _AgentBadgeGenerationView extends StatefulWidget {
  const _AgentBadgeGenerationView({
    required this.currentAgents,
  });

  final List<Agent> currentAgents;

  @override
  State<_AgentBadgeGenerationView> createState() =>
      _AgentBadgeGenerationViewState();
}

class _AgentBadgeGenerationViewState extends State<_AgentBadgeGenerationView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AgentBadgeProvider>(
      builder: (context, provider, _) {
        return PageModel(
          pageIndex: 3,
          title: 'Génération des badges agents',
          child: RefreshIndicator(
            onRefresh: () async {
              if (provider.useCurrentList) {
                provider.setCurrentAgents(widget.currentAgents);
              } else {
                await provider.loadAgentsFromFirebase();
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroCard(context, provider),
                      const SizedBox(height: 20),
                      _buildSourceSelectorCard(context, provider),
                      const SizedBox(height: 20),
                      _buildFilterPanel(context, provider),
                      const SizedBox(height: 20),
                      _buildSelectionToolbar(context, provider),
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

  Future<void> _runBadgeGeneration(
    BuildContext context,
    AgentBadgeProvider provider,
  ) async {
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
                    provider.generationMessage,
                    style:
                        Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF667085),
                              height: 1.45,
                            ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Merci de patienter pendant la préparation du document.',
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
      await provider.generateSelectedBadges(
        onGenerate: (agents) async {
          await Future<void>.delayed(const Duration(milliseconds: 120));
          CarteGenerator.generateMiltiCarteAgent(agents);
        },
      );
    } finally {
      if (mounted) {
        navigator.pop();
      }
    }
  }

  Widget _buildIntroCard(BuildContext context, AgentBadgeProvider provider) {
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
            width: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélectionne précisément les agents à imprimer',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF152033),
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tu peux partir de la liste actuellement affichée ou charger une nouvelle sélection complète avec des filtres. Ensuite, tu peux tout sélectionner, tout désélectionner, ou choisir seulement les agents voulus avant génération.',
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
                      label: provider.useCurrentList
                          ? 'Source : sélection actuelle'
                          : 'Source : nouvelle sélection',
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

  Widget _buildSourceSelectorCard(
    BuildContext context,
    AgentBadgeProvider provider,
  ) {
    final canUseCurrentList = widget.currentAgents.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Source des données',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF152033),
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _SelectionSourceCard(
                title: 'Utiliser la liste actuelle',
                subtitle: canUseCurrentList
                    ? '${widget.currentAgents.length} agent${widget.currentAgents.length > 1 ? 's' : ''} transmis depuis la page Agents'
                    : 'Aucune liste actuelle transmise',
                icon: Icons.list_alt_rounded,
                active: provider.useCurrentList,
                enabled: canUseCurrentList,
                onTap: canUseCurrentList
                    ? () => provider.setMode(
                          useCurrentList: true,
                          currentAgents: widget.currentAgents,
                        )
                    : null,
              ),
              _SelectionSourceCard(
                title: 'Créer une nouvelle sélection',
                subtitle:
                    'Récupérer une liste complète d’agents à partir des filtres choisis',
                icon: Icons.cloud_download_rounded,
                active: !provider.useCurrentList,
                enabled: true,
                onTap: () => provider.setMode(
                  useCurrentList: false,
                  currentAgents: widget.currentAgents,
                ),
              ),
            ],
          ),
          if (!provider.useCurrentList) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: provider.isLoadingAgents
                  ? null
                  : provider.loadAgentsFromFirebase,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Charger la sélection'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, AgentBadgeProvider provider) {
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
                items: AgentBadgeProvider.typeOptions
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
                onPressed: () => provider.resetFilters(
                  currentAgents: widget.currentAgents,
                ),
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
    AgentBadgeProvider provider,
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
          FilledButton.icon(
            onPressed:
                provider.selectedCount == 0 || provider.isGeneratingBadges
                    ? null
                    : () async => _runBadgeGeneration(context, provider),
            icon: provider.isGeneratingBadges
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.badge_rounded),
            label: Text(
              provider.isGeneratingBadges
                  ? 'Traitement en cours...'
                  : 'Générer les badges',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AgentBadgeProvider provider) {
    if (provider.errorMessage != null) {
      return _MessageCard(
        icon: Icons.error_outline_rounded,
        title: 'Erreur',
        subtitle: provider.errorMessage!,
        actionLabel: 'Réessayer',
        onPressed: provider.useCurrentList
            ? () => provider.setCurrentAgents(widget.currentAgents)
            : provider.loadAgentsFromFirebase,
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
        title: provider.useCurrentList
            ? 'Aucun agent disponible'
            : 'Aucun agent chargé',
        subtitle: provider.useCurrentList
            ? 'La sélection actuelle ne contient aucun agent exploitable pour les badges.'
            : 'Lance le chargement avec les filtres souhaités pour préparer la sélection.',
        actionLabel: provider.useCurrentList
            ? 'Retour à la liste'
            : 'Charger la sélection',
        onPressed: provider.useCurrentList
            ? () => context.go('/agents')
            : provider.loadAgentsFromFirebase,
      );
    }

    if (provider.visibleAgents.isEmpty) {
      return _MessageCard(
        icon: Icons.filter_alt_off_rounded,
        title: 'Aucun résultat',
        subtitle:
            'Aucun agent ne correspond à la recherche actuelle. Réinitialise les filtres ou modifie la recherche.',
        actionLabel: 'Réinitialiser',
        onPressed: () =>
            provider.resetFilters(currentAgents: widget.currentAgents),
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
                  'Agents disponibles pour badges',
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
}

class _SelectionSourceCard extends StatelessWidget {
  const _SelectionSourceCard({
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
          width: 320,
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
