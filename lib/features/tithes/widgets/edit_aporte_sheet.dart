import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
import 'package:flutter_app_aportes/features/sync/services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class EditAporteSheet extends ConsumerStatefulWidget {
  final AporteConFeligres aporteItem;

  const EditAporteSheet({super.key, required this.aporteItem});

  @override
  ConsumerState<EditAporteSheet> createState() => _EditAporteSheetState();
}

class _EditAporteSheetState extends ConsumerState<EditAporteSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _montoController;

  late String _selectedTipo;
  late DateTime _selectedDate;
  bool _isSaving = false;

  final List<String> _tiposAporte = [
    'Diezmo',
    'Ofrenda',
    'Promesa',
    'Pro-Templo',
    'Especial',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing contribution data
    _montoController = TextEditingController(
      text: widget.aporteItem.aporte.monto.toString(),
    );

    // Safely load the type, defaulting to 'Diezmo' if there's a typo in the DB
    final tipo = widget.aporteItem.aporte.tipo.trim();
    _selectedTipo = _tiposAporte.contains(tipo) ? tipo : _tiposAporte.first;

    _selectedDate = widget.aporteItem.aporte.fecha;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // --- BACKGROUND SYNC HELPER ---
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

  // --- UPDATE LOGIC ---
  Future<void> _updateAporte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final database = ref.read(databaseProvider);

    try {
      await database
          .update(database.aportes)
          .replace(
            widget.aporteItem.aporte.copyWith(
              monto: double.parse(_montoController.text.trim()),
              tipo: _selectedTipo,
              fecha: _selectedDate,
              syncStatus: 0, // Mark as pending sync
            ),
          );

      await _triggerBackgroundSync();

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccess(context, 'Aporte actualizado');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAporte() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Aporte?'),
        content: const Text(
          'Esta acción eliminará el registro financiero de forma permanente en la nube y localmente. ¿Desea continuar?',
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
      // 1. Check internet connection
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet =
          connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);

      if (!hasInternet) {
        throw Exception(
          'Se requiere conexión a internet para eliminar un registro financiero permanentemente de la nube.',
        );
      }

      // 2. Delete from Supabase FIRST
      final supabase = Supabase.instance.client;
      await supabase
          .from('aportes')
          .delete()
          .eq('id', widget.aporteItem.aporte.id);

      // 3. If cloud deletion succeeds, delete from local SQLite
      // Using a direct query ensures Drift deletes the exact ID properly
      await (database.delete(
        database.aportes,
      )..where((tbl) => tbl.id.equals(widget.aporteItem.aporte.id))).go();

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showWarning(context, 'Aporte eliminado permanentemente');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Error al eliminar: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
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
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Editar Aporte',
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
              const SizedBox(height: 8),
              Text(
                'Feligrés: ${widget.aporteItem.feligres.nombre}',
                style: GoogleFonts.poppins(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // DUAL INPUTS: Tipo & Monto
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedTipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo *',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      dropdownColor: colorScheme.surface,
                      items: _tiposAporte
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedTipo = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto (\$)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Obligatorio';
                        if (double.tryParse(value) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // INPUT: Fecha
              TextFormField(
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText:
                      'Fecha: ${DateFormat('dd MMM yyyy', 'es').format(_selectedDate)}',
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
              ),
              const SizedBox(height: 32),

              // GLOWING UPDATE BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF89216B), const Color(0xFFDA4453)]
                          : [colorScheme.secondary, Colors.redAccent],
                    ),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: const Color(0xFFDA4453).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateAporte,
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
                            'ACTUALIZAR APORTE',
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

              // DELETE BUTTON
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isSaving ? null : _deleteAporte,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  label: Text(
                    'Eliminar Aporte',
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
