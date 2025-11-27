import 'package:audira_frontend/features/home/screens/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- Colores Locales Dark Mode ---
  final Color _darkBgStart = const Color(0xFF0F111A);
  final Color _darkBgEnd = Colors.black;
  final Color _darkSurface = const Color(0xFF1A1D2B);
  final Color _darkInputFill = const Color(0xFF24283B);
  final Color _textLightGrey = const Color(0xFFB0B3C7);
  // ----------------------------------------------------

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _artistNameController = TextEditingController();

  bool _obscurePassword = true;
  String _selectedRole = AppConstants.roleUser;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _artistNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus(); // Cerrar teclado

    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      firstName: _firstNameController.text.trim().isEmpty
          ? null
          : _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      artistName: _selectedRole == AppConstants.roleArtist &&
              _artistNameController.text.trim().isNotEmpty
          ? _artistNameController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ?? 'Error al registrarse',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorRed.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darkBgStart, _darkBgEnd],
            stops: const [0.0, 0.8],
          ),
        ),
        child: SafeArea(
          // SOLUCIÓN: Envolvemos todo el contenido en SingleChildScrollView
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BRANDING HEADER ---
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.graphic_eq,
                          color: AppTheme.primaryBlue, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'AUDIRA',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms),

                const SizedBox(height: 24),

                // Texto secundario
                Text(
                  'Crea tu cuenta',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 30),

                // --- Form Container ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _darkSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Selector de Rol Personalizado ---
                        Text(
                          'QUIERO SER',
                          style: TextStyle(
                            color: _textLightGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                title: 'Oyente',
                                value: AppConstants.roleUser,
                                icon: Icons.headphones,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRoleCard(
                                title: 'Artista',
                                value: AppConstants.roleArtist,
                                icon: Icons.mic_external_on,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 24),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 24),

                        // --- Campos Principales ---
                        _buildDarkInput(
                          controller: _usernameController,
                          label: 'Usuario *',
                          icon: Icons.alternate_email_rounded,
                          action: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            if (value.length < AppConstants.minUsernameLength) {
                              return 'Mínimo ${AppConstants.minUsernameLength} caracteres';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 400.ms).slideX(),

                        const SizedBox(height: 16),

                        _buildDarkInput(
                          controller: _emailController,
                          label: 'Email *',
                          icon: Icons.email_outlined,
                          inputType: TextInputType.emailAddress,
                          action: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            if (!value.contains('@')) return 'Email inválido';
                            return null;
                          },
                        ).animate().fadeIn(delay: 500.ms).slideX(),

                        const SizedBox(height: 16),

                        _buildDarkInput(
                          controller: _passwordController,
                          label: 'Contraseña *',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          isObscure: _obscurePassword,
                          toggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          action: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            if (value.length < AppConstants.minPasswordLength) {
                              return 'Mínimo ${AppConstants.minPasswordLength} caracteres';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 600.ms).slideX(),

                        const SizedBox(height: 24),

                        // --- Datos Personales (Opcionales) ---
                        Text(
                          'OPCIONAL',
                          style: TextStyle(
                            color: _textLightGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ).animate().fadeIn(delay: 700.ms),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildDarkInput(
                                controller: _firstNameController,
                                label: 'Nombre',
                                icon: Icons.person_outline,
                                action: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDarkInput(
                                controller: _lastNameController,
                                label: 'Apellido',
                                icon: Icons.person_outline,
                                action: _selectedRole == AppConstants.roleArtist
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 800.ms),

                        // --- Campo Condicional para Artista ---
                        if (_selectedRole == AppConstants.roleArtist) ...[
                          const SizedBox(height: 16),
                          _buildDarkInput(
                            controller: _artistNameController,
                            label: 'Nombre Artístico',
                            icon: Icons.library_music_outlined,
                            action: TextInputAction.done,
                            borderColor:
                                AppTheme.primaryBlue.withValues(alpha: 0.5),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: -0.2),
                        ],

                        const SizedBox(height: 32),

                        // --- Botón de Registro ---
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                authProvider.isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor:
                                  AppTheme.primaryBlue.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'CREAR CUENTA',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ).animate().fadeIn(delay: 900.ms).scale(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: '¿Ya tienes cuenta? ',
                        style: TextStyle(color: _textLightGrey),
                        children: [
                          TextSpan(
                            text: 'Inicia Sesión',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget personalizado para seleccionar Rol
  Widget _buildRoleCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.15)
              : _darkInputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : _textLightGrey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : _textLightGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input Helper
  Widget _buildDarkInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? inputType,
    TextInputAction? action,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? toggleObscure,
    Color? borderColor,
  }) {
    final OutlineInputBorder borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      textInputAction: action,
      obscureText: isObscure,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      cursorColor: AppTheme.primaryBlue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textLightGrey, fontSize: 14),
        floatingLabelStyle: TextStyle(color: AppTheme.primaryBlue),
        prefixIcon:
            Icon(icon, color: _textLightGrey.withValues(alpha: 0.7), size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _textLightGrey,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: _darkInputFill,
        border: borderStyle,
        enabledBorder: borderColor != null
            ? borderStyle.copyWith(borderSide: BorderSide(color: borderColor))
            : borderStyle,
        focusedBorder: borderStyle.copyWith(
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        errorBorder: borderStyle.copyWith(
          borderSide: BorderSide(
              color: AppTheme.errorRed.withValues(alpha: 0.5), width: 1),
        ),
        focusedErrorBorder: borderStyle.copyWith(
          borderSide: BorderSide(color: AppTheme.errorRed, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: true,
      ),
    );
  }
}
