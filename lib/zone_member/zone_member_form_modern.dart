import 'dart:convert';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';
import 'package:spas_web/pointage_redesign/presentation/widgets/success_snackbar.dart';
import 'package:spas_web/pointage_redesign/presentation/dialogs/modern_dialog.dart';

import '../model.dart';
import '../services/zone.dart';
import '../services/zoneMember.dart';

/// Modern zone member form with design system
/// Implements Requirements 7.1-7.7
class ZoneMemberFormModern extends StatefulWidget {
  final ZoneMember zoneMember;

  const ZoneMemberFormModern({super.key, required this.zoneMember});

  @override
  State<ZoneMemberFormModern> createState() => _ZoneMemberFormModernState();
}

class _ZoneMemberFormModernState extends State<ZoneMemberFormModern> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _postCtrl = TextEditingController();
  
  // State
  bool _obscurePass = true;
  bool _isSubmitting = false;
  Zone? _selectedZone;
  List<String> _validationErrors = [];
  
  // Animation state for sections
  bool _personalInfoExpanded = true;
  bool _assignmentExpanded = true;
  bool _contactExpanded = true;
  bool _authExpanded = true;

  bool get _isNewMember => widget.zoneMember.UID.isEmpty;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _postCtrl.text = widget.zoneMember.poste ?? '';
    _emailCtrl.text = widget.zoneMember.email;
    _codeCtrl.text = widget.zoneMember.code;
    _firstNameCtrl.text = widget.zoneMember.firstName;
    _lastNameCtrl.text = widget.zoneMember.lastName;
    _phoneCtrl.text = widget.zoneMember.phone;
    _passCtrl.text = widget.zoneMember.code;
    _selectedZone = widget.zoneMember.zone;
  }

  @override
  void dispose() {
    _postCtrl.dispose();
    _phoneCtrl.dispose();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _codeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName obligatoire';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email obligatoire';
    }
    if (!EmailValidator.validate(value)) {
      return 'Email invalide';
    }
    return null;
  }

  void _collectValidationErrors() {
    _validationErrors.clear();
    
    if (_selectedZone == null) {
      _validationErrors.add('Zone obligatoire');
    }
    if (_codeCtrl.text.trim().isEmpty) {
      _validationErrors.add('Code obligatoire');
    }
    if (_firstNameCtrl.text.trim().isEmpty) {
      _validationErrors.add('Prénom obligatoire');
    }
    if (_lastNameCtrl.text.trim().isEmpty) {
      _validationErrors.add('Nom obligatoire');
    }
    if (_postCtrl.text.trim().isEmpty) {
      _validationErrors.add('Poste obligatoire');
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _validationErrors.add('Téléphone obligatoire');
    }
    if (!EmailValidator.validate(_emailCtrl.text)) {
      _validationErrors.add('Email invalide');
    }
    if (_isNewMember && _passCtrl.text.trim().isEmpty) {
      _validationErrors.add('Mot de passe obligatoire');
    }
  }

  Future<void> _submit() async {
    _collectValidationErrors();
    
    if (!_formKey.currentState!.validate() || _validationErrors.isNotEmpty) {
      setState(() {});
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationErrors.clear();
    });

    // Update zone member data
    widget.zoneMember.zone = _selectedZone;
    widget.zoneMember.poste = _postCtrl.text;
    widget.zoneMember.code = _codeCtrl.text;
    widget.zoneMember.firstName = _firstNameCtrl.text;
    widget.zoneMember.lastName = _lastNameCtrl.text;
    widget.zoneMember.email = _emailCtrl.text;
    widget.zoneMember.phone = _phoneCtrl.text;

    try {
      if (_isNewMember) {
        await ZoneMemberService().add(widget.zoneMember, _passCtrl.text);
      } else {
        await ZoneMemberService().update(widget.zoneMember);
      }

      if (!mounted) return;

      SuccessSnackbar.show(
        context,
        message: _isNewMember
            ? 'Chef de zone créé avec succès'
            : 'Chef de zone mis à jour avec succès',
        icon: Icons.check_circle,
      );

      context.pop();
    } catch (error) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: PointageColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await ModernDialog.show<bool>(
      context: context,
      title: 'Supprimer le chef de zone',
      content: Text(
        'Êtes-vous sûr de vouloir supprimer ${widget.zoneMember.firstName} ${widget.zoneMember.lastName} ?\n\nCette action est irréversible.',
        style: PointageTextStyles.body1,
      ),
      actions: [
        DialogAction(
          label: 'Annuler',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DialogAction(
          label: 'Supprimer',
          isDestructive: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ZoneMemberService().delete(widget.zoneMember);

      if (!mounted) return;

      SuccessSnackbar.show(
        context,
        message: 'Chef de zone supprimé avec succès',
        icon: Icons.delete,
      );

      context.pop();
    } catch (error) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: PointageColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 16,
      title: _isNewMember ? "Nouveau chef de zone" : "Modifier chef de zone",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Validation errors summary
              if (_validationErrors.isNotEmpty) ...[
                _buildErrorSummary(),
                const SizedBox(height: PointageSpacing.lg),
              ],
              
              // Personal Information Section
              _buildSectionCard(
                title: 'Informations personnelles',
                icon: Icons.person_outline,
                isExpanded: _personalInfoExpanded,
                onToggle: () => setState(() => _personalInfoExpanded = !_personalInfoExpanded),
                children: [
                  _buildFormRow([
                    _buildTextField(
                      controller: _firstNameCtrl,
                      label: 'Prénom',
                      icon: Icons.person,
                      validator: (v) => _requiredValidator(v, 'Prénom'),
                    ),
                    _buildTextField(
                      controller: _lastNameCtrl,
                      label: 'Nom',
                      icon: Icons.person,
                      validator: (v) => _requiredValidator(v, 'Nom'),
                    ),
                  ]),
                  _buildTextField(
                    controller: _codeCtrl,
                    label: 'Code',
                    icon: Icons.badge,
                    readOnly: !_isNewMember,
                    validator: (v) => _requiredValidator(v, 'Code'),
                  ),
                ],
              ),
              
              const SizedBox(height: PointageSpacing.lg),
              
              // Assignment Section
              _buildSectionCard(
                title: 'Affectation',
                icon: Icons.location_on_outlined,
                isExpanded: _assignmentExpanded,
                onToggle: () => setState(() => _assignmentExpanded = !_assignmentExpanded),
                children: [
                  _buildZoneDropdown(),
                  const SizedBox(height: PointageSpacing.md),
                  _buildTextField(
                    controller: _postCtrl,
                    label: 'Poste',
                    icon: Icons.work_outline,
                    validator: (v) => _requiredValidator(v, 'Poste'),
                  ),
                ],
              ),
              
              const SizedBox(height: PointageSpacing.lg),
              
              // Contact Section
              _buildSectionCard(
                title: 'Contact',
                icon: Icons.contact_phone_outlined,
                isExpanded: _contactExpanded,
                onToggle: () => setState(() => _contactExpanded = !_contactExpanded),
                children: [
                  _buildTextField(
                    controller: _phoneCtrl,
                    label: 'Téléphone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => _requiredValidator(v, 'Téléphone'),
                  ),
                  _buildTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: !_isNewMember,
                    validator: _emailValidator,
                  ),
                ],
              ),
              
              // Authentication Section (only for new members)
              if (_isNewMember) ...[
                const SizedBox(height: PointageSpacing.lg),
                _buildSectionCard(
                  title: 'Authentification',
                  icon: Icons.lock_outline,
                  isExpanded: _authExpanded,
                  onToggle: () => setState(() => _authExpanded = !_authExpanded),
                  children: [
                    _buildPasswordField(),
                  ],
                ),
              ],
              
              const SizedBox(height: PointageSpacing.xl),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildErrorSummary() {
    return AnimatedContainer(
      duration: PointageAnimations.normal,
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: BoxDecoration(
        color: PointageColors.error.withValues(alpha: 0.1),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: PointageColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: PointageColors.error,
                size: PointageIconSizes.sm,
              ),
              const SizedBox(width: PointageSpacing.sm),
              Text(
                'Veuillez corriger les erreurs suivantes:',
                style: PointageTextStyles.body2.copyWith(
                  color: PointageColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          ...(_validationErrors.map((error) => Padding(
            padding: const EdgeInsets.only(left: PointageSpacing.lg, top: PointageSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: PointageColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: PointageSpacing.sm),
                Text(
                  error,
                  style: PointageTextStyles.caption.copyWith(
                    color: PointageColors.error,
                  ),
                ),
              ],
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return AnimatedContainer(
      duration: PointageAnimations.normal,
      curve: PointageAnimations.defaultCurve,
      decoration: PointageCardDecorations.standard,
      child: Column(
        children: [
          // Section header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(PointageBorderRadius.lg),
              topRight: Radius.circular(PointageBorderRadius.lg),
              bottomLeft: Radius.circular(isExpanded ? 0 : PointageBorderRadius.lg),
              bottomRight: Radius.circular(isExpanded ? 0 : PointageBorderRadius.lg),
            ),
            child: Container(
              padding: const EdgeInsets.all(PointageSpacing.md),
              decoration: BoxDecoration(
                color: PointageColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(PointageBorderRadius.lg),
                  topRight: Radius.circular(PointageBorderRadius.lg),
                  bottomLeft: Radius.circular(isExpanded ? 0 : PointageBorderRadius.lg),
                  bottomRight: Radius.circular(isExpanded ? 0 : PointageBorderRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(PointageSpacing.sm),
                    decoration: BoxDecoration(
                      color: PointageColors.primary,
                      borderRadius: PointageBorderRadius.small,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: PointageIconSizes.sm,
                    ),
                  ),
                  const SizedBox(width: PointageSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      style: PointageTextStyles.headline4,
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: PointageAnimations.fast,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: PointageColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Section content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.all(PointageSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: PointageAnimations.normal,
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PointageSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((child) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: children.indexOf(child) < children.length - 1
                  ? PointageSpacing.md
                  : 0,
            ),
            child: child,
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PointageSpacing.md),
      child: _AnimatedFormField(
        child: TextFormField(
          controller: controller,
          decoration: PointageInputDecorations.standard(
            labelText: label,
            prefixIcon: Icon(icon),
          ).copyWith(
            filled: readOnly,
            fillColor: readOnly ? PointageColors.background : null,
          ),
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: PointageSpacing.md),
      child: _AnimatedFormField(
        child: TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          decoration: PointageInputDecorations.standard(
            labelText: 'Mot de passe',
            prefixIcon: const Icon(Icons.lock),
          ).copyWith(
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePass = !_obscurePass;
                });
              },
              icon: Icon(
                _obscurePass ? Icons.visibility : Icons.visibility_off,
                color: PointageColors.textSecondary,
              ),
            ),
          ),
          validator: (value) {
            if (_isNewMember && (value == null || value.trim().isEmpty)) {
              return 'Mot de passe obligatoire';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildZoneDropdown() {
    return _AnimatedFormField(
      child: StreamBuilder(
        stream: ZoneService().all(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              padding: const EdgeInsets.all(PointageSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: PointageColors.divider),
                borderRadius: PointageBorderRadius.medium,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: PointageSpacing.md),
                  Text(
                    'Chargement des zones...',
                    style: PointageTextStyles.body2.copyWith(
                      color: PointageColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs
              .map((e) => jsonDecode(jsonEncode(e.data())))
              .toList();
          final zones = docs?.map((e) => Zone.fromJson(e)).toList() ?? [];

          // Find the currently selected zone in the list
          Zone? currentZone;
          if (_selectedZone != null) {
            try {
              currentZone = zones.firstWhere(
                (z) => z.codeZone == _selectedZone!.codeZone,
              );
            } catch (_) {
              currentZone = null;
            }
          }

          return DropdownButtonFormField<Zone>(
            decoration: PointageInputDecorations.standard(
              labelText: 'Zone',
              prefixIcon: const Icon(Icons.location_city),
            ),
            value: currentZone,
            isExpanded: true,
            items: zones.map((Zone zone) => DropdownMenuItem<Zone>(
              value: zone,
              child: Text(zone.name),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedZone = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Zone obligatoire';
              }
              return null;
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    final canDelete = !_isNewMember &&
        AuthService.currentManager?.profil
            ?.getModule(ModuleName.SUPERVISEUR)
            ?.delete == true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel button
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : () => context.pop(),
          icon: const Icon(Icons.close),
          label: const Text('Annuler'),
          style: PointageButtonStyles.outlined,
        ),
        
        const SizedBox(width: PointageSpacing.md),
        
        // Delete button (only for existing members with permission)
        if (canDelete) ...[
          _HoverButton(
            onPressed: _isSubmitting ? null : _confirmDelete,
            isDestructive: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline, size: 18),
                const SizedBox(width: PointageSpacing.sm),
                const Text('Supprimer'),
              ],
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
        ],
        
        // Submit button
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(_isSubmitting ? 'Enregistrement...' : 'Valider'),
          style: PointageButtonStyles.primary,
        ),
      ],
    );
  }
}


/// Animated form field with glass smooth hover effect
class _AnimatedFormField extends StatefulWidget {
  final Widget child;

  const _AnimatedFormField({required this.child});

  @override
  State<_AnimatedFormField> createState() => _AnimatedFormFieldState();
}

class _AnimatedFormFieldState extends State<_AnimatedFormField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: PointageAnimations.fast,
        curve: PointageAnimations.defaultCurve,
        transform: Matrix4.identity()..scale(_isHovered ? 1.01 : 1.0),
        child: widget.child,
      ),
    );
  }
}

/// Hover button with glass smooth effect
class _HoverButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isDestructive;

  const _HoverButton({
    required this.onPressed,
    required this.child,
    this.isDestructive = false,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDestructive
        ? PointageColors.error
        : PointageColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: PointageAnimations.fast,
          curve: PointageAnimations.defaultCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: PointageSpacing.lg,
            vertical: PointageSpacing.md,
          ),
          decoration: BoxDecoration(
            color: _isHovered && widget.onPressed != null
                ? baseColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: PointageBorderRadius.medium,
            border: Border.all(
              color: widget.onPressed != null
                  ? baseColor
                  : PointageColors.disabled,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered && widget.onPressed != null
                ? PointageShadows.sm
                : null,
          ),
          child: DefaultTextStyle(
            style: PointageTextStyles.button.copyWith(
              color: widget.onPressed != null
                  ? baseColor
                  : PointageColors.disabled,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: widget.onPressed != null
                    ? baseColor
                    : PointageColors.disabled,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
