import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
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
  late TextEditingController _cedulaController;
  late TextEditingController _dateController;

  String? _selectedGender;
  DateTime? _selectedDate;
  String? _estadoCivil;
  String _tipoFeligres = 'feligres';
  bool _poseeDiscapacidad = false;
  bool _bautizadoAgua = false;
  bool _bautizadoEspiritu = false;

  final List<String> _estadosCiviles = [
    'Soltero(a)',
    'Casado(a)',
    'Divorciado(a)',
    'Viudo(a)',
    'Unión Libre',
  ];
  final List<String> _tiposFeligres = ['simpatizante', 'feligres', 'visita'];

  bool _isSaving = false;
  List<String> _nombresSimilares = [];
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
    _dateController = TextEditingController(
      text: _selectedDate == null
          ? ''
          : DateFormat('dd MMM yyyy', 'es').format(_selectedDate!),
    );

    _cedulaController = TextEditingController(
      text: widget.feligres.cedula ?? '',
    );

    final dbEstado = widget.feligres.estadoCivil;
    if (dbEstado != null && _estadosCiviles.contains(dbEstado)) {
      _estadoCivil = dbEstado;
    } else {
      _estadoCivil = null;
    }
    _tipoFeligres = widget.feligres.tipoFeligres ?? 'feligres';
    _poseeDiscapacidad = widget.feligres.poseeDiscapacidad;
    _bautizadoAgua = widget.feligres.bautizadoAgua;
    _bautizadoEspiritu = widget.feligres.bautizadoEspiritu;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _normalizeString(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áäâà]'), 'a')
        .replaceAll(RegExp(r'[éëêè]'), 'e')
        .replaceAll(RegExp(r'[íïîì]'), 'i')
        .replaceAll(RegExp(r'[óöôò]'), 'o')
        .replaceAll(RegExp(r'[úüûù]'), 'u');
  }

  Future<void> _checkDuplicateName(String name) async {
    final query = _normalizeString(name.trim());
    if (query.length < 3) {
      if (_nombresSimilares.isNotEmpty) {
        setState(() => _nombresSimilares = []);
      }
      return;
    }

    final database = ref.read(databaseProvider);
    final allFeligreses = await database.select(database.feligreses).get();

    final matches = allFeligreses
        .where(
          (f) =>
              f.id != widget.feligres.id &&
              _normalizeString(f.nombre).contains(query),
        )
        .map((f) => f.nombre)
        .take(3)
        .toList();

    setState(() => _nombresSimilares = matches);
  }

  bool _validarCedulaEcuatoriana(String cedula) {
    if (cedula.length != 10) return false;
    final int provincia = int.parse(cedula.substring(0, 2));
    if (provincia < 1 || (provincia > 24 && provincia != 30)) return false;
    final int tercerDigito = int.parse(cedula[2]);
    if (tercerDigito >= 6) return false;

    final List<int> coeficientes = [2, 1, 2, 1, 2, 1, 2, 1, 2];
    int suma = 0;
    for (int i = 0; i < coeficientes.length; i++) {
      int valor = int.parse(cedula[i]) * coeficientes[i];
      if (valor > 9) valor -= 9;
      suma += valor;
    }

    int digitoVerificador = int.parse(cedula[9]);
    int decenaSuperior = ((suma + 9) ~/ 10) * 10;
    int resultado = decenaSuperior - suma;
    if (resultado == 10) resultado = 0;

    return resultado == digitoVerificador;
  }

  // --- NUEVA LÓGICA DE CALENDARIO INTUITIVO ---
  Future<void> _pickDate() async {
    // Esto quita el foco de cualquier campo de texto, solucionando el bug visual
    FocusScope.of(context).unfocus();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'), // Fuerza Español
      initialDatePickerMode:
          DatePickerMode.year, // Abre los AÑOS primero (Súper intuitivo)
      initialEntryMode: DatePickerEntryMode
          .calendarOnly, // Evita que se abra el teclado numérico
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMM yyyy', 'es').format(picked);
      });
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
              cedula: drift.Value(
                _cedulaController.text.trim().isEmpty
                    ? null
                    : _cedulaController.text.trim(),
              ),
              estadoCivil: drift.Value(_estadoCivil),
              tipoFeligres: _tipoFeligres,
              poseeDiscapacidad: _poseeDiscapacidad,
              bautizadoAgua: _bautizadoAgua,
              bautizadoEspiritu: _bautizadoEspiritu,
              syncStatus: 0,
            ),
          );

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccess(context, 'Feligrés actualizado');
      }

      final syncService = SyncService(database);
      syncService.syncAll().catchError(
        (e) => debugPrint("Auto-sync skipped: $e"),
      );
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Error: $e');
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
          .replace(
            widget.feligres.copyWith(
              activo: 0,
              fechaModificacion: drift.Value(DateTime.now()),
              syncStatus: 0,
            ),
          );

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showWarning(context, 'Feligrés eliminado');
      }

      final syncService = SyncService(database);
      syncService.syncAll().catchError(
        (e) => debugPrint("Auto-sync skipped: $e"),
      );
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Error: $e');
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

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccess(context, 'Feligrés restaurado con éxito');
      }

      final syncService = SyncService(database);
      syncService.syncAll().catchError(
        (e) => debugPrint("Auto-sync skipped: $e"),
      );
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      child: _isDeleted
          ? _buildReadOnlyRestoreView(colorScheme)
          : _buildEditableForm(colorScheme, isDark),
    );
  }

  Widget _buildReadOnlyRestoreView(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registro en Papelera',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Icon(Icons.delete_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            'Este feligrés fue eliminado. No puedes editar sus datos a menos que lo restaures primero.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary.withOpacity(0.2),
                      child: Icon(Icons.person, color: colorScheme.primary),
                    ),
                    title: Text(
                      widget.feligres.nombre,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Membresía: ${widget.feligres.tipoFeligres?.toUpperCase() ?? "FELIGRÉS"}',
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFixedInfo(
                        'Género',
                        widget.feligres.genero ?? 'N/A',
                      ),
                      _buildFixedInfo(
                        'Cédula',
                        widget.feligres.cedula == null ||
                                widget.feligres.cedula!.isEmpty
                            ? 'N/A'
                            : widget.feligres.cedula!,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

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
                icon: _isSaving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.restore, color: Colors.white),
                label: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'RESTAURAR FELIGRÉS',
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
    );
  }

  Widget _buildFixedInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEditableForm(ColorScheme colorScheme, bool isDark) {
    return Form(
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
              onChanged: _checkDuplicateName,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              decoration: InputDecoration(
                labelText: 'Nombre Completo *',
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: _nombresSimilares.isNotEmpty ? Colors.orange : null,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: _nombresSimilares.isNotEmpty
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.orange,
                          width: 2,
                        ),
                      )
                    : null,
                focusedBorder: _nombresSimilares.isNotEmpty
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.orange,
                          width: 2,
                        ),
                      )
                    : null,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Obligatorio' : null,
            ),
            if (_nombresSimilares.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Hay ${_nombresSimilares.length} coincidencia(s) similar(es):',
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ..._nombresSimilares
                        .map(
                          (n) => Text(
                            '• $n',
                            style: GoogleFonts.poppins(
                              color: Colors.orange.shade700,
                              fontSize: 11,
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Género *',
                      prefixIcon: const Icon(Icons.wc_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
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
                    validator: (value) => value == null ? 'Obligatorio' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: 'Fecha de Nacimiento',
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: EdgeInsets.zero,
                collapsedIconColor: colorScheme.primary,
                iconColor: colorScheme.primary,
                title: Text(
                  'Datos Avanzados de Secretaría',
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
                  TextFormField(
                    controller: _cedulaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Número de Cédula',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length != 10)
                          return 'Debe tener exactamente 10 dígitos';
                        if (!_validarCedulaEcuatoriana(value))
                          return 'Cédula Ecuatoriana inválida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _estadoCivil,
                    decoration: InputDecoration(
                      labelText: 'Estado Civil',
                      prefixIcon: const Icon(Icons.favorite_border),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _estadosCiviles
                        .map(
                          (estado) => DropdownMenuItem(
                            value: estado,
                            child: Text(estado),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _estadoCivil = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _tipoFeligres,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Membresía',
                      prefixIcon: const Icon(Icons.card_membership),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _tiposFeligres
                        .map(
                          (tipo) => DropdownMenuItem(
                            value: tipo,
                            child: Text(
                              tipo[0].toUpperCase() + tipo.substring(1),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _tipoFeligres = val!),
                  ),
                  const SizedBox(height: 16),
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
                    secondary: const Icon(Icons.local_fire_department_outlined),
                    value: _bautizadoEspiritu,
                    onChanged: (val) =>
                        setState(() => _bautizadoEspiritu = val),
                  ),
                  const SizedBox(height: 16),
                ],
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
                            color: isDark
                                ? const Color(0xFF1A1A2C)
                                : Colors.white,
                            fontWeight: FontWeight.w800,
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
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: Text(
                  'Eliminar Feligrés',
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
    );
  }
}
