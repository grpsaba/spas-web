import '../model.dart';

/// Badge wording is independent of the operational type (FIXE, RONDIER...).
String agentBadgeRole(Agent agent,
    {Iterable<Department> departments = const []}) {
  final id = normalizeDepartmentId(agent.departmentId ?? agent.department?.id);
  Department? department;
  for (final candidate in departments) {
    if (candidate.id == id) {
      department = candidate;
      break;
    }
  }
  department ??= agent.department;
  final label = department?.label.trim() ?? '';
  final key = id.isNotEmpty ? id : normalizeDepartmentId(label);
  switch (key) {
    case 'security':
      return 'Agent de sécurité';
    case 'cleaning':
      return 'Agent de nettoyage';
  }
  // A custom technical ID can still have a known department label.
  switch (normalizeDepartmentId(label)) {
    case 'security':
      return 'Agent de sécurité';
    case 'cleaning':
      return 'Agent de nettoyage';
    default:
      return label.isEmpty ? 'Agent' : label;
  }
}

String agentBadgeSite(Agent agent) {
  final site = agent.site?.name.trim() ?? '';
  return site.isEmpty ? 'Non affecté' : site;
}
