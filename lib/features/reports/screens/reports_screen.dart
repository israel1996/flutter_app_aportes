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

  // ESTADO PARA MOSTRAR/OCULTAR FILTROS
  bool _showFilters = false;

  DateTimeRange? _dateRange;
  int _groupingMode =
      1; // 0 = Sin agrupación, 1 = Mensual, 2 = Feligrés, 3 = Tipo

  bool _isExportingChart = false;

  late String _masterSortBy;
  List<String> _getSortOptionsForMode(int mode) {
    if (mode == 0)
      return [
        'Más reciente primero',
        'Más antiguo primero',
        'Más alto primero',
        'Más bajo primero',
      ];
    if (mode == 1) return ['De enero a diciembre', 'De diciembre a enero'];
    if (mode == 2) return ['Nombre (A-Z)', 'Nombre (Z-A)'];
    if (mode == 3) return ['Menores aportes primero', 'Mayor aportes primero'];
    return [];
  }

  String _getDefaultSortForMode(int mode) {
    return _getSortOptionsForMode(mode).first;
  }

  String _detailSortBy = 'Más recientes primero';
  final List<String> _detailSortOptions = [
    'Más recientes primero',
    'Más antiguos primero',
    'Aportes más altos',
    'Aportes más bajos',
  ];

  String? _selectedDetailId;
  String _selectedDetailName = '';

  int? _selectedYear;

  int _masterCurrentPage = 1;
  int _detailCurrentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _pageOptions = [10, 20, 50, 100];

  final Map<String, bool> _activeChartTypes = {};

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
    _masterSortBy = _getDefaultSortForMode(_groupingMode);
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

  bool _hasActiveFilters() {
    return _masterSortBy != _getDefaultSortForMode(_groupingMode) ||
        _dateRange != null;
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
              pw.Text('Diácono(a)', style: const pw.TextStyle(fontSize: 12)),
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
              pw.Text('Pastor', style: const pw.TextStyle(fontSize: 12)),
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
    CustomSnackBar.showInfo(context, 'Generando Reporte PDF...');
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
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              headers: [
                '#',
                _groupingMode == 0 ? 'Feligrés / Tipo' : 'Categoría / Nombre',
                _groupingMode == 0 ? 'Fecha' : 'Cantidad de Aportes',
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
              data: displayList.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                return [
                  index.toString(),
                  item['name'].toString(),
                  _groupingMode == 0
                      ? item['subtitle'].toString()
                      : item['count'].toString(),
                  _currencyFormat.format(item['total'] as double),
                ];
              }).toList(),
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

    setState(() => _isExportingChart = true);
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

    setState(() => _isExportingChart = false);

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
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(1.5),
              },
              headers: ['#', 'Fecha', 'Tipo', 'Feligrés', 'Monto'],
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
              data: targetData.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                return [
                  index.toString(),
                  DateFormat(
                    'dd MMM yyyy, hh:mm a',
                    'es',
                  ).format(item.aporte.fecha),
                  item.aporte.tipo,
                  item.feligres.nombre,
                  _currencyFormat.format(item.aporte.monto),
                ];
              }).toList(),
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
          'rawDate': item.aporte.fecha,
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
      if (_groupingMode == 0) {
        DateTime dateA = a['rawDate'];
        DateTime dateB = b['rawDate'];
        if (_masterSortBy == 'Más reciente primero')
          return dateB.compareTo(dateA);
        if (_masterSortBy == 'Más antiguo primero')
          return dateA.compareTo(dateB);
        if (_masterSortBy == 'Más alto primero')
          return (b['total'] as double).compareTo(a['total'] as double);
        if (_masterSortBy == 'Más bajo primero')
          return (a['total'] as double).compareTo(b['total'] as double);
      } else if (_groupingMode == 1) {
        if (_masterSortBy == 'De enero a diciembre')
          return a['id'].toString().compareTo(b['id'].toString());
        if (_masterSortBy == 'De diciembre a enero')
          return b['id'].toString().compareTo(a['id'].toString());
      } else if (_groupingMode == 2) {
        if (_masterSortBy == 'Nombre (A-Z)')
          return a['name'].toString().compareTo(b['name'].toString());
        if (_masterSortBy == 'Nombre (Z-A)')
          return b['name'].toString().compareTo(a['name'].toString());
      } else if (_groupingMode == 3) {
        if (_masterSortBy == 'Mayor aportes primero')
          return (b['total'] as double).compareTo(a['total'] as double);
        if (_masterSortBy == 'Menores aportes primero')
          return (a['total'] as double).compareTo(b['total'] as double);
      }
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
            fontSize: 12,
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
        onSelected: (v) {
          if (v) {
            setState(() {
              _groupingMode = modeValue;
              _masterSortBy = _getDefaultSortForMode(modeValue);
              _masterCurrentPage = 1;
            });
          }
        },
      );
    }

    return Column(
      children: [
        // --- HEADER COMPACTO CON FILTROS OCULTOS ---
        Container(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 16,
            top: 10,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar registros...',
                          hintStyle: const TextStyle(fontSize: 14),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
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
                  ),
                  const SizedBox(width: 8),
                  // BOTÓN PARA MOSTRAR/OCULTAR FILTROS Y PDF
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: _hasActiveFilters()
                          ? colorScheme.primary
                          : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: _hasActiveFilters()
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                    ),
                  ),
                ],
              ),

              // SECCIÓN DESPLEGABLE
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showFilters
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Filtros Avanzados',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        if (_hasActiveFilters())
                          InkWell(
                            onTap: () {
                              setState(() {
                                _masterSortBy = _getDefaultSortForMode(
                                  _groupingMode,
                                );
                                _dateRange = null;
                                _masterCurrentPage = 1;
                              });
                            },
                            child: Text(
                              'Limpiar Todo',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: 45,
                            child: DropdownButtonFormField<String>(
                              value: _masterSortBy,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Ordenar lista por',
                                labelStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: _getSortOptionsForMode(_groupingMode)
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o,
                                      child: Text(
                                        o,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _masterSortBy = val!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 45,
                            child: ElevatedButton.icon(
                              onPressed: () => _pickDateRange(false),
                              icon: const Icon(
                                Icons.calendar_month_outlined,
                                size: 16,
                              ),
                              label: const Text(
                                'Fechas',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                                backgroundColor: colorScheme.primary
                                    .withOpacity(0.1),
                                foregroundColor: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_dateRange != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.filter_alt,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${DateFormat('dd MMM yy').format(_dateRange!.start)} - ${DateFormat('dd MMM yy').format(_dateRange!.end)}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => setState(() {
                                _dateRange = null;
                                _masterCurrentPage = 1;
                              }),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _exportMasterToPDF(displayList, currentIglesia),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('Exportar Reporte General PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: paginatedMasterList.length,
                  itemBuilder: (context, index) {
                    final item = paginatedMasterList[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
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
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          _groupingMode == 0
                              ? item['subtitle']
                              : '${item['count']} aportes',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currencyFormat.format(item['total']),
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                            if (_groupingMode != 0) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade400,
                                size: 20,
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
                                  _selectedYear = null;
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
              top: 12,
              bottom: 24,
              left: 20,
              right: 20,
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
                  'Ver:',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _itemsPerPage,
                  underline: const SizedBox(),
                  iconSize: 20,
                  items: _pageOptions
                      .map(
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text(
                            '$i',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                  icon: const Icon(Icons.chevron_left, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _masterCurrentPage > 1
                      ? () => setState(() => _masterCurrentPage--)
                      : null,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '$_masterCurrentPage / $totalPages',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
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

    var baseData = allData.where((item) {
      if (_groupingMode == 1)
        return DateFormat('yyyy-MM').format(item.aporte.fecha) ==
            _selectedDetailId;
      if (_groupingMode == 2) return item.feligres.id == _selectedDetailId;
      return item.aporte.tipo == _selectedDetailId;
    }).toList();

    List<int> availableYears = [];
    int currentYear = DateTime.now().year;

    if (_groupingMode == 2 || _groupingMode == 3) {
      availableYears = baseData.map((e) => e.aporte.fecha.year).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
      if (availableYears.isNotEmpty) {
        currentYear = _selectedYear ?? availableYears.first;
        if (!availableYears.contains(currentYear))
          currentYear = availableYears.first;
      }
      baseData = baseData
          .where((item) => item.aporte.fecha.year == currentYear)
          .toList();
    }

    Set<String> existingTypes = {};
    if (_groupingMode == 1 || _groupingMode == 2) {
      existingTypes = baseData.map((e) => e.aporte.tipo).toSet();
      for (var type in existingTypes) {
        _activeChartTypes.putIfAbsent(type, () => true);
      }
    }

    var targetData = baseData;
    if (_groupingMode == 1 || _groupingMode == 2) {
      targetData = targetData
          .where((item) => _activeChartTypes[item.aporte.tipo] == true)
          .toList();
    }

    targetData.sort((a, b) {
      final timeA = a.aporte.fecha;
      final timeB = b.aporte.fecha;
      if (_detailSortBy == 'Más recientes primero')
        return timeB.compareTo(timeA);
      if (_detailSortBy == 'Más antiguos primero')
        return timeA.compareTo(timeB);
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

    List<String> xAxisLabels = [];
    Map<String, Map<String, double>> groupedChartData = {};

    if (_groupingMode == 1) {
      xAxisLabels = ['Semana 1', 'Semana 2', 'Semana 3', 'Semana 4'];
      for (var type in existingTypes) {
        if (_activeChartTypes[type] == true) {
          groupedChartData[type] = {for (var w in xAxisLabels) w: 0.0};
        }
      }
      for (var item in targetData) {
        int day = item.aporte.fecha.day;
        int weekIndex = (day - 1) ~/ 7;
        if (weekIndex > 3) weekIndex = 3;
        String weekKey = xAxisLabels[weekIndex];
        groupedChartData[item.aporte.tipo]![weekKey] =
            groupedChartData[item.aporte.tipo]![weekKey]! + item.aporte.monto;
      }
    } else {
      xAxisLabels = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ];
      if (_groupingMode == 2) {
        for (var type in existingTypes) {
          if (_activeChartTypes[type] == true) {
            groupedChartData[type] = {for (var m in xAxisLabels) m: 0.0};
          }
        }
      } else {
        groupedChartData[_selectedDetailId!] = {
          for (var m in xAxisLabels) m: 0.0,
        };
      }
      for (var item in targetData) {
        String monthKey = xAxisLabels[item.aporte.fecha.month - 1];
        String typeKey = _groupingMode == 2
            ? item.aporte.tipo
            : _selectedDetailId!;
        groupedChartData[typeKey]![monthKey] =
            groupedChartData[typeKey]![monthKey]! + item.aporte.monto;
      }
    }

    double maxY = 10;
    for (var totals in groupedChartData.values) {
      for (var val in totals.values) {
        if (val > maxY) maxY = val;
      }
    }

    List<LineChartBarData> lineBars = [];
    List<BarChartGroupData> barGroups = [];
    List<String> activeTypesList = groupedChartData.keys.toList();

    if (_groupingMode == 1) {
      for (int xIndex = 0; xIndex < xAxisLabels.length; xIndex++) {
        List<BarChartRodData> rods = [];
        String xLabel = xAxisLabels[xIndex];

        for (var type in activeTypesList) {
          double val = groupedChartData[type]![xLabel] ?? 0.0;
          final chartColor = typeColors[type] ?? colorScheme.primary;
          rods.add(
            BarChartRodData(
              toY: val,
              color: chartColor,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }
        barGroups.add(
          BarChartGroupData(x: xIndex, barRods: rods, barsSpace: 4),
        );
      }
    } else if (_groupingMode == 3) {
      String type = _selectedDetailId!;
      Map<String, double> dataPoints = groupedChartData[type] ?? {};
      for (int xIndex = 0; xIndex < xAxisLabels.length; xIndex++) {
        double val = dataPoints[xAxisLabels[xIndex]] ?? 0.0;
        final chartColor = typeColors[type] ?? colorScheme.primary;
        barGroups.add(
          BarChartGroupData(
            x: xIndex,
            barRods: [
              BarChartRodData(
                toY: val,
                color: chartColor,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
    } else if (_groupingMode == 2) {
      groupedChartData.forEach((type, dataPoints) {
        List<FlSpot> spots = [];
        int xIndex = 0;
        final chartColor = typeColors[type] ?? colorScheme.primary;

        dataPoints.forEach((label, value) {
          spots.add(FlSpot(xIndex.toDouble(), value));
          xIndex++;
        });

        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: chartColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) => spot.y > 0,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withOpacity(0.1),
            ),
          ),
        );
      });
    }

    final effectiveIsDark = _isExportingChart ? false : isDark;
    final chartBgColor = effectiveIsDark
        ? const Color(0xFF1E1E2C)
        : Colors.white;
    final gridLineColor = effectiveIsDark ? Colors.white10 : Colors.black12;
    final textColor = effectiveIsDark ? Colors.grey : Colors.black87;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 16,
            top: 10,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() {
                      _selectedDetailId = null;
                      _selectedYear = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedDetailName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportDetailToPDF(
                      targetData,
                      _selectedDetailName,
                      currentIglesia,
                    ),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text(
                      'Exportar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _groupingMode == 1 || _groupingMode == 2
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Wrap(
                              spacing: 6,
                              children: existingTypes.map((type) {
                                final isSelected =
                                    _activeChartTypes[type] ?? true;
                                final badgeColor =
                                    typeColors[type] ?? colorScheme.primary;
                                return FilterChip(
                                  label: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 11,
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
                                  padding: const EdgeInsets.all(0),
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
                          )
                        : const SizedBox.shrink(),
                  ),

                  if ((_groupingMode == 2 || _groupingMode == 3) &&
                      availableYears.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: currentYear,
                          icon: Icon(
                            Icons.calendar_month,
                            color: colorScheme.primary,
                            size: 14,
                          ),
                          style: GoogleFonts.poppins(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          items: availableYears
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Text('$y'),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _selectedYear = val);
                          },
                        ),
                      ),
                    ),
                ],
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gráfico
                      RepaintBoundary(
                        key: _chartExportKey,
                        child: Container(
                          height: 250, // Altura optimizada para móvil
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: chartBgColor,
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _groupingMode == 2
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
                                                    fontSize: 11,
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
                                          reservedSize: 35,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0 ||
                                                value == maxY * 1.2)
                                              return const SizedBox.shrink();
                                            return Text(
                                              NumberFormat.compactCurrency(
                                                symbol: '\$',
                                              ).format(value),
                                              style: TextStyle(
                                                fontSize: 10,
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
                                                    xAxisLabels.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  xAxisLabels[value.toInt()],
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
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
                                    maxX: (xAxisLabels.length - 1).toDouble(),
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
                                              String typeLabel = '';
                                              if (_groupingMode == 1 &&
                                                  rodIndex <
                                                      activeTypesList.length) {
                                                typeLabel =
                                                    '${activeTypesList[rodIndex]}\n';
                                              }
                                              return BarTooltipItem(
                                                '$typeLabel${_currencyFormat.format(rod.toY)}',
                                                const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
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
                                          reservedSize: 35,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0 ||
                                                value == maxY * 1.2)
                                              return const SizedBox.shrink();
                                            return Text(
                                              NumberFormat.compactCurrency(
                                                symbol: '\$',
                                              ).format(value),
                                              style: TextStyle(
                                                fontSize: 10,
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
                                                    xAxisLabels.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  xAxisLabels[value.toInt()],
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
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

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Historial',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            height: 35,
                            child: DropdownButtonFormField<String>(
                              value: _detailSortBy,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.sort, size: 16),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 0,
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
                                        style: const TextStyle(fontSize: 10),
                                        overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 8),

                      if (targetData.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'No hay registros con los filtros actuales.',
                            ),
                          ),
                        )
                      else
                        ...paginatedDetailList.map((item) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.monetization_on,
                                color:
                                    typeColors[item.aporte.tipo] ??
                                    Colors.green,
                                size: 28,
                              ),
                              title: Text(
                                item.feligres.nombre,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                '${item.aporte.tipo} • ${DateFormat('dd MMM yy, hh:mm a', 'es').format(item.aporte.fecha)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Text(
                                _currencyFormat.format(item.aporte.monto),
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
                      top: 12,
                      bottom: 24,
                      left: 16,
                      right: 16,
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
                          'Ver:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _itemsPerPage,
                          underline: const SizedBox(),
                          iconSize: 20,
                          items: _pageOptions
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    '$i',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
                          icon: const Icon(Icons.chevron_left, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _detailCurrentPage > 1
                              ? () => setState(() => _detailCurrentPage--)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '$_detailCurrentPage / $totalDetailPages',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
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
