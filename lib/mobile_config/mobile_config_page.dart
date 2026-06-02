import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/access_control.dart';
import 'package:spas_web/services/mobile_config.dart';

class MobileConfigPage extends StatefulWidget {
  const MobileConfigPage({super.key});

  @override
  State<MobileConfigPage> createState() => _MobileConfigPageState();
}

class _MobileConfigPageState extends State<MobileConfigPage> {
  static const int _pageIndex = 19;

  final MobileConfigService _service = MobileConfigService();
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
                _buildHeader(canEdit),
                const SizedBox(height: 16),
                if (!canEdit) ...[
                  _buildReadOnlyNotice(),
                  const SizedBox(height: 16),
                ],
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

  Widget _buildReadOnlyNotice() {
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
          const Expanded(
            child: Text(
              'Votre profil peut consulter cette configuration, mais ne peut pas la modifier.',
              style: TextStyle(fontWeight: FontWeight.w500),
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
                  'Absent ou non configure: actif par defaut sur mobile.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: _backgroundTrackingEnabled,
            onChanged: canEdit && !_isSaving
                ? (value) {
                    setState(() {
                      _backgroundTrackingEnabled = value;
                    });
                  }
                : null,
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
