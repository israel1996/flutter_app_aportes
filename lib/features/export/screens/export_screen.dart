import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';
import 'package:excel/excel.dart'; // The new Excel package
import 'package:intl/intl.dart';

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

  // --- LOGIC TO GENERATE AND SAVE A BEAUTIFUL .XLSX FILE ---
  Future<void> _exportToExcel(List<AporteConFeligres> aportes) async {
    setState(() => _isExporting = true);

    try {
      // 1. Create a new Excel Document
      var excel = Excel.createExcel();

      // Rename the default sheet
      String sheetName = 'Reporte Financiero';
      excel.rename('Sheet1', sheetName);
      Sheet sheetObject = excel[sheetName];

      // 2. Add the Headers
      sheetObject.appendRow([
        TextCellValue("Fecha"),
        TextCellValue("Feligrés"),
        TextCellValue("Tipo de Aporte"),
        TextCellValue("Monto (\$)"),
      ]);

      // 3. Loop through the data and add it to the sheet
      double total = 0;
      for (var item in aportes) {
        sheetObject.appendRow([
          TextCellValue(
            DateFormat('dd/MM/yyyy HH:mm').format(item.aporte.fecha),
          ),
          TextCellValue(item.feligres.nombre),
          TextCellValue(item.aporte.tipo),
          DoubleCellValue(
            item.aporte.monto,
          ), // Saves as a real number in Excel!
        ]);
        total += item.aporte.monto;
      }

      // Add a blank row, then the Total row
      sheetObject.appendRow([
        TextCellValue(""),
        TextCellValue(""),
        TextCellValue(""),
        TextCellValue(""),
      ]);
      sheetObject.appendRow([
        TextCellValue(""),
        TextCellValue(""),
        TextCellValue("TOTAL:"),
        DoubleCellValue(total),
      ]);

      // 4. Convert the Excel file to bytes
      List<int>? fileBytesList = excel.save();

      if (fileBytesList != null) {
        Uint8List fileBytes = Uint8List.fromList(fileBytesList);
        final String fileName =
            "Reporte_Aportes_${DateFormat('yyyyMMdd').format(DateTime.now())}";

        // 5. Trigger the Save/Download dialog across all platforms
        if (kIsWeb) {
          await FileSaver.instance.saveFile(
            name: fileName,
            bytes: fileBytes,
            fileExtension: 'xlsx',
            mimeType: MimeType.microsoftExcel,
          );
        } else {
          await FileSaver.instance.saveAs(
            name: fileName,
            bytes: fileBytes,
            fileExtension: 'xlsx',
            mimeType: MimeType.microsoftExcel,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Archivo Excel exportado con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
                const Icon(
                  Icons.table_chart,
                  size: 80,
                  color: Colors.green,
                ), // Changed to green Excel color
                const SizedBox(height: 20),
                const Text(
                  'Generar Reporte Excel',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Exporte los registros financieros en formato .xlsx. Las columnas estarán separadas y los montos listos para sumar.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

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
                      : () => _exportToExcel(aportes),
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
                    'Descargar Archivo Excel',
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
