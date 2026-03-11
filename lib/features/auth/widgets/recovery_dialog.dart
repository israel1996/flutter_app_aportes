import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/custom_snackbar.dart';

class RecoveryDialog extends StatefulWidget {
  const RecoveryDialog({super.key});

  @override
  State<RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<RecoveryDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  DateTime? _lockoutTime;

  @override
  void initState() {
    super.initState();
    _checkLockout();
  }

  Future<void> _checkLockout() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedTimestamp = prefs.getInt('recovery_lockout');

    if (lockedTimestamp != null) {
      final lockTime = DateTime.fromMillisecondsSinceEpoch(lockedTimestamp);
      if (DateTime.now().isBefore(lockTime)) {
        setState(() => _lockoutTime = lockTime);
        _startTimer();
      } else {
        await prefs.remove('recovery_lockout');
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      if (_lockoutTime != null && now.isBefore(_lockoutTime!)) {
        if (mounted) {
          setState(() {
            _remainingSeconds = _lockoutTime!.difference(now).inSeconds;
          });
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('recovery_lockout');
        if (mounted) {
          setState(() {
            _lockoutTime = null;
            _remainingSeconds = 0;
          });
        }
        _timer?.cancel();
      }
    });
  }

  // --- NUEVA LÓGICA DIRECTA Y SEGURA ---
  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      // Enviamos el correo de recuperación directamente
      // (Estándar de seguridad de Supabase, no da error si no existe para evitar enumeración)
      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      // Bloqueamos la interfaz por 2 minutos para evitar Spam de correos
      final prefs = await SharedPreferences.getInstance();
      final lockTime = DateTime.now().add(const Duration(minutes: 2));
      await prefs.setInt('recovery_lockout', lockTime.millisecondsSinceEpoch);

      if (mounted) {
        Navigator.pop(context); // Cerramos el modal PRIMERO
        CustomSnackBar.showSuccess(
          context,
          'Si el correo está registrado, recibirá un enlace de recuperación. Por favor, revise su bandeja de entrada.',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showError(
          context,
          'Error al intentar enviar el enlace.',
        );
      }
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
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Recuperar Cuenta',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingrese su correo registrado. Le enviaremos un enlace mágico para restablecer su contraseña.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock_clock,
                        color: Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Solicitud enviada.\nIntente de nuevo en:',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
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
                    'Enviar Enlace',
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
