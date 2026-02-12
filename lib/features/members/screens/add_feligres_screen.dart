import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../providers.dart';

class AddFeligresScreen extends ConsumerStatefulWidget {
  const AddFeligresScreen({super.key});

  @override
  ConsumerState<AddFeligresScreen> createState() => _AddFeligresScreenState();
}

class _AddFeligresScreenState extends ConsumerState<AddFeligresScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  Future<void> _addFeligres() async {
    if (_formKey.currentState!.validate()) {
      final database = ref.read(databaseProvider);
      final uuid = const Uuid().v4();

      await database
          .into(database.feligreses)
          .insert(
            FeligresesCompanion(
              id: drift.Value(uuid),
              nombre: drift.Value(_nombreController.text),
              telefono: drift.Value(_telefonoController.text),
              syncStatus: const drift.Value(0),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('¡Feligrés guardado!')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Feligrés')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Escribe un nombre' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono / Celular',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _addFeligres,
                  icon: const Icon(Icons.save),
                  label: const Text('GUARDAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
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
}
