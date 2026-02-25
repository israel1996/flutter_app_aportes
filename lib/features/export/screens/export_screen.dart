import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTimeRange? _selectedDateRange;
  bool _isExporting = false;

  // --- LOGIC TO GENERATE AND SAVE THE EXCEL (CSV) FILE ---
  Future<void> _exportToCSV(List<AporteConFeligres> aportes) async {
    setState(() => _isExporting = true);

    try {
      // 1. Build the CSV string manually
      final StringBuffer csvBuffer = StringBuffer();
      // Added a special character (BOM) so Excel reads accents correctly
      csvBuffer.write('\uFEFF');
      csvBuffer.writeln("Fecha;Feligrés;Tipo de Aporte;Monto (\$);");

      // 2. Loop through the data
      double total = 0;
      for (var item in aportes) {
        final date = DateFormat('dd/MM/yyyy HH:mm').format(item.aporte.fecha);
        final name = item.feligres.nombre.replaceAll(';', ',');
        final type = item.aporte.tipo.replaceAll(';', ',');
        final amount = item.aporte.monto.toStringAsFixed(2);

        csvBuffer.writeln("$date;$name;$type;$amount;");
        total += item.aporte.monto;
      }

      csvBuffer.writeln(";;TOTAL:;${total.toStringAsFixed(2)};");

      // 3. Convert the string into pure data bytes (Web & Desktop safe)
      Uint8List fileBytes = Uint8List.fromList(
        utf8.encode(csvBuffer.toString()),
      );
      final String fileName =
          "Reporte_Aportes_${DateFormat('yyyyMMdd').format(DateTime.now())}";

      // 4. Trigger the Save/Download dialog across all platforms
      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: fileBytes,
          fileExtension: 'csv',
          mimeType: MimeType.csv,
        );
      } else {
        // Lógica para Windows y Android (Abre el menú "Guardar como...")
        await FileSaver.instance.saveAs(
          name: fileName,
          bytes: fileBytes,
          fileExtension:
              'csv', // Recuerda cambiar a fileExtension si tu versión lo requiere
          mimeType: MimeType.csv,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Archivo exportado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final historyStream = database.watchHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Datos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<List<AporteConFeligres>>(
        stream: historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var aportes = snapshot.data ?? [];

          // Filter by selected dates if applicable
          if (_selectedDateRange != null) {
            aportes = aportes.where((a) {
              return a.aporte.fecha.isAfter(
                    _selectedDateRange!.start.subtract(const Duration(days: 1)),
                  ) &&
                  a.aporte.fecha.isBefore(
                    _selectedDateRange!.end.add(const Duration(days: 1)),
                  );
            }).toList();
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.table_view, size: 80, color: Colors.indigo),
                const SizedBox(height: 20),
                const Text(
                  'Generar Reporte Excel (CSV)',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Exporte los registros financieros para abrirlos en Excel. Puede filtrar por fechas antes de exportar.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // ---------------------------------------------------------
                // DATE FILTER BUTTON
                // ---------------------------------------------------------
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateRange = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Filtrar por Fecha (Opcional)'
                        : 'Del ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} al ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                  ),
                ),
                if (_selectedDateRange != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedDateRange = null),
                    child: const Text(
                      'Quitar Filtro',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                const Spacer(),

                // ---------------------------------------------------------
                // EXPORT BUTTON
                // ---------------------------------------------------------
                Text(
                  'Se exportarán ${aportes.length} registros',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade700,
                  ),
                  onPressed: (_isExporting || aportes.isEmpty)
                      ? null
                      : () => _exportToCSV(aportes),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: const Text(
                    'Descargar Archivo',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
