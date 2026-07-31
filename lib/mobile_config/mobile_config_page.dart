import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/access_control.dart';
import 'package:spas_web/services/mobile_config.dart';
import 'package:spas_web/services/tenant.dart';

class MobileConfigPage extends StatefulWidget {
  const MobileConfigPage({super.key});

  @override
  State<MobileConfigPage> createState() => _MobileConfigPageState();
}

class _MobileConfigPageState extends State<MobileConfigPage> {
  static const int _pageIndex = 19;

  final MobileConfigService _service = MobileConfigService();
  final TenantService _tenantService = TenantService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _maxWidthController = TextEditingController();
  final TextEditingController _maxHeightController = TextEditingController();
  final TextEditingController _uploadTimeoutController =
      TextEditingController();

  late Future<MobileConfig> _configFuture;
  bool _backgroundTrackingEnabled =
      MobileConfig.defaultBackgroundTrackingEnabled;
  double _photoQuality = MobileConfig.defaultPointingPhotoQuality.toDouble();
  bool _isSaving = false;
  final Set<String> _savingPointageTenantIds = <String>{};

  @override
  void initState() {
    super.initState();
    _configFuture = _loadConfig();
  }

  @override
  void dispose() {
    _maxWidthController.dispose();
    _maxHeightController.dispose();
    _uploadTimeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AccessControl.canView(ModuleName.MOBILE_CONFIG)) {
      return PageModel(
        pageIndex: _pageIndex,
        title: 'Configuration Mobile',
        child: _buildAccessDenied(),
      );
    }

