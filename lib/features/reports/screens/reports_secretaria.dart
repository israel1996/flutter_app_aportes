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

  // Grouping modes: 1 = Estado Civil, 2 = Género, 3 = Tipo Membresía, 4 = Bautismo (Agua)
  int _groupingMode = 1;

  // Drill-down State
  String? _selectedDetailCategory;

  // Pagination States
  int _detailCurrentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _pageOptions = [10, 20, 50, 100];

  final Map<String, Color> _categoryColors = {
    'Soltero': const Color(0xFF00C9FF),
    'Casado': const Color(0xFFFF007F),
    'Divorciado': Colors.orangeAccent,
    'Viudo': Colors.purpleAccent,
    'Unión libre': Colors.greenAccent,
    'Masculino': Colors.blueAccent,
    'Femenino': Colors.pinkAccent,
    'Feligres': const Color(0xFF00C9FF),
    'Simpatizante': Colors.orangeAccent,
    'Visita': Colors.greenAccent,
    'Bautizado': Colors.blueAccent,
    'No bautizado': Colors.grey,
    'No especificado': Colors.blueGrey,
  };

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

  // Capitalize the first letter to ensure it matches the _categoryColors perfectly
  String _capitalize(String s) =>
      s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  String _getCategoryKey(Feligrese m) {
    switch (_groupingMode) {
      case 1:
        return m.estadoCivil != null
            ? _capitalize(m.estadoCivil!)
            : 'No especificado';
      case 2:
        return m.genero != null ? _capitalize(m.genero!) : 'No especificado';
      case 3:
        return m.tipoFeligres != null
            ? _capitalize(m.tipoFeligres!)
            : 'No especificado';
      case 4:
        return m.bautizadoAgua ? 'Bautizado' : 'No bautizado';
      default:
        return 'Desconocido';
    }
  }

  // ==========================================
  // DIRECT PDF EXPORT LOGIC
  // ==========================================

  Future<void> _exportMasterToPDF(
    List<Map<String, dynamic>> displayList,
    String reportTitle,
  ) async {
    CustomSnackBar.showInfo(context, 'Generando Reporte PDF...');

    Uint8List? chartBytes;
    try {
      RenderRepaintBoundary boundary =
          _chartExportKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      chartBytes = byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('Chart capture failed: $e');
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
                    'Reporte Demográfico: $reportTitle',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

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
              headers: ['Categoría', 'Cantidad de Personas'],
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
                    ],
                  )
                  .toList(),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getDownloadsDirectory();
    if (directory != null) {
      final fileName =
          'Reporte_Demografico_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted)
        CustomSnackBar.showSuccess(
          context,
          'PDF guardado en Descargas: $fileName',
        );
    }
  }

  Future<void> _exportDetailToPDF(
    List<Feligrese> targetData,
    String title,
  ) async {
    CustomSnackBar.showInfo(context, 'Generando PDF de miembros...');
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
                    'Directorio: $title',
                    style: pw.TextStyle(
                      fontSize: 20,
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
              columnWidths: {
                0: const pw.FixedColumnWidth(25), // #
                1: const pw.FlexColumnWidth(2.5), // Nombre
                2: const pw.FlexColumnWidth(1.2), // Teléfono
                3: const pw.FlexColumnWidth(1.2), // Membresía
                4: const pw.FlexColumnWidth(1.2), // Estado civil
              },
              headers: [
                '#',
                'Nombre Completo',
                'Teléfono',
                'Tipo Membresía',
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
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              data: targetData.asMap().entries.map((entry) {
                final index = entry.key + 1; // Creates the sequence
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
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getDownloadsDirectory();
    if (directory != null) {
      final safeTitle = title.replaceAll(' ', '_');
      final fileName =
          'Directorio_${safeTitle}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted)
        CustomSnackBar.showSuccess(
          context,
          'PDF guardado en Descargas: $fileName',
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
          // FILTER ACTIVE MEMBERS AND MATCHING CHURCH
          allData = allData
              .where(
                (m) =>
                    m.activo == 1 &&
                    (currentIglesia == null ||
                        m.iglesiaId == currentIglesia.id),
              )
              .toList();

          if (_selectedDetailCategory != null) {
            return _buildDetailView(allData, colorScheme, isDark);
          } else {
            return _buildMasterGroupedView(allData, colorScheme, isDark);
          }
        },
      ),
    );
  }

  // ==========================================
  // VIEW 1: MASTER DEMOGRAPHICS (PIE CHART)
  // ==========================================
  // ==========================================
  // VIEW 1: MASTER DEMOGRAPHICS (PIE CHART)
  // ==========================================
  Widget _buildMasterGroupedView(
    List<Feligrese> data,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final groupedMap = <String, Map<String, dynamic>>{};
    for (var m in data) {
      final key = _getCategoryKey(m);
      if (!groupedMap.containsKey(key)) {
        groupedMap[key] = {'name': key, 'count': 0};
      }
      groupedMap[key]!['count'] += 1;
    }

    final displayList = groupedMap.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    String getReportTitle() {
      switch (_groupingMode) {
        case 1:
          return 'Estado Civil';
        case 2:
          return 'Género';
        case 3:
          return 'Tipo de Membresía';
        case 4:
          return 'Bautismos (Agua)';
        default:
          return 'Reporte';
      }
    }

    // --- ROBUST COLOR MATCHER ---
    Color getCategoryColor(String categoryName) {
      final normalized = categoryName.toLowerCase().replaceAll('é', 'e').trim();
      final Map<String, Color> colors = {
        'soltero': const Color(0xFF00C9FF),
        'casado': const Color(0xFFFF007F),
        'divorciado': Colors.orangeAccent,
        'viudo': Colors.purpleAccent,
        'union libre': Colors.greenAccent,
        'masculino': Colors.blueAccent,
        'femenino': Colors.pinkAccent,
        'feligres': const Color(0xFF00C9FF),
        'simpatizante': Colors.orangeAccent,
        'visita': Colors.greenAccent,
        'bautizado': Colors.blueAccent,
        'no bautizado': Colors.grey,
        'no especificado': Colors.blueGrey,
      };
      return colors[normalized] ??
          colorScheme.primary; // Fallback to primary if not found
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agrupaciones Demográficas',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _exportMasterToPDF(displayList, getReportTitle()),
                    icon: const Icon(Icons.download),
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
                      label: const Text('Bautismo'),
                      selected: _groupingMode == 4,
                      onSelected: (v) => setState(() => _groupingMode = 4),
                    ),
                  ],
                ),
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
                // PIE CHART
                if (data.isNotEmpty)
                  RepaintBoundary(
                    key: _chartExportKey,
                    child: Container(
                      height: 280,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 50,
                                sections: displayList.map((item) {
                                  final double percentage =
                                      (item['count'] / data.length) * 100;
                                  final categoryColor = getCategoryColor(
                                    item['name'],
                                  ); // APPLY SAFE COLOR
                                  return PieChartSectionData(
                                    value: item['count'].toDouble(),
                                    color: categoryColor,
                                    title:
                                        '${item['count']}\n(${percentage.toStringAsFixed(1)}%)',
                                    radius: 50,
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
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: displayList.map((item) {
                                final categoryColor = getCategoryColor(
                                  item['name'],
                                ); // APPLY SAFE COLOR
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: categoryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['name'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
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
                  final categoryColor = getCategoryColor(
                    item['name'],
                  ); // APPLY SAFE COLOR
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
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
                            '${item['count']} personas',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

  // ==========================================
  // VIEW 2: DETAIL (MEMBER DIRECTORY LIST)
  // ==========================================
  Widget _buildDetailView(
    List<Feligrese> allData,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    var targetData = allData
        .where((m) => _getCategoryKey(m) == _selectedDetailCategory)
        .toList();

    // Apply internal search filter
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

    // Pagination
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () =>
                        setState(() => _selectedDetailCategory = null),
                  ),
                  Expanded(
                    child: Text(
                      'Directorio: $_selectedDetailCategory',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportDetailToPDF(
                      targetData,
                      _selectedDetailCategory!,
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // SEARCH FILTER ONLY IN DETAIL VIEW
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar en este grupo...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.black12 : Colors.grey.shade100,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
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
                  padding: const EdgeInsets.all(24),
                  itemCount: paginatedDetailList.length,
                  itemBuilder: (context, index) {
                    final member = paginatedDetailList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.person, color: colorScheme.primary),
                        ),
                        title: Text(
                          member.nombre,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          member.telefono ?? 'Sin teléfono',
                          style: const TextStyle(color: Colors.grey),
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

        // Detail Pagination Controls
        if (targetData.isNotEmpty)
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
                    _detailCurrentPage = 1;
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
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
    );
  }
}
