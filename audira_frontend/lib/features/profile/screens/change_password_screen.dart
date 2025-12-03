import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('User not identified');
      }

      final authService = AuthService();
      final response = await authService.changePassword(
        userId: userId,
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
        confirmPassword: _confirmPasswordController.text.trim(),
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception(response.error ?? 'Failed to update password');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text(
          'Security Settings',
          style: TextStyle(
              color: AppTheme.primaryBlue, fontWeight: FontWeight.w800),
        ),
        backgroundColor: darkBg,
        elevation: 0,
        iconTheme: IconThemeData(color: subText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        width: 2),
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 48,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'Change Password',
                  style: TextStyle(
                      color: lightText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'Your new password must be different from\npreviously used passwords.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subText, fontSize: 14),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // Inputs Section
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Current Password',
                isObscured: _obscureCurrentPassword,
                onToggle: () => setState(
                    () => _obscureCurrentPassword = !_obscureCurrentPassword),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ).animate().slideX(begin: -0.1, delay: 300.ms).fadeIn(),

              const SizedBox(height: 20),

              _buildPasswordField(
                controller: _newPasswordController,
                label: 'New Password',
                isObscured: _obscureNewPassword,
                onToggle: () =>
                    setState(() => _obscureNewPassword = !_obscureNewPassword),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (val.length < 8) return 'Min 8 characters';
                  if (val == _currentPasswordController.text) {
                    return 'Must be different from current';
                  }
                  return null;
                },
              ).animate().slideX(begin: -0.1, delay: 400.ms).fadeIn(),

              const SizedBox(height: 20),

              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                isObscured: _obscureConfirmPassword,
                onToggle: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (val != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ).animate().slideX(begin: -0.1, delay: 500.ms).fadeIn(),

              const SizedBox(height: 32),

              // Requirements Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[850]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PASSWORD REQUIREMENTS',
                      style: TextStyle(
                          color: subText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementRow('Minimum 8 characters long'),
                    const SizedBox(height: 8),
                    _buildRequirementRow('Different from current password'),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Update Password',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ).animate().slideY(begin: 0.2, delay: 700.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: subText, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscured,
          style: TextStyle(color: lightText),
          decoration: InputDecoration(
            filled: true,
            fillColor: darkCardBg,
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey[700]),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[850]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryBlue)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[900]!)),
            errorStyle: const TextStyle(color: Colors.redAccent),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRequirementRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline,
            size: 16, color: Colors.greenAccent),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ],
    );
  }
}
