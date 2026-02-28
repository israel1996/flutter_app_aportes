import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
  }

  Future<void> _fetchUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('usuarios_app')
          .select()
          .order('estado', ascending: false);
      setState(() => _usuarios = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarEstado(String userId, String nuevoEstado) async {
    try {
      await _supabase
          .from('usuarios_app')
          .update({'estado': nuevoEstado})
          .eq('id', userId);

      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          'Estado actualizado a $nuevoEstado',
        );
      }
      _fetchUsuarios(); // Refresh list
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final user = _usuarios[index];

                // Define the states
                final isPending = user['estado'] == 'pendiente';
                final isActive = user['estado'] == 'activo';
                final isResetRequested =
                    user['estado'] == 'solicita_reseteo'; // NEW STATE!

                // Prevent superadmin from locking themselves out
                if (user['rol'] == 'superadmin') return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        // Make it glow red if a reset is requested!
                        color: isResetRequested
                            ? Colors.redAccent.withOpacity(0.4)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: isResetRequested ? 15 : 8,
                      ),
                    ],
                    border: isResetRequested
                        ? Border.all(
                            color: Colors.redAccent,
                            width: 2,
                          ) // Bold Red Border
                        : isPending
                        ? Border.all(
                            color: Colors.orangeAccent.withOpacity(0.5),
                            width: 2,
                          )
                        : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isResetRequested
                          ? Colors.redAccent.withOpacity(0.2)
                          : isPending
                          ? Colors.orange.withOpacity(0.2)
                          : (isActive
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2)),
                      child: Icon(
                        isResetRequested
                            ? Icons
                                  .lock_reset // Special key alert icon
                            : isPending
                            ? Icons.hourglass_empty
                            : (isActive ? Icons.check : Icons.block),
                        color: isResetRequested
                            ? Colors.redAccent
                            : isPending
                            ? Colors.orange
                            : (isActive ? Colors.green : Colors.grey),
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isResetRequested)
                          Text(
                            '¡SOLICITA CAMBIO DE CLAVE!',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        Text(
                          user['nombre'] ?? 'Sin nombre',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      user['email'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show Approve Button for Pending users
                        if (isPending)
                          IconButton(
                            tooltip: 'Aprobar Acceso',
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 28,
                            ),
                            onPressed: () =>
                                _cambiarEstado(user['id'], 'activo'),
                          ),

                        // Show Reset Password Button (For Active OR Reset Requested users)
                        if (isActive || isResetRequested)
                          IconButton(
                            tooltip: 'Restablecer Contraseña (Iglesia2026)',
                            // Make the icon pulse or stand out if requested
                            icon: Icon(
                              Icons.lock_reset,
                              color: isResetRequested
                                  ? Colors.redAccent
                                  : Colors.blueAccent,
                              size: isResetRequested ? 32 : 28,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('¿Restablecer Contraseña?'),
                                  content: Text(
                                    'Esto cambiará la contraseña de ${user['nombre']} a "Iglesia2026" y le obligará a cambiarla al iniciar sesión. ¿Continuar?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Restablecer',
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await _supabase.rpc(
                                    'admin_reset_password',
                                    params: {
                                      'target_user_id': user['id'],
                                      'new_password': 'Iglesia2026',
                                    },
                                  );
                                  if (mounted)
                                    CustomSnackBar.showSuccess(
                                      context,
                                      'Contraseña restablecida a Iglesia2026',
                                    );
                                  _fetchUsuarios(); // Refresh list to remove the red glow!
                                } catch (e) {
                                  if (mounted)
                                    CustomSnackBar.showError(
                                      context,
                                      'Error: $e',
                                    );
                                }
                              }
                            },
                          ),

                        // Block Button (Hide it if they just requested a reset to keep UI clean)
                        if ((isActive || isPending) && !isResetRequested)
                          IconButton(
                            tooltip: 'Desactivar/Bloquear',
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.grey,
                              size: 24,
                            ),
                            onPressed: () =>
                                _cambiarEstado(user['id'], 'inactivo'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
