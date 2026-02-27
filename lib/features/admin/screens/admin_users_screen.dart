import 'package:flutter/material.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Estado actualizado a $nuevoEstado'),
            backgroundColor: Colors.green,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final user = _usuarios[index];
                final isPending = user['estado'] == 'pendiente';
                final isActive = user['estado'] == 'activo';

                // Prevent superadmin from locking themselves out
                if (user['rol'] == 'superadmin') return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                    border: isPending
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
                      backgroundColor: isPending
                          ? Colors.orange.withOpacity(0.2)
                          : (isActive
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2)),
                      child: Icon(
                        isPending
                            ? Icons.hourglass_empty
                            : (isActive ? Icons.check : Icons.block),
                        color: isPending
                            ? Colors.orange
                            : (isActive ? Colors.green : Colors.red),
                      ),
                    ),
                    title: Text(
                      user['nombre'] ?? 'Sin nombre',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
                        if (!isActive) // Show Approve Button
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
                        if (isActive || isPending) // Show Block Button
                          IconButton(
                            tooltip: 'Desactivar/Bloquear',
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.redAccent,
                              size: 28,
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
