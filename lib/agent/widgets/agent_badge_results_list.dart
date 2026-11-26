import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../agent_badge_details.dart';
import '../providers/agent_badge_provider.dart';

/// Only the current page is laid out; selection still spans all results.
class AgentBadgeResultsList extends StatelessWidget {
  const AgentBadgeResultsList({
    super.key,
    required this.provider,
    required this.withPhoto,
  });

  final AgentBadgeProvider provider;
  final bool withPhoto;

  @override
  Widget build(BuildContext context) {
    final agents = provider.pageAgents;
    final departments = provider.departments;
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
                    '${provider.pageStart}–${provider.pageEnd} sur ${provider.visibleCount} agents',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF475467),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          _BadgePagination(provider: provider),
          // Paint row ink effects above the surrounding card decoration.
          Material(
            type: MaterialType.transparency,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              itemCount: agents.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final agent = agents[index];
                final isSelected = provider.isSelected(agent);

                return CheckboxListTile(
                  key: ValueKey(agent.code),
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
                        if (withPhoto) ...[
                          _TagCell(
                            label:
                                agentBadgeRole(agent, departments: departments),
                            backgroundColor: const Color(0xFFEDF3FA),
                            foregroundColor: const Color(0xFF143D65),
                          ),
                          _TagCell(
                            label: agent.photoUrl?.trim().isNotEmpty == true
                                ? 'Photo renseignée'
                                : 'Photo manquante',
                            backgroundColor: const Color(0xFFFFF1E8),
                            foregroundColor: const Color(0xFFB54708),
                          ),
                          _TagCell(
                            label: agentBadgeSite(agent),
                            backgroundColor: const Color(0xFFEDF3FA),
                            foregroundColor: const Color(0xFF143D65),
                          ),
                        ],
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
                  secondary: withPhoto
                      ? IconButton(
                          tooltip: 'Modifier la fiche et la photo',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              context.go('/agents/add', extra: agent),
                        )
                      : SizedBox(
                          width: 280,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                agent.phone.isEmpty ? '—' : agent.phone,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF344054),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                agent.site?.name ?? 'Aucun site',
                                textAlign: TextAlign.right,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF667085),
                                    ),
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
          ),
          _BadgePagination(provider: provider),
        ],
      ),
    );
  }
}

class _BadgePagination extends StatelessWidget {
  const _BadgePagination({required this.provider});

  final AgentBadgeProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
              'Page ${provider.pageIndex + 1} / ${provider.pageCount} · ${AgentBadgeProvider.pageSize} agents par page'),
          IconButton(
            tooltip: 'Page précédente',
            icon: const Icon(Icons.chevron_left),
            onPressed: provider.pageIndex > 0
                ? () => provider.setPage(provider.pageIndex - 1)
                : null,
          ),
          IconButton(
            tooltip: 'Page suivante',
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.pageIndex + 1 < provider.pageCount
                ? () => provider.setPage(provider.pageIndex + 1)
                : null,
          ),
        ],
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
