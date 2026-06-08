import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/sos_wiget.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/model.dart';

import '../services/authentication.dart';
import '../services/player.dart';
import '../services/tenant.dart';
import '../services/tenant_scope.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FocusNode _passwordFocusNode = FocusNode();

  String _message = "";
  bool _isLoading = false;
  bool _isLoadingTenants = false;
  bool _obscurePassword = true;
  bool _enableTTS = false;
  String _selectedTenantId = TenantDefaults.defaultTenantId;
  List<Tenant> _tenants = [];
  late Consigne_model _consigne;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    TenantScope.selectedTenantId = null;
    _initializeAnimations();
    _loadTenants();
    if (kDebugMode) {
      _emailController.text = 'bgaledou@groupesaba.com';
    }
    _consigne = _getConsigneOfTheDay();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTenants() async {
    setState(() {
      _isLoadingTenants = true;
    });

    try {
      final tenants = await TenantService().allActive();
      if (!mounted) return;
      setState(() {
        _tenants = tenants.isEmpty ? _fallbackTenants : tenants;
        if (!_tenants.any((tenant) => tenant.id == _selectedTenantId)) {
          _selectedTenantId = _tenants.first.id;
        }
        _isLoadingTenants = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tenants = _fallbackTenants;
        _selectedTenantId = TenantDefaults.defaultTenantId;
        _isLoadingTenants = false;
      });
    }
  }

  List<Tenant> get _fallbackTenants => const [
        Tenant(id: TenantDefaults.maliTenantId, label: 'Mali', countryCode: 'ML'),
      ];

  Consigne_model _getConsigneOfTheDay() {
    final random = Random();
    final index = random.nextInt(AppConstants.consignes.length);
    return AppConstants.consignes[index];
  }

  void _toggleTTS() {
    setState(() {
      _enableTTS = !_enableTTS;
    });
    if (_enableTTS) {
      TTS().speetch(_consigne.tache);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;
    final cardWidth = isDesktop ? 450.0 : size.width * 0.9;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor,
              AppConstants.primaryColor.withValues(alpha: 0.8),
              AppConstants.bgColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SOS Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Spacer(),
                            Sos(),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Logo and Title
                        _buildHeader(),
                        const SizedBox(height: 10),

                        // Daily Instructions Card
                        _buildInstructionsCard(),
                        const SizedBox(height: 10),

                        // Login Form
                        _buildLoginForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Hero(
          tag: 'logo',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 45,
              backgroundImage: AssetImage("assets/logo.png"),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          AppConstants.oragnisationName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Système de Protection et d'Assistance Sécuritaire",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "CONSIGNES DU JOUR",
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _toggleTTS,
                  icon: Icon(
                    _enableTTS ? Icons.volume_up : Icons.volume_off,
                    color: AppConstants.primaryColor,
                  ),
                  tooltip: _enableTTS ? "Désactiver l'audio" : "Activer l'audio",
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _consigne.consigne,
                style: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _consigne.tache,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Connexion",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              _buildTenantDropdown(),
              const SizedBox(height: 16),

              // Email Field
              _buildTextField(
                controller: _emailController,
                hintText: "Adresse email",
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildTextField(
                controller: _passwordController,
                hintText: "Mot de passe",
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                ),
                validator: _validatePassword,
                focusNode: _passwordFocusNode,
                onFieldSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "Se connecter",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Error Message
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _message,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTenantDropdown() {
    final tenants = _tenants.isEmpty ? _fallbackTenants : _tenants;
    return DropdownButtonFormField<String>(
      value: _selectedTenantId,
      items: tenants
          .map(
            (tenant) => DropdownMenuItem<String>(
              value: tenant.id,
              child: Text(tenant.label),
            ),
          )
          .toList(),
      onChanged: _isLoadingTenants
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                _selectedTenantId = value;
              });
            },
      decoration: InputDecoration(
        hintText: _isLoadingTenants ? 'Chargement des pays...' : 'Pays',
        prefixIcon: const Icon(Icons.public, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.1),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    FocusNode? focusNode, // Added focusNode parameter
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode, // Assign focusNode to TextFormField
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: Colors.grey),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.1),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Veuillez saisir un email valide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  // Méthode de connexion optimisée
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = "";
    });

    try {
      final user = await _authService.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user == null) {
        throw Exception('login-failed');
      }

      final manager =
          await _authService.authState(selectedTenantId: _selectedTenantId);

      if (manager == null) {
        throw Exception('manager-profile-not-found');
      }

      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = _getErrorMessage(error);
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is TenantAssignmentRequiredException) {
      return "Votre compte n'est pas encore rattaché a un pays. Contactez un administrateur.";
    }

    switch (error.hashCode) {
      case 495537990:
        return "Vérifiez votre connexion internet.";
      default:
        return "Email ou mot de passe incorrect.";
    }
  }
}
