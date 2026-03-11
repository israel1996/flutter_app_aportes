import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_app_aportes/features/auth/screens/register_screen.dart';
import 'package:flutter_app_aportes/features/auth/widgets/recovery_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Verificar si la app está bloqueada por intentos fallidos
    final prefs = await SharedPreferences.getInstance();
    final lockedUntil = prefs.getInt('lockout_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now < lockedUntil) {
      final minutes = DateTime.fromMillisecondsSinceEpoch(
        lockedUntil,
      ).difference(DateTime.now()).inMinutes;
      // Mostrar alerta por encima
      CustomSnackBar.showError(
        context,
        'Demasiados intentos fallidos. Intente de nuevo en ${minutes > 0 ? minutes : 1} minuto(s).',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Intento de inicio de sesión
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Si el login es exitoso, reseteamos el contador de fallos
      await prefs.setInt('failed_attempts', 0);

      // 3. Verificamos el estado del usuario en la base de datos (usuarios_app)
      final userData = await Supabase.instance.client
          .from('usuarios_app')
          .select('estado')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userData != null) {
        final estado = userData['estado'];
        if (estado == 'pendiente' || estado == 'inactivo') {
          await Supabase.instance.client.auth.signOut(); // Expulsar
          if (mounted) {
            CustomSnackBar.showError(
              context,
              'Para solicitar activación contactarse al correo mx.u7000@gmail.com',
            );
          }
          return;
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMsg = 'Ocurrió un error al ingresar.';

        // 4. Traducción de errores y control de intentos
        if (e.message.contains('Invalid login credentials')) {
          errorMsg = 'El correo o la contraseña son incorrectos.';

          int attempts = (prefs.getInt('failed_attempts') ?? 0) + 1;
          if (attempts >= 5) {
            // Bloquear por 15 minutos (ejemplo) al 5to intento fallido
            await prefs.setInt(
              'lockout_time',
              DateTime.now()
                  .add(const Duration(minutes: 15))
                  .millisecondsSinceEpoch,
            );
            await prefs.setInt('failed_attempts', 0);
            errorMsg = 'Demasiados intentos. Cuenta bloqueada temporalmente.';
          } else {
            await prefs.setInt('failed_attempts', attempts);
            errorMsg += ' (Intento $attempts de 5)';
          }
        } else if (e.message.contains('Email not confirmed')) {
          errorMsg =
              'Por favor, verifique su correo electrónico mediante el enlace que se le envió.';
        }

        CustomSnackBar.showError(context, errorMsg);
      }
    } catch (e) {
      if (mounted)
        CustomSnackBar.showError(
          context,
          'Error de conexión. Intente nuevamente.',
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF00C9FF).withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: isDark
                      ? Border.all(
                          color: const Color(0xFF00C9FF).withOpacity(0.2),
                          width: 1,
                        )
                      : null,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF00C9FF).withOpacity(0.1)
                              : colorScheme.primary.withOpacity(0.1),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00C9FF,
                                    ).withOpacity(0.2),
                                    blurRadius: 20,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.lock_person_outlined,
                          size: 48,
                          color: isDark
                              ? const Color(0xFF00C9FF)
                              : colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bienvenido',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingrese sus credenciales para continuar',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'El correo es obligatorio';
                          if (!value.contains('@'))
                            return 'Ingrese un correo válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'La contraseña es obligatoria'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const RecoveryDialog(),
                            );
                          },
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: GoogleFonts.poppins(
                              color: isDark
                                  ? const Color(0xFF00C9FF)
                                  : colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF00C9FF),
                                      const Color(0xFF92FE9D),
                                    ]
                                  : [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                            ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00C9FF,
                                      ).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    'INICIAR SESIÓN',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          '¿No tienes cuenta? Regístrate aquí',
                          style: GoogleFonts.poppins(
                            color: isDark
                                ? const Color(0xFF00C9FF)
                                : colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
