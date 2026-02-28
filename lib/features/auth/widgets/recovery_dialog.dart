import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/custom_snackbar.dart';

class RecoveryDialog extends StatefulWidget {
  const RecoveryDialog({super.key});

  @override
  State<RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<RecoveryDialog> {
  // Static variables keep their value even if the dialog is closed!
  static int _failedAttempts = 0;
  static DateTime? _lockoutTime;

  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkLockout();
  }

  void _checkLockout() {
    if (_lockoutTime != null) {
      final now = DateTime.now();
      if (now.isBefore(_lockoutTime!)) {
        _startTimer();
      } else {
        // Penalty time is over, reset variables
        _failedAttempts = 0;
        _lockoutTime = null;
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_lockoutTime != null && now.isBefore(_lockoutTime!)) {
        if (mounted) {
          setState(() {
            _remainingSeconds = _lockoutTime!.difference(now).inSeconds;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _failedAttempts = 0;
            _lockoutTime = null;
            _remainingSeconds = 0;
          });
        }
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final supabase = Supabase.instance.client;

      // Check if email exists in our custom table
      final response = await supabase
          .from('usuarios_app')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        // --- 1. NEW: FLAG THE USER IN THE DATABASE ---
        await supabase
            .from('usuarios_app')
            .update({'estado': 'solicita_reseteo'})
            .eq('id', response['id']);

        // SUCCESS: The email exists and the admin is notified!
        if (mounted) {
          Navigator.pop(context); // Close the input dialog

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Solicitud Enviada',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Su cuenta ha sido verificada y se ha notificado al Administrador.\n\nPor favor, contacte al Superadmin para recibir su clave temporal.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        // FAILED: Email does not exist
        _failedAttempts++;

        if (_failedAttempts >= 3) {
          _lockoutTime = DateTime.now().add(const Duration(minutes: 5));
          _startTimer();
          if (mounted)
            CustomSnackBar.showError(
              context,
              'Demasiados intentos. Bloqueado por 5 minutos.',
            );
        } else {
          if (mounted)
            CustomSnackBar.showWarning(
              context,
              'Correo no encontrado. Intentos restantes: ${3 - _failedAttempts}',
            );
        }
      }
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocked = _lockoutTime != null;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? const Color(0xFF00C9FF).withOpacity(0.5)
              : colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            color: isDark ? const Color(0xFF00C9FF) : colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Verificar Cuenta',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingrese su correo registrado para verificar su identidad antes de solicitar el cambio de clave.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (isLocked)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_clock,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Intentos agotados.\nIntente de nuevo en:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              )
            else
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Obligatorio';
                  if (!value.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        if (!isLocked)
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF00C9FF)
                  : colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Verificar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
      ],
    );
  }
}
