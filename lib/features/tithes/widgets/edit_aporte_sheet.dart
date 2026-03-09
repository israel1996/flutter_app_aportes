import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class NaturalCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove existing commas to get the raw string
    String text = newValue.text.replaceAll(',', '');

    // Split into integer and decimal parts based on the dot
    List<String> parts = text.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // Prevent more than 2 decimal digits
    if (parts.length > 1 && parts[1].length > 2) {
      decimalPart = '.${parts[1].substring(0, 2)}';
    }

    // Format the integer part with thousands separators
    if (integerPart.isNotEmpty) {
      final number = int.tryParse(integerPart);
      if (number != null) {
        final formatter = NumberFormat('#,###', 'en_US');
        integerPart = formatter.format(number);
      }
    }

    String finalString = integerPart + decimalPart;

    return TextEditingValue(
      text: finalString,
      selection: TextSelection.collapsed(offset: finalString.length),
    );
  }
}

class EditAporteSheet extends ConsumerStatefulWidget {
  final AporteConFeligres aporteItem;

  const EditAporteSheet({super.key, required this.aporteItem});

  @override
  ConsumerState<EditAporteSheet> createState() => _EditAporteSheetState();
}

class _EditAporteSheetState extends ConsumerState<EditAporteSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _montoController;
  final _dateController = TextEditingController();

  late String _selectedTipo;
  late DateTime _selectedDate;
  bool _isSaving = false;

  final List<String> _tiposAporte = [
    'Diezmo',
    'Ofrenda',
    'Primicia',
    'Pro-Templo',
    'Especial',
  ];

  @override
  void initState() {
    super.initState();
    // Extraemos solo el número, ej: "10.50"
    final formatter = NumberFormat('#,##0.##', 'en_US');
    _montoController = TextEditingController(
      text: formatter.format(widget.aporteItem.aporte.monto),
    );

    final tipo = widget.aporteItem.aporte.tipo.trim();
    _selectedTipo = _tiposAporte.contains(tipo) ? tipo : _tiposAporte.first;

    _selectedDate = widget.aporteItem.aporte.fecha;
    _dateController.text = DateFormat(
      'dd MMM yyyy',
      'es',
    ).format(_selectedDate);
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
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMM yyyy', 'es').format(picked);
      });
    }
  }

  Future<void> _updateAporte() async {
    if (!_formKey.currentState!.validate()) return;

    final double? montoFinal = double.tryParse(
      _montoController.text.replaceAll(',', '').trim(),
    );

    if (montoFinal == null || montoFinal <= 0) {
      CustomSnackBar.showWarning(context, 'El monto debe ser mayor a \$0.00');
      return;
    }

    setState(() => _isSaving = true);
    final database = ref.read(databaseProvider);

    try {
      await database
          .update(database.aportes)
          .replace(
            widget.aporteItem.aporte.copyWith(
              monto: montoFinal,
              tipo: _selectedTipo,
              fecha: _selectedDate,
              syncStatus: 0,
            ),
          );

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccess(context, 'Aporte actualizado');
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
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet =
          connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);

      if (!hasInternet) {
        throw Exception(
          'Se requiere conexión a internet para eliminar un registro financiero.',
        );
      }

      final supabase = Supabase.instance.client;
      await supabase
          .from('aportes')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', widget.aporteItem.aporte.id);

      await (database.delete(
        database.aportes,
      )..where((tbl) => tbl.id.equals(widget.aporteItem.aporte.id))).go();

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showWarning(context, 'Aporte eliminado permanentemente');
      }

      Future.microtask(() {
        final authService = ref.read(authServiceProvider);
        if (authService.currentUser != null) {
          SyncService(
            database,
          ).syncAll().catchError((e) => debugPrint("Sync error: $e"));
        }
      });
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Error al eliminar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _dateController.dispose();
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
                    flex: 3,
                    child: TextFormField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      // USE THE NEW FORMATTER HERE:
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[\d.,]'),
                        ), // Allow digits, dots, and commas
                        NaturalCurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Monto *',
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Obligatorio';
                        // Ignore commas for validation
                        if (double.tryParse(value.replaceAll(',', '')) == null)
                          return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Fecha del Aporte',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
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