    return PageModel(
      pageIndex: _pageIndex,
      title: 'Configuration Mobile',
      child: FutureBuilder<MobileConfig>(
        future: _configFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          return _buildContent();
        },
      ),
    );
  }

  Future<MobileConfig> _loadConfig() async {
    final config = await _service.getConfig();
    if (mounted) {
      _applyConfig(config);
    }
    return config;
  }

  void _applyConfig(MobileConfig config) {
    _backgroundTrackingEnabled = config.backgroundTrackingEnabled;
    _photoQuality = config.pointingPhotoQuality.toDouble();
    _maxWidthController.text = _formatOptionalDouble(
      config.pointingPhotoMaxWidth,
    );
    _maxHeightController.text = _formatOptionalDouble(
      config.pointingPhotoMaxHeight,
    );
    _uploadTimeoutController.text =
        config.pointingPhotoUploadTimeoutSeconds?.toString() ?? '';
  }

  Widget _buildContent() {
    final canEdit = AccessControl.canAdd(ModuleName.MOBILE_CONFIG);
    final canEditPointageModes = AccessControl.canView(
      ModuleName.MOBILE_CONFIG,
    );

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(canEdit || canEditPointageModes),
                const SizedBox(height: 16),
                if (!canEdit) ...[
                  _buildReadOnlyNotice(canEditPointageModes),
                  const SizedBox(height: 16),
                ],
                _buildPointageModesPanel(canEditPointageModes),
                const SizedBox(height: 16),
                _buildTrackingPanel(canEdit),
                const SizedBox(height: 16),
                _buildPhotoPanel(canEdit),
                const SizedBox(height: 20),
                _buildActions(canEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool canEdit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(color: const Color(0xFFF7F8FC)),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_cell_rounded,
                  color: AppConstants.primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parametres mobile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Document Firestore: app_config/global',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: canEdit
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: canEdit
                    ? Colors.green.withValues(alpha: 0.25)
                    : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  canEdit ? Icons.edit_rounded : Icons.visibility_rounded,
                  size: 18,
                  color:
                      canEdit ? Colors.green.shade700 : Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Text(
                  canEdit ? 'Modification active' : 'Lecture seule',
                  style: TextStyle(
                    color: canEdit
                        ? Colors.green.shade800
                        : Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyNotice(bool canEditPointageModes) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              canEditPointageModes
                  ? 'Votre profil peut modifier les modes de pointage de son pays. Les autres parametres mobiles sont en lecture seule.'
                  : 'Votre profil peut consulter cette configuration, mais ne peut pas la modifier.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointageModesPanel(bool canEdit) {
    final includeAllTenants = AccessControl.canBypassTenantFilter;
    final tenantId = AccessControl.currentTenantId;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildPanelIcon(Icons.rule_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modes de pointage par pays',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      includeAllTenants
                          ? 'Configuration des superviseurs et chefs de zone pour tous les pays.'
                          : 'Configuration des superviseurs et chefs de zone pour votre pays.',
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Tenant>>(
            stream: _tenantService.watchPointageModeTenants(
              includeAll: includeAllTenants,
              tenantId: tenantId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildPanelMessage(
                  icon: Icons.error_outline_rounded,
                  message:
                      'Impossible de charger les modes de pointage: ${snapshot.error}',
                  isError: true,
                );
              }

              final tenants = snapshot.data ?? <Tenant>[];
              if (tenants.isEmpty) {
                return _buildPanelMessage(
                  icon: Icons.info_outline_rounded,
                  message: includeAllTenants
                      ? 'Aucun pays configure.'
                      : 'Aucun pays trouve pour votre profil.',
                );
              }

              return Column(
                children: tenants
                    .map(
                      (tenant) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildTenantPointageModeRow(
                          tenant,
                          canEdit: canEdit,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTenantPointageModeRow(Tenant tenant, {required bool canEdit}) {
    final isSaving = _savingPointageTenantIds.contains(tenant.id);
    final rowEnabled = canEdit && !isSaving;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;
          final country = Row(
            children: [
              Icon(
                Icons.public_rounded,
                size: 22,
                color: tenant.active ? AppConstants.primaryColor : Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.label.isEmpty
                          ? tenant.id.toUpperCase()
                          : tenant.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tenant.id.toUpperCase()} - ${tenant.countryCode}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSaving)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          );

          final controls = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPointageModeDropdown(
                label: 'Superviseurs',
                value: tenant.pointageMode,
                enabled: rowEnabled,
                onChanged: (mode) => _updateTenantPointageModes(
                  tenant,
                  pointageMode: mode,
                ),
              ),
              _buildPointageModeDropdown(
                label: 'Chefs de zone',
                value: tenant.zoneChiefPointageMode,
                enabled: rowEnabled,
                onChanged: (mode) => _updateTenantPointageModes(
                  tenant,
                  zoneChiefPointageMode: mode,
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                country,
                const SizedBox(height: 12),
                controls,
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 250, child: country),
              const SizedBox(width: 16),
              Expanded(child: controls),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPointageModeDropdown({
    required String label,
    required String value,
    required bool enabled,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value'),
        initialValue: TenantPointageMode.normalize(value),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
        ),
        items: const [
          DropdownMenuItem(
            value: TenantPointageMode.photo,
            child: Text('Photo'),
          ),
          DropdownMenuItem(
            value: TenantPointageMode.geo,
            child: Text('Geolocalisation'),
          ),
        ],
        onChanged: enabled
            ? (mode) {
                if (mode != null) onChanged(mode);
              }
            : null,
      ),
    );
  }

  Widget _buildPanelMessage({
    required IconData icon,
    required String message,
    bool isError = false,
  }) {
    final color = isError ? Colors.red.shade700 : Colors.black54;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withValues(alpha: 0.06)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError
              ? Colors.red.withValues(alpha: 0.18)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingPanel(bool canEdit) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          _buildPanelIcon(Icons.my_location_rounded),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suivi GPS en arriere-plan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Pilote par le mode de pointage du pays: geo active, photo desactive.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: _backgroundTrackingEnabled,
            onChanged: null,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPanel(bool canEdit) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildPanelIcon(Icons.photo_camera_rounded),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photos de pointage',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Les champs vides gardent le comportement actuel.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Qualite de compression',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${_photoQuality.round()}%',
                      style: const TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _photoQuality,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '${_photoQuality.round()}%',
                  onChanged: canEdit && !_isSaving
                      ? (value) {
                          setState(() {
                            _photoQuality = value;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildNumberField(
                controller: _maxWidthController,
                label: 'Largeur max',
                suffixText: 'px',
                enabled: canEdit && !_isSaving,
                integerOnly: false,
              ),
              _buildNumberField(
                controller: _maxHeightController,
                label: 'Hauteur max',
                suffixText: 'px',
                enabled: canEdit && !_isSaving,
                integerOnly: false,
              ),
              _buildNumberField(
                controller: _uploadTimeoutController,
                label: 'Timeout upload photo',
                suffixText: 'sec',
                enabled: canEdit && !_isSaving,
                integerOnly: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool canEdit) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: canEdit && !_isSaving ? _resetToDefaults : null,
          icon: const Icon(Icons.restore_rounded),
          label: const Text('Valeurs par defaut'),
        ),
        ElevatedButton.icon(
          onPressed: canEdit && !_isSaving ? _save : null,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffixText,
    required bool enabled,
    required bool integerOnly,
  }) {
    return SizedBox(
      width: 300,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.numberWithOptions(decimal: !integerOnly),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffixText,
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          helperText: 'Vide = valeur par defaut',
        ),
        validator: (value) => _validatePositiveNumber(
          value,
          integerOnly: integerOnly,
        ),
      ),
    );
  }

  Widget _buildPanelIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppConstants.primaryColor, size: 22),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(20),
        decoration: _panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger la configuration mobile.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return const Center(
      child: Text(
        'Acces non autorise.',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  BoxDecoration _panelDecoration({Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Future<void> _updateTenantPointageModes(
    Tenant tenant, {
    String? pointageMode,
    String? zoneChiefPointageMode,
  }) async {
    final tenantId = tenant.id.trim().toLowerCase();
    if (tenantId.isEmpty) return;

    final currentTenantId = AccessControl.currentTenantId.trim().toLowerCase();
    if (!AccessControl.canBypassTenantFilter && tenantId != currentTenantId) {
      _showSnackBar(
        'Votre profil ne peut modifier que son pays.',
        isError: true,
      );
      return;
    }

    final nextPointageMode = TenantPointageMode.normalize(
      pointageMode ?? tenant.pointageMode,
    );
    final nextZoneChiefPointageMode = TenantPointageMode.normalize(
      zoneChiefPointageMode ?? tenant.zoneChiefPointageMode,
    );

    if (nextPointageMode == tenant.pointageMode &&
        nextZoneChiefPointageMode == tenant.zoneChiefPointageMode) {
      return;
    }

    setState(() {
      _savingPointageTenantIds.add(tenantId);
    });

    try {
      await _tenantService.updatePointageModes(
        tenantId: tenantId,
        pointageMode: nextPointageMode,
        zoneChiefPointageMode: nextZoneChiefPointageMode,
      );
      if (!mounted) return;
      _showSnackBar('Modes de pointage mis a jour.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        'Erreur pendant la mise a jour des modes: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingPointageTenantIds.remove(tenantId);
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.saveConfig(_buildConfigFromForm());
      if (!mounted) return;
      _showSnackBar('Configuration mobile enregistree.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Erreur pendant l enregistrement: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remettre les valeurs par defaut ?'),
        content: const Text(
          'Les champs de configuration mobile seront supprimes de Firestore. Le mobile utilisera alors ses valeurs par defaut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Reinitialiser'),
          ),
        ],
      ),
    );

    if (!mounted || shouldReset != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.resetToDefaults();
      const config = MobileConfig.defaults();
      if (!mounted) return;
      _applyConfig(config);
      setState(() {
        _configFuture = Future<MobileConfig>.value(config);
      });
      _showSnackBar('Configuration mobile remise aux valeurs par defaut.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Erreur pendant la reinitialisation: $error',
          isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _reload() {
    setState(() {
      _configFuture = _loadConfig();
    });
  }

  MobileConfig _buildConfigFromForm() {
    return MobileConfig(
      backgroundTrackingEnabled: _backgroundTrackingEnabled,
      pointingPhotoQuality: _photoQuality.round(),
      pointingPhotoMaxWidth: _parseOptionalDouble(_maxWidthController.text),
      pointingPhotoMaxHeight: _parseOptionalDouble(_maxHeightController.text),
      pointingPhotoUploadTimeoutSeconds:
          _parseOptionalInt(_uploadTimeoutController.text),
    );
  }

  String? _validatePositiveNumber(
    String? value, {
    required bool integerOnly,
  }) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    final number = num.tryParse(text.replaceAll(',', '.'));
    if (number == null || number <= 0) {
      return 'Valeur positive attendue';
    }

    if (integerOnly && number.toDouble() % 1 != 0) {
      return 'Nombre entier attendu';
    }

    return null;
  }

  double? _parseOptionalDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  int? _parseOptionalInt(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parsed = num.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return null;
    return parsed.round();
  }

  String _formatOptionalDouble(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toString();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }
}
