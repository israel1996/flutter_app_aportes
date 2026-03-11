import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

// PDF Packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/database/database.dart';
import '../../../providers.dart';

class ReportesSecretariaScreen extends ConsumerStatefulWidget {
  const ReportesSecretariaScreen({super.key});

  @override
  ConsumerState<ReportesSecretariaScreen> createState() =>
      _ReportesSecretariaScreenState();
}

class _ReportesSecretariaScreenState
    extends ConsumerState<ReportesSecretariaScreen> {
  final GlobalKey _chartExportKey = GlobalKey();

  late Stream<List<Feligrese>> _membersStream;
  late TextEditingController _searchController;

  // 1=Estado Civil, 2=Género, 3=Membresía, 4=Estado Espiritual, 5=Rango de Edades, 6=Discapacidad
  int _groupingMode = 1;

  bool _isExportingChart = false;

  String? _selectedDetailCategory;

  int _detailCurrentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _pageOptions = [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _membersStream = ref.read(databaseProvider).watchAllFeligreses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return -1;
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (birthDate.month > currentDate.month ||
        (birthDate.month == currentDate.month &&
            birthDate.day > currentDate.day)) {
      age--;
    }
    return age;
  }

  String _getCategoryKey(Feligrese m) {
    switch (_groupingMode) {
      case 1:
        return m.estadoCivil?.isNotEmpty == true
            ? _capitalize(m.estadoCivil!)
            : 'No especificado';
      case 2:
        return m.genero?.isNotEmpty == true
            ? _capitalize(m.genero!)
            : 'No especificado';
      case 3:
        return m.tipoFeligres?.isNotEmpty == true
            ? _capitalize(m.tipoFeligres!)
            : 'No especificado';
      case 4:
        if (m.bautizadoAgua && m.bautizadoEspiritu) return 'Agua y Espíritu';
        if (m.bautizadoAgua) return 'Solo Agua';
        if (m.bautizadoEspiritu) return 'Solo Espíritu';
        return 'No Bautizados';
      case 5:
        int age = _calculateAge(m.fechaNacimiento);
        if (age < 0) return 'Edad desconocida';
        if (age <= 12) return 'Niños (0-12)';
        if (age <= 17) return 'Adolescentes (13-17)';
        if (age <= 25) return 'Jóvenes (18-25)';
        if (age <= 59) return 'Adultos (26-59)';
        return 'Adultos Mayores (60+)';
      case 6:
        return m.poseeDiscapacidad ? 'Con Discapacidad' : 'Sin Discapacidad';
      default:
        return 'Desconocido';
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  Color _getCategoryColor(String categoryName, ColorScheme colorScheme) {
    final normalized = categoryName
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .trim();
    final Map<String, Color> colors = {
      'soltero(a)': const Color(0xFF00C9FF),
      'casado(a)': const Color(0xFFFF007F),
      'divorciado(a)': Colors.orangeAccent,
      'viudo(a)': Colors.purpleAccent,
      'union libre': Colors.greenAccent,
      'masculino': Colors.blueAccent,
      'femenino': Colors.pinkAccent,
      'feligres': const Color(0xFF00C9FF),
      'simpatizante': Colors.orangeAccent,
      'visita': Colors.greenAccent,
      'agua y espiritu': Colors.blueAccent,
      'solo agua': Colors.cyan,
      'solo espiritu': Colors.deepOrangeAccent,
      'no bautizados': Colors.grey,
      'niños (0-12)': Colors.tealAccent,
      'adolescentes (13-17)': Colors.lightBlueAccent,
      'jovenes (18-25)': Colors.indigoAccent,
      'adultos (26-59)': Colors.blueGrey,
      'adultos mayores (60+)': Colors.deepPurpleAccent,
      'edad desconocida': Colors.brown,
      'con discapacidad': Colors.purpleAccent,
      'sin discapacidad': Colors.grey.shade400,
      'no especificado': Colors.grey.shade400,
    };
    return colors[normalized] ?? colorScheme.primary;
  }

  // ==========================================
  // PDF WIDGETS
  // ==========================================
  pw.Widget _buildPdfHeader(String title, Iglesia? currentIglesia) {
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
                  'Reporte Oficial de Secretaría',
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
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10.0),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildPdfSignatures() {
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
              pw.Text('Secretario(a)', style: const pw.TextStyle(fontSize: 12)),
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

  // ==========================================
  // EXPORTS
  // ==========================================
  Future<void> _exportMasterToPDF(
    List<Map<String, dynamic>> displayList,
    String reportTitle,
    Iglesia? currentIglesia,
  ) async {
    CustomSnackBar.showInfo(context, 'Preparando gráfico...');

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
      debugPrint('Chart capture failed: $e');
    }

    setState(() => _isExportingChart = false);

    CustomSnackBar.showInfo(context, 'Generando Documento PDF...');
    final pdf = pw.Document();

    int totalPersonas = displayList.fold(
      0,
      (sum, item) => sum + (item['count'] as int),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(
          'Resumen Demográfico: $reportTitle',
          currentIglesia,
        ),
        footer: _buildPdfFooter,
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
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Total de Registros Analizados: ',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    totalPersonas.toString(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ],
              ),
            ),

            if (chartBytes != null) ...[
              pw.Container(
                height: 250,
                width: double.infinity,
                child: pw.Image(
                  pw.MemoryImage(chartBytes),
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 30),
            ],

            pw.TableHelper.fromTextArray(
              context: context,
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
              },
              headers: ['#', 'Categoría / Grupo', 'Cantidad de Personas'],
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
                  item['count'].toString(),
                ];
              }).toList(),
            ),

            _buildPdfSignatures(),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getDownloadsDirectory();
    if (directory != null) {
      final fileName =
          'Reporte_Demografico_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted)
        CustomSnackBar.showSuccess(context, 'PDF generado exitosamente');
      await OpenFilex.open(file.path);
    } else {
      if (mounted)
        CustomSnackBar.showError(
          context,
          'No se pudo encontrar la carpeta de Descargas',
        );
    }
  }

  Future<void> _exportDetailToPDF(
    List<Feligrese> targetData,
    String title,
    Iglesia? currentIglesia,
  ) async {
    CustomSnackBar.showInfo(context, 'Generando PDF del directorio...');
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) =>
            _buildPdfHeader('Directorio Filtrado: $title', currentIglesia),
        footer: _buildPdfFooter,
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Text(
                'Total en este grupo: ${targetData.length} personas',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.TableHelper.fromTextArray(
              context: context,
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              headers: [
                '#',
                'Nombre Completo',
                'Teléfono',
                'Membresía',
                'Estado Civil',
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 6,
              ),
              data: targetData.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                return [
                  index.toString(),
                  item.nombre,
                  item.telefono ?? 'N/A',
                  item.tipoFeligres != null
                      ? _capitalize(item.tipoFeligres!)
                      : 'N/A',
                  item.estadoCivil != null
                      ? _capitalize(item.estadoCivil!)
                      : 'N/A',
                ];
              }).toList(),
            ),
            _buildPdfSignatures(),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getDownloadsDirectory();
    if (directory != null) {
      final safeTitle = title.replaceAll(' ', '_');
      final fileName =
          'Directorio_${safeTitle}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted)
        CustomSnackBar.showSuccess(
          context,
          'PDF guardado en Descargas:\n$fileName',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Feligrese>>(
        stream: _membersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final currentIglesia = ref.watch(currentIglesiaProvider);
          var allData = snapshot.data ?? [];

          allData = allData
              .where(
                (m) =>
                    m.activo == 1 &&
                    (currentIglesia == null ||
                        m.iglesiaId == currentIglesia.id),
              )
              .toList();

          if (_selectedDetailCategory != null) {
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
    List<Feligrese> data,
    ColorScheme colorScheme,
    bool isDark,
    Iglesia? currentIglesia,
  ) {
    final groupedMap = <String, Map<String, dynamic>>{};
    for (var m in data) {
      final key = _getCategoryKey(m);
      if (!groupedMap.containsKey(key)) {
        groupedMap[key] = {'name': key, 'count': 0};
      }
      groupedMap[key]!['count'] += 1;
    }

    List<Map<String, dynamic>> displayList = groupedMap.values.toList();

    if (_groupingMode == 5) {
      final ageOrder = [
        'Niños (0-12)',
        'Adolescentes (13-17)',
        'Jóvenes (18-25)',
        'Adultos (26-59)',
        'Adultos Mayores (60+)',
        'Edad desconocida',
      ];
      displayList.sort(
        (a, b) =>
            ageOrder.indexOf(a['name']).compareTo(ageOrder.indexOf(b['name'])),
      );
    } else if (_groupingMode == 4) {
      final spiritOrder = [
        'Agua y Espíritu',
        'Solo Agua',
        'Solo Espíritu',
        'No Bautizados',
      ];
      displayList.sort(
        (a, b) => spiritOrder
            .indexOf(a['name'])
            .compareTo(spiritOrder.indexOf(b['name'])),
      );
    } else {
      displayList.sort(
        (a, b) => (b['count'] as int).compareTo(a['count'] as int),
      );
    }

    String getReportTitle() {
      switch (_groupingMode) {
        case 1:
          return 'Estado Civil';
        case 2:
          return 'Género';
        case 3:
          return 'Tipo de Membresía';
        case 4:
          return 'Estado Espiritual';
        case 5:
          return 'Generaciones (Edades)';
        case 6:
          return 'Necesidades Especiales';
        default:
          return 'Reporte';
      }
    }

    // PDF EXPORT THEME FORCING
    final effectiveIsDark = _isExportingChart ? false : isDark;
    final chartBgColor = effectiveIsDark
        ? const Color(0xFF1E1E2C)
        : Colors.white;
    final textColor = effectiveIsDark ? Colors.white70 : Colors.black87;
    final gridColor = effectiveIsDark ? Colors.white10 : Colors.black12;

    int maxY = 10;
    for (var item in displayList) {
      if (item['count'] > maxY) maxY = item['count'] as int;
    }

    // =====================================
    // DYNAMIC CHART RENDERER (RESPONSIVE)
    // =====================================
    Widget buildDynamicChart() {
      if (displayList.isEmpty) return const Center(child: Text('Sin datos'));

      // 1. PIE & DONUT CHARTS (Civil Status, Gender, Discapacidad)
      if (_groupingMode == 1 || _groupingMode == 2 || _groupingMode == 6) {
        return Column(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: _groupingMode == 1 ? 40 : 0,
                  sections: displayList.map((item) {
                    final double percentage =
                        (item['count'] / data.length) * 100;
                    final categoryColor = _getCategoryColor(
                      item['name'],
                      colorScheme,
                    );
                    return PieChartSectionData(
                      value: item['count'].toDouble(),
                      color: categoryColor,
                      title:
                          '${item['count']}\n(${percentage.toStringAsFixed(1)}%)',
                      radius: _groupingMode == 1 ? 60 : 90,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: displayList.map((item) {
                final categoryColor = _getCategoryColor(
                  item['name'],
                  colorScheme,
                );
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: textColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      }
      // 3. VERTICAL BAR CHART (Membership)
      else if (_groupingMode == 3) {
        return BarChart(
          BarChartData(
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.blueGrey.shade800,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} personas',
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
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value % 1 != 0 || value == 0)
                      return const SizedBox.shrink();
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(color: textColor, fontSize: 11),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < 0 ||
                        value.toInt() >= displayList.length)
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        displayList[value.toInt()]['name'],
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: gridColor, strokeWidth: 1, dashArray: [5, 5]),
            ),
            barGroups: displayList.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value['count'].toDouble(),
                    color: _getCategoryColor(entry.value['name'], colorScheme),
                    width: 25,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      }
      // 4. HORIZONTAL CUSTOM BAR CHART (Spiritual Status)
      else if (_groupingMode == 4) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: displayList.map((item) {
            double pct = data.isEmpty
                ? 0
                : (item['count'] as int) / data.length;
            Color barColor = _getCategoryColor(item['name'], colorScheme);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '${item['count']} (${(pct * 100).toStringAsFixed(1)}%)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: gridColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }
      // 5. AREA LINE CHART (Generations / Age Ranges)
      else {
        List<FlSpot> spots = [];
        for (int i = 0; i < displayList.length; i++) {
          spots.add(FlSpot(i.toDouble(), displayList[i]['count'].toDouble()));
        }

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => Colors.blueGrey.shade800,
                  getTooltipItems: (touchedSpots) => touchedSpots
                      .map(
                        (spot) => LineTooltipItem(
                          '${spot.y.toInt()} personas',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: gridColor, strokeWidth: 1, dashArray: [5, 5]),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 != 0 || value == 0 || value == maxY * 1.2)
                        return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(color: textColor, fontSize: 11),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < 0 ||
                          value.toInt() >= displayList.length)
                        return const SizedBox.shrink();

                      String label = displayList[value.toInt()]['name'];
                      label = label
                          .replaceAll(' ', '\n')
                          .replaceAll('(', '\n(');

                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (displayList.length - 1).toDouble(),
              minY: 0,
              maxY: maxY * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: colorScheme.primary,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) => spot.y > 0,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

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
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Agrupaciones Demográficas',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _exportMasterToPDF(
                      displayList,
                      getReportTitle(),
                      currentIglesia,
                    ),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text(
                      'Exportar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      elevation: 0,
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
                      label: const Text('Estado Civil'),
                      selected: _groupingMode == 1,
                      onSelected: (v) => setState(() => _groupingMode = 1),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Género'),
                      selected: _groupingMode == 2,
                      onSelected: (v) => setState(() => _groupingMode = 2),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Membresía'),
                      selected: _groupingMode == 3,
                      onSelected: (v) => setState(() => _groupingMode = 3),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('E. Espiritual'),
                      selected: _groupingMode == 4,
                      onSelected: (v) => setState(() => _groupingMode = 4),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Edades'),
                      selected: _groupingMode == 5,
                      onSelected: (v) => setState(() => _groupingMode = 5),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Discapacidad'),
                      selected: _groupingMode == 6,
                      onSelected: (v) => setState(() => _groupingMode = 6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isNotEmpty)
                  RepaintBoundary(
                    key: _chartExportKey,
                    child: Container(
                      height: 320,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: chartBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: buildDynamicChart(),
                    ),
                  ),

                const SizedBox(height: 24),
                Text(
                  'Detalle de Grupos',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ...displayList.map((item) {
                  final categoryColor = _getCategoryColor(
                    item['name'],
                    colorScheme,
                  );
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: categoryColor.withOpacity(0.2),
                        child: Icon(Icons.groups, color: categoryColor),
                      ),
                      title: Text(
                        item['name'],
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item['count']} pers.',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () => setState(() {
                        _selectedDetailCategory = item['name'];
                        _detailCurrentPage = 1;
                        _searchController.clear();
                      }),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(
    List<Feligrese> allData,
    ColorScheme colorScheme,
    bool isDark,
    Iglesia? currentIglesia,
  ) {
    var targetData = allData
        .where((m) => _getCategoryKey(m) == _selectedDetailCategory)
        .toList();

    if (_searchController.text.isNotEmpty) {
      targetData = targetData
          .where(
            (item) => item.nombre.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }

    targetData.sort((a, b) => a.nombre.compareTo(b.nombre));

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
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () =>
                        setState(() => _selectedDetailCategory = null),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_selectedDetailCategory',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _exportDetailToPDF(
                      targetData,
                      _selectedDetailCategory!,
                      currentIglesia,
                    ),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text(
                      'Exportar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar en este grupo...',
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.black12 : Colors.grey.shade100,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _detailCurrentPage = 1;
                          }),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _detailCurrentPage = 1),
              ),
            ],
          ),
        ),

        Expanded(
          child: paginatedDetailList.isEmpty
              ? const Center(
                  child: Text('No hay registros con esos criterios.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: paginatedDetailList.length,
                  itemBuilder: (context, index) {
                    final member = paginatedDetailList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.person, color: colorScheme.primary),
                        ),
                        title: Text(
                          member.nombre,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          member.telefono ?? 'Sin teléfono',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              member.tipoFeligres != null
                                  ? _capitalize(member.tipoFeligres!)
                                  : 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              member.estadoCivil != null
                                  ? _capitalize(member.estadoCivil!)
                                  : '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        if (targetData.isNotEmpty)
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
                    _detailCurrentPage = 1;
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
    );
  }
}
