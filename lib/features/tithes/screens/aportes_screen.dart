import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/features/members/widgets/add_feligres_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/add_aporte_sheet.dart';
import '../widgets/edit_aporte_sheet.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class AportesScreen extends ConsumerStatefulWidget {
  const AportesScreen({super.key});

  @override
  ConsumerState<AportesScreen> createState() => _AportesScreenState();
}

class _AportesScreenState extends ConsumerState<AportesScreen> {
  late Stream<List<AporteConFeligres>> _historyStream;
  late TextEditingController _searchController;

  DateTimeRange? _dateRange;
  String _sortBy = 'Fecha (Descendente)';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  final List<String> _sortOptions = [
    'Fecha (Descendente)',
    'Fecha (Ascendente)',
    'Nombre (A-Z)',
    'Nombre (Z-A)',
  ];

  final List<int> _pageOptions = [10, 20, 50];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _historyStream = ref.read(databaseProvider).watchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        _currentPage = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF89216B), const Color(0xFFDA4453)]
                : [colorScheme.secondary, Colors.redAccent],
          ),
          shape: BoxShape.circle,
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFFDA4453).withOpacity(0.4),
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
            builder: (context) => const AddAporteSheet(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_card, color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<AporteConFeligres>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final allAportes = snapshot.data ?? [];

          // 1. Filter
          var filtered = allAportes.where((item) {
            final matchName = item.feligres.nombre.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
            bool matchDate = true;
            if (_dateRange != null) {
              matchDate =
                  item.aporte.fecha.isAfter(
                    _dateRange!.start.subtract(const Duration(days: 1)),
                  ) &&
                  item.aporte.fecha.isBefore(
                    _dateRange!.end.add(const Duration(days: 1)),
                  );
            }
            return matchName && matchDate;
          }).toList();

          // 2. Sort
          filtered.sort((a, b) {
            switch (_sortBy) {
              case 'Fecha (Descendente)':
                return b.aporte.fecha.compareTo(a.aporte.fecha);
              case 'Fecha (Ascendente)':
                return a.aporte.fecha.compareTo(b.aporte.fecha);
              case 'Nombre (A-Z)':
                return a.feligres.nombre.compareTo(b.feligres.nombre);
              case 'Nombre (Z-A)':
                return b.feligres.nombre.compareTo(a.feligres.nombre);
              default:
                return 0;
            }
          });

          // 3. Paginate
          final totalPages = (filtered.length / _itemsPerPage).ceil() == 0
              ? 1
              : (filtered.length / _itemsPerPage).ceil();
          if (_currentPage > totalPages) _currentPage = totalPages;
          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage > filtered.length)
              ? filtered.length
              : startIndex + _itemsPerPage;
          final paginatedList = filtered.sublist(startIndex, endIndex);

          return Column(
            children: [
              // HEADER CONTROLS
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
                    // Date Range Button (Highly Visible)
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
                                  ? 'Seleccionar Rango de Fechas'
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
                                  _currentPage = 1;
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search & Sorting (Stacked vertically to prevent overflow)
                    Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar feligrés...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.black12
                                : Colors.grey.shade100,
                          ),
                          onChanged: (val) => setState(() => _currentPage = 1),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _sortBy,
                          isExpanded:
                              true, // Prevents text overflow inside the dropdown
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
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
                          onChanged: (val) => setState(() => _sortBy = val!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // LIST
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No hay aportes.',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        itemCount: paginatedList.length,
                        itemBuilder: (context, index) {
                          final item = paginatedList[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
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
                                    EditAporteSheet(aporteItem: item),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.secondary
                                    .withOpacity(0.1),
                                child: Icon(
                                  Icons.monetization_on,
                                  color: colorScheme.secondary,
                                ),
                              ),
                              title: Text(
                                item.feligres.nombre,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat('dd MMM yyyy').format(item.aporte.fecha)} • ${item.aporte.tipo}',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Text(
                                '\$${item.aporte.monto.toStringAsFixed(2)}',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // PAGINATION WITH DROPDOWN
              Container(
                // Added extra padding on the right (80) and bottom (32) to prevent FAB overlap
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 32,
                  left: 24,
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
