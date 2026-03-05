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
import 'package:printing/printing.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  // Exclusive key to capture ONLY the chart
  final GlobalKey _chartExportKey = GlobalKey();

  late Stream<List<AporteConFeligres>> _historyStream;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  DateTimeRange? _dateRange;
  int _groupingMode = 1; // 1 = Feligrés, 2 = Tipo

  // Navigation State (Detail)
  String? _selectedDetailId;
  String _selectedDetailName = '';

  // Pagination States
  int _masterCurrentPage = 1;
  int _detailCurrentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _pageOptions = [10, 20, 50, 100];

  // Chart Filters
  final Map<String, bool> _activeChartTypes = {
    'Diezmo': true,
    'Ofrenda': true,
    'Promesa': true,
    'Pro-Templo': true,
    'Especial': true,
  };

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

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() {
        _dateRange = range;
        _detailCurrentPage = 1;
      });
    }
  }

  // ==========================================
  // CLEAN NATIVE PDF EXPORT LOGIC
  // ==========================================

  // 1. Export Master List (Grouped Summary)
  Future<void> _exportMasterToPDF(
    List<Map<String, dynamic>> displayList,
  ) async {
    CustomSnackBar.showInfo(context, 'Generando Reporte PDF...');
    final pdf = pw.Document();

    // Native PDF table configuration
    pdf.addPage(
      pw.MultiPage(
        // MultiPage creates pages automatically if the table is very long
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Reporte Financiero Resumido',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Nombre / Tipo', 'Cantidad de Aportes', 'Monto Total'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              data: displayList
                  .map(
                    (item) => [
                      item['name'].toString(),
                      item['count'].toString(),
                      '\$${(item['total'] as double).toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
            ),
          ];
        },
      ),
    );
    // GENERATE THE BYTES
    final bytes = await pdf.save();

    // GET DOWNLOADS FOLDER AND SAVE DIRECTLY
    final directory = await getDownloadsDirectory();
    if (directory != null) {
      final fileName =
          'Reporte_General_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes);

      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          'PDF guardado en Descargas: $fileName',
        );
      }
    } else {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          'No se pudo encontrar la carpeta de Descargas',
        );
      }
    }
  }

  // 2. Export Detail View (Chart + Transactions)
  Future<void> _exportDetailToPDF(
    List<AporteConFeligres> targetData,
    String title,
  ) async {
    CustomSnackBar.showInfo(context, 'Capturando gráfico y generando PDF...');

    Uint8List? chartBytes;
    try {
      // Extracts ONLY the chart as a high-quality image
      RenderRepaintBoundary boundary =
          _chartExportKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      chartBytes = byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('No se pudo capturar el gráfico: $e');
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Historial Detallado: $title',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // If the chart was captured, we embed it cleanly
            if (chartBytes != null) ...[
              pw.Container(
                height: 200,
                width: double.infinity,
                child: pw.Image(
                  pw.MemoryImage(chartBytes),
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            pw.Text(
              'Lista de Transacciones Filtradas',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // Native table with ALL filtered data (ignores the UI's pagination)
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Fecha', 'Tipo de Aporte', 'Monto'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              data: targetData
                  .map(
                    (item) => [
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                        'es',
                      ).format(item.aporte.fecha),
                      item.aporte.tipo,
                      '\$${item.aporte.monto.toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
            ),
          ];
        },
      ),
    );

    // GENERATE THE BYTES
    final bytes = await pdf.save();

    // GET DOWNLOADS FOLDER AND SAVE DIRECTLY
    final directory = await getDownloadsDirectory();
    if (directory != null) {
      final safeTitle = title.replaceAll(' ', '_');
      final fileName =
          'Detalle_${safeTitle}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes);

      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          'PDF guardado en Descargas: $fileName',
        );
      }
    } else {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          'No se pudo encontrar la carpeta de Descargas',
        );
      }
    }
  }

  // ==========================================
  // MAIN WIDGET BUILDER
  // ==========================================
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
            allData = allData
                .where(
                  (item) => item.feligres.nombre.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ),
                )
                .toList();
          }

          if (_selectedDetailId != null) {
            return _buildDetailView(allData, colorScheme, isDark);
          } else {
            return _buildMasterGroupedView(allData, colorScheme, isDark);
          }
        },
      ),
    );
  }

  // ==========================================
  // VIEW 1: MASTER GROUPED LIST
  // ==========================================
  Widget _buildMasterGroupedView(
    List<AporteConFeligres> data,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final groupedMap = <String, Map<String, dynamic>>{};
    for (var item in data) {
      final key = _groupingMode == 1 ? item.feligres.id : item.aporte.tipo;
      final name = _groupingMode == 1 ? item.feligres.nombre : item.aporte.tipo;

      if (!groupedMap.containsKey(key))
        groupedMap[key] = {'id': key, 'name': name, 'total': 0.0, 'count': 0};
      groupedMap[key]!['total'] += item.aporte.monto;
      groupedMap[key]!['count'] += 1;
    }

    final displayList = groupedMap.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    // Master Pagination Logic
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
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (val) => setState(() {
                        _masterCurrentPage = 1;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // NATIVE EXPORT BUTTON (Summary)
                  ElevatedButton.icon(
                    onPressed: () => _exportMasterToPDF(
                      displayList,
                    ), // Passes the FULL list, not the paginated one
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Agrupar por Feligrés'),
                      selected: _groupingMode == 1,
                      onSelected: (v) => setState(() {
                        _groupingMode = 1;
                        _masterCurrentPage = 1;
                      }),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Agrupar por Tipo'),
                      selected: _groupingMode == 2,
                      onSelected: (v) => setState(() {
                        _groupingMode = 2;
                        _masterCurrentPage = 1;
                      }),
                    ),
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
                            _groupingMode == 1 ? Icons.person : Icons.category,
                            color: colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          item['name'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('${item['count']} aportes'),
                        trailing: Text(
                          '\$${item['total'].toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedDetailId = item['id'];
                            _selectedDetailName = item['name'];
                            _dateRange = null;
                            _detailCurrentPage = 1;
                          });
                        },
                      ),
                    );
                  },
                ),
        ),

        // UI Pagination
        if (displayList.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: colorScheme.surface,
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
                  onPressed: _masterCurrentPage > 1
                      ? () => setState(() => _masterCurrentPage--)
                      : null,
                ),
                Text(
                  'Pág $_masterCurrentPage de $totalPages',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
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

  // ==========================================
  // VIEW 2: DETAIL AND CHARTS
  // ==========================================
  Widget _buildDetailView(
    List<AporteConFeligres> allData,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final Map<String, Color> typeColors = {
      'Diezmo': const Color(0xFF4FACFE),
      'Ofrenda': const Color(0xFF92FE9D),
      'Promesa': const Color(0xFF89216B),
      'Pro-Templo': Colors.orangeAccent,
      'Especial': const Color(0xFFFF007F),
    };

    var targetData = allData.where((item) {
      if (_groupingMode == 1) return item.feligres.id == _selectedDetailId;
      return item.aporte.tipo == _selectedDetailId;
    }).toList();

    if (_dateRange != null) {
      targetData = targetData
          .where(
            (item) =>
                item.aporte.fecha.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                item.aporte.fecha.isBefore(
                  _dateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
    }

    if (_groupingMode == 1) {
      targetData = targetData
          .where((item) => _activeChartTypes[item.aporte.tipo] == true)
          .toList();
    }

    targetData.sort((a, b) => b.aporte.fecha.compareTo(a.aporte.fecha));

    // Detail Pagination Logic
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

    // Prepare Chart
    final now = DateTime.now();
    List<DateTime> last12Months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i, 1),
    ).reversed.toList();

    Map<String, Map<String, double>> groupedMonthlyData = {};
    if (_groupingMode == 1) {
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
        if (_groupingMode == 2) {
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

      if (_groupingMode == 1) {
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

              // NATIVE EXPORT BUTTON (Detail)
              ElevatedButton.icon(
                onPressed: () => _exportDetailToPDF(
                  targetData,
                  _selectedDetailName,
                ), // We pass ALL the filtered data, not just the paginated ones
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
                      InkWell(
                        onTap: _pickDateRange,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.primary),
                            borderRadius: BorderRadius.circular(16),
                            color: colorScheme.primary.withOpacity(0.05),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.date_range,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _dateRange == null
                                    ? 'Filtrar por Rango de Fechas'
                                    : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)}  -  ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
                                style: GoogleFonts.poppins(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_dateRange != null) ...[
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() {
                                    _dateRange = null;
                                    _detailCurrentPage = 1;
                                  }),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_groupingMode == 1)
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

                      // BOUNDARY ONLY FOR THE CHART
                      RepaintBoundary(
                        key: _chartExportKey,
                        child: Container(
                          height: 300,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E2C)
                                : Colors.white,
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _groupingMode == 1
                              ? LineChart(
                                  LineChartData(
                                    clipData: const FlClipData.none(),
                                    gridData: const FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
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
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
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
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
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
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
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
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
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
                                    gridData: const FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                    ),
                                    barGroups: barGroups,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      Text(
                        'Historial de Transacciones',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                                item.aporte.tipo,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                  'es',
                                ).format(item.aporte.fecha),
                              ),
                              trailing: Text(
                                '\$${item.aporte.monto.toStringAsFixed(2)}',
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    color: colorScheme.surface,
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
                          onPressed: _detailCurrentPage > 1
                              ? () => setState(() => _detailCurrentPage--)
                              : null,
                        ),
                        Text(
                          'Pág $_detailCurrentPage de $totalDetailPages',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
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
