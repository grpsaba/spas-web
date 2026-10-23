import 'package:flutter/material.dart';

import '../model.dart';
import '../pointage_redesign/presentation/design_system.dart';

/// Natural card heights avoid clipping when the viewport or text scale changes.
class ZoneMemberCardGrid extends StatelessWidget {
  const ZoneMemberCardGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 12.0;
      final columns = ((constraints.maxWidth + gap) / (320 + gap))
          .floor()
          .clamp(1, 4)
          .toInt();
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    });
  }
}

class ZoneMemberCard extends StatelessWidget {
  const ZoneMemberCard({
    super.key,
    required this.member,
    this.onEdit,
    this.statusControl,
  });

  final ZoneMember member;
  final VoidCallback? onEdit;
  final Widget? statusControl;

  @override
  Widget build(BuildContext context) {
    final name = '${member.firstName} ${member.lastName}'.trim();
    final initials = [member.firstName, member.lastName]
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.trim().characters.first)
        .join()
        .toUpperCase();
    final role = member.poste?.trim();

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3E7EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: PointageColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PointageColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: name,
                        child: Text(
                          name.isEmpty ? 'Chef de zone' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF25324A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role == null || role.isEmpty ? 'Chef de zone' : role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PointageTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Modifier $name',
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    color: PointageColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _MemberDetail(
              icon: member.hasGlobalZoneAccess
                  ? Icons.public_outlined
                  : Icons.location_on_outlined,
              text: member.zoneScopeLabel,
              color: PointageColors.primary,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            SelectionArea(
              child: _MemberDetail(
                icon: Icons.mail_outline,
                text: member.email.trim().isEmpty
                    ? 'Email non renseigné'
                    : member.email.trim(),
              ),
            ),
            const SizedBox(height: 6),
            LayoutBuilder(builder: (context, constraints) {
              final phone = SelectionArea(
                child: _MemberDetail(
                  icon: Icons.phone_outlined,
                  text: member.phone.trim().isEmpty
                      ? 'Téléphone non renseigné'
                      : member.phone.trim(),
                ),
              );
              final status = statusControl ??
                  ZoneMemberStatusControl(active: member.actif == true);
              // Keep contacts readable at narrow widths and larger text sizes.
              if (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(13) > 16) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    phone,
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerRight, child: status),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: phone),
                  const SizedBox(width: 8),
                  status,
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MemberDetail extends StatelessWidget {
  const _MemberDetail({
    required this.icon,
    required this.text,
    this.color = const Color(0xFF596579),
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final Color color;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Tooltip(
            message: text,
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, height: 1.35, color: color),
            ),
          ),
        ),
      ],
    );
  }
}

/// A compact status indicator; editing is available only with a callback.
class ZoneMemberStatusControl extends StatelessWidget {
  const ZoneMemberStatusControl({
    super.key,
    required this.active,
    this.onChanged,
    this.updating = false,
  });

  final bool active;
  final ValueChanged<bool>? onChanged;
  final bool updating;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF237A53) : const Color(0xFF717888);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 6, color: color),
        const SizedBox(width: 5),
        Text(
          active ? 'Actif' : 'Inactif',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: color),
        ),
        if (updating)
          const SizedBox(
            width: 48,
            height: 32,
            child: Center(
              child: SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  semanticsLabel: 'Mise à jour du statut',
                ),
              ),
            ),
          )
        else if (onChanged != null)
          Tooltip(
            message: active ? 'Désactiver le compte' : 'Activer le compte',
            child: Switch.adaptive(
              value: active,
              onChanged: onChanged,
              activeTrackColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}
