import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/database/database.dart';
import '../../../providers.dart';

class AddIglesiaSheet extends ConsumerStatefulWidget {
  const AddIglesiaSheet({super.key});

  @override
  ConsumerState<AddIglesiaSheet> createState() => _AddIglesiaSheetState();
}

class _AddIglesiaSheetState extends ConsumerState<AddIglesiaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  int? _distritoSeleccionado;
  String? _categoriaSeleccionada;
  DateTime? _fechaLlegada;
  DateTime? _fechaSalida;

  final List<int> _distritos = List.generate(16, (i) => i + 1);
  final List<String> _categorias = [
    'Misionera',
    'En formación',
    'Formada',
    'Consolidada',
    'Emblemática',
  ];

  void _guardarIglesia() async {
    if (_formKey.currentState!.validate()) {
      final database = ref.read(databaseProvider);

      final nuevaIglesia = IglesiasCompanion(
        id: drift.Value(const Uuid().v4()),
        nombre: drift.Value(_nombreController.text.trim()),
        distrito: drift.Value(_distritoSeleccionado!),
        categoria: drift.Value(_categoriaSeleccionada),
        fechaLlegada: drift.Value(_fechaLlegada),
        fechaSalida: drift.Value(_fechaSalida),
      );

      await database.insertIglesia(nuevaIglesia);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sede registrada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarFecha(bool isLlegada) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2050),
    );
    if (date != null) {
      setState(() {
        if (isLlegada)
          _fechaLlegada = date;
        else
          _fechaSalida = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrar Sede (Iglesia)',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Name (Required)
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Iglesia *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // District (Required)
                DropdownButtonFormField<int>(
                  value: _distritoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Distrito (1-16) *',
                    border: OutlineInputBorder(),
                  ),
                  items: _distritos
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text('Distrito $d'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _distritoSeleccionado = val),
                  validator: (value) => value == null ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Category (Optional)
                DropdownButtonFormField<String>(
                  value: _categoriaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Categoría (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _categoriaSeleccionada = val),
                ),
                const SizedBox(height: 16),

                // Dates (Optional)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _seleccionarFecha(true),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _fechaLlegada == null
                              ? 'Llegada'
                              : DateFormat(
                                  'dd MMM yyyy',
                                ).format(_fechaLlegada!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _seleccionarFecha(false),
                        icon: const Icon(Icons.event_busy, size: 16),
                        label: Text(
                          _fechaSalida == null
                              ? 'Salida'
                              : DateFormat('dd MMM yyyy').format(_fechaSalida!),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _guardarIglesia,
                    child: Text(
                      'Guardar Iglesia',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
