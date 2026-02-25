import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';
import '../../sync/services/sync_service.dart';

class AddAporteScreen extends ConsumerStatefulWidget {
  const AddAporteScreen({super.key});

  @override
  ConsumerState<AddAporteScreen> createState() => _AddAporteScreenState();
}

class _AddAporteScreenState extends ConsumerState<AddAporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();

  String? _selectedFeligresId;
  String? _selectedTipo;
  DateTime _selectedDate = DateTime.now();

  final List<String> _tipoOptions = [
    'Diezmo',
    'Ofrenda',
    'Primicia',
    'Fondo Especial',
  ];

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .trim();
  }

  Future<void> _showFullAddDialog(
    BuildContext context,
    List<Feligrese> existingMembers,
  ) async {
    final dialogFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String? dialogGender;
    DateTime? dialogDate;
    final List<String> genderOptions = ['Masculino', 'Femenino'];

    bool isDuplicate = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar Nuevo Feligrés'),
              content: SingleChildScrollView(
                child: Form(
                  key: dialogFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombres y Apellidos *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'El nombre es obligatorio'
                            : null,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val.trim().isNotEmpty) {
                              isDuplicate = existingMembers.any(
                                (m) =>
                                    _normalizeText(m.nombre) ==
                                    _normalizeText(val),
                              );
                            } else {
                              isDuplicate = false;
                            }
                          });
                        },
                      ),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: isDuplicate
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                  bottom: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '¡Atención! Ya existe un feligrés con este nombre exacto.',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: dialogGender,
                        decoration: const InputDecoration(
                          labelText: 'Género (Opcional)',
                          prefixIcon: Icon(Icons.people),
                        ),
                        items: genderOptions
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => dialogGender = val),
                      ),
                      const SizedBox(height: 15),

                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(
                              const Duration(days: 365 * 20),
                            ),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => dialogDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Nacimiento (Opcional)',
                            prefixIcon: Icon(Icons.cake),
                          ),
                          child: Text(
                            dialogDate == null
                                ? 'Seleccionar fecha'
                                : DateFormat('dd/MM/yyyy').format(dialogDate!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (Opcional)',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (dialogFormKey.currentState!.validate()) {
                      final newId = const Uuid().v4();
                      final database = ref.read(databaseProvider);

                      await database.insertFeligres(
                        FeligresesCompanion.insert(
                          id: newId,
                          nombre: nameController.text.trim(),
                          telefono: drift.Value(
                            phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                          ),
                          genero: drift.Value(dialogGender),
                          fechaNacimiento: drift.Value(dialogDate),
                          activo: const drift.Value(1),
                          syncStatus: const drift.Value(0),
                        ),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);

                        setState(() {
                          _selectedFeligresId = newId;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Feligrés agregado con éxito'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _trySyncAfterSave(); // Push to cloud
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _trySyncAfterSave() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet =
        connectivity.contains(ConnectivityResult.mobile) ||
        connectivity.contains(ConnectivityResult.wifi) ||
        connectivity.contains(ConnectivityResult.ethernet);
    if (hasInternet) {
      final database = ref.read(databaseProvider);
      try {
        await SyncService(database).syncAll();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final membersStream = database.watchAllFeligreses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Aporte'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<List<Feligrese>>(
                stream: membersStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final members = snapshot.data!;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Autocomplete<Feligrese>(
                          displayStringForOption: (Feligrese option) =>
                              option.nombre,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return const Iterable<Feligrese>.empty();
                            }
                            return members.where((Feligrese option) {
                              return _normalizeText(
                                option.nombre,
                              ).contains(_normalizeText(textEditingValue.text));
                            });
                          },
                          onSelected: (Feligrese selection) {
                            setState(() {
                              _selectedFeligresId = selection.id;
                            });
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          fieldViewBuilder:
                              (
                                context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                if (_selectedFeligresId != null &&
                                    textEditingController.text.isEmpty) {
                                  final selected = members.firstWhere(
                                    (m) => m.id == _selectedFeligresId,
                                    orElse: () => members.first,
                                  );
                                  textEditingController.text = selected.nombre;
                                }

                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText:
                                        'Buscar Feligrés (Escriba el nombre) *',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        textEditingController.clear();
                                        setState(
                                          () => _selectedFeligresId = null,
                                        );
                                      },
                                    ),
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (_selectedFeligresId == null) {
                                      return 'Debe seleccionar un feligrés de la lista';
                                    }
                                    return null;
                                  },
                                );
                              },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 56,
                        child: FilledButton.tonal(
                          onPressed: () => _showFullAddDialog(context, members),
                          child: const Icon(Icons.person_add),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedTipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Aporte *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _tipoOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) =>
                    value == null ? 'Seleccione el tipo' : null,
                onChanged: (newValue) =>
                    setState(() => _selectedTipo = newValue),
              ),
              const SizedBox(height: 20),

              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha del Aporte *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor (\$) *',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Ingrese un valor';
                  if (double.tryParse(value) == null) return 'Número inválido';
                  if (double.parse(value) <= 0) return 'Mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final database = ref.read(databaseProvider);

                    await database.insertAporte(
                      AportesCompanion.insert(
                        id: const Uuid().v4(),
                        feligresId: _selectedFeligresId!,
                        tipo: _selectedTipo!,
                        monto: double.parse(_montoController.text.trim()),
                        fecha: drift.Value(_selectedDate),
                        syncStatus: const drift.Value(0), // 0 = Pending sync
                      ),
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Aporte registrado con éxito'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _trySyncAfterSave(); // Push data to Supabase
                    }
                  }
                },
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Guardar Aporte', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
