import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// PDF Packages
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
  final GlobalKey _exportKey = GlobalKey();

  // STATE CACHING (Fixes the focus bug)
  late Stream<List<AporteConFeligres>> _historyStream;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  DateTimeRange? _dateRange;
  int _groupingMode = 1; // 1 = Feligrés, 2 = Tipo

  // Drill-down State
  String? _selectedDetailId;
  String _selectedDetailName = '';

  // Chart Toggle States for the Detail View
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
    // Cache the stream so typing doesn't destroy the widget tree
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
      setState(() => _dateRange = range);
    }
  }

  // --- REAL PDF EXPORT LOGIC ---
  Future<void> _exportCurrentViewToPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando PDF... por favor espere.')),
    );

    try {
      // 1. Capture the screen as an image
      RenderRepaintBoundary boundary =
          _exportKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. Create the PDF Document
      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat:
              PdfPageFormat.a4.landscape, // Landscape fits charts better
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(imageProvider));
          },
        ),
      );

      // 3. Open the Native Save Dialog / Preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'Reporte_Financiero_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      key: _exportKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<List<AporteConFeligres>>(
          stream: _historyStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());

            var allData = snapshot.data ?? [];

            // Apply Master Filters
            if (_dateRange != null) {
              allData = allData
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
            if (_searchController.text.isNotEmpty) {
              allData = allData
                  .where(
                    (item) => item.feligres.nombre.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ),
                  )
                  .toList();
            }

            // --- VIEW SWITCHER ---
            if (_selectedDetailId != null) {
              return _buildDetailView(allData, colorScheme, isDark);
            } else {
              return _buildMasterGroupedView(allData, colorScheme, isDark);
            }
          },
        ),
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
              // INTUITIVE DATE RANGE BUTTON
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
                      Icon(Icons.date_range, color: colorScheme.primary),
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
                          onPressed: () => setState(() => _dateRange = null),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                      onChanged: (val) =>
                          setState(() {}), // Trigger rebuild for search
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _exportCurrentViewToPDF,
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
                      onSelected: (v) => setState(() => _groupingMode = 1),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Agrupar por Tipo'),
                      selected: _groupingMode == 2,
                      onSelected: (v) => setState(() => _groupingMode = 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: displayList.isEmpty
              ? Center(
                  child: Text(
                    'No hay datos para mostrar',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final item = displayList[index];
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
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 2: DETAIL VIEW WITH REAL CHARTS
  // ==========================================
  // ==========================================
  // VIEW 2: DETAIL VIEW WITH REAL CHARTS
  // ==========================================
  Widget _buildDetailView(
    List<AporteConFeligres> allData,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    // --- 1. DEFINE CUSTOM COLORS FOR EACH TYPE ---
    final Map<String, Color> typeColors = {
      'Diezmo': const Color(0xFF4FACFE), // Neon Blue
      'Ofrenda': const Color(0xFF92FE9D), // Bright Green
      'Promesa': const Color(0xFF89216B), // Deep Purple
      'Pro-Templo': Colors.orangeAccent, // Orange
      'Especial': const Color(0xFFFF007F), // Pink
    };

    // 2. Filter data specific to the selected item
    var targetData = allData.where((item) {
      if (_groupingMode == 1) return item.feligres.id == _selectedDetailId;
      return item.aporte.tipo == _selectedDetailId;
    }).toList();

    // 3. Filter by selected toggles (Only if viewing a Parishioner)
    if (_groupingMode == 1) {
      targetData = targetData
          .where((item) => _activeChartTypes[item.aporte.tipo] == true)
          .toList();
    }

    // 4. Prepare Chart Data (Group by Type AND Month)
    final now = DateTime.now();
    List<DateTime> last12Months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i, 1),
    ).reversed.toList();

    // Initialize map structure for multiple lines
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
      final typeKey = item.aporte.tipo; // Group by type to draw separate lines

      if (groupedMonthlyData.containsKey(typeKey) &&
          groupedMonthlyData[typeKey]!.containsKey(key)) {
        groupedMonthlyData[typeKey]![key] =
            groupedMonthlyData[typeKey]![key]! + item.aporte.monto;
        if (groupedMonthlyData[typeKey]![key]! > maxY)
          maxY = groupedMonthlyData[typeKey]![key]!;
      }
    }

    // 5. Generate Multi-Colored LineSpots and BarGroups
    List<LineChartBarData> lineBars = [];
    List<BarChartGroupData> barGroups = [];

    groupedMonthlyData.forEach((type, monthlyTotals) {
      List<FlSpot> spots = [];
      int xIndex = 0;
      final chartColor =
          typeColors[type] ?? colorScheme.primary; // Apply custom color!

      monthlyTotals.forEach((month, value) {
        spots.add(FlSpot(xIndex.toDouble(), value));

        // Build bars for "Por Tipo" mode
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

      // Build multiple lines for "Por Feligrés" mode
      if (_groupingMode == 1) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: chartColor, // Apply custom color!
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
        // DETAIL HEADER
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
                onPressed: _exportCurrentViewToPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MULTI-COLORED CHART TOGGLES
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
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: badgeColor.withOpacity(
                          0.9,
                        ), // Toggles match the line colors!
                        checkmarkColor: Colors.white,
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        onSelected: (val) =>
                            setState(() => _activeChartTypes[type] = val),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),

                // THE CHART
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.white,
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0 || value == maxY * 1.2)
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
                                        value.toInt() < last12Months.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          DateFormat(
                                            'MMM',
                                            'es',
                                          ).format(last12Months[value.toInt()]),
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
                            lineBarsData:
                                lineBars, // Render the multiple colored lines here!
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY * 1.2,
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0 || value == maxY * 1.2)
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
                                        value.toInt() < last12Months.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          DateFormat(
                                            'MMM',
                                            'es',
                                          ).format(last12Months[value.toInt()]),
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

                const SizedBox(height: 30),
                Text(
                  'Historial de Transacciones',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // THE TRANSACTIONS LIST
                if (targetData.isEmpty)
                  const Center(
                    child: Text('No hay registros con los filtros actuales.'),
                  )
                else
                  ...targetData.map((item) {
                    return Card(
                      child: ListTile(
                        // Match the icon color to the specific contribution type
                        leading: Icon(
                          Icons.monetization_on,
                          color: typeColors[item.aporte.tipo] ?? Colors.green,
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
        ),
      ],
    );
  }
}
