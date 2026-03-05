import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

// PDF Packages
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
  // STREAM CACHE
  late Stream<List<Feligrese>> _membersStream;

  // STATE
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  bool _showDeleted = false;

  // FILTERS
  String _sortBy = 'Nombre (A-Z)';
  String _filterTipo = 'Todos';
  String _filterGenero = 'Todos';

  // PAGINATION
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _pageOptions = [10, 20, 50, 100];

  final List<String> _sortOptions = ['Nombre (A-Z)', 'Nombre (Z-A)'];
  final List<String> _tipoOptions = [
    'Todos',
    'Feligres',
    'Simpatizante',
    'Visita',
  ];
  final List<String> _generoOptions = ['Todos', 'Masculino', 'Femenino'];

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

  // ==========================================
  // FULL DIRECTORY EXPORT LOGIC (WITH NUMBERS)
  // ==========================================
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

            // Native PDF Table with Index (#) Column
            pw.TableHelper.fromTextArray(
              context: context,
              // Define custom widths to make the '#' column narrow and 'Name' wider
              columnWidths: {
                0: const pw.FixedColumnWidth(25), // #
                1: const pw.FlexColumnWidth(2.5), // Nombre
                2: const pw.FlexColumnWidth(1.2), // Teléfono
                3: const pw.FlexColumnWidth(1), // Género
                4: const pw.FlexColumnWidth(1.2), // Estado Civil
                5: const pw.FlexColumnWidth(1.2), // Membresía
                6: const pw.FlexColumnWidth(1.5), // Bautizado
                7: const pw.FlexColumnWidth(1), // Discapacidad
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
                final index = entry.key + 1; // Creates the 1, 2, 3... sequence
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIglesia = ref.watch(currentIglesiaProvider);

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

          // 1. FILTERING
          var filteredMembers = allMembers.where((m) {
            // Multi-tenancy Filter
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

            return matchIglesia &&
                matchStatus &&
                matchSearch &&
                matchTipo &&
                matchGenero;
          }).toList();

          // 2. SORTING
          filteredMembers.sort((a, b) {
            if (_sortBy == 'Nombre (A-Z)') return a.nombre.compareTo(b.nombre);
            if (_sortBy == 'Nombre (Z-A)') return b.nombre.compareTo(a.nombre);
            return 0;
          });

          // 3. PAGINATION
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
              // --- HEADER & FILTERS ---
              Container(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  top: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
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
                    // ACTIVE / TRASH TOGGLE
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black12 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
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
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: !_showDeleted
                                      ? colorScheme.primary.withOpacity(
                                          isDark ? 0.2 : 0.1,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
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
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _showDeleted
                                      ? Colors.redAccent.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Papelera',
                                    style: GoogleFonts.poppins(
                                      color: _showDeleted
                                          ? Colors.redAccent
                                          : Colors.grey,
                                      fontWeight: _showDeleted
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SEARCH BAR & EXPORT BUTTON
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () => setState(() {
                                        _searchController.clear();
                                        _currentPage = 1;
                                      }),
                                    )
                                  : null,
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
                        const SizedBox(width: 12),
                        // NATIVE EXPORT BUTTON
                        ElevatedButton.icon(
                          onPressed: () => _exportFeligresesToPDF(
                            filteredMembers,
                          ), // We pass ALL the filtered data, not just paginated
                          icon: const Icon(Icons.download),
                          label: const Text('Exportar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // DROPDOWN FILTERS
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Sort
                          SizedBox(
                            width: 150,
                            child: DropdownButtonFormField<String>(
                              value: _sortBy,
                              decoration: InputDecoration(
                                labelText: 'Ordenar',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _sortOptions
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o,
                                      child: Text(
                                        o,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _sortBy = val!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Type
                          SizedBox(
                            width: 140,
                            child: DropdownButtonFormField<String>(
                              value: _filterTipo,
                              decoration: InputDecoration(
                                labelText: 'Tipo',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _tipoOptions
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o,
                                      child: Text(
                                        o,
                                        style: const TextStyle(fontSize: 12),
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
                          const SizedBox(width: 12),
                          // Gender
                          SizedBox(
                            width: 140,
                            child: DropdownButtonFormField<String>(
                              value: _filterGenero,
                              decoration: InputDecoration(
                                labelText: 'Género',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _generoOptions
                                  .map(
                                    (o) => DropdownMenuItem(
                                      value: o,
                                      child: Text(
                                        o,
                                        style: const TextStyle(fontSize: 12),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- DYNAMIC LIST ---
              Expanded(
                child: filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showDeleted
                                  ? Icons.delete_outline
                                  : Icons.people_outline,
                              size: 64,
                              color: colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _showDeleted
                                  ? 'La papelera está vacía.'
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
                        padding: const EdgeInsets.only(
                          bottom: 20,
                          top: 16,
                          left: 24,
                          right: 24,
                        ),
                        itemCount: paginatedList.length,
                        itemBuilder: (context, index) {
                          final member = paginatedList[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
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
                            child: ListTile(
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    EditFeligresSheet(feligres: member),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: _showDeleted
                                    ? Colors.redAccent.withOpacity(0.1)
                                    : colorScheme.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: _showDeleted
                                      ? Colors.redAccent
                                      : colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                member.nombre,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                member.telefono ?? 'Sin teléfono',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    member.tipoFeligres ?? 'Feligres',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // --- PAGINATION CONTROLS ---
              if (filteredMembers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.only(
                    top: 16,
                    bottom: 32,
                    left: 24,
                    right: 80,
                  ), // Right padding prevents FAB overlap
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
                          _currentPage = 1;
                        }),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Text(
                        'Pág $_currentPage de $totalPages',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < totalPages
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
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
