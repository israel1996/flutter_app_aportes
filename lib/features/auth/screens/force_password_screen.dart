import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/custom_snackbar.dart';

class ForcePasswordScreen extends ConsumerStatefulWidget {
  const ForcePasswordScreen({super.key});

  @override
  ConsumerState<ForcePasswordScreen> createState() =>
      _ForcePasswordScreenState();
}

class _ForcePasswordScreenState extends ConsumerState<ForcePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      // 1. Update the password securely
      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      // 2. Remove the restriction from their account
      await supabase
          .from('usuarios_app')
          .update({'estado': 'activo'})
          .eq('id', supabase.auth.currentUser!.id);

      if (mounted)
        CustomSnackBar.showSuccess(context, 'Contraseña actualizada con éxito');

      // 3. Trigger Riverpod to redraw the HomeScreen!
      ref.invalidate(userRoleProvider);
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Error al actualizar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cyber/Neon accent colors
    final accentColor = isDark ? const Color(0xFF00C9FF) : colorScheme.primary;
    final alertColor = Colors.orangeAccent;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: alertColor.withOpacity(isDark ? 0.15 : 0.05),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: alertColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing Security Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: alertColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: alertColor.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 56,
                      color: alertColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'CAMBIO OBLIGATORIO',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Por razones de seguridad, debes establecer una nueva clave privada para tu cuenta antes de acceder al sistema.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // New Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    style: GoogleFonts.poppins(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey),
                      prefixIcon: Icon(Icons.lock_outline, color: accentColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: accentColor, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (val) => val != null && val.length < 6
                        ? 'Debe tener al menos 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscure,
                    style: GoogleFonts.poppins(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey),
                      prefixIcon: Icon(Icons.lock_reset, color: accentColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: accentColor, width: 2),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return 'Por favor confirma la contraseña';
                      if (val != _passwordController.text)
                        return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alertColor,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: alertColor.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'GUARDAR Y CONTINUAR',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
