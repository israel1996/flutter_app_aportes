import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Para generar IDs únicos
import 'package:drift/drift.dart' as drift; // Para usar 'Value'
import '../../../core/database/database.dart';
import '../../../providers.dart'; // Para acceder a la base de datos

class AddFeligresScreen extends ConsumerStatefulWidget {
  const AddFeligresScreen({super.key});

  @override
  ConsumerState<AddFeligresScreen> createState() => _AddFeligresScreenState();
}

class _AddFeligresScreenState extends ConsumerState<AddFeligresScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  // Función para guardar en la Base de Datos Local
  Future<void> _guardarFeligres() async {
    if (_formKey.currentState!.validate()) {
      final database = ref.read(databaseProvider);
      final uuid = const Uuid()
          .v4(); // Generamos un ID único universal (Ej: a1b2-c3d4...)

      // Insertamos en la tabla 'Feligreses'
      await database
          .into(database.feligreses)
          .insert(
            FeligresesCompanion(
              id: drift.Value(uuid),
              nombre: drift.Value(_nombreController.text),
              telefono: drift.Value(_telefonoController.text),
              syncStatus: const drift.Value(
                0,
              ), // 0 = Pendiente de subir a la nube
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Feligrés guardado localmente!')),
        );
        Navigator.pop(context); // Volver atrás
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
                  onPressed: _guardarFeligres,
                  icon: const Icon(Icons.save),
                  label: const Text('GUARDAR EN DISPOSITIVO'),
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
