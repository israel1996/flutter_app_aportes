import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
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

    final prefs = await SharedPreferences.getInstance();
    final lockedUntil = prefs.getInt('login_lockout_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now < lockedUntil) {
      final minutes = DateTime.fromMillisecondsSinceEpoch(
        lockedUntil,
      ).difference(DateTime.now()).inMinutes;
      CustomSnackBar.showError(
        context,
        'Demasiados intentos fallidos. Intente de nuevo en ${minutes > 0 ? minutes : 1} minuto(s).',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      final estado = await Supabase.instance.client.rpc(
        'obtener_estado_usuario',
        params: {'correo': email},
      );

      if (estado == 'pendiente' ||
          estado == 'inactivo' ||
          estado == 'solicita_reseteo') {
        if (mounted) {
          setState(() => _isLoading = false);

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              final colorScheme = Theme.of(context).colorScheme;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                backgroundColor: colorScheme.surface,
                elevation: 8,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: Colors.orange,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Atención Requerida',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Actualmente tu cuenta se encuentra en estado:',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            estado.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Para proteger tu información y habilitar tu acceso, por favor comunícate con nuestro equipo de soporte técnico:',
                          style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'mx.u7000@gmail.com',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'ENTENDIDO',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
        return;
      }

      final authService = ref.read(authServiceProvider);
      await authService.signIn(email, _passwordController.text.trim());

      await prefs.setInt('login_failed_attempts', 0);
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();

        if (errorMessage.contains('Invalid login credentials')) {
          int attempts = (prefs.getInt('login_failed_attempts') ?? 0) + 1;
          if (attempts >= 5) {
            await prefs.setInt(
              'login_lockout_time',
              DateTime.now()
                  .add(const Duration(minutes: 3))
                  .millisecondsSinceEpoch,
            );
            await prefs.setInt('login_failed_attempts', 0);
            CustomSnackBar.showError(
              context,
              'Demasiados intentos. Cuenta bloqueada por 3 minutos.',
            );
          } else {
            await prefs.setInt('login_failed_attempts', attempts);
            CustomSnackBar.showError(
              context,
              'El correo o la contraseña son incorrectos. (Intento $attempts de 5)',
            );
          }
        } else if (errorMessage.contains('Email not confirmed')) {
          CustomSnackBar.showError(
            context,
            'Por favor, verifique su correo electrónico antes de ingresar.',
          );
        } else {
          CustomSnackBar.showError(context, 'Error al iniciar sesión.');
        }
      }
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
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
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
