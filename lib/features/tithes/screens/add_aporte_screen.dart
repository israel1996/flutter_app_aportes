import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/features/sync/services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../providers.dart';

class AddAporteScreen extends ConsumerStatefulWidget {
  const AddAporteScreen({super.key});

  @override
  ConsumerState<AddAporteScreen> createState() => _AddAporteScreenState();
}

class _AddAporteScreenState extends ConsumerState<AddAporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();

  String? _selectedFeligresId;
  String _tipoAporte = 'Diezmo';

  final List<String> _tipos = ['Diezmo', 'Ofrenda', 'Pro-Templo', 'Misiones'];

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Aporte')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Quién entrega el aporte?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              StreamBuilder<List<Feligrese>>(
                stream: database.watchAllFeligreses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  final members = snapshot.data!;

                  if (members.isEmpty) {
                    return const Text(
                      'Primero debes registrar feligreses.',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedFeligresId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    hint: const Text('Seleccionar Feligrés'),
                    items: members.map((member) {
                      return DropdownMenuItem(
                        value: member.id,
                        child: Text(member.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFeligresId = value;
                      });
                    },
                    validator: (value) => value == null ? 'Obligatorio' : null,
                  );
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monto (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa un monto';
                  if (double.tryParse(value) == null)
                    return 'Debe ser un número';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Tipo de Aporte:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                children: _tipos.map((tipo) {
                  return ChoiceChip(
                    label: Text(tipo),
                    selected: _tipoAporte == tipo,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _tipoAporte = tipo;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _addAporte,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('GUARDAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _trySyncAfterSave(WidgetRef ref) async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet =
        connectivity.contains(ConnectivityResult.mobile) ||
        connectivity.contains(ConnectivityResult.wifi);

    if (hasInternet) {
      debugPrint("Nuevo registro: Intentando sincronización automática...");
      final database = ref.read(databaseProvider);
      await SyncService(database).syncAll();
    }
  }

  Future<void> _addAporte() async {
    if (_formKey.currentState!.validate()) {
      final database = ref.read(databaseProvider);
      final uuid = const Uuid().v4();

      await database
          .into(database.aportes)
          .insert(
            AportesCompanion(
              id: drift.Value(uuid),
              feligresId: drift.Value(_selectedFeligresId!),
              monto: drift.Value(double.parse(_montoController.text)),
              tipo: drift.Value(_tipoAporte),
              fecha: drift.Value(DateTime.now()),
              syncStatus: const drift.Value(0),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aporte registrado correctamente')),
        );
        Navigator.pop(context);
        _trySyncAfterSave(ref);
      }
    }
  }
}
