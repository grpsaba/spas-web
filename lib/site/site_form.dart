import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/liste_selection_pages/supervisor_search_dialog.dart';
import 'package:spas_web/services/zone.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/site.dart';

class AddSite extends StatefulWidget {
  const AddSite({
    super.key,
    required this.site,
  });

  final Site site;

  @override
  State<AddSite> createState() => _AddSiteState();
}

class _AddSiteState extends State<AddSite> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _adresseCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _supervisorCtrl = TextEditingController();
  final TextEditingController _supervisor2Ctrl = TextEditingController();
  final TextEditingController _nbAgentCtrl = TextEditingController();
  final TextEditingController _nbRondeCtrl = TextEditingController();
  final TextEditingController _dateContratCtrl = TextEditingController();

  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final DateTime _identityTimestamp = DateTime.now();

  bool _obscurePass = true;
  bool _adding = false;
  bool _isTwoSupervisor = false;
  bool _codeWasEdited = false;
  bool _emailWasEdited = false;

  bool get _isEditing => widget.site.UID.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _isTwoSupervisor = widget.site.supervisor_2 != null;
    widget.site.pointageType = _normalizePointageType(widget.site.pointageType);

    final contractDate = widget.site.dateContrat ?? DateTime.now();
    widget.site.dateContrat = contractDate;

    _nameCtrl.text = widget.site.name;
    _codeCtrl.text = widget.site.codeSite;
    _emailCtrl.text = widget.site.email;
    _adresseCtrl.text = widget.site.adresse;
    _phoneCtrl.text = widget.site.phone;
    _latCtrl.text = widget.site.latLng.lat == 0
        ? ''
        : widget.site.latLng.lat.toString();
    _lngCtrl.text = widget.site.latLng.lng == 0
        ? ''
        : widget.site.latLng.lng.toString();
    _nbAgentCtrl.text =
        widget.site.nbAgent == 0 ? '' : widget.site.nbAgent.toString();
    _nbRondeCtrl.text =
        widget.site.nbRonde == null ? '' : widget.site.nbRonde.toString();
    _dateContratCtrl.text = _formatDate(contractDate);
    _passCtrl.text = _isEditing ? '' : '00000000';
    _supervisorCtrl.text = _supervisorName(widget.site.supervisor);
    _supervisor2Ctrl.text = _supervisorName(widget.site.supervisor_2);

    _codeWasEdited = _isEditing && _codeCtrl.text.trim().isNotEmpty;
    _emailWasEdited = _isEditing && _emailCtrl.text.trim().isNotEmpty;
    if (!_isEditing && _nameCtrl.text.trim().isNotEmpty) {
      _syncGeneratedIdentity(_nameCtrl.text);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _adresseCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _passCtrl.dispose();
    _supervisorCtrl.dispose();
    _supervisor2Ctrl.dispose();
    _nbAgentCtrl.dispose();
    _nbRondeCtrl.dispose();
    _dateContratCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 2,
      title: 'Gestion des sites -> Edition de site',
      child: Container(
        color: const Color(0xFFF6F7FB),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Form(
                key: _key,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FormHeader(isEditing: _isEditing),
                    const SizedBox(height: 16),
                    _FormSection(
                      icon: HugeIcons.strokeRoundedBuilding03,
                      title: 'Identite du site',
                      child: _ResponsiveFormGrid(
                        children: [
                          _buildNameField(),
                          _buildCodeField(),
                          _buildEmailField(),
                          _buildContractDateField(),
                          if (!_isEditing) _buildPasswordField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FormSection(
                      icon: HugeIcons.strokeRoundedLocationUser01,
                      title: 'Affectation',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSupervisorMode(),
                          const SizedBox(height: 14),
                          _ResponsiveFormGrid(
                            children: [
                              _buildZoneField(),
                              _buildSupervisorField(
                                controller: _supervisorCtrl,
                                label: 'Superviseur 1',
                                isRequired: true,
                                onSelected: (supervisor) {
                                  widget.site.supervisor = supervisor;
                                  _supervisorCtrl.text =
                                      _supervisorName(supervisor);
                                },
                              ),
                              if (_isTwoSupervisor)
                                _buildSupervisorField(
                                  controller: _supervisor2Ctrl,
                                  label: 'Superviseur 2',
                                  isRequired: false,
                                  onSelected: (supervisor) {
                                    widget.site.supervisor_2 = supervisor;
                                    _supervisor2Ctrl.text =
                                        _supervisorName(supervisor);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FormSection(
                      icon: HugeIcons.strokeRoundedCheckList,
                      title: 'Exploitation',
                      child: _ResponsiveFormGrid(
                        children: [
                          _buildPointageTypeField(),
                          _buildPhoneField(),
                          _buildAddressField(),
                          _buildAgentCountField(),
                          _buildRoundCountField(),
                          _buildLatitudeField(),
                          _buildLongitudeField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        widget.site.name = value;
        _syncGeneratedIdentity(value);
      },
      validator: (value) {
        return value != null && value.trim().isNotEmpty
            ? null
            : 'Nom obligatoir';
      },
      decoration: _fieldDecoration(
        label: 'Nom du site',
        icon: HugeIcons.strokeRoundedBuilding03,
      ),
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeCtrl,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        _codeWasEdited = true;
        widget.site.codeSite = value.trim();
      },
      validator: (value) {
        return value != null && value.trim().isNotEmpty
            ? null
            : 'Code obligatoir';
      },
      decoration: _fieldDecoration(
        label: 'Code',
        icon: HugeIcons.strokeRoundedQrCode,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      readOnly: _isEditing,
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        _emailWasEdited = true;
        widget.site.email = value.trim();
      },
      validator: (value) {
        return EmailValidator.validate(value ?? '') ? null : 'Email invalide';
      },
      decoration: _fieldDecoration(
        label: 'Email',
        icon: HugeIcons.strokeRoundedMail01,
      ),
    );
  }

  Widget _buildContractDateField() {
    return TextFormField(
      readOnly: true,
      controller: _dateContratCtrl,
      onTap: _pickContractDate,
      validator: (value) {
        return _parseDate(value) == null
            ? 'Date du contrat obligatoir'
            : null;
      },
      decoration: _fieldDecoration(
        label: 'Date du contrat',
        icon: HugeIcons.strokeRoundedCalendar03,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      obscureText: _obscurePass,
      controller: _passCtrl,
      validator: (value) {
        return value != null && value.trim().isNotEmpty
            ? null
            : 'Mot de passe obligatoir';
      },
      decoration: _fieldDecoration(
        label: 'Mot de passe',
        icon: HugeIcons.strokeRoundedLockPassword,
        suffixIcon: IconButton(
          tooltip: _obscurePass ? 'Afficher' : 'Masquer',
          onPressed: () {
            setState(() {
              _obscurePass = !_obscurePass;
            });
          },
          icon: Icon(
            _obscurePass
                ? HugeIcons.strokeRoundedView
                : HugeIcons.strokeRoundedViewOff,
          ),
        ),
      ),
    );
  }

  Widget _buildSupervisorMode() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              HugeIcons.strokeRoundedLocationUser01,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isTwoSupervisor ? 'Deux superviseurs' : 'Un superviseur',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Switch(
            value: _isTwoSupervisor,
            onChanged: (value) {
              setState(() {
                _isTwoSupervisor = value;
                if (!value) {
                  widget.site.supervisor_2 = null;
                  _supervisor2Ctrl.clear();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildZoneField() {
    return StreamBuilder(
      stream: ZoneService().all(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 56,
            alignment: Alignment.centerLeft,
            child: Loading(size: 28, inline: true),
          );
        }

        final zones = snapshot.data?.docs
                .map((e) => Zone.fromJson(e.data() as Map<String, dynamic>))
                .toList() ??
            <Zone>[];
        final selectedZone = _findSelectedZone(zones);

        return DropdownButtonFormField<Zone>(
          value: selectedZone,
          hint: const Text('Zone'),
          decoration: _fieldDecoration(
            label: 'Zone',
            icon: HugeIcons.strokeRoundedMapsCircle01,
          ),
          validator: (value) {
            if (zones.isEmpty) return "Creez d'abord une zone";
            return value != null ? null : 'Zone obligatoir';
          },
          isExpanded: true,
          items: zones
              .map(
                (zone) => DropdownMenuItem<Zone>(
                  value: zone,
                  child: Text(zone.name),
                ),
              )
              .toList(),
          onChanged: zones.isEmpty
              ? null
              : (value) {
                  setState(() {
                    widget.site.zone = value;
                  });
                },
          onSaved: (value) {
            widget.site.zone = value;
          },
        );
      },
    );
  }

  Widget _buildSupervisorField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    required ValueChanged<Supervisor> onSelected,
  }) {
    return TextFormField(
      readOnly: true,
      controller: controller,
      onTap: () => _selectSupervisor(onSelected),
      validator: isRequired
          ? (_) {
              return widget.site.supervisor != null
                  ? null
                  : 'Superviseur obligatoir';
            }
          : null,
      decoration: _fieldDecoration(
        label: label,
        icon: HugeIcons.strokeRoundedLocationUser01,
      ),
    );
  }

  Widget _buildPointageTypeField() {
    return DropdownButtonFormField<String>(
      initialValue: _normalizePointageType(widget.site.pointageType),
      decoration: _fieldDecoration(
        label: 'Type de pointage',
        icon: HugeIcons.strokeRoundedCheckList,
      ),
      items: const [
        DropdownMenuItem(value: 'jour', child: Text('Jour')),
        DropdownMenuItem(value: 'nuit', child: Text('Nuit')),
        DropdownMenuItem(value: 'jour_nuit', child: Text('Jour / Nuit')),
      ],
      onChanged: (value) {
        widget.site.pointageType = _normalizePointageType(value);
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      keyboardType: TextInputType.phone,
      controller: _phoneCtrl,
      validator: (value) {
        return value != null && value.trim().isNotEmpty
            ? null
            : 'Contact obligatoir';
      },
      decoration: _fieldDecoration(
        label: 'Contact',
        icon: HugeIcons.strokeRoundedCall,
      ),
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _adresseCtrl,
      minLines: 1,
      maxLines: 2,
      validator: (value) {
        return value != null && value.trim().isNotEmpty
            ? null
            : 'Adresse obligatoir';
      },
      decoration: _fieldDecoration(
        label: 'Adresse',
        icon: HugeIcons.strokeRoundedPinLocation01,
      ),
    );
  }

  Widget _buildAgentCountField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: _nbAgentCtrl,
      validator: (value) {
        final count = int.tryParse(value ?? '');
        return count != null && count >= 0 ? null : 'Nombre agent invalide';
      },
      decoration: _fieldDecoration(
        label: 'Nombre agent prevus',
        icon: HugeIcons.strokeRoundedUserGroup,
      ),
    );
  }

  Widget _buildRoundCountField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: _nbRondeCtrl,
      validator: (value) {
        final count = int.tryParse(value ?? '');
        return count != null && count > 0 ? null : 'Nombre de ronde invalide';
      },
      decoration: _fieldDecoration(
        label: 'Nombre de ronde prevus',
        icon: HugeIcons.strokeRoundedRoute03,
      ),
    );
  }

  Widget _buildLatitudeField() {
    return TextFormField(
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      controller: _latCtrl,
      validator: (value) {
        final latitude = double.tryParse((value ?? '').replaceAll(',', '.'));
        return latitude != null ? null : 'Latitude invalide';
      },
      decoration: _fieldDecoration(
        label: 'Latitude',
        icon: HugeIcons.strokeRoundedGps01,
      ),
    );
  }

  Widget _buildLongitudeField() {
    return TextFormField(
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      controller: _lngCtrl,
      validator: (value) {
        final longitude = double.tryParse((value ?? '').replaceAll(',', '.'));
        return longitude != null ? null : 'Longitude invalide';
      },
      decoration: _fieldDecoration(
        label: 'Longitude',
        icon: HugeIcons.strokeRoundedGps01,
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _adding ? null : () => context.pop(),
          icon: const Icon(HugeIcons.strokeRoundedCancelCircle, size: 18),
          label: const Text('Annuler'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: _adding ? null : _submit,
          icon: _adding
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: Loading(size: 18, inline: true),
                )
              : const Icon(HugeIcons.strokeRoundedCheckmarkCircle01, size: 18),
          label: Text(_isEditing ? 'Mettre a jour' : 'Creer le site'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectSupervisor(ValueChanged<Supervisor> onSelected) async {
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          alignment: Alignment.center,
          contentPadding: EdgeInsets.zero,
          content: SupervisorSearchDialog(
            onSelected: (supervisor) {
              onSelected(supervisor);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _pickContractDate() async {
    final currentDate = _parseDate(_dateContratCtrl.text) ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(3000),
    );

    if (selectedDate == null) return;

    setState(() {
      widget.site.dateContrat = selectedDate;
      _dateContratCtrl.text = _formatDate(selectedDate);
    });
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;

    _applyFormToSite();
    setState(() {
      _adding = true;
    });

    try {
      if (_isEditing) {
        await SiteService().update(widget.site);
      } else {
        await SiteService().add(widget.site, _passCtrl.text.trim());
      }

      if (mounted) {
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
        });
      }
    }
  }

  void _applyFormToSite() {
    widget.site.codeSite = _codeCtrl.text.trim();
    widget.site.name = _nameCtrl.text.trim();
    widget.site.adresse = _adresseCtrl.text.trim();
    widget.site.email = _emailCtrl.text.trim();
    widget.site.phone = _phoneCtrl.text.trim();
    widget.site.nbAgent = int.parse(_nbAgentCtrl.text.trim());
    widget.site.nbRonde = int.parse(_nbRondeCtrl.text.trim());
    widget.site.dateContrat = _parseDate(_dateContratCtrl.text);
    widget.site.latLng.lat = double.parse(_latCtrl.text.replaceAll(',', '.'));
    widget.site.latLng.lng = double.parse(_lngCtrl.text.replaceAll(',', '.'));
    widget.site.pointageType = _normalizePointageType(widget.site.pointageType);
  }

  void _syncGeneratedIdentity(String siteName) {
    if (_isEditing) return;

    final slug = _normalizeIdentifier(siteName);
    if (slug.isEmpty) {
      if (!_codeWasEdited) {
        _codeCtrl.clear();
        widget.site.codeSite = '';
      }
      if (!_emailWasEdited) {
        _emailCtrl.clear();
        widget.site.email = '';
      }
      return;
    }

    final generatedCode = '$slug${_dateSuffix(_identityTimestamp)}';
    final generatedEmail = '$slug${_dateSuffix(_identityTimestamp)}@gmail.com';

    if (!_codeWasEdited) {
      _codeCtrl.text = generatedCode;
      widget.site.codeSite = generatedCode;
    }
    if (!_emailWasEdited) {
      _emailCtrl.text = generatedEmail;
      widget.site.email = generatedEmail;
    }
  }

  Zone? _findSelectedZone(List<Zone> zones) {
    final selectedCode = widget.site.zone?.codeZone.trim();
    if (selectedCode == null || selectedCode.isEmpty) return null;

    for (final zone in zones) {
      if (zone.codeZone == selectedCode) return zone;
    }

    return null;
  }

  String _normalizePointageType(String? value) {
    switch (value) {
      case 'jour':
      case 'nuit':
      case 'jour_nuit':
        return value!;
      case 'jour-nuit':
      case 'jour/nuit':
        return 'jour_nuit';
      default:
        return 'jour';
    }
  }

  String _normalizeIdentifier(String value) {
    var text = value.trim().toLowerCase();
    const replacements = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'œ': 'oe',
    };
    replacements.forEach((source, replacement) {
      text = text.replaceAll(source, replacement);
    });
    return text.replaceAll(RegExp('[^a-z0-9]'), '');
  }

  String _dateSuffix(DateTime value) {
    return '${_twoDigits(value.day)}${_twoDigits(value.month)}${value.year}';
  }

  String _formatDate(DateTime value) {
    return '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';
  }

  DateTime? _parseDate(String? value) {
    final parts = (value ?? '').split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _supervisorName(Supervisor? supervisor) {
    if (supervisor == null) return '';
    return '${supervisor.firstName} ${supervisor.lastName}'.trim();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            HugeIcons.strokeRoundedBuilding03,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Modifier le site' : 'Nouveau site',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Informations, affectation et parametres de pointage',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFormGrid extends StatelessWidget {
  const _ResponsiveFormGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 760;
        final width = twoColumns
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
