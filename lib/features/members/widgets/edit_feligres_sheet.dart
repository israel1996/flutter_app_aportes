import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
import 'package:flutter_app_aportes/features/sync/services/sync_service.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class EditFeligresSheet extends ConsumerStatefulWidget {
  final Feligrese feligres;

  const EditFeligresSheet({super.key, required this.feligres});

  @override
  ConsumerState<EditFeligresSheet> createState() => _EditFeligresSheetState();
}

class _EditFeligresSheetState extends ConsumerState<EditFeligresSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;

  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isSaving = false;

  bool get _isDeleted => widget.feligres.activo == 0;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.feligres.nombre);
    _telefonoController = TextEditingController(
      text: widget.feligres.telefono ?? '',
    );
    final g = widget.feligres.genero;
    if (g == 'Masculino' || g == 'Femenino') {
      _selectedGender = g;
    }
    _selectedDate = widget.feligres.fechaNacimiento;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _triggerBackgroundSync() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet =
          connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);

      if (hasInternet) {
        final authService = ref.read(authServiceProvider);
        if (authService.currentUser != null) {
          final syncService = SyncService(ref.read(databaseProvider));
          await syncService.syncAll();
        }
      }
    } catch (e) {
      debugPrint("Auto-sync skipped: $e");
    }
  }

  Future<void> _updateFeligres() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final database = ref.read(databaseProvider);

    try {
      await database
          .update(database.feligreses)
          .replace(
            widget.feligres.copyWith(
              nombre: _nombreController.text.trim(),
              telefono: drift.Value(
                _telefonoController.text.trim().isEmpty
                    ? null
                    : _telefonoController.text.trim(),
              ),
              genero: drift.Value(_selectedGender),
              fechaNacimiento: drift.Value(_selectedDate),
              syncStatus: 0,
            ),
          );

      await _triggerBackgroundSync();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Feligrés actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteFeligres() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Feligrés?'),
        content: const Text(
          'Esta acción ocultará al feligrés de las listas. Sus aportes históricos se mantendrán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    final database = ref.read(databaseProvider);

    try {
      await database
          .update(database.feligreses)
          .replace(widget.feligres.copyWith(activo: 0, syncStatus: 0));

      await _triggerBackgroundSync();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Feligrés eliminado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _restoreFeligres() async {
    setState(() => _isSaving = true);
    final database = ref.read(databaseProvider);

    try {
      await database
          .update(database.feligreses)
          .replace(widget.feligres.copyWith(activo: 1, syncStatus: 0));
      await _triggerBackgroundSync();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('♻️ Feligrés restaurado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Editar Feligrés',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value!.isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Género *',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      dropdownColor: colorScheme.surface,
                      items: const [
                        DropdownMenuItem(
                          value: 'Masculino',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem(
                          value: 'Femenino',
                          child: Text('Femenino'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: _selectedDate == null
                      ? 'Fecha de Nacimiento'
                      : 'Fecha: ${DateFormat('dd MMM yyyy', 'es').format(_selectedDate!)}',
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
              ),
              const SizedBox(height: 32),

              if (_isDeleted)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.teal.shade400],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _restoreFeligres,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      icon: const Icon(Icons.restore, color: Colors.white),
                      label: Text(
                        'RESTAURAR FELIGRÉS',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF00C9FF), const Color(0xFF92FE9D)]
                            : [colorScheme.primary, colorScheme.secondary],
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00C9FF).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateFeligres,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'ACTUALIZAR',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _isSaving ? null : _deleteFeligres,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    label: Text(
                      'Eliminar Feligrés',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
