import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/services/authentication.dart';

import '../model.dart';
import '../pointage_redesign/presentation/design_system.dart';
import '../services/access_control.dart';
import '../services/department.dart';
import '../services/loading.dart';
import '../services/supervisor.dart';
import '../services/tenant_options.dart';

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
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  bool _obscurePass = true;
  bool _adding = false;
  bool _loadingTenants = true;
  List<Tenant> _tenants = TenantOptions.fallback;
  String? _selectedTenantId;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.supervisor.email;
    _codeCtrl.text = widget.supervisor.code;
    _firstNameCtrl.text = widget.supervisor.firstName;
    _lastNameCtrl.text = widget.supervisor.lastName;
    _phoneCtrl.text = widget.supervisor.phone;
    _passCtrl.text = widget.supervisor.code;
    _selectedTenantId =
        widget.supervisor.hasTenantId ? widget.supervisor.tenantId : null;
    if (!AccessControl.canBypassTenantFilter) {
      _selectedTenantId = AccessControl.currentTenantId;
    }
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    final tenants = await TenantOptions.load(includeTenantId: _selectedTenantId);
    if (!mounted) return;

    setState(() {
      _tenants = AccessControl.canBypassTenantFilter
          ? tenants
          : tenants
              .where((tenant) => tenant.id == AccessControl.currentTenantId)
              .toList();
      if (_tenants.isEmpty) {
        _tenants = [
          Tenant(
            id: AccessControl.currentTenantId,
            label: AccessControl.currentTenantId.toUpperCase(),
            countryCode: AccessControl.currentTenantId.toUpperCase(),
          ),
        ];
      }
      _loadingTenants = false;
    });
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

  InputDecoration _decoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return PointageInputDecorations.standard(
      hintText: hintText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
    );
  }

  void _copyControllersToModel() {
    widget.supervisor.code = _codeCtrl.text;
    widget.supervisor.firstName = _firstNameCtrl.text;
    widget.supervisor.lastName = _lastNameCtrl.text;
    widget.supervisor.email = _emailCtrl.text;
    widget.supervisor.phone = _phoneCtrl.text;
    final tenantId = _selectedTenantId?.trim();
    widget.supervisor.hasTenantId = tenantId != null && tenantId.isNotEmpty;
    if (widget.supervisor.hasTenantId) {
      widget.supervisor.tenantId = tenantId!;
    }
  }

  Future<void> _submit() async {
    _copyControllersToModel();

    if (!_key.currentState!.validate()) {
      return;
    }

    setState(() {
      _adding = true;
    });

    try {
      if (widget.supervisor.UID.isEmpty) {
        final created =
            await SupervisorService().add(widget.supervisor, _passCtrl.text);
        if (created == null) {
          throw Exception('Impossible de créer le superviseur');
        }
      } else {
        await SupervisorService().update(widget.supervisor);
      }

      if (!mounted) {
        return;
      }

      widget.onChanged?.call();

      if (widget.closeAfterSubmit) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Superviseur enregistré avec succès')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
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

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirmer la suppression'),
              content: Text(
                'Supprimer ${widget.supervisor.firstName} ${widget.supervisor.lastName} ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PointageColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Supprimer'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _delete() async {
    final confirmed = await _confirmDelete();
    if (!confirmed) {
      return;
    }

    setState(() {
      _adding = true;
    });

    try {
      await SupervisorService().delete(widget.supervisor);

      if (!mounted) {
        return;
      }

      widget.onChanged?.call();

      if (widget.closeAfterSubmit) {
        context.pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
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

  Widget _buildDepartmentField() {
    return StreamBuilder(
      stream: DepartmentService().all(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Loading(size: 28, inline: true);
        }

        final departments = snapshot.data?.docs
                .map(DepartmentService.fromSnapshot)
                .toList() ??
            [];

        Department? initialDepartment;
        if (widget.supervisor.department != null) {
          for (final department in departments) {
            if (department.id == widget.supervisor.department!.id ||
                department.label == widget.supervisor.department!.label) {
              initialDepartment = department;
              break;
            }
          }
        }

        return DropdownButtonFormField<Department>(
          initialValue: initialDepartment,
          hint: const Text('Département'),
          decoration:
              _decoration(hintText: 'Département', icon: Icons.apartment),
          validator: (value) {
            return value != null ? null : 'Département obligatoir';
          },
          isExpanded: true,
          items: departments
              .map(
                (Department department) => DropdownMenuItem<Department>(
                  value: department,
                  child: Text(department.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            widget.supervisor.department = value;
          },
          onSaved: (value) {
            widget.supervisor.department = value;
          },
        );
      },
    );
  }

  Widget _buildTenantField() {
    if (_loadingTenants) {
      return Loading(size: 28, inline: true);
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedTenantId,
      hint: const Text('Pays'),
      decoration: _decoration(hintText: 'Pays', icon: Icons.public),
      validator: (value) {
        return value != null && value.trim().isNotEmpty
            ? null
            : 'Pays obligatoir';
      },
      isExpanded: true,
      items: _tenants
          .map(
            (tenant) => DropdownMenuItem<String>(
              value: tenant.id,
              child: Text(tenant.label),
            ),
          )
          .toList(),
      onChanged: AccessControl.canBypassTenantFilter
          ? (value) {
              setState(() {
                _selectedTenantId = value;
              });
            }
          : null,
      onSaved: (value) {
        _selectedTenantId = value;
      },
    );
  }

  Widget _buildActionButtons() {
    final canDelete = widget.supervisor.UID.isNotEmpty &&
        AuthService.currentManager!.profil!
            .getModule(ModuleName.SUPERVISEUR)!
            .delete;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!widget.embedded) ...[
          OutlinedButton.icon(
            onPressed: _adding ? null : () => context.pop(),
            icon: const Icon(Icons.close),
            label: const Text('Annuler'),
            style: PointageButtonStyles.outlined,
          ),
          const SizedBox(width: PointageSpacing.md),
        ],
        if (canDelete) ...[
          ElevatedButton.icon(
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
            onPressed: _adding ? null : _delete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Supprimer'),
          ),
          const SizedBox(width: PointageSpacing.md),
        ],
        ElevatedButton.icon(
          style: PointageButtonStyles.primary,
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
              : const Icon(Icons.check_circle),
          label: Text(_adding ? 'Enregistrement...' : 'Valider'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        widget.embedded ? 0.0 : MediaQuery.of(context).size.width * 0.1;

    final content = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(PointageSpacing.lg),
          decoration: PointageCardDecorations.standard,
          child: Form(
            key: _key,
            child: Column(
              children: [
                _buildDepartmentField(),
                const SizedBox(height: PointageSpacing.md),
                _buildTenantField(),
                const SizedBox(height: PointageSpacing.md),
                TextFormField(
                  readOnly: widget.supervisor.code.isNotEmpty,
                  controller: _codeCtrl,
                  onChanged: (value) => widget.supervisor.code = value,
                  validator: (value) {
                    return value!.isNotEmpty ? null : 'Code obligatoir';
                  },
                  decoration: _decoration(hintText: 'Code', icon: Icons.badge),
                ),
                const SizedBox(height: PointageSpacing.md),
                TextFormField(
                  controller: _firstNameCtrl,
                  onChanged: (value) => widget.supervisor.firstName = value,
                  validator: (value) {
                    return value!.isNotEmpty ? null : 'Prénom obligatoir';
                  },
                  decoration:
                      _decoration(hintText: 'Prénom', icon: Icons.person),
                ),
                const SizedBox(height: PointageSpacing.md),
                TextFormField(
                  controller: _lastNameCtrl,
                  onChanged: (value) => widget.supervisor.lastName = value,
                  validator: (value) {
                    return value!.isNotEmpty ? null : 'Nom obligatoir';
                  },
                  decoration:
                      _decoration(hintText: 'Nom', icon: Icons.person_outline),
                ),
                const SizedBox(height: PointageSpacing.md),
                TextFormField(
                  keyboardType: TextInputType.phone,
                  controller: _phoneCtrl,
                  onChanged: (value) => widget.supervisor.phone = value,
                  validator: (value) {
                    return value!.isNotEmpty ? null : 'Téléphone obligatoir';
                  },
                  decoration: _decoration(
                    hintText: 'Téléphone',
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: PointageSpacing.md),
                TextFormField(
                  readOnly: widget.supervisor.email.isNotEmpty,
                  controller: _emailCtrl,
                  onChanged: (value) => widget.supervisor.email = value,
                  validator: (value) {
                    return EmailValidator.validate(value!)
                        ? null
                        : 'email obligatoir';
                  },
                  decoration: _decoration(
                    hintText: 'Email',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: PointageSpacing.md),
                if (widget.supervisor.UID.isEmpty)
                  TextFormField(
                    obscureText: _obscurePass,
                    controller: _passCtrl,
                    validator: (value) {
                      return value!.isNotEmpty
                          ? null
                          : 'mot de passe obligatoir';
                    },
                    decoration: _decoration(
                      hintText: 'Mot de passe',
                      icon: Icons.lock_outline,
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
                const SizedBox(height: PointageSpacing.lg),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return PageModel(
      pageIndex: 4,
      title: 'Gestion superviseurs -> Edition superviseur',
      child: content,
    );
  }
}
