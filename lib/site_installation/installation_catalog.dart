import '../model.dart' show departmentIdFromJson;
import 'installation_order.dart';

/// Equipment designations are shared by all companies. Older entries carry
/// only department.label instead of departmentId; normalize both formats.
List<InstallationOption> installationCatalogOptions(
    Map<String, Map<String, dynamic>> documents, Iterable<String> departments) {
  final allowed = departments.toSet();
  final options = <InstallationOption>[];
  documents.forEach((id, data) {
    final department = departmentIdFromJson(data);
    if (!allowed.contains(department) ||
        data['active'] == false ||
        installationMap(data['department'])['active'] == false) {
      return;
    }
    final label = (data['label'] as String? ?? id).trim();
    if (label.isEmpty) return;
    options.add(
        InstallationOption(id, label, {...data, 'departmentId': department}));
  });
  options
      .sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return options;
}
