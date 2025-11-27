import 'package:audira_frontend/features/home/screens/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Definición de colores locales para el tema oscuro ---
  final Color _darkBgStart =
      const Color(0xFF0F111A); // Negro azulado muy oscuro
  final Color _darkBgEnd = Colors.black;
  final Color _darkSurface =
      const Color(0xFF1A1D2B); // Superficie de tarjeta oscura
  final Color _darkInputFill = const Color(0xFF24283B); // Fondo de inputs
  final Color _textLightGrey = const Color(0xFFB0B3C7); // Texto secundario
  // ---------------------------------------------------------

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } else {
      // SnackBar adaptado al tema oscuro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ?? 'Error al iniciar sesión',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorRed.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo gradiente oscuro para profundidad
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darkBgStart, _darkBgEnd],
            stops: const [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // --- Header Logo ---
                  _buildDarkHeader(),

                  const SizedBox(height: 50),

                  // --- Dark Form Container ---
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _darkSurface,
                      borderRadius: BorderRadius.circular(30),
                      // Sutil borde y sombra azulada para efecto "neón"
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Iniciar Sesión",
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // Texto blanco
                                ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 30),

                          // Input Usuario
                          _buildDarkInput(
                            controller: _emailController,
                            label: 'Email o Usuario',
                            icon: Icons.person_outline_rounded,
                            inputType: TextInputType.emailAddress,
                            action: TextInputAction.next,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Por favor ingresa tu email o usuario'
                                    : null,
                          )
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 20),

                          // Input Contraseña
                          _buildDarkInput(
                            controller: _passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isObscure: _obscurePassword,
                            toggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            action: TextInputAction.done,
                            onSubmitted: (_) => _handleLogin(),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Por favor ingresa tu contraseña'
                                    : null,
                          )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 36),

                          // Botón Principal Azul
                          Selector<AuthProvider, bool>(
                            selector: (context, provider) => provider.isLoading,
                            builder: (context, isLoading, child) {
                              return Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  // Gradiente sutil en el botón azul
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue,
                                      AppTheme.primaryBlue.withBlue(
                                          200), // Un poco más claro al final
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue
                                          .withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'ENTRAR',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ).animate().fadeIn(delay: 500.ms).scale(),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                      .moveY(begin: 40),

                  const SizedBox(height: 40),

                  // --- Footer Links Dark ---
                  _buildDarkFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkHeader() {
    return Column(
      children: [
        // Icono de Ecualizador (Igual que MainLayout pero más grande)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.backgroundBlack, // Fondo negro para resaltar
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                blurRadius: 50,
                spreadRadius: -5,
              ),
            ],
          ),
          child: const Icon(
            Icons.graphic_eq, // CAMBIO: Icono correcto
            size: 64,
            color: AppTheme.primaryBlue,
          ),
        ).animate().fadeIn(duration: 800.ms).scale(),

        const SizedBox(height: 24),

        // Texto AUDIRA (Estilo del MainLayout)
        const Text(
          'AUDIRA', // CAMBIO: Texto en mayúsculas
          style: TextStyle(
            fontFamily: 'Poppins', // CAMBIO: Fuente Poppins
            fontWeight: FontWeight.w900,
            fontSize: 32, // Más grande que en el header
            letterSpacing: 4, // Espaciado característico
            color: Colors.white,
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 8),

        Text(
          'Tu música, tu mundo',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFB0B3C7),
                letterSpacing: 0.5,
              ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  // Helper para inputs estilo Dark Mode
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
    Function(String)? onSubmitted,
  }) {
    final OutlineInputBorder borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    );

    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      textInputAction: action,
      obscureText: isObscure,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.white, // Texto que escribe el usuario es blanco
      ),
      cursorColor: AppTheme.primaryBlue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: _textLightGrey), // Color del label inactivo
        floatingLabelStyle:
            TextStyle(color: AppTheme.primaryBlue), // Color label activo

        prefixIcon: Icon(icon, color: _textLightGrey),

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
        fillColor: _darkInputFill, // Fondo oscuro para el input

        border: borderStyle,
        enabledBorder: borderStyle,
        focusedBorder: borderStyle.copyWith(
          borderSide: BorderSide(
              color: AppTheme.primaryBlue, width: 1.5), // Borde azul al enfocar
        ),
        errorBorder: borderStyle.copyWith(
          borderSide: BorderSide(
              color: AppTheme.errorRed.withValues(alpha: 0.8), width: 1),
        ),
        focusedErrorBorder: borderStyle.copyWith(
          borderSide: BorderSide(color: AppTheme.errorRed, width: 1.5),
        ),

        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildDarkFooter(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("¿No tienes cuenta? ",
                style: TextStyle(color: _textLightGrey)),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: Text(
                'Regístrate aquí',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 700.ms),
        const SizedBox(height: 32),
        TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainLayout()),
                  );
                },
                style: TextButton.styleFrom(
                    foregroundColor: _textLightGrey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                            color: _textLightGrey.withValues(alpha: 0.3)))),
                icon: const Icon(Icons.person_outline, size: 20),
                label: const Text("Continuar como Invitado"))
            .animate()
            .fadeIn(delay: 900.ms),
      ],
    );
  }
}
