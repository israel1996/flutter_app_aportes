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
  String _sortBy = 'Más recientes primero';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  final List<String> _sortOptions = [
    'Más recientes primero',
    'Más antiguos primero',
    'Aportes más altos',
    'Aportes más bajos',
  ];

  final List<int> _pageOptions = [10, 20, 50];

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$ ',
    decimalDigits: 2,
  );

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
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
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
    final currentIglesia = ref.watch(currentIglesiaProvider);

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allAportes = snapshot.data ?? [];

          final query = _searchController.text.toLowerCase().trim();
          final isSearchingNumber =
              double.tryParse(
                query.replaceAll('\$', '').replaceAll(',', '').trim(),
              ) !=
              null;

          var filtered = allAportes.where((item) {
            final matchIglesia =
                currentIglesia == null ||
                item.feligres.iglesiaId == currentIglesia.id;
            final matchName = item.feligres.nombre.toLowerCase().contains(
              query,
            );
            final matchAmount =
                isSearchingNumber &&
                item.aporte.monto.toString().contains(
                  query.replaceAll('\$', '').replaceAll(',', '').trim(),
                );

            bool matchSearch = matchName || matchAmount;

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

            return matchIglesia && matchSearch && matchDate;
          }).toList();

          filtered.sort((a, b) {
            if (_sortBy == 'Más recientes primero')
              return b.aporte.fecha.compareTo(a.aporte.fecha);
            if (_sortBy == 'Más antiguos primero')
              return a.aporte.fecha.compareTo(b.aporte.fecha);
            if (_sortBy == 'Aportes más altos')
              return b.aporte.monto.compareTo(a.aporte.monto);
            if (_sortBy == 'Aportes más bajos')
              return a.aporte.monto.compareTo(b.aporte.monto);
            return 0;
          });

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
              // --- REDESIGNED INTUITIVE HEADER ---
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
                    // 1. Search Bar at the top (Natural flow)
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar feligrés o monto...',
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

                    // 2. Sort Dropdown and Date Button side-by-side
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: DropdownButtonFormField<String>(
                            value: _sortBy,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Ordenar lista por',
                              prefixIcon: const Icon(Icons.sort),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
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
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(() => _sortBy = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: _pickDateRange,
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                            ),
                            label: const Text('Fechas'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ), // Match height with dropdown
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              backgroundColor: colorScheme.primary.withOpacity(
                                0.1,
                              ),
                              foregroundColor: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 3. Active Date Filter Chip (Only shows when dates are selected)
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
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
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
                                _currentPage = 1;
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
                  ],
                ),
              ),

              // --- LIST ---
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
                                _currencyFormat.format(item.aporte.monto),
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

              // --- PAGINATION ---
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
                    const SizedBox(width: 4),
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
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Pág $_currentPage de $totalPages',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
