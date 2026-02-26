import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Future<void> _exportToExcel(List<AporteConFeligres> aportes) async {
    setState(() => _isExporting = true);

    try {
      var excel = Excel.createExcel();
      String sheetName = 'Reporte Financiero';
      excel.rename('Sheet1', sheetName);
      Sheet sheetObject = excel[sheetName];

      sheetObject.appendRow([
        TextCellValue("Fecha"),
        TextCellValue("Feligrés"),
        TextCellValue("Tipo de Aporte"),
        TextCellValue("Monto (\$)"),
      ]);

      double total = 0;
      for (var item in aportes) {
        sheetObject.appendRow([
          TextCellValue(
            DateFormat('dd/MM/yyyy HH:mm', 'es').format(item.aporte.fecha),
          ),
          TextCellValue(item.feligres.nombre),
          TextCellValue(item.aporte.tipo),
          DoubleCellValue(item.aporte.monto),
        ]);
        total += item.aporte.monto;
      }

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

      List<int>? fileBytesList = excel.save();

      if (fileBytesList != null) {
        Uint8List fileBytes = Uint8List.fromList(fileBytesList);
        final String fileName =
            "Reporte_Aportes_${DateFormat('yyyyMMdd').format(DateTime.now())}";

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
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final historyStream = database.watchHistory();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<AporteConFeligres>>(
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

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.table_chart_rounded,
                          size: 64,
                          color: isDark
                              ? const Color(0xFF92FE9D)
                              : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Exportar a Excel',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Descargue un reporte financiero detallado en formato .xlsx. Seleccione un rango de fechas si es necesario.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),

                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: _selectedDateRange,
                            builder: (context, child) =>
                                Theme(data: Theme.of(context), child: child!),
                          );
                          if (picked != null) {
                            setState(() => _selectedDateRange = picked);
                          }
                        },
                        icon: Icon(
                          Icons.date_range,
                          color: colorScheme.primary,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _selectedDateRange == null
                                ? 'Filtrar por Fecha (Opcional)'
                                : 'Del ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} al ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                            style: GoogleFonts.poppins(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),

                      if (_selectedDateRange != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedDateRange = null),
                          child: Text(
                            'Quitar Filtro',
                            style: GoogleFonts.poppins(color: Colors.redAccent),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),

                      Text(
                        'Se exportarán ${aportes.length} registros',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF00C9FF),
                                      const Color(0xFF92FE9D),
                                    ]
                                  : [
                                      Colors.green.shade600,
                                      Colors.teal.shade500,
                                    ],
                            ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF92FE9D,
                                      ).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: (_isExporting || aportes.isEmpty)
                                ? null
                                : () => _exportToExcel(aportes),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isExporting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.download,
                                    color: Colors.white,
                                  ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'DESCARGAR REPORTE',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
