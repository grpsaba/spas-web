import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/agentType.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/services/department.dart';
import 'package:spas_web/services/loading.dart';
import 'package:spas_web/services/agent_bulk_config.dart';
import 'package:spas_web/services/agent_bulk_service.dart';

class AgentBulkCreatePage extends StatefulWidget {
  const AgentBulkCreatePage({super.key});

  @override
  State<AgentBulkCreatePage> createState() => _AgentBulkCreatePageState();
}

class _AgentBulkCreatePageState extends State<AgentBulkCreatePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _phoneController =
      TextEditingController(text: '00000000');
  final TextEditingController _emailController = TextEditingController();

  final AgentBulkService _bulkService = AgentBulkService();
  final AgentBulkConfigService _configService = AgentBulkConfigService();

  Department? _selectedDepartment;
  AgentType? _selectedAgentType;

  bool _isSubmitting = false;
  bool _isLoadingConfig = true;
  String? _errorMessage;
  AgentBulkConfig _config = const AgentBulkConfig();
  AgentBulkCreationResult? _lastResult;

  bool get _canAdd =>
      AuthService.currentManager?.profil?.getModule(ModuleName.AGENT)?.add ??
      false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoadingConfig = true;
      _errorMessage = null;
    });

    try {
      await _configService.ensureConfigExists();
      final config = await _configService.getConfig();
      if (!mounted) return;

      setState(() {
        _config = config;
        _isLoadingConfig = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Impossible de charger la configuration bulk: ${error.toString()}';
        _isLoadingConfig = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_canAdd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu n’as pas les droits pour créer des agents.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartment == null || _selectedAgentType == null) {
      setState(() {
        _errorMessage = 'Le département et le type d’agent sont obligatoires.';
      });
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _lastResult = null;
    });

    try {
      final result = await _bulkService.createAgents(
        department: _selectedDepartment!,
        agentType: _selectedAgentType!,
        quantity: quantity,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      final updatedConfig = await _configService.getConfig();

      if (!mounted) return;

      setState(() {
        _lastResult = result;
        _config = updatedConfig;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.createdCount} agent(s) créé(s) avec succès.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isSubmitting = false;
      });
    }
  }

  bool _isSupportedDepartment(Department department) {
    final normalized = department.label.trim().toLowerCase();
    return normalized.contains('sec') || normalized.contains('net');
  }

  String _departmentPreview(Department department) {
    final normalized = department.label.trim().toLowerCase();
    if (normalized.contains('sec')) {
      return 'Préfixe code: SEC';
    }
    if (normalized.contains('net')) {
      return 'Préfixe code: NET';
    }
    return 'Département non supporté pour la création en masse';
  }

  int _nextNumberForDepartment(Department? department) {
    if (department == null) return 1;
    final normalized = department.label.trim().toLowerCase();
    if (normalized.contains('net')) {
      return _config.lastCleaningAgentNum + 1;
    }
    return _config.lastSecurityAgentNum + 1;
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 3,
      title: 'Gestion des agents -> Création en masse',
      child: _isLoadingConfig
          ? Center(
              child: Loading(
                size: 56,
                inline: true,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroCard(context),
                      const SizedBox(height: 20),
                      _buildCountersCard(context),
                      const SizedBox(height: 20),
                      _buildFormCard(context),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        _buildErrorCard(context),
                      ],
                      if (_lastResult != null) ...[
                        const SizedBox(height: 20),
                        _buildSuccessCard(context),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
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
        runSpacing: 20,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créer plusieurs agents en une seule opération',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF152033),
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cette page permet de générer en masse des agents de Sécurité ou de Nettoyage avec code automatique, numéro séquentiel et type paramétrable.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF667085),
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _InfoChip(label: 'Site non assigné'),
                    _InfoChip(label: 'Téléphone par défaut 00000000'),
                    _InfoChip(label: 'Code auto SEC / NET'),
                    _InfoChip(label: 'Numérotation séquentielle'),
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

  Widget _buildCountersCard(BuildContext context) {
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
          _CounterCard(
            title: 'Dernier n° Sécurité',
            value: _config.lastSecurityAgentNum.toString(),
            color: const Color(0xFF1D4ED8),
            icon: Icons.security_rounded,
          ),
          _CounterCard(
            title: 'Dernier n° Nettoyage',
            value: _config.lastCleaningAgentNum.toString(),
            color: const Color(0xFF047857),
            icon: Icons.cleaning_services_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations générales',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF152033),
                  ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 280,
                  child: StreamBuilder(
                    stream: DepartmentService().all(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const _DisabledInputPlaceholder(
                          label: 'Département',
                          value: 'Chargement...',
                          icon: Icons.apartment_rounded,
                        );
                      }

                      final docs = snapshot.data?.docs
                              .map((e) => jsonDecode(jsonEncode(e.data())))
                              .toList() ??
                          [];

                      final departments = docs
                          .map((e) => Department.fromJson(e))
                          .where(_isSupportedDepartment)
                          .toList()
                        ..sort(
                          (a, b) => a.label
                              .toLowerCase()
                              .compareTo(b.label.toLowerCase()),
                        );

                      if (_selectedDepartment != null &&
                          !departments.any(
                            (element) =>
                                element.label == _selectedDepartment!.label,
                          )) {
                        _selectedDepartment = null;
                      }

                      return DropdownButtonFormField<Department>(
                        value: _selectedDepartment,
                        decoration: const InputDecoration(
                          labelText: 'Département',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                        validator: (value) {
                          return value == null
                              ? 'Département obligatoire'
                              : null;
                        },
                        items: departments
                            .map(
                              (department) => DropdownMenuItem<Department>(
                                value: department,
                                child: Text(department.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: StreamBuilder(
                    stream: AgentTypeService().all(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const _DisabledInputPlaceholder(
                          label: 'Type d’agent',
                          value: 'Chargement...',
                          icon: Icons.badge_rounded,
                        );
                      }

                      final docs = snapshot.data?.docs
                              .map((e) => jsonDecode(jsonEncode(e.data())))
                              .toList() ??
                          [];

                      final agentTypes = docs
                          .map((e) => AgentType.fromJson(e))
                          .where(
                            (type) => const ['POINT ZERO', 'RONDIER', 'FIXE']
                                .contains(type.label.toUpperCase()),
                          )
                          .toList()
                        ..sort(
                          (a, b) => a.label
                              .toLowerCase()
                              .compareTo(b.label.toLowerCase()),
                        );

                      if (_selectedAgentType == null && agentTypes.isNotEmpty) {
                        _selectedAgentType = agentTypes.firstWhere(
                          (element) =>
                              element.label.toUpperCase() == 'POINT ZERO',
                          orElse: () => agentTypes.first,
                        );
                      } else if (_selectedAgentType != null &&
                          !agentTypes.any(
                            (element) =>
                                element.label == _selectedAgentType!.label,
                          )) {
                        _selectedAgentType = null;
                      }

                      return DropdownButtonFormField<AgentType>(
                        value: _selectedAgentType,
                        decoration: const InputDecoration(
                          labelText: 'Type d’agent',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.supervised_user_circle_rounded),
                        ),
                        validator: (value) {
                          return value == null ? 'Type obligatoire' : null;
                        },
                        items: agentTypes
                            .map(
                              (agentType) => DropdownMenuItem<AgentType>(
                                value: agentType,
                                child: Text(agentType.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAgentType = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final quantity = int.tryParse(value?.trim() ?? '');
                      if (quantity == null) {
                        return 'Nombre invalide';
                      }
                      if (quantity <= 0) {
                        return 'Minimum 1';
                      }
                      if (quantity > 500) {
                        return 'Maximum 500';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.format_list_numbered_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 280,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Téléphone obligatoire';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Téléphone par défaut',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email par défaut (facultatif)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPreviewPanel(context),
            const SizedBox(height: 24),
            _isSubmitting
                ? Center(
                    child: Loading(
                      size: 48,
                      inline: false,
                    ),
                  )
                : Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Créer le lot'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _loadConfig,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Rafraîchir les compteurs'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(BuildContext context) {
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final nextNumber = _nextNumberForDepartment(_selectedDepartment);
    final lastNumber = quantity > 0 ? nextNumber + quantity - 1 : nextNumber;
    final departmentLabel = _selectedDepartment?.label ?? 'Non sélectionné';
    final typeLabel = _selectedAgentType?.label ?? 'POINT ZERO';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prévisualisation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF152033),
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _PreviewInfoTile(
                label: 'Département',
                value: departmentLabel,
              ),
              _PreviewInfoTile(
                label: 'Type',
                value: typeLabel,
              ),
              _PreviewInfoTile(
                label: 'Prochain numéro',
                value: nextNumber.toString(),
              ),
              _PreviewInfoTile(
                label: 'Dernier numéro du lot',
                value: lastNumber.toString(),
              ),
              _PreviewInfoTile(
                label: 'Règle code',
                value: _selectedDepartment == null
                    ? 'Sélectionne un département'
                    : _departmentPreview(_selectedDepartment!),
              ),
              _PreviewInfoTile(
                label: 'Nom généré',
                value: 'Agent / N° X',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF7B5BD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB42318),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB42318),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    final result = _lastResult!;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBF1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFABEFC6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF067647),
              ),
              const SizedBox(width: 10),
              Text(
                'Création terminée',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF067647),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _PreviewInfoTile(
                label: 'Département',
                value: result.departmentLabel,
              ),
              _PreviewInfoTile(
                label: 'Type',
                value: result.agentTypeLabel,
              ),
              _PreviewInfoTile(
                label: 'Créés',
                value: result.createdCount.toString(),
              ),
              _PreviewInfoTile(
                label: 'De',
                value: result.startNumber.toString(),
              ),
              _PreviewInfoTile(
                label: 'À',
                value: result.endNumber.toString(),
              ),
              _PreviewInfoTile(
                label: 'Préfixe',
                value: result.codePrefix,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result.agents.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD0D7E2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exemples générés',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF152033),
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...result.agents.take(5).map(
                        (agent) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${agent.code} • ${agent.firstName} ${agent.lastName}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF344054),
                                ),
                          ),
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

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF152033),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewInfoTile extends StatelessWidget {
  const _PreviewInfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF667085),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF152033),
                ),
          ),
        ],
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
