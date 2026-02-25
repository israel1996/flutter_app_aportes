import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange? _selectedDateRange;
  String? _selectedReportFeligresId;

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final historyStream = database.watchHistory();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes y Analíticas'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: 'General'),
              Tab(icon: Icon(Icons.pie_chart), text: 'Demografía'),
              Tab(icon: Icon(Icons.person_search), text: 'Por Feligrés'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range),
              tooltip: 'Filtrar por Fecha',
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  initialDateRange: _selectedDateRange,
                );
                if (picked != null) {
                  setState(() {
                    _selectedDateRange = picked;
                  });
                }
              },
            ),
          ],
        ),
        body: StreamBuilder<List<AporteConFeligres>>(
          stream: historyStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            var aportes = snapshot.data ?? [];

            if (_selectedDateRange != null) {
              aportes = aportes.where((a) {
                return a.aporte.fecha.isAfter(
                      _selectedDateRange!.start.subtract(
                        const Duration(days: 1),
                      ),
                    ) &&
                    a.aporte.fecha.isBefore(
                      _selectedDateRange!.end.add(const Duration(days: 1)),
                    );
              }).toList();
            }

            return TabBarView(
              children: [
                _buildGeneralReportTab(aportes),
                _buildDemographicsTab(aportes),
                _buildMemberReportTab(aportes),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGeneralReportTab(List<AporteConFeligres> aportes) {
    if (aportes.isEmpty) {
      return const Center(
        child: Text(
          "No hay datos para este periodo.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final total = aportes.fold(0.0, (sum, item) => sum + item.aporte.monto);

    List<double> monthlyTotals = List.filled(12, 0.0);
    for (var item in aportes) {
      final month = item.aporte.fecha.month;
      monthlyTotals[month - 1] += item.aporte.monto;
    }

    double maxY = monthlyTotals.reduce(
      (curr, next) => curr > next ? curr : next,
    );
    maxY = maxY == 0 ? 100 : maxY * 1.2;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.indigo.shade50,
            elevation: 2,
            child: ListTile(
              title: const Text(
                'Ingreso Total del Periodo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          const Text(
            'Historial de Ingresos por Mes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey.shade800,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        );
                        final months = [
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
                        int index = value.toInt();
                        if (index >= 0 && index < 12) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(months[index], style: style),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == maxY || value == 0)
                          return const SizedBox.shrink();
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade300, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: monthlyTotals[index],
                        color: Colors.indigo,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Widget _buildDemographicsTab(List<AporteConFeligres> aportes) {
    if (aportes.isEmpty) {
      return const Center(
        child: Text(
          "No hay datos para este periodo.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    double ninosTotal = 0;
    double caballerosTotal = 0;
    double damasTotal = 0;
    double otrosTotal = 0;

    for (var item in aportes) {
      final feligres = item.feligres;
      final amount = item.aporte.monto;

      if (feligres.fechaNacimiento != null) {
        final age = _calculateAge(feligres.fechaNacimiento!);
        if (age < 14) {
          ninosTotal += amount;
        } else {
          if (feligres.genero == 'Masculino')
            caballerosTotal += amount;
          else if (feligres.genero == 'Femenino')
            damasTotal += amount;
          else
            otrosTotal += amount;
        }
      } else {
        if (feligres.genero == 'Masculino')
          caballerosTotal += amount;
        else if (feligres.genero == 'Femenino')
          damasTotal += amount;
        else
          otrosTotal += amount;
      }
    }

    final totalAmount = ninosTotal + caballerosTotal + damasTotal + otrosTotal;

    List<PieChartSectionData> getSections() {
      return [
        if (ninosTotal > 0)
          PieChartSectionData(
            color: Colors.orange,
            value: ninosTotal,
            title: '${((ninosTotal / totalAmount) * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        if (caballerosTotal > 0)
          PieChartSectionData(
            color: Colors.blue,
            value: caballerosTotal,
            title:
                '${((caballerosTotal / totalAmount) * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        if (damasTotal > 0)
          PieChartSectionData(
            color: Colors.pink,
            value: damasTotal,
            title: '${((damasTotal / totalAmount) * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        if (otrosTotal > 0)
          PieChartSectionData(
            color: Colors.grey,
            value: otrosTotal,
            title: '${((otrosTotal / totalAmount) * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Distribución de Ingresos por Demografía',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: getSections(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildLegendRow(Colors.blue, 'Caballeros', caballerosTotal),
                  _buildLegendRow(Colors.pink, 'Damas', damasTotal),
                  _buildLegendRow(
                    Colors.orange,
                    'Niños (Menores de 14)',
                    ninosTotal,
                  ),
                  if (otrosTotal > 0)
                    _buildLegendRow(Colors.grey, 'No Especificado', otrosTotal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 16, height: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberReportTab(List<AporteConFeligres> aportes) {
    final uniqueMembers = aportes.map((a) => a.feligres).toSet().toList();

    final memberAportes = _selectedReportFeligresId == null
        ? <AporteConFeligres>[]
        : aportes
              .where((a) => a.feligres.id == _selectedReportFeligresId)
              .toList();

    final memberTotal = memberAportes.fold(
      0.0,
      (sum, item) => sum + item.aporte.monto,
    );

    List<double> monthlyData = List.filled(12, 0.0);
    for (var item in memberAportes) {
      monthlyData[item.aporte.fecha.month - 1] += item.aporte.monto;
    }

    double maxY = 10;
    if (memberAportes.isNotEmpty) {
      maxY = monthlyData.reduce((curr, next) => curr > next ? curr : next);
      maxY = maxY == 0 ? 10 : maxY * 1.2;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Autocomplete<Feligrese>(
            displayStringForOption: (Feligrese option) => option.nombre,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Feligrese>.empty();
              }
              return uniqueMembers.where((Feligrese option) {
                return _normalizeText(
                  option.nombre,
                ).contains(_normalizeText(textEditingValue.text));
              });
            },
            onSelected: (Feligrese selection) {
              setState(() {
                _selectedReportFeligresId = selection.id;
              });
              FocusManager.instance.primaryFocus?.unfocus();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Buscar Feligrés',
                      prefixIcon: const Icon(Icons.person_search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          setState(() {
                            _selectedReportFeligresId = null;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  );
                },
          ),
          const SizedBox(height: 20),

          if (_selectedReportFeligresId == null)
            const Expanded(
              child: Center(
                child: Text(
                  'Busque un feligrés para ver su historial.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
            Card(
              color: Colors.green.shade50,
              elevation: 2,
              child: ListTile(
                title: const Text(
                  'Total Aportado',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '\$${memberTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            if (memberAportes.isNotEmpty) ...[
              const Text(
                'Tendencia de Aportes a lo largo del Año',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                      getDrawingVerticalLine: (value) =>
                          FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            const style = TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            );
                            final months = [
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
                            int index = value.toInt();
                            if (index >= 0 && index < 12) {
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(months[index], style: style),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            if (value == maxY || value == 0)
                              return const SizedBox.shrink();
                            return Text(
                              '\$${value.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    minX: 0,
                    maxX: 11,
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(12, (index) {
                          return FlSpot(index.toDouble(), monthlyData[index]);
                        }),
                        isCurved: true,
                        color: Colors.indigo,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.indigo.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Desglose Detallado',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Divider(),
            ],
            Expanded(
              child: memberAportes.isEmpty
                  ? const Center(child: Text('No hay registros detallados.'))
                  : ListView.builder(
                      itemCount: memberAportes.length,
                      itemBuilder: (context, index) {
                        final item = memberAportes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.shade50,
                              foregroundColor: Colors.indigo,
                              child: const Icon(Icons.monetization_on),
                            ),
                            title: Text(
                              item.aporte.tipo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat(
                                'dd MMMM yyyy',
                                'es',
                              ).format(item.aporte.fecha),
                            ),
                            trailing: Text(
                              '\$${item.aporte.monto.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
