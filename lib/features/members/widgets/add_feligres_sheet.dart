import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
import 'package:flutter_app_aportes/features/sync/services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class AddFeligresSheet extends ConsumerStatefulWidget {
  const AddFeligresSheet({super.key});

  @override
  ConsumerState<AddFeligresSheet> createState() => _AddFeligresSheetState();
}

class _AddFeligresSheetState extends ConsumerState<AddFeligresSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveFeligres() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione un género'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final database = ref.read(databaseProvider);

    try {
      await database.insertFeligres(
        FeligresesCompanion.insert(
          id: const Uuid().v4(),
          nombre: _nombreController.text.trim(),
          telefono: drift.Value(
            _telefonoController.text.trim().isEmpty
                ? null
                : _telefonoController.text.trim(),
          ),
          genero: drift.Value(_selectedGender),
          fechaNacimiento: drift.Value(_selectedDate),
          activo: const drift.Value(1),
          syncStatus: const drift.Value(0),
        ),
      );

      try {
        final connectivity = await Connectivity().checkConnectivity();
        final hasInternet =
            connectivity.contains(ConnectivityResult.mobile) ||
            connectivity.contains(ConnectivityResult.wifi) ||
            connectivity.contains(ConnectivityResult.ethernet);

        if (hasInternet) {
          final authService = ref.read(authServiceProvider);
          if (authService.currentUser != null) {
            final syncService = SyncService(database);
            await syncService.syncAll();
            debugPrint("✅ Auto-sync background complete.");
          }
        }
      } catch (syncError) {
        debugPrint("⚠️ Auto-sync skipped or failed: $syncError");
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Feligrés registrado y respaldado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar localmente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                  // 1. Wrap the title in Expanded
                  Expanded(
                    child: Text(
                      'Nuevo Feligrés',
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
                validator: (value) =>
                    value!.isEmpty ? 'El nombre es obligatorio' : null,
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
                        labelText: 'Teléfono (Opcional)',
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
                      ? 'Fecha de Nacimiento (Opcional)'
                      : 'Fecha: ${DateFormat('dd MMM yyyy', 'es').format(_selectedDate!)}',
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
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
                    onPressed: _isSaving ? null : _saveFeligres,
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
                            'GUARDAR FELIGRÉS',
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
            ],
          ),
        ),
      ),
    );
  }
}
