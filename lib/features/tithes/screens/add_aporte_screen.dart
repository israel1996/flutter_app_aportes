import 'package:flutter/material.dart';
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

  // State variables
  String? _selectedFeligresId;
  String _tipoAporte = 'Diezmo'; // Default value

  // Dropdown options
  final List<String> _tipos = ['Diezmo', 'Ofrenda', 'Pro-Templo', 'Misiones'];

  @override
  Widget build(BuildContext context) {
    // 1. We get the database connection
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

              // 2. THE DROPDOWN OF MEMBERS (Async)
              // We use a StreamBuilder to listen to the list of members live
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

              // 3. AMOUNT FIELD
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

              // 4. TYPE SELECTOR (Chips)
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

              // 5. SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardarAporte,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('GUARDAR APORTE'),
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

  Future<void> _guardarAporte() async {
    if (_formKey.currentState!.validate()) {
      final database = ref.read(databaseProvider);
      final uuid = const Uuid().v4();

      // Insert into 'Aportes' table
      await database
          .into(database.aportes)
          .insert(
            AportesCompanion(
              id: drift.Value(uuid),
              feligresId: drift.Value(_selectedFeligresId!),
              monto: drift.Value(double.parse(_montoController.text)),
              tipo: drift.Value(_tipoAporte),
              fecha: drift.Value(DateTime.now()),
              syncStatus: const drift.Value(0), // 0 = Not Synced yet
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aporte registrado correctamente')),
        );
        Navigator.pop(context);
      }
    }
  }
}
