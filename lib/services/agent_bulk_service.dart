import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/agent_bulk_config.dart';

class AgentBulkService {
  AgentBulkService({
    FirebaseFirestore? firestore,
    AgentBulkConfigService? configService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _configService =
            configService ?? AgentBulkConfigService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final AgentBulkConfigService _configService;

  static const String agentsCollectionName = 'Agents';

  Future<AgentBulkCreationResult> createAgents({
    required Department department,
    required AgentType agentType,
    required int quantity,
    String phone = '00000000',
    String email = '',
    bool actif = true,
    bool tracking = false,
  }) async {
    _validateInput(
      department: department,
      agentType: agentType,
      quantity: quantity,
      phone: phone,
      email: email,
    );

    await _configService.ensureConfigExists();

    final allocation = await _configService.reserveRangeForDepartment(
      departmentLabel: department.label,
      quantity: quantity,
    );

    final agents = <Agent>[];
    final batch = _firestore.batch();
    final collection = _firestore.collection(agentsCollectionName);

    for (int i = 0; i < quantity; i++) {
      final agentNumber = allocation.startNumber + i;
      final agent = _buildAgent(
        department: department,
        agentType: agentType,
        number: agentNumber,
        phone: phone,
        email: email,
        actif: actif,
        tracking: tracking,
      );

      final docRef = collection.doc(agent.code);
      batch.set(docRef, agent.toJson());
      agents.add(agent);
    }

    await batch.commit();

    return AgentBulkCreationResult(
      agents: agents,
      createdCount: agents.length,
      startNumber: allocation.startNumber,
      endNumber: allocation.endNumber,
      codePrefix: _configService.getCodePrefixForDepartment(department.label),
      departmentLabel: department.label,
      agentTypeLabel: agentType.label,
    );
  }

  Agent _buildAgent({
    required Department department,
    required AgentType agentType,
    required int number,
    required String phone,
    required String email,
    required bool actif,
    required bool tracking,
  }) {
    final code = _configService.formatCode(
      departmentLabel: department.label,
      agentNumber: number,
    );

    return Agent(
      code: code,
      firstName: 'Agent',
      lastName: 'N° $number',
      phone: phone,
      email: email,
      tracking: tracking,
      site: null,
      department: department,
      typeAgent: agentType,
      actif: actif,
      docs: <DocumentFile>[],
      contacts: <ConactReference>[],
      dateEmbauche: DateTime.now(),
      dateArret: null,
    );
  }

  void _validateInput({
    required Department department,
    required AgentType agentType,
    required int quantity,
    required String phone,
    required String email,
  }) {
    final departmentLabel = department.label.trim();
    final agentTypeLabel = agentType.label.trim();

    if (departmentLabel.isEmpty) {
      throw ArgumentError('Le département est obligatoire.');
    }

    final normalizedDepartment = departmentLabel.toLowerCase();
    final isSupportedDepartment = normalizedDepartment.contains('sec') ||
        normalizedDepartment.contains('net');

    if (!isSupportedDepartment) {
      throw ArgumentError(
        'Seuls les départements Sécurité et Nettoyage sont supportés pour la création en masse.',
      );
    }

    if (agentTypeLabel.isEmpty) {
      throw ArgumentError('Le type d’agent est obligatoire.');
    }

    if (quantity <= 0) {
      throw ArgumentError('Le nombre d’agents doit être supérieur à 0.');
    }

    if (phone.trim().isEmpty) {
      throw ArgumentError('Le téléphone par défaut ne peut pas être vide.');
    }

    if (email.trim().isNotEmpty && !email.contains('@')) {
      throw ArgumentError(
        'Si un email par défaut est renseigné, il doit être valide.',
      );
    }
  }
}

class AgentBulkCreationResult {
  const AgentBulkCreationResult({
    required this.agents,
    required this.createdCount,
    required this.startNumber,
    required this.endNumber,
    required this.codePrefix,
    required this.departmentLabel,
    required this.agentTypeLabel,
  });

  final List<Agent> agents;
  final int createdCount;
  final int startNumber;
  final int endNumber;
  final String codePrefix;
  final String departmentLabel;
  final String agentTypeLabel;

  bool get isEmpty => agents.isEmpty;
}
