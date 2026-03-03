import 'dart:convert';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../services/department.dart';
import '../services/supervisor.dart';

class AddSupervisor extends StatefulWidget {
  const AddSupervisor({
    super.key,
    required this.supervisor,
    this.embedded = false,
    this.closeAfterSubmit = true,
    this.onChanged,
  });

  final Supervisor supervisor;
  final bool embedded;
  final bool closeAfterSubmit;
  final VoidCallback? onChanged;

  @override
  State<AddSupervisor> createState() => _AddSupervisorState();
}

class _AddSupervisorState extends State<AddSupervisor> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePass = true;
  bool _adding = false;
  Department? _selectedDepartment;

  bool get _isNewSupervisor => widget.supervisor.UID.isEmpty;

  @override
  void initState() {
    super.initState();
    _syncControllersFromSupervisor();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _codeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _syncControllersFromSupervisor() {
    _emailCtrl.text = widget.supervisor.email;
    _codeCtrl.text = widget.supervisor.code;
    _firstNameCtrl.text = widget.supervisor.firstName;
    _lastNameCtrl.text = widget.supervisor.lastName;
    _phoneCtrl.text = widget.supervisor.phone;
    _passCtrl.text = widget.supervisor.code;
    _selectedDepartment = widget.supervisor.department;
  }

  void _syncSupervisorFromControllers() {
    widget.supervisor.code = _codeCtrl.text.trim();
    widget.supervisor.firstName = _firstNameCtrl.text.trim();
    widget.supervisor.lastName = _lastNameCtrl.text.trim();
    widget.supervisor.email = _emailCtrl.text.trim();
    widget.supervisor.phone = _phoneCtrl.text.trim();
    widget.supervisor.department = _selectedDepartment;
  }

  void _onLocalCancel() {
    FocusScope.of(context).unfocus();
    if (widget.embedded) {
      setState(_syncControllersFromSupervisor);
      return;
    }
    context.pop();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Département obligatoir')),
      );
      return;
    }

    final creating = _isNewSupervisor;
    _syncSupervisorFromControllers();

    setState(() {
      _adding = true;
    });

    try {
      if (creating) {
        await SupervisorService().add(widget.supervisor, _passCtrl.text.trim());
      } else {
        await SupervisorService().update(widget.supervisor);
      }

      if (!mounted) return;

      widget.onChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            creating
                ? 'Superviseur créé avec succès'
                : 'Superviseur mis à jour avec succès',
          ),
        ),
      );

      if (widget.closeAfterSubmit) {
        context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Supprimer ce superviseur ?'),
              content: const Text(
                'Cette action est irréversible. Voulez-vous continuer ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Supprimer',
                    style: TextStyle(color: PointageColors.error),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() {
      _adding = true;
    });

    try {
      await SupervisorService().delete(widget.supervisor);

      if (!mounted) return;

      widget.onChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Superviseur supprimé avec succès')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      setState(() {
        _adding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isNewSupervisor
        ? 'Gestion superviseurs -> Nouveau superviseur'
        : 'Gestion superviseurs -> Edition superviseur';

    if (widget.embedded) {
      return _buildFormLayout(context);
    }

    return PageModel(
      pageIndex: 4,
      title: title,
      child: _buildFormLayout(context),
    );
  }

  Widget _buildFormLayout(BuildContext context) {
    final horizontalPadding = widget.embedded
        ? PointageSpacing.md
        : (MediaQuery.of(context).size.width * 0.1)
            .clamp(PointageSpacing.lg, 180.0)
            .toDouble();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: PointageSpacing.md,
        bottom: PointageSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(PointageSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: PointageBorderRadius.large,
            border: Border.all(color: PointageColors.divider),
            boxShadow: PointageShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_adding) const LinearProgressIndicator(),
              if (_adding) const SizedBox(height: PointageSpacing.md),
              _buildDepartmentField(),
              const SizedBox(height: PointageSpacing.md),
              _buildTextField(
                controller: _codeCtrl,
                hintText: 'Code',
                prefixIcon: const Icon(Icons.badge_outlined),
                validator: (value) =>
                    value != null && value.trim().isNotEmpty
                        ? null
                        : 'Code obligatoir',
                readOnly: !_isNewSupervisor,
              ),
              const SizedBox(height: PointageSpacing.md),
              _buildTextField(
                controller: _firstNameCtrl,
                hintText: 'Prénom',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) =>
                    value != null && value.trim().isNotEmpty
                        ? null
                        : 'Prénom obligatoir',
              ),
              const SizedBox(height: PointageSpacing.md),
              _buildTextField(
                controller: _lastNameCtrl,
                hintText: 'Nom',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) =>
                    value != null && value.trim().isNotEmpty
                        ? null
                        : 'Nom obligatoir',
              ),
              const SizedBox(height: PointageSpacing.md),
              _buildTextField(
                controller: _phoneCtrl,
                hintText: 'Téléphone',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value != null && value.trim().isNotEmpty
                        ? null
                        : 'Téléphone obligatoir',
              ),
              const SizedBox(height: PointageSpacing.md),
              _buildTextField(
                controller: _emailCtrl,
                hintText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                readOnly: !_isNewSupervisor,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'email obligatoir';
                  }
                  return EmailValidator.validate(value.trim())
                      ? null
                      : 'email obligatoir';
                },
              ),
              if (_isNewSupervisor) ...[
                const SizedBox(height: PointageSpacing.md),
                TextFormField(
                  obscureText: _obscurePass,
                  controller: _passCtrl,
                  validator: (value) {
                    return value != null && value.trim().isNotEmpty
                        ? null
                        : 'mot de passe obligatoir';
                  },
                  decoration: PointageInputDecorations.standard(
                    hintText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePass = !_obscurePass;
                        });
                      },
                      icon: Icon(
                        _obscurePass
                            ? Icons.remove_red_eye
                            : Icons.remove_red_eye_outlined,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: PointageSpacing.lg),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentField() {
    return StreamBuilder(
      stream: DepartmentService().all(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Chargement des départements en cours...');
        }

        final docs = snapshot.data?.docs
                .map((e) => jsonDecode(jsonEncode(e.data())) as Map<String, dynamic>)
                .toList() ??
            [];

        final departments = docs.map((e) => Department.fromJson(e)).toList();

        Department? currentDepartment;
        if (_selectedDepartment != null) {
          for (final department in departments) {
            if (department.label == _selectedDepartment!.label) {
              currentDepartment = department;
              break;
            }
          }
        }

        return DropdownButtonFormField<Department>(
          hint: const Text('Département'),
          decoration: PointageInputDecorations.standard(
            hintText: 'Département',
            prefixIcon: const Icon(Icons.apartment_outlined),
          ),
          validator: (value) {
            return value != null ? null : 'Département obligatoir';
          },
          isExpanded: true,
          initialValue: currentDepartment,
          items: departments
              .map((department) => DropdownMenuItem<Department>(
                    value: department,
                    child: Text(department.label),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedDepartment = value;
              widget.supervisor.department = value;
            });
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Widget prefixIcon,
    required String? Function(String?) validator,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      readOnly: readOnly,
      keyboardType: keyboardType,
      controller: controller,
      validator: validator,
      decoration: PointageInputDecorations.standard(
        hintText: hintText,
        prefixIcon: prefixIcon,
      ),
    );
  }

  Widget _buildActionButtons() {
    final canDelete = !_isNewSupervisor &&
        AuthService.currentManager!.profil!
            .getModule(ModuleName.SUPERVISEUR)!
            .delete;

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: PointageSpacing.sm,
      runSpacing: PointageSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: _adding ? null : _onLocalCancel,
          icon: const Icon(Icons.close),
          label: const Text('Annuler'),
          style: PointageButtonStyles.outlined,
        ),
        if (canDelete)
          ElevatedButton.icon(
            onPressed: _adding ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PointageColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: PointageSpacing.lg,
                vertical: PointageSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: PointageBorderRadius.medium,
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _adding ? null : _submit,
          icon: _adding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(_adding ? 'Validation...' : 'Valider'),
          style: PointageButtonStyles.primary,
        ),
      ],
    );
  }
}
