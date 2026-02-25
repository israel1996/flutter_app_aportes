import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';
import '../../sync/services/sync_service.dart';

class AddFeligresScreen extends ConsumerStatefulWidget {
  const AddFeligresScreen({super.key});

  @override
  ConsumerState<AddFeligresScreen> createState() => _AddFeligresScreenState();
}

class _AddFeligresScreenState extends ConsumerState<AddFeligresScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedGender;
  final List<String> _genderOptions = ['Masculino', 'Femenino'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
      debugPrint("☁️ Nuevo Feligrés: Intentando sincronización automática...");
      final database = ref.read(databaseProvider);
      try {
        await SyncService(database).syncAll();
      } catch (e) {
        debugPrint("Sincronización fallida: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final membersStream = database.watchAllFeligreses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Feligrés'),
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
                  final members = snapshot.data ?? [];
                  bool isDuplicate = false;
                  if (_nombreController.text.trim().isNotEmpty) {
                    isDuplicate = members.any(
                      (m) =>
                          m.nombre.toLowerCase().trim() ==
                          _nombreController.text.toLowerCase().trim(),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombres y Apellidos *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),

                      if (isDuplicate)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '¡Atención! Ya existe un feligrés con este nombre exacto.',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Género (Opcional)',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                items: _genderOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
              ),
              const SizedBox(height: 20),

              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Nacimiento (Opcional)',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Seleccionar fecha'
                        : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.grey.shade700
                          : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (Opcional)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final database = ref.read(databaseProvider);

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

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Feligrés guardado correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      _trySyncAfterSave();
                    }
                  }
                },
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Guardar Registro',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
