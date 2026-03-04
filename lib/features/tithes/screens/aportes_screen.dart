import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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
  // --- DATABASE STREAM CACHE (Fixes Focus Loss) ---
  late Stream<List<AporteConFeligres>> _historyStream;

  // --- FILTER & PAGINATION STATE ---
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  DateTimeRange? _listDateRange;

  String _sortBy = 'Fecha (Más recientes)';
  int _groupingMode = 0; // 0 = Individual, 1 = Por Feligrés, 2 = Por Tipo

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // --- HISTORICAL CHART STATE ---
  String? _chartFilterType; // 'feligres' or 'tipo'
  String? _chartFilterValue;
  String _chartTitle = '';
  String _chartPeriod = '3M';
  DateTimeRange? _chartCustomRange;

  final List<String> _sortOptions = [
    'Fecha (Más recientes)',
    'Fecha (Más antiguos)',
    'Monto (Mayor a Menor)',
    'Monto (Menor a Mayor)',
  ];

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

  Future<void> _pickListDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _listDateRange,
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (range != null) {
      setState(() {
        _listDateRange = range;
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
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddAporteSheet(),
            );
          },
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

          // Extract available years for the chart dropdown
          final availableYears =
              allAportes.map((e) => e.aporte.fecha.year).toSet().toList()
                ..sort((a, b) => b.compareTo(a));

          // 1. APPLY SEARCH & DATE RANGE FILTERS
          var filteredAportes = allAportes.where((item) {
            final matchesSearch = item.feligres.nombre.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
            bool matchesDate = true;
            if (_listDateRange != null) {
              matchesDate =
                  item.aporte.fecha.isAfter(
                    _listDateRange!.start.subtract(const Duration(days: 1)),
                  ) &&
                  item.aporte.fecha.isBefore(
                    _listDateRange!.end.add(const Duration(days: 1)),
                  );
            }
            return matchesSearch && matchesDate;
          }).toList();

          // 2. APPLY SORTING
          filteredAportes.sort((a, b) {
            switch (_sortBy) {
              case 'Fecha (Más recientes)':
                return b.aporte.fecha.compareTo(a.aporte.fecha);
              case 'Fecha (Más antiguos)':
                return a.aporte.fecha.compareTo(b.aporte.fecha);
              case 'Monto (Mayor a Menor)':
                return b.aporte.monto.compareTo(a.aporte.monto);
              case 'Monto (Menor a Mayor)':
                return a.aporte.monto.compareTo(b.aporte.monto);
              default:
                return 0;
            }
          });

          // 3. APPLY GROUPING
          List<dynamic> listToDisplay = [];

          if (_groupingMode == 1) {
            // By Parishioner
            final groupedMap = <String, Map<String, dynamic>>{};
            for (var item in filteredAportes) {
              final fId = item.feligres.id;
              if (!groupedMap.containsKey(fId)) {
                groupedMap[fId] = {
                  'feligres': item.feligres,
                  'totalMonto': 0.0,
                  'cantidad': 0,
                };
              }
              groupedMap[fId]!['totalMonto'] += item.aporte.monto;
              groupedMap[fId]!['cantidad'] += 1;
            }
            listToDisplay = groupedMap.values.toList();
            if (_sortBy.contains('Monto (Mayor a Menor)'))
              listToDisplay.sort(
                (a, b) => (b['totalMonto'] as double).compareTo(
                  a['totalMonto'] as double,
                ),
              );
            if (_sortBy.contains('Monto (Menor a Mayor)'))
              listToDisplay.sort(
                (a, b) => (a['totalMonto'] as double).compareTo(
                  b['totalMonto'] as double,
                ),
              );
          } else if (_groupingMode == 2) {
            // By Contribution Type
            final groupedMap = <String, Map<String, dynamic>>{};
            for (var item in filteredAportes) {
              final tipo = item.aporte.tipo;
              if (!groupedMap.containsKey(tipo)) {
                groupedMap[tipo] = {
                  'tipo': tipo,
                  'totalMonto': 0.0,
                  'cantidad': 0,
                };
              }
              groupedMap[tipo]!['totalMonto'] += item.aporte.monto;
              groupedMap[tipo]!['cantidad'] += 1;
            }
            listToDisplay = groupedMap.values.toList();
            if (_sortBy.contains('Monto (Mayor a Menor)'))
              listToDisplay.sort(
                (a, b) => (b['totalMonto'] as double).compareTo(
                  a['totalMonto'] as double,
                ),
              );
            if (_sortBy.contains('Monto (Menor a Mayor)'))
              listToDisplay.sort(
                (a, b) => (a['totalMonto'] as double).compareTo(
                  b['totalMonto'] as double,
                ),
              );
          } else {
            // Individual
            listToDisplay = filteredAportes;
          }

          // 4. PAGINATION LOGIC
          final totalItems = listToDisplay.length;
          final totalPages = (totalItems / _itemsPerPage).ceil() == 0
              ? 1
              : (totalItems / _itemsPerPage).ceil();

          if (_currentPage > totalPages) _currentPage = totalPages;
          if (_currentPage < 1) _currentPage = 1;

          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage > totalItems)
              ? totalItems
              : startIndex + _itemsPerPage;
          final paginatedList = listToDisplay.sublist(startIndex, endIndex);

          return Column(
            children: [
              // HEADER: Filters and Charts
              Container(
                padding: const EdgeInsets.all(24),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar & Date Range Filter
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Buscar feligrés...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _currentPage = 1);
                                },
                              ),
                            Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.shade400,
                            ),
                            IconButton(
                              icon: Icon(
                                _listDateRange == null
                                    ? Icons.date_range
                                    : Icons.event_available,
                                color: _listDateRange == null
                                    ? Colors.grey
                                    : colorScheme.primary,
                              ),
                              tooltip: 'Filtrar por Rango de Fechas',
                              onPressed: _pickListDateRange,
                            ),
                            if (_listDateRange != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => setState(() {
                                  _listDateRange = null;
                                  _currentPage = 1;
                                }),
                              ),
                          ],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.black12
                            : Colors.grey.shade100,
                      ),
                      onChanged: (val) => setState(() => _currentPage = 1),
                    ),
                    const SizedBox(height: 16),

                    // Sorting and Intuitive Grouping
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sortBy,
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
                                  (opt) => DropdownMenuItem(
                                    value: opt,
                                    child: Text(
                                      opt,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(() => _sortBy = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Lista Individual'),
                            selected: _groupingMode == 0,
                            onSelected: (val) => setState(() {
                              _groupingMode = 0;
                              _currentPage = 1;
                              _chartFilterValue = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Por Feligrés'),
                            selected: _groupingMode == 1,
                            onSelected: (val) => setState(() {
                              _groupingMode = 1;
                              _currentPage = 1;
                              _chartFilterValue = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Por Tipo de Aporte'),
                            selected: _groupingMode == 2,
                            onSelected: (val) => setState(() {
                              _groupingMode = 2;
                              _currentPage = 1;
                              _chartFilterValue = null;
                            }),
                          ),
                        ],
                      ),
                    ),

                    // HISTORICAL CHART
                    if (_chartFilterValue != null) ...[
                      const SizedBox(height: 24),
                      _buildHistoricalChart(
                        allAportes,
                        availableYears,
                        isDark,
                        colorScheme,
                      ),
                    ],
                  ],
                ),
              ),

              // PAGINATED LIST
              Expanded(
                child: totalItems == 0
                    ? Center(
                        child: Text(
                          'No hay registros con estos filtros.',
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
                          if (_groupingMode == 1) {
                            return _buildGroupedFeligresCard(
                              paginatedList[index],
                              isDark,
                              colorScheme,
                            );
                          } else if (_groupingMode == 2) {
                            return _buildGroupedTipoCard(
                              paginatedList[index],
                              isDark,
                              colorScheme,
                            );
                          } else {
                            return _buildAporteCard(
                              paginatedList[index],
                              isDark,
                              colorScheme,
                            );
                          }
                        },
                      ),
              ),

              // PAGINATION CONTROLS
              if (totalItems > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(color: colorScheme.surface),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                      Text(
                        'Página $_currentPage de $totalPages',
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

  // --- WIDGETS: CARDS ---
  Widget _buildAporteCard(
    AporteConFeligres item,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final aporte = item.aporte;
    final feligres = item.feligres;
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
      'es',
    ).format(aporte.fecha);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => EditAporteSheet(aporteItem: item),
          );
        },
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondary.withOpacity(0.1),
          child: Icon(Icons.monetization_on, color: colorScheme.secondary),
        ),
        title: Text(
          feligres.nombre,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '$formattedDate • ${aporte.tipo}',
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
        trailing: Text(
          '\$${aporte.monto.toStringAsFixed(2)}',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? const Color(0xFF92FE9D) : Colors.green.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedFeligresCard(
    Map<String, dynamic> groupData,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final Feligrese feligres = groupData['feligres'];
    final double totalMonto = groupData['totalMonto'];
    final int cantidad = groupData['cantidad'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.person, color: colorScheme.primary),
        ),
        title: Text(
          feligres.nombre,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$cantidad aportes en total',
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${totalMonto.toStringAsFixed(2)}',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colorScheme.primary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.show_chart, color: Colors.blueAccent),
              tooltip: 'Ver Historial',
              onPressed: () => setState(() {
                _chartFilterType = 'feligres';
                _chartFilterValue = feligres.id;
                _chartTitle = feligres.nombre;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedTipoCard(
    Map<String, dynamic> groupData,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final String tipo = groupData['tipo'];
    final double totalMonto = groupData['totalMonto'];
    final int cantidad = groupData['cantidad'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondary.withOpacity(0.1),
          child: Icon(Icons.category, color: colorScheme.secondary),
        ),
        title: Text(
          tipo,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$cantidad registros',
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${totalMonto.toStringAsFixed(2)}',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colorScheme.secondary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart, color: Colors.blueAccent),
              tooltip: 'Ver Historial',
              onPressed: () => setState(() {
                _chartFilterType = 'tipo';
                _chartFilterValue = tipo;
                _chartTitle = tipo;
              }),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: ADVANCED HISTORICAL CHART ---
  Widget _buildHistoricalChart(
    List<AporteConFeligres> allAportes,
    List<int> availableYears,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    List<AporteConFeligres> targetAportes = [];
    if (_chartFilterType == 'feligres') {
      targetAportes = allAportes
          .where((a) => a.feligres.id == _chartFilterValue)
          .toList();
    } else if (_chartFilterType == 'tipo') {
      targetAportes = allAportes
          .where((a) => a.aporte.tipo == _chartFilterValue)
          .toList();
    }

    // Determine X-axis months based on period
    List<DateTime> months = [];
    final now = DateTime.now();

    if (_chartPeriod == '3M') {
      months = List.generate(
        3,
        (i) => DateTime(now.year, now.month - i, 1),
      ).reversed.toList();
    } else if (_chartPeriod == '6M') {
      months = List.generate(
        6,
        (i) => DateTime(now.year, now.month - i, 1),
      ).reversed.toList();
    } else if (_chartPeriod == '1A') {
      months = List.generate(
        12,
        (i) => DateTime(now.year, now.month - i, 1),
      ).reversed.toList();
    } else if (_chartPeriod == 'CUSTOM' && _chartCustomRange != null) {
      DateTime current = DateTime(
        _chartCustomRange!.start.year,
        _chartCustomRange!.start.month,
        1,
      );
      while (current.isBefore(_chartCustomRange!.end) ||
          current.isAtSameMomentAs(
            DateTime(
              _chartCustomRange!.end.year,
              _chartCustomRange!.end.month,
              1,
            ),
          )) {
        months.add(current);
        current = DateTime(current.year, current.month + 1, 1);
      }
    } else {
      int year = int.tryParse(_chartPeriod) ?? now.year;
      months = List.generate(12, (i) => DateTime(year, i + 1, 1));
    }

    Map<String, double> monthlyTotals = {};
    for (var m in months) {
      monthlyTotals[DateFormat('MMM yy', 'es').format(m)] = 0.0;
    }

    double maxY = 10;
    for (var item in targetAportes) {
      final key = DateFormat('MMM yy', 'es').format(item.aporte.fecha);
      if (monthlyTotals.containsKey(key)) {
        monthlyTotals[key] = monthlyTotals[key]! + item.aporte.monto;
        if (monthlyTotals[key]! > maxY) maxY = monthlyTotals[key]!;
      }
    }

    List<FlSpot> spots = [];
    int xIndex = 0;
    monthlyTotals.forEach((key, value) {
      spots.add(FlSpot(xIndex.toDouble(), value));
      xIndex++;
    });

    List<DropdownMenuItem<String>> periodOptions = [
      const DropdownMenuItem(value: '3M', child: Text('Últimos 3 Meses')),
      const DropdownMenuItem(value: '6M', child: Text('Últimos 6 Meses')),
      const DropdownMenuItem(value: '1A', child: Text('Último Año')),
      const DropdownMenuItem(
        value: 'CUSTOM',
        child: Text('Rango Personalizado...'),
      ),
    ];
    for (var year in availableYears) {
      periodOptions.add(
        DropdownMenuItem(value: year.toString(), child: Text('Año $year')),
      );
    }

    final isBarChart = _chartFilterType == 'tipo';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Historial: $_chartTitle',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _chartFilterValue = null),
              ),
            ],
          ),

          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: Colors.blueAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _chartPeriod,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: GoogleFonts.poppins(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.blueAccent,
                  ),
                  items: periodOptions,
                  onChanged: (val) async {
                    if (val == 'CUSTOM') {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (range != null) {
                        setState(() {
                          _chartCustomRange = range;
                          _chartPeriod = 'CUSTOM';
                        });
                      }
                    } else {
                      setState(() => _chartPeriod = val!);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // DYNAMIC CHART RENDERING (Line vs Bar)
          SizedBox(
            height: 180,
            child: isBarChart
                ? BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY * 1.3, // Prevents top overflow
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < months.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('MMM', 'es')
                                        .format(months[value.toInt()])
                                        .toUpperCase(),
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
                      barGroups: spots.map((spot) {
                        return BarChartGroupData(
                          x: spot.x.toInt(),
                          barRods: [
                            BarChartRodData(
                              toY: spot.y,
                              color: colorScheme.secondary,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      clipData:
                          const FlClipData.none(), // Prevents left/right overflow
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
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < months.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('MMM', 'es')
                                        .format(months[value.toInt()])
                                        .toUpperCase(),
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
                      maxX: (months.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY * 1.3, // Prevents top overflow
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.blueAccent,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blueAccent.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
