import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
import 'package:flutter_app_aportes/features/members/widgets/add_feligres_sheet.dart';
import 'package:flutter_app_aportes/features/sync/services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

    String text = newValue.text.replaceAll(',', '');

    List<String> parts = text.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    if (parts.length > 1 && parts[1].length > 2) {
      decimalPart = '.${parts[1].substring(0, 2)}';
    }

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

class AddAporteSheet extends ConsumerStatefulWidget {
  const AddAporteSheet({super.key});

  @override
  ConsumerState<AddAporteSheet> createState() => _AddAporteSheetState();
}

class _AddAporteSheetState extends ConsumerState<AddAporteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _dateController = TextEditingController();

  TextEditingController? _searchController;

  String? _selectedFeligresId;
  String? _selectedTipo = 'Diezmo';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _noResults = false;

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
    _dateController.text = DateFormat(
      'dd MMM yyyy',
      'es',
    ).format(_selectedDate);
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

  Future<void> _pickDate() async {
    // Quitar foco para evitar bug visual
    FocusScope.of(context).unfocus();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      initialEntryMode:
          DatePickerEntryMode.calendarOnly, // Desactiva escritura manual
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

  Future<void> _saveAporte() async {
    if (!_formKey.currentState!.validate()) return;

    final double? montoFinal = double.tryParse(
      _montoController.text.replaceAll(',', '').trim(),
    );

    final currentIglesia = ref.read(currentIglesiaProvider);
    if (currentIglesia == null) {
      CustomSnackBar.showError(
        context,
        'Debes registrar o seleccionar una Sede.',
      );
      return;
    }
    if (_selectedFeligresId == null || _selectedTipo == null) {
      CustomSnackBar.showWarning(
        context,
        'Seleccione el feligrés y el tipo de aporte',
      );
      return;
    }
    if (montoFinal == null || montoFinal <= 0) {
      CustomSnackBar.showWarning(context, 'El monto debe ser mayor a \$0.00');
      return;
    }

    setState(() => _isSaving = true);
    final database = ref.read(databaseProvider);

    try {
      await database.insertAporte(
        AportesCompanion.insert(
          id: const Uuid().v4(),
          feligresId: _selectedFeligresId!,
          monto: montoFinal,
          tipo: _selectedTipo!,
          fecha: drift.Value(_selectedDate),
          syncStatus: const drift.Value(0),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccess(context, 'Aporte registrado exitosamente');
      }

      Connectivity().checkConnectivity().then((connectivity) {
        final hasInternet =
            connectivity.contains(ConnectivityResult.mobile) ||
            connectivity.contains(ConnectivityResult.wifi) ||
            connectivity.contains(ConnectivityResult.ethernet);

        if (hasInternet && ref.read(authServiceProvider).currentUser != null) {
          final syncService = SyncService(database);
          syncService.syncAll().catchError(
            (e) => debugPrint("Auto-sync failed: $e"),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Error al guardar localmente: $e');
      }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Registrar Aporte',
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

              StreamBuilder<List<Feligrese>>(
                stream: database.watchAllFeligreses(),
                builder: (context, snapshot) {
                  final currentIglesia = ref.watch(currentIglesiaProvider);
                  final members =
                      snapshot.data
                          ?.where(
                            (m) =>
                                m.activo == 1 &&
                                (currentIglesia == null ||
                                    m.iglesiaId == currentIglesia.id),
                          )
                          .toList() ??
                      [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Autocomplete<Feligrese>(
                        displayStringForOption: (Feligrese option) =>
                            option.nombre,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            Future.microtask(() {
                              if (mounted && _noResults)
                                setState(() => _noResults = false);
                            });
                            return const Iterable<Feligrese>.empty();
                          }

                          final query = _normalizeString(textEditingValue.text);
                          final matches = members.where((Feligrese member) {
                            final nombreNormalizado = _normalizeString(
                              member.nombre,
                            );
                            return nombreNormalizado.contains(query);
                          });

                          Future.microtask(() {
                            if (mounted && _noResults != matches.isEmpty) {
                              setState(() => _noResults = matches.isEmpty);
                            }
                          });

                          return matches;
                        },
                        onSelected: (Feligrese selection) {
                          setState(() {
                            _selectedFeligresId = selection.id;
                            _noResults = false;
                          });
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              _searchController = controller;

                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                readOnly: _selectedFeligresId != null,
                                onFieldSubmitted: (String value) {
                                  if (value.isNotEmpty) {
                                    final query = _normalizeString(value);
                                    final match = members
                                        .where(
                                          (m) => _normalizeString(
                                            m.nombre,
                                          ).contains(query),
                                        )
                                        .firstOrNull;

                                    if (match != null) {
                                      setState(() {
                                        _selectedFeligresId = match.id;
                                        controller.text = match.nombre;
                                        _noResults = false;
                                      });
                                    }
                                  }
                                  onFieldSubmitted();
                                },
                                decoration: InputDecoration(
                                  labelText: 'Buscar Feligrés *',
                                  hintText: 'Escriba el nombre...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: _selectedFeligresId != null
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _selectedFeligresId = null;
                                              controller.clear();
                                              _noResults = false;
                                              focusNode.requestFocus();
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                validator: (value) =>
                                    _selectedFeligresId == null
                                    ? 'Debe seleccionar un feligrés'
                                    : null,
                              );
                            },
                      ),

                      if (_noResults && _selectedFeligresId == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0, right: 8.0),
                          child: Text(
                            'No existe el feligrés',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const AddFeligresSheet(),
                          ).then((_) {
                            if (mounted) {
                              setState(() {
                                _selectedFeligresId = null;
                                _searchController?.clear();
                                _noResults = false;
                              });
                            }
                          });
                        },
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: Text(
                          'Registrar Nuevo Feligrés',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedTipo,
                      decoration: InputDecoration(
                        labelText: 'Tipo *',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
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
                    flex: 3,
                    child: TextFormField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                        NaturalCurrencyInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Monto *',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Obligatorio';
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
                decoration: InputDecoration(
                  labelText: 'Fecha del Aporte',
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
