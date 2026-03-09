import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/database/database.dart';
import '../../../providers.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  final GlobalKey _chartExportKey = GlobalKey();

  late Stream<List<AporteConFeligres>> _historyStream;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  DateTimeRange? _dateRange;
  int _groupingMode =
      1; // 0 = Sin agrupación, 1 = Mensual, 2 = Feligrés, 3 = Tipo

  // NUEVA VARIABLE PARA CONTROLAR EL TEMA DEL GRÁFICO AL EXPORTAR
  bool _isExportingChart = false;

  String _masterSortBy = 'Aportes más altos';
  final List<String> _masterSortOptions = [
    'Aportes más altos',
    'Aportes más bajos',
    'Nombre (A-Z)',
    'Nombre (Z-A)',
  ];

  String _detailSortBy = 'Más recientes primero';
  final List<String> _detailSortOptions = [
    'Más recientes primero',
    'Más antiguos primero',
    'Aportes más altos',
    'Aportes más bajos',
  ];

  String? _selectedDetailId;
  String _selectedDetailName = '';

  int _masterCurrentPage = 1;
  int _detailCurrentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _pageOptions = [10, 20, 50, 100];

  final Map<String, bool> _activeChartTypes = {
    'Diezmo': true,
    'Ofrenda': true,
    'Primicia': true,
    'Pro-Templo': true,
    'Especial': true,
  };

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$ ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _historyStream = ref.read(databaseProvider).watchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(bool isDetail) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (range != null) {
      setState(() {
        _dateRange = range;
        if (isDetail) {
          _detailCurrentPage = 1;
        } else {
          _masterCurrentPage = 1;
        }
      });
    }
  }

  pw.Widget _buildHeader(
    String title,
    Iglesia? currentIglesia,
    String filterText,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  currentIglesia?.nombre ?? 'Iglesia / Sede Principal',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Reporte Financiero Oficial',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Fecha de Emisión:',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  DateFormat(
                    'dd MMM yyyy, hh:mm a',
                    'es',
                  ).format(DateTime.now()),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Divider(color: PdfColors.blue900, thickness: 2),
        pw.SizedBox(height: 10),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          filterText,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10.0),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildSignatureLines() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 50),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          pw.Column(
            children: [
              pw.Container(
                width: 150,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Preparado por (Finanzas)',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.Column(
            children: [
              pw.Container(
                width: 150,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Revisado / Aprobado por',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportMasterToPDF(
    List<Map<String, dynamic>> displayList,
    Iglesia? currentIglesia,
  ) async {
    CustomSnackBar.showInfo(context, 'Generando Reporte PDF Profesional...');
    final pdf = pw.Document();

    double grandTotal = 0;
    int totalContributions = 0;
    for (var item in displayList) {
      grandTotal += item['total'] as double;
      totalContributions += _groupingMode == 0 ? 1 : (item['count'] as int);
    }

    String filterText =
        'Agrupación: ${_groupingMode == 0 ? "Sin Agrupación" : (_groupingMode == 1 ? "Mensual" : (_groupingMode == 2 ? "Por Feligrés" : "Por Tipo"))}';
    if (_dateRange != null) {
      filterText +=
          ' | Fechas: ${DateFormat('dd MMM yy').format(_dateRange!.start)} al ${DateFormat('dd MMM yy').format(_dateRange!.end)}';
    }

    pdf.addPage(
      pw.MultiPage(
        maxPages: 200,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          'Resumen General de Aportes',
          currentIglesia,
          filterText,
        ),
        footer: _buildFooter,
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'Total Recaudado',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        _currencyFormat.format(grandTotal),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'Registros Procesados',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        totalContributions.toString(),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            pw.TableHelper.fromTextArray(
              context: context,
              headers: _groupingMode == 0
                  ? ['Feligrés / Tipo', 'Fecha', 'Monto']
                  : [
                      'Categoría / Nombre',
                      'Cantidad de Aportes',
                      'Monto Total',
                    ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 11,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              cellAlignment: pw.Alignment.centerLeft,
              data: displayList
                  .map(
                    (item) => [
                      item['name'].toString(),
                      _groupingMode == 0
                          ? item['subtitle'].toString()
                          : item['count'].toString(),
                      _currencyFormat.format(item['total'] as double),
                    ],
                  )
                  .toList(),
            ),

            _buildSignatureLines(),
          ];
        },
      ),
    );

    await _saveAndNotifyPDF(pdf, 'Reporte_General');
  }

  Future<void> _exportDetailToPDF(
    List<AporteConFeligres> targetData,
    String title,
    Iglesia? currentIglesia,
  ) async {
    CustomSnackBar.showInfo(context, 'Preparando gráfico para exportación...');

    // 1. FORZAMOS EL MODO CLARO TEMPORALMENTE
    setState(() {
      _isExportingChart = true;
    });

    // 2. ESPERAMOS A QUE FLUTTER REPINTE LA PANTALLA EN BLANCO (150 milisegundos)
    await Future.delayed(const Duration(milliseconds: 150));

    Uint8List? chartBytes;
    try {
      if (_chartExportKey.currentContext != null) {
        RenderRepaintBoundary boundary =
            _chartExportKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        chartBytes = byteData!.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('No se pudo capturar el gráfico: $e');
    }

    // 3. RESTAURAMOS EL TEMA ORIGINAL DEL USUARIO INMEDIATAMENTE
    setState(() {
      _isExportingChart = false;
    });

    CustomSnackBar.showInfo(context, 'Generando documento PDF...');
    final pdf = pw.Document();

    double grandTotal = targetData.fold(
      0,
      (sum, item) => sum + item.aporte.monto,
    );
    String filterText = 'Filtro Detallado Aplicado';
    if (_dateRange != null) {
      filterText =
          'Fechas: ${DateFormat('dd MMM yy').format(_dateRange!.start)} al ${DateFormat('dd MMM yy').format(_dateRange!.end)}';
    }

    pdf.addPage(
      pw.MultiPage(
        maxPages: 200,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          'Historial Detallado: $title',
          currentIglesia,
          filterText,
        ),
        footer: _buildFooter,
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total de Aportes: ${targetData.length}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Monto Total: ${_currencyFormat.format(grandTotal)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ),

            if (chartBytes != null) ...[
              pw.Container(
                height: 180,
                width: double.infinity,
                child: pw.Image(
                  pw.MemoryImage(chartBytes),
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 25),
            ],

            pw.Text(
              'Desglose de Transacciones',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Fecha', 'Tipo', 'Feligrés', 'Monto'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 6,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              cellAlignment: pw.Alignment.centerLeft,
              data: targetData
                  .map(
                    (item) => [
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                        'es',
                      ).format(item.aporte.fecha),
                      item.aporte.tipo,
                      item.feligres.nombre,
                      _currencyFormat.format(item.aporte.monto),
                    ],
                  )
                  .toList(),
            ),

            _buildSignatureLines(),
          ];
        },
      ),
    );

    await _saveAndNotifyPDF(pdf, 'Detalle_${title.replaceAll(' ', '_')}');
  }

  Future<void> _saveAndNotifyPDF(pw.Document pdf, String baseName) async {
    final bytes = await pdf.save();
    final directory = await getDownloadsDirectory();

    if (directory != null) {
      final fileName =
          '${baseName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted)
        CustomSnackBar.showSuccess(
          context,
          'PDF guardado en Descargas:\n$fileName',
        );
    } else {
      if (mounted)
        CustomSnackBar.showError(
          context,
          'No se pudo encontrar la carpeta de Descargas',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIglesia = ref.watch(currentIglesiaProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<AporteConFeligres>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          var allData = snapshot.data ?? [];

          allData = allData
              .where(
                (item) =>
                    currentIglesia == null ||
                    item.feligres.iglesiaId == currentIglesia.id,
              )
              .toList();

          if (_searchController.text.isNotEmpty) {
            final query = _searchController.text.toLowerCase().trim();
            final isNumber =
                double.tryParse(query.replaceAll(RegExp(r'[^\d.]'), '')) !=
                null;

            allData = allData.where((item) {
              final matchName = item.feligres.nombre.toLowerCase().contains(
                query,
              );
              final matchType = item.aporte.tipo.toLowerCase().contains(query);
              final matchAmount =
                  isNumber &&
                  item.aporte.monto.toString().contains(
                    query.replaceAll(RegExp(r'[^\d.]'), ''),
                  );
              return matchName || matchType || matchAmount;
            }).toList();
          }

          if (_dateRange != null) {
            allData = allData.where((item) {
              return item.aporte.fecha.isAfter(
                    _dateRange!.start.subtract(const Duration(days: 1)),
                  ) &&
                  item.aporte.fecha.isBefore(
                    _dateRange!.end.add(const Duration(days: 1)),
                  );
            }).toList();
          }

          if (_selectedDetailId != null) {
            return _buildDetailView(
              allData,
              colorScheme,
              isDark,
              currentIglesia,
            );
          } else {
            return _buildMasterGroupedView(
              allData,
              colorScheme,
              isDark,
              currentIglesia,
            );
          }
        },
      ),
    );
  }

  Widget _buildMasterGroupedView(
    List<AporteConFeligres> data,
    ColorScheme colorScheme,
    bool isDark,
    Iglesia? currentIglesia,
  ) {
    final groupedMap = <String, Map<String, dynamic>>{};

    if (_groupingMode == 0) {
      int idx = 0;
      for (var item in data) {
        groupedMap['$idx'] = {
          'id': item.aporte.id,
          'name': '${item.feligres.nombre} - ${item.aporte.tipo}',
          'subtitle': DateFormat(
            'dd MMM yyyy, hh:mm a',
            'es',
          ).format(item.aporte.fecha),
          'total': item.aporte.monto,
          'count': 1,
        };
        idx++;
      }
    } else {
      for (var item in data) {
        String key;
        String name;

        if (_groupingMode == 1) {
          key = DateFormat('yyyy-MM').format(item.aporte.fecha);
          name = DateFormat(
            'MMMM yyyy',
            'es',
          ).format(item.aporte.fecha).toUpperCase();
        } else if (_groupingMode == 2) {
          key = item.feligres.id;
          name = item.feligres.nombre;
        } else {
          key = item.aporte.tipo;
          name = item.aporte.tipo;
        }

        if (!groupedMap.containsKey(key)) {
          groupedMap[key] = {'id': key, 'name': name, 'total': 0.0, 'count': 0};
        }
        groupedMap[key]!['total'] += item.aporte.monto;
        groupedMap[key]!['count'] += 1;
      }
    }

    final displayList = groupedMap.values.toList();

    displayList.sort((a, b) {
      if (_masterSortBy == 'Aportes más altos')
        return (b['total'] as double).compareTo(a['total'] as double);
      if (_masterSortBy == 'Aportes más bajos')
        return (a['total'] as double).compareTo(b['total'] as double);
      if (_masterSortBy == 'Nombre (A-Z)')
        return a['name'].toString().compareTo(b['name'].toString());
      if (_masterSortBy == 'Nombre (Z-A)')
        return b['name'].toString().compareTo(a['name'].toString());
      return 0;
    });

    final totalPages = (displayList.length / _itemsPerPage).ceil() == 0
        ? 1
        : (displayList.length / _itemsPerPage).ceil();
    if (_masterCurrentPage > totalPages) _masterCurrentPage = totalPages;
    if (_masterCurrentPage < 1) _masterCurrentPage = 1;

    final startIndex = (_masterCurrentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > displayList.length)
        ? displayList.length
        : startIndex + _itemsPerPage;
    final paginatedMasterList = displayList.sublist(startIndex, endIndex);

    Widget buildFilterChip(String label, int modeValue) {
      final isSelected = _groupingMode == modeValue;
      return ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : colorScheme.primary)
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: colorScheme.primary.withOpacity(0.2),
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.5)
              : Colors.transparent,
        ),
        onSelected: (v) => setState(() {
          _groupingMode = modeValue;
          _masterCurrentPage = 1;
        }),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, tipo o cantidad...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.black12
                            : Colors.grey.shade100,
                      ),
                      onChanged: (val) =>
                          setState(() => _masterCurrentPage = 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _exportMasterToPDF(displayList, currentIglesia),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: DropdownButtonFormField<String>(
                      value: _masterSortBy,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Ordenar lista por',
                        prefixIcon: const Icon(Icons.sort),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _masterSortOptions
                          .map(
                            (o) => DropdownMenuItem(
                              value: o,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  o,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _masterSortBy = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickDateRange(false),
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: const Text('Fechas'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),

              if (_dateRange != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('dd MMM yy').format(_dateRange!.start)}  -  ${DateFormat('dd MMM yy').format(_dateRange!.end)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() {
                          _dateRange = null;
                          _masterCurrentPage = 1;
                        }),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildFilterChip('Sin agrupación', 0),
                    const SizedBox(width: 8),
                    buildFilterChip('Mensual', 1),
                    const SizedBox(width: 8),
                    buildFilterChip('Por Feligrés', 2),
                    const SizedBox(width: 8),
                    buildFilterChip('Por Tipo', 3),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: paginatedMasterList.isEmpty
              ? Center(
                  child: Text(
                    'No hay datos para mostrar',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: paginatedMasterList.length,
                  itemBuilder: (context, index) {
                    final item = paginatedMasterList[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            _groupingMode == 0
                                ? Icons.monetization_on
                                : (_groupingMode == 1
                                      ? Icons.calendar_today
                                      : (_groupingMode == 2
                                            ? Icons.person
                                            : Icons.category)),
                            color: colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          item['name'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          _groupingMode == 0
                              ? item['subtitle']
                              : '${item['count']} aportes',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currencyFormat.format(item['total']),
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: colorScheme.primary,
                              ),
                            ),
                            if (_groupingMode != 0) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ],
                        ),
                        onTap: _groupingMode == 0
                            ? null
                            : () {
                                setState(() {
                                  _selectedDetailId = item['id'];
                                  _selectedDetailName = item['name'];
                                  _detailCurrentPage = 1;
                                });
                              },
                      ),
                    );
                  },
                ),
        ),

        if (displayList.isNotEmpty)
          Container(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 32,
              left: 20,
              right: 80,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Mostrar:',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _itemsPerPage,
                  underline: const SizedBox(),
                  items: _pageOptions
                      .map(
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(
                            '$i',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() {
                    _itemsPerPage = val!;
                    _masterCurrentPage = 1;
                    _detailCurrentPage = 1;
                  }),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _masterCurrentPage > 1
                      ? () => setState(() => _masterCurrentPage--)
                      : null,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Pág $_masterCurrentPage de $totalPages',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _masterCurrentPage < totalPages
                      ? () => setState(() => _masterCurrentPage++)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailView(
    List<AporteConFeligres> allData,
    ColorScheme colorScheme,
    bool isDark,
    Iglesia? currentIglesia,
  ) {
    final Map<String, Color> typeColors = {
      'Diezmo': const Color(0xFF4FACFE),
      'Ofrenda': const Color(0xFF92FE9D),
      'Primicia': const Color(0xFF89216B),
      'Pro-Templo': Colors.orangeAccent,
      'Especial': const Color(0xFFFF007F),
    };

    var targetData = allData.where((item) {
      if (_groupingMode == 1)
        return DateFormat('yyyy-MM').format(item.aporte.fecha) ==
            _selectedDetailId;
      if (_groupingMode == 2) return item.feligres.id == _selectedDetailId;
      return item.aporte.tipo == _selectedDetailId;
    }).toList();

    if (_groupingMode == 1 || _groupingMode == 2) {
      targetData = targetData
          .where((item) => _activeChartTypes[item.aporte.tipo] == true)
          .toList();
    }

    targetData.sort((a, b) {
      if (_detailSortBy == 'Más recientes primero')
        return b.aporte.fecha.compareTo(a.aporte.fecha);
      if (_detailSortBy == 'Más antiguos primero')
        return a.aporte.fecha.compareTo(b.aporte.fecha);
      if (_detailSortBy == 'Aportes más altos')
        return b.aporte.monto.compareTo(a.aporte.monto);
      if (_detailSortBy == 'Aportes más bajos')
        return a.aporte.monto.compareTo(b.aporte.monto);
      return 0;
    });

    final totalDetailPages = (targetData.length / _itemsPerPage).ceil() == 0
        ? 1
        : (targetData.length / _itemsPerPage).ceil();
    if (_detailCurrentPage > totalDetailPages)
      _detailCurrentPage = totalDetailPages;
    if (_detailCurrentPage < 1) _detailCurrentPage = 1;

    final startDetailIndex = (_detailCurrentPage - 1) * _itemsPerPage;
    final endDetailIndex =
        (startDetailIndex + _itemsPerPage > targetData.length)
        ? targetData.length
        : startDetailIndex + _itemsPerPage;
    final paginatedDetailList = targetData.sublist(
      startDetailIndex,
      endDetailIndex,
    );

    final now = DateTime.now();
    List<DateTime> last12Months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i, 1),
    ).reversed.toList();

    Map<String, Map<String, double>> groupedMonthlyData = {};
    if (_groupingMode == 1 || _groupingMode == 2) {
      for (var type in _activeChartTypes.keys.where(
        (k) => _activeChartTypes[k] == true,
      )) {
        groupedMonthlyData[type] = {
          for (var m in last12Months) DateFormat('MMM yy', 'es').format(m): 0.0,
        };
      }
    } else {
      groupedMonthlyData[_selectedDetailId!] = {
        for (var m in last12Months) DateFormat('MMM yy', 'es').format(m): 0.0,
      };
    }

    double maxY = 10;
    for (var item in targetData) {
      final key = DateFormat('MMM yy', 'es').format(item.aporte.fecha);
      final typeKey = item.aporte.tipo;
      if (groupedMonthlyData.containsKey(typeKey) &&
          groupedMonthlyData[typeKey]!.containsKey(key)) {
        groupedMonthlyData[typeKey]![key] =
            groupedMonthlyData[typeKey]![key]! + item.aporte.monto;
        if (groupedMonthlyData[typeKey]![key]! > maxY)
          maxY = groupedMonthlyData[typeKey]![key]!;
      }
    }

    List<LineChartBarData> lineBars = [];
    List<BarChartGroupData> barGroups = [];

    groupedMonthlyData.forEach((type, monthlyTotals) {
      List<FlSpot> spots = [];
      int xIndex = 0;
      final chartColor = typeColors[type] ?? colorScheme.primary;

      monthlyTotals.forEach((month, value) {
        spots.add(FlSpot(xIndex.toDouble(), value));
        if (_groupingMode == 3) {
          barGroups.add(
            BarChartGroupData(
              x: xIndex,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: chartColor,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }
        xIndex++;
      });

      if (_groupingMode == 1 || _groupingMode == 2) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: chartColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withOpacity(0.1),
            ),
          ),
        );
      }
    });

    // APLICACIÓN DEL TEMA FORZADO PARA EL PDF
    final effectiveIsDark = _isExportingChart ? false : isDark;
    final chartBgColor = effectiveIsDark
        ? const Color(0xFF1E1E2C)
        : Colors.white;
    final gridLineColor = effectiveIsDark ? Colors.white10 : Colors.black12;
    final textColor = effectiveIsDark ? Colors.grey : Colors.black87;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedDetailId = null),
              ),
              Expanded(
                child: Text(
                  _selectedDetailName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _exportDetailToPDF(
                  targetData,
                  _selectedDetailName,
                  currentIglesia,
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Exportar PDF'),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_groupingMode == 1 || _groupingMode == 2)
                        Wrap(
                          spacing: 8,
                          children: _activeChartTypes.keys.map((type) {
                            final isSelected = _activeChartTypes[type]!;
                            final badgeColor =
                                typeColors[type] ?? colorScheme.primary;
                            return FilterChip(
                              label: Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: badgeColor.withOpacity(0.9),
                              checkmarkColor: Colors.white,
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              onSelected: (val) => setState(() {
                                _activeChartTypes[type] = val;
                                _detailCurrentPage = 1;
                              }),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      RepaintBoundary(
                        key: _chartExportKey,
                        child: Container(
                          height: 300,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: chartBgColor, // Tema dinámico/forzado
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _groupingMode == 1 || _groupingMode == 2
                              ? LineChart(
                                  LineChartData(
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipColor: (touchedSpot) =>
                                            Colors.blueGrey.shade800,
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots
                                              .map(
                                                (spot) => LineTooltipItem(
                                                  _currencyFormat.format(
                                                    spot.y,
                                                  ),
                                                  const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                              .toList();
                                        },
                                      ),
                                    ),
                                    clipData: const FlClipData.none(),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) =>
                                          FlLine(
                                            color: gridLineColor,
                                            strokeWidth: 1,
                                            dashArray: [5, 5],
                                          ),
                                    ),
                                    titlesData: FlTitlesData(
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 50,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0 ||
                                                value == maxY * 1.2)
                                              return const SizedBox.shrink();
                                            return Text(
                                              NumberFormat.compactCurrency(
                                                symbol: '\$',
                                              ).format(value),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: textColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= 0 &&
                                                value.toInt() <
                                                    last12Months.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  DateFormat(
                                                    'MMM',
                                                    'es',
                                                  ).format(
                                                    last12Months[value.toInt()],
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX: 11,
                                    minY: 0,
                                    maxY: maxY * 1.2,
                                    lineBarsData: lineBars,
                                  ),
                                )
                              : BarChart(
                                  BarChartData(
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) =>
                                            Colors.blueGrey.shade800,
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                              return BarTooltipItem(
                                                _currencyFormat.format(rod.toY),
                                                const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: maxY * 1.2,
                                    titlesData: FlTitlesData(
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 50,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0 ||
                                                value == maxY * 1.2)
                                              return const SizedBox.shrink();
                                            return Text(
                                              NumberFormat.compactCurrency(
                                                symbol: '\$',
                                              ).format(value),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: textColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= 0 &&
                                                value.toInt() <
                                                    last12Months.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  DateFormat(
                                                    'MMM',
                                                    'es',
                                                  ).format(
                                                    last12Months[value.toInt()],
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) =>
                                          FlLine(
                                            color: gridLineColor,
                                            strokeWidth: 1,
                                            dashArray: [5, 5],
                                          ),
                                    ),
                                    barGroups: barGroups,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Historial de Transacciones',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              value: _detailSortBy,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.sort, size: 18),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _detailSortOptions
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o,
                                      child: Text(
                                        o,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _detailSortBy = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (targetData.isEmpty)
                        const Center(
                          child: Text(
                            'No hay registros con los filtros actuales.',
                          ),
                        )
                      else
                        ...paginatedDetailList.map((item) {
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.monetization_on,
                                color:
                                    typeColors[item.aporte.tipo] ??
                                    Colors.green,
                              ),
                              title: Text(
                                item.feligres.nombre,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${item.aporte.tipo} • ${DateFormat('dd MMM yyyy, hh:mm a', 'es').format(item.aporte.fecha)}',
                              ),
                              trailing: Text(
                                _currencyFormat.format(item.aporte.monto),
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),

                if (targetData.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.only(
                      top: 16,
                      bottom: 32,
                      left: 20,
                      right: 80,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Mostrar:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _itemsPerPage,
                          underline: const SizedBox(),
                          items: _pageOptions
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    '$i',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(() {
                            _itemsPerPage = val!;
                            _detailCurrentPage = 1;
                            _masterCurrentPage = 1;
                          }),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _detailCurrentPage > 1
                              ? () => setState(() => _detailCurrentPage--)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Pág $_detailCurrentPage de $totalDetailPages',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _detailCurrentPage < totalDetailPages
                              ? () => setState(() => _detailCurrentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
