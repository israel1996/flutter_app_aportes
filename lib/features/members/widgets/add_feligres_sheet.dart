import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
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
  final bool initiallyExpanded; // ADD THIS VARIABLE

  // Update the constructor to accept the variable, defaulting to false
  const AddFeligresSheet({super.key, this.initiallyExpanded = false});

  @override
  ConsumerState<AddFeligresSheet> createState() => _AddFeligresSheetState();
}

class _AddFeligresSheetState extends ConsumerState<AddFeligresSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _cedulaController = TextEditingController();
  String? _estadoCivil;
  String _tipoFeligres = 'feligres';
  bool _poseeDiscapacidad = false;
  bool _bautizadoAgua = false;
  bool _bautizadoEspiritu = false;

  final List<String> _estadosCiviles = [
    'Soltero',
    'Casado',
    'Divorciado',
    'Viudo',
    'Unión Libre',
  ];
  final List<String> _tiposFeligres = ['simpatizante', 'feligres', 'visita'];

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
      CustomSnackBar.showWarning(context, 'Por favor seleccione un género');
      return;
    }

    // 1. READ THE CURRENT CHURCH
    final currentIglesia = ref.read(currentIglesiaProvider);
    if (currentIglesia == null) {
      CustomSnackBar.showError(
        context,
        'Debes registrar o seleccionar una Iglesia (Sede) del menú principal.',
      );
      return;
    }

    setState(() => _isSaving = true);
    final database = ref.read(databaseProvider);

    try {
      await database.insertFeligres(
        FeligresesCompanion.insert(
          id: const Uuid().v4(),
          iglesiaId: drift.Value(
            currentIglesia.id,
          ), // 2. ASSIGN THE CHURCH TO THE PARISHIONER
          nombre: _nombreController.text.trim(),
          telefono: drift.Value(
            _telefonoController.text.trim().isEmpty
                ? null
                : _telefonoController.text.trim(),
          ),
          genero: drift.Value(_selectedGender),
          fechaNacimiento: drift.Value(_selectedDate),
          cedula: drift.Value(
            _cedulaController.text.trim().isEmpty
                ? null
                : _cedulaController.text.trim(),
          ),
          estadoCivil: drift.Value(_estadoCivil),
          tipoFeligres: drift.Value(_tipoFeligres),
          poseeDiscapacidad: drift.Value(_poseeDiscapacidad),
          bautizadoAgua: drift.Value(_bautizadoAgua),
          bautizadoEspiritu: drift.Value(_bautizadoEspiritu),
          activo: const drift.Value(1),
          syncStatus: const drift.Value(0),
        ),
      );

      // ... rest of the code (sync and success messages) remains the same ...
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
          }
        }
      } catch (syncError) {
        debugPrint("⚠️ Auto-sync skipped or failed: $syncError");
      }

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccess(
          context,
          'Feligrés registrado en ${currentIglesia.nombre}',
        );
      }
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Error al guardar:$e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
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

              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: widget.initiallyExpanded,
                  tilePadding: EdgeInsets.zero,
                  collapsedIconColor: colorScheme.primary,
                  iconColor: colorScheme.primary,
                  title: Text(
                    'Datos Avanzados de Secretaría (Opcional)',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: colorScheme.primary,
                    ),
                  ),
                  children: [
                    const SizedBox(height: 16),

                    // 1. Cédula
                    TextFormField(
                      controller: _cedulaController,
                      decoration: InputDecoration(
                        labelText: 'Número de Cédula',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // 2. Estado Civil
                    DropdownButtonFormField<String>(
                      value: _estadoCivil,
                      decoration: InputDecoration(
                        labelText: 'Estado Civil',
                        prefixIcon: const Icon(Icons.favorite_border),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: _estadosCiviles.map((estado) {
                        return DropdownMenuItem(
                          value: estado,
                          child: Text(estado),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _estadoCivil = val),
                    ),
                    const SizedBox(height: 16),

                    // 3. Tipo de Feligrés
                    DropdownButtonFormField<String>(
                      value: _tipoFeligres,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Membresía',
                        prefixIcon: const Icon(Icons.card_membership),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: _tiposFeligres.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(
                            tipo[0].toUpperCase() + tipo.substring(1),
                          ), // Capitalize
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _tipoFeligres = val!),
                    ),
                    const SizedBox(height: 16),

                    // 4. Toggles (Switches)
                    SwitchListTile(
                      title: const Text('Posee alguna discapacidad'),
                      secondary: const Icon(Icons.accessible),
                      value: _poseeDiscapacidad,
                      onChanged: (val) =>
                          setState(() => _poseeDiscapacidad = val),
                    ),
                    SwitchListTile(
                      title: const Text('Bautizado en Agua'),
                      secondary: const Icon(Icons.water_drop_outlined),
                      value: _bautizadoAgua,
                      onChanged: (val) => setState(() => _bautizadoAgua = val),
                    ),
                    SwitchListTile(
                      title: const Text('Bautizado en Espíritu Santo'),
                      secondary: const Icon(
                        Icons.local_fire_department_outlined,
                      ),
                      value: _bautizadoEspiritu,
                      onChanged: (val) =>
                          setState(() => _bautizadoEspiritu = val),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

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
