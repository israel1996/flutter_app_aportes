import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
import 'package:flutter_app_aportes/features/sync/services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class AddAporteSheet extends ConsumerStatefulWidget {
  const AddAporteSheet({super.key});

  @override
  ConsumerState<AddAporteSheet> createState() => _AddAporteSheetState();
}

class _AddAporteSheetState extends ConsumerState<AddAporteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();

  String? _selectedFeligresId;
  String? _selectedTipo;
  DateTime _selectedDate = DateTime.now(); // Defaults to right now
  bool _isSaving = false;

  final List<String> _tiposAporte = [
    'Diezmo',
    'Ofrenda',
    'Promesa',
    'Pro-Templo',
    'Especial',
  ];

  // --- MODERN DATE PICKER ---
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // --- SAVE & AUTO-SYNC LOGIC ---
  Future<void> _saveAporte() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFeligresId == null || _selectedTipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione el feligrés y el tipo de aporte'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final database = ref.read(databaseProvider);

    try {
      // 1. Save locally to SQLite
      await database.insertAporte(
        AportesCompanion.insert(
          id: const Uuid().v4(),
          feligresId: _selectedFeligresId!,
          monto: double.parse(_montoController.text.trim()),
          tipo: _selectedTipo!,
          fecha: drift.Value(_selectedDate),
          syncStatus: const drift.Value(0),
        ),
      );

      // 2. Opportunistic Background Sync
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

      // 3. Close & Show Success
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Aporte registrado exitosamente'),
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
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final database = ref.watch(databaseProvider);

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
                  Text(
                    'Registrar Aporte',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // DYNAMIC INPUT: Feligrés Dropdown (Loads from SQLite)
              StreamBuilder<List<Feligrese>>(
                stream: database.watchAllFeligreses(),
                builder: (context, snapshot) {
                  final members = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedFeligresId,
                    decoration: const InputDecoration(
                      labelText: 'Feligrés *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    dropdownColor: colorScheme.surface,
                    items: members.map((member) {
                      return DropdownMenuItem(
                        value: member.id,
                        child: Text(member.nombre),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedFeligresId = value),
                    hint: members.isEmpty
                        ? const Text('No hay feligreses registrados')
                        : const Text('Seleccione un feligrés'),
                  );
                },
              ),
              const SizedBox(height: 16),

              // DUAL INPUTS: Tipo & Monto
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedTipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo *',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      dropdownColor: colorScheme.surface,
                      items: _tiposAporte.map((tipo) {
                        return DropdownMenuItem(value: tipo, child: Text(tipo));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedTipo = value),
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

              // GLOWING SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF89216B),
                              const Color(0xFFDA4453),
                            ] // Pink/Purple Neon for Money
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
                    onPressed: _isSaving ? null : _saveAporte,
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
                            'REGISTRAR APORTE',
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
