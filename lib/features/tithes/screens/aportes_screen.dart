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
  late FocusNode _searchFocusNode;

  bool _showFilters = false;

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

  bool _hasActiveFilters() {
    return _sortBy != 'Más recientes primero' || _dateRange != null;
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
            final timeA =
                a.aporte.fechaModificacion ??
                a.aporte.fechaRegistro ??
                a.aporte.fecha;
            final timeB =
                b.aporte.fechaModificacion ??
                b.aporte.fechaRegistro ??
                b.aporte.fecha;

            if (_sortBy == 'Más recientes primero')
              return timeB.compareTo(timeA);
            if (_sortBy == 'Más antiguos primero')
              return timeA.compareTo(timeB);
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
          if (_currentPage < 1) _currentPage = 1;

          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage > filtered.length)
              ? filtered.length
              : startIndex + _itemsPerPage;
          final paginatedList = filtered.sublist(startIndex, endIndex);

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
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
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
                                hintText: 'Buscar feligrés o monto...',
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
                                      _sortBy = 'Más recientes primero';
                                      _dateRange = null;
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

                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: SizedBox(
                                  height: 45,
                                  child: DropdownButtonFormField<String>(
                                    value: _sortBy,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Ordenar lista por',
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
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(() {
                                      _sortBy = val!;
                                      _currentPage = 1;
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 4,
                                child: SizedBox(
                                  height: 45,
                                  child: ElevatedButton.icon(
                                    onPressed: _pickDateRange,
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
                                      _currentPage = 1;
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- LIST ---
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No hay aportes con estos filtros.',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 80,
                          top: 16,
                          left: 16,
                          right: 16,
                        ),
                        itemCount: paginatedList.length,
                        itemBuilder: (context, index) {
                          final item = paginatedList[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
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
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Aporte del: ${DateFormat('dd MMM yyyy').format(item.aporte.fecha)} • ${item.aporte.tipo}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.aporte.fechaModificacion != null
                                          ? 'Modificado: ${DateFormat('dd MMM yy, hh:mm a', 'es').format(item.aporte.fechaModificacion!)}'
                                          : item.aporte.fechaRegistro != null
                                          ? 'Registrado: ${DateFormat('dd MMM yy, hh:mm a', 'es').format(item.aporte.fechaRegistro!)}'
                                          : 'Registrado: Desc.',
                                      style: GoogleFonts.poppins(
                                        color: colorScheme.primary.withOpacity(
                                          0.7,
                                        ),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
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

              // --- PAGINATION COMPACTA ---
              if (filtered.isNotEmpty)
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
