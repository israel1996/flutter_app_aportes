import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../widgets/add_feligres_sheet.dart';
import '../widgets/edit_feligres_sheet.dart';
import '../../../core/database/database.dart';
import '../../../providers.dart';

class FeligresesScreen extends ConsumerStatefulWidget {
  const FeligresesScreen({super.key});

  @override
  ConsumerState<FeligresesScreen> createState() => _FeligresesScreenState();
}

class _FeligresesScreenState extends ConsumerState<FeligresesScreen> {
  late Stream<List<Feligrese>> _membersStream;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  bool _showDeleted = false;
  bool _showFilters = false;

  String _sortBy = 'Más Recientes';
  String _filterTipo = 'Todos';
  String _filterGenero = 'Todos';
  String _filterEstadoCivil = 'Todos';
  String _filterEstadoEspiritual = 'Todos';
  String _filterDiscapacidad = 'Todos';

  int _currentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _pageOptions = [10, 20, 50, 100];

  final List<String> _sortOptions = [
    'Más Recientes',
    'Más Antiguos',
    'Nombre (A-Z)',
    'Nombre (Z-A)',
  ];
  final List<String> _tipoOptions = [
    'Todos',
    'Feligres',
    'Simpatizante',
    'Visita',
  ];
  final List<String> _generoOptions = ['Todos', 'Masculino', 'Femenino'];
  final List<String> _estadoCivilOptions = [
    'Todos',
    'Soltero(a)',
    'Casado(a)',
    'Divorciado(a)',
    'Viudo(a)',
    'Unión Libre',
  ];
  final List<String> _estadoEspiritualOptions = [
    'Todos',
    'Agua y Espíritu',
    'Solo Agua',
    'Solo Espíritu',
    'No Bautizado',
  ];
  final List<String> _discapacidadOptions = ['Todos', 'Sí', 'No'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _membersStream = ref.read(databaseProvider).watchAllFeligreses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _exportFeligresesToPDF(List<Feligrese> members) async {
    CustomSnackBar.showInfo(context, 'Generando PDF del Directorio...');
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Directorio de Feligreses Filtrado',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.2),
                6: const pw.FlexColumnWidth(1.5),
                7: const pw.FlexColumnWidth(1),
              },
              headers: [
                '#',
                'Nombre Completo',
                'Teléfono',
                'Género',
                'Estado Civil',
                'Membresía',
                'Bautismo\n(Agua / Esp.)',
                'Discapacidad',
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
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
              cellStyle: const pw.TextStyle(fontSize: 8),
              data: members.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final m = entry.value;
                return [
                  index.toString(),
                  m.nombre,
                  m.telefono ?? 'N/A',
                  m.genero ?? 'N/A',
                  m.estadoCivil ?? 'N/A',
                  m.tipoFeligres ?? 'N/A',
                  '${m.bautizadoAgua ? 'Sí' : 'No'} / ${m.bautizadoEspiritu ? 'Sí' : 'No'}',
                  m.poseeDiscapacidad ? 'Sí' : 'No',
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
      final fileName =
          'Directorio_Feligreses_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted)
        CustomSnackBar.showSuccess(context, 'PDF generado exitosamente');
      await OpenFilex.open(file.path);
    }
  }

  bool _hasActiveFilters() {
    return _filterTipo != 'Todos' ||
        _filterGenero != 'Todos' ||
        _filterEstadoCivil != 'Todos' ||
        _filterEstadoEspiritual != 'Todos' ||
        _filterDiscapacidad != 'Todos' ||
        _sortBy != 'Más Recientes';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIglesia = ref.watch(currentIglesiaProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final displayFilters = isDesktop || _showFilters;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _showDeleted
          ? null
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF00C9FF), const Color(0xFF92FE9D)]
                      : [colorScheme.primary, colorScheme.secondary],
                ),
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00C9FF).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: FloatingActionButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      const AddFeligresSheet(initiallyExpanded: true),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.person_add, color: Colors.white),
              ),
            ),
      body: StreamBuilder<List<Feligrese>>(
        stream: _membersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final allMembers = snapshot.data ?? [];

          var filteredMembers = allMembers.where((m) {
            final matchIglesia =
                currentIglesia == null || m.iglesiaId == currentIglesia.id;
            final matchStatus = m.activo == (_showDeleted ? 0 : 1);
            final matchSearch = m.nombre.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
            final matchTipo =
                _filterTipo == 'Todos' ||
                m.tipoFeligres?.toLowerCase() == _filterTipo.toLowerCase();
            final matchGenero =
                _filterGenero == 'Todos' ||
                m.genero?.toLowerCase() == _filterGenero.toLowerCase();
            final matchEstadoCivil =
                _filterEstadoCivil == 'Todos' ||
                m.estadoCivil == _filterEstadoCivil;

            bool matchEspiritual = true;
            if (_filterEstadoEspiritual != 'Todos') {
              if (_filterEstadoEspiritual == 'Agua y Espíritu')
                matchEspiritual = m.bautizadoAgua && m.bautizadoEspiritu;
              else if (_filterEstadoEspiritual == 'Solo Agua')
                matchEspiritual = m.bautizadoAgua && !m.bautizadoEspiritu;
              else if (_filterEstadoEspiritual == 'Solo Espíritu')
                matchEspiritual = !m.bautizadoAgua && m.bautizadoEspiritu;
              else if (_filterEstadoEspiritual == 'No Bautizado')
                matchEspiritual = !m.bautizadoAgua && !m.bautizadoEspiritu;
            }

            final matchDiscapacidad =
                _filterDiscapacidad == 'Todos' ||
                (_filterDiscapacidad == 'Sí'
                    ? m.poseeDiscapacidad
                    : !m.poseeDiscapacidad);

            return matchIglesia &&
                matchStatus &&
                matchSearch &&
                matchTipo &&
                matchGenero &&
                matchEstadoCivil &&
                matchEspiritual &&
                matchDiscapacidad;
          }).toList();

          filteredMembers.sort((a, b) {
            if (_sortBy == 'Nombre (A-Z)') return a.nombre.compareTo(b.nombre);
            if (_sortBy == 'Nombre (Z-A)') return b.nombre.compareTo(a.nombre);
            final dateA =
                a.fechaModificacion ??
                a.fechaRegistro ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final dateB =
                b.fechaModificacion ??
                b.fechaRegistro ??
                DateTime.fromMillisecondsSinceEpoch(0);
            if (_sortBy == 'Más Recientes') return dateB.compareTo(dateA);
            if (_sortBy == 'Más Antiguos') return dateA.compareTo(dateB);
            return 0;
          });

          final totalPages =
              (filteredMembers.length / _itemsPerPage).ceil() == 0
              ? 1
              : (filteredMembers.length / _itemsPerPage).ceil();
          if (_currentPage > totalPages) _currentPage = totalPages;
          if (_currentPage < 1) _currentPage = 1;

          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage > filteredMembers.length)
              ? filteredMembers.length
              : startIndex + _itemsPerPage;
          final paginatedList = filteredMembers.sublist(startIndex, endIndex);

          return Column(
            children: [
              Container(
                // FIX 2: ALIGN MARGIN TO 16 ON MOBILE
                padding: EdgeInsets.only(
                  left: isDesktop ? 20 : 16,
                  right: isDesktop ? 20 : 16,
                  bottom: 16,
                  top: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black12 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _showDeleted = false;
                                _currentPage = 1;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: !_showDeleted
                                      ? colorScheme.primary.withOpacity(
                                          isDark ? 0.2 : 0.1,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Activos',
                                    style: GoogleFonts.poppins(
                                      color: !_showDeleted
                                          ? colorScheme.primary
                                          : Colors.grey,
                                      fontWeight: !_showDeleted
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _showDeleted = true;
                                _currentPage = 1;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _showDeleted
                                      ? Colors.orangeAccent.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'Inactivos',
                                    style: GoogleFonts.poppins(
                                      color: _showDeleted
                                          ? Colors.orange
                                          : Colors.grey,
                                      fontWeight: _showDeleted
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Buscar feligrés...',
                                hintStyle: const TextStyle(fontSize: 14),
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setState(() {
                                          _searchController.clear();
                                          _currentPage = 1;
                                        }),
                                      )
                                    : null,
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
                                  setState(() => _currentPage = 1),
                            ),
                          ),
                        ),
                        if (!isDesktop) ...[
                          const SizedBox(width: 8),
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
                      ],
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: displayFilters
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
                                      _sortBy = 'Más Recientes';
                                      _filterTipo = 'Todos';
                                      _filterGenero = 'Todos';
                                      _filterEstadoCivil = 'Todos';
                                      _filterEstadoEspiritual = 'Todos';
                                      _filterDiscapacidad = 'Todos';
                                      _currentPage = 1;
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 45,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _sortBy,
                                    decoration: InputDecoration(
                                      labelText: 'Ordenar',
                                      labelStyle: const TextStyle(fontSize: 12),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    items: _sortOptions
                                        .map(
                                          (o) => DropdownMenuItem(
                                            value: o,
                                            child: Text(
                                              o,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) =>
                                        setState(() => _sortBy = val!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 130,
                                  height: 45,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _filterTipo,
                                    decoration: InputDecoration(
                                      labelText: 'Tipo',
                                      labelStyle: const TextStyle(fontSize: 12),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    items: _tipoOptions
                                        .map(
                                          (o) => DropdownMenuItem(
                                            value: o,
                                            child: Text(
                                              o,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(() {
                                      _filterTipo = val!;
                                      _currentPage = 1;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 120,
                                  height: 45,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _filterGenero,
                                    decoration: InputDecoration(
                                      labelText: 'Género',
                                      labelStyle: const TextStyle(fontSize: 12),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    items: _generoOptions
                                        .map(
                                          (o) => DropdownMenuItem(
                                            value: o,
                                            child: Text(
                                              o,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(() {
                                      _filterGenero = val!;
                                      _currentPage = 1;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 130,
                                  height: 45,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _filterEstadoCivil,
                                    decoration: InputDecoration(
                                      labelText: 'Estado Civil',
                                      labelStyle: const TextStyle(fontSize: 12),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    items: _estadoCivilOptions
                                        .map(
                                          (o) => DropdownMenuItem(
                                            value: o,
                                            child: Text(
                                              o,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(() {
                                      _filterEstadoCivil = val!;
                                      _currentPage = 1;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 150,
                                  height: 45,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _filterEstadoEspiritual,
                                    decoration: InputDecoration(
                                      labelText: 'E. Espiritual',
                                      labelStyle: const TextStyle(fontSize: 12),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    items: _estadoEspiritualOptions
                                        .map(
                                          (o) => DropdownMenuItem(
                                            value: o,
                                            child: Text(
                                              o,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(() {
                                      _filterEstadoEspiritual = val!;
                                      _currentPage = 1;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 140,
                                  height: 45,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _filterDiscapacidad,
                                    decoration: InputDecoration(
                                      labelText: 'Discapacidad',
                                      labelStyle: const TextStyle(fontSize: 12),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    items: _discapacidadOptions
                                        .map(
                                          (o) => DropdownMenuItem(
                                            value: o,
                                            child: Text(
                                              o,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(() {
                                      _filterDiscapacidad = val!;
                                      _currentPage = 1;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _exportFeligresesToPDF(filteredMembers),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text('Exportar Directorio a PDF'),
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
                  ],
                ),
              ),
              Expanded(
                child: filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showDeleted
                                  ? Icons.person_off
                                  : Icons.people_outline,
                              size: 64,
                              color: colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showDeleted
                                  ? 'No hay usuarios inactivos.'
                                  : 'No hay feligreses con estos filtros.',
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: 80,
                          top: 16,
                          left: isDesktop ? 20 : 16,
                          right: isDesktop ? 20 : 16,
                        ),
                        itemCount: paginatedList.length,
                        // ITEM EXTENT REMOVED to allow dynamic height for long names
                        itemBuilder: (context, index) {
                          final member = paginatedList[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.3 : 0.05,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      EditFeligresSheet(feligres: member),
                                ),
                                borderRadius: BorderRadius.circular(16),
                                // FIX 3: PERFECT VERTICAL CENTERING WITH CUSTOM ROW
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: _showDeleted
                                            ? Colors.orangeAccent.withOpacity(
                                                0.1,
                                              )
                                            : colorScheme.primary.withOpacity(
                                                0.1,
                                              ),
                                        child: Icon(
                                          Icons.person,
                                          color: _showDeleted
                                              ? Colors.orange
                                              : colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member.nombre,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              member.telefono ?? 'Sin teléfono',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              member.fechaModificacion != null
                                                  ? 'Modificado: ${DateFormat('dd MMM yy, hh:mm a', 'es').format(member.fechaModificacion!)}'
                                                  : member.fechaRegistro != null
                                                  ? 'Creado: ${DateFormat('dd MMM yy, hh:mm a', 'es').format(member.fechaRegistro!)}'
                                                  : 'Creado: Desc.',
                                              style: GoogleFonts.poppins(
                                                color: colorScheme.primary
                                                    .withOpacity(0.7),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            member.tipoFeligres ?? 'Feligres',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Colors.grey.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (filteredMembers.isNotEmpty)
                Container(
                  padding: EdgeInsets.only(
                    top: 12,
                    bottom: 24,
                    left: isDesktop ? 20 : 16,
                    right: isDesktop ? 20 : 16,
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
                          _currentPage = 1;
                        }),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          '$_currentPage / $totalPages',
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
                        onPressed: _currentPage < totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
