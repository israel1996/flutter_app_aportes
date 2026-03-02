import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class DashboardSummary extends ConsumerWidget {
  const DashboardSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;

    return StreamBuilder<List<AporteConFeligres>>(
      stream: database.watchHistory(),
      builder: (context, historySnapshot) {
        return StreamBuilder<List<Feligrese>>(
          stream: database.watchAllFeligreses(),
          builder: (context, membersSnapshot) {
            // 1. Calculate Real Data
            final aportes = historySnapshot.data ?? [];
            final allMembers = membersSnapshot.data ?? [];

            final activeMembers = allMembers
                .where((m) => m.activo == 1)
                .toList();

            double totalAportes = 0;
            final now = DateTime.now();
            int aportesEsteMes = 0;

            // Group data by month for the chart
            List<double> monthlyData = List.filled(12, 0.0);

            for (var a in aportes) {
              totalAportes += a.aporte.monto;
              monthlyData[a.aporte.fecha.month - 1] += a.aporte.monto;

              if (a.aporte.fecha.year == now.year &&
                  a.aporte.fecha.month == now.month) {
                aportesEsteMes++;
              }
            }

            // Scale the chart Y-axis dynamically
            double maxY = 10;
            if (aportes.isNotEmpty) {
              maxY = monthlyData.reduce(
                (curr, next) => curr > next ? curr : next,
              );
              maxY = maxY == 0 ? 10 : maxY * 1.2;
            }

            if (aportes.isNotEmpty) {
              maxY = monthlyData.reduce(
                (curr, next) => curr > next ? curr : next,
              );
              maxY = maxY == 0 ? 10 : maxY * 1.2;
            }

            // --- 1. NEW LOGIC: TOP 5 CONTRIBUTORS (THIS MONTH) ---
            final Map<String, double> top5Map = {};
            for (var a in aportes) {
              if (a.aporte.fecha.year == now.year &&
                  a.aporte.fecha.month == now.month) {
                final key = '${a.feligres.nombre} - ${a.aporte.tipo}';
                top5Map[key] = (top5Map[key] ?? 0) + a.aporte.monto;
              }
            }
            final top5List = top5Map.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final top5 = top5List.take(5).toList();

            // --- 2. NEW LOGIC: TOTAL BY GENDER ---
            double totalMasculino = 0;
            double totalFemenino = 0;

            for (var a in aportes) {
              // Only add if the contribution is from the current year and month
              if (a.aporte.fecha.year == now.year &&
                  a.aporte.fecha.month == now.month) {
                final genero = a.feligres.genero?.toLowerCase() ?? '';
                if (genero == 'masculino' || genero == 'm') {
                  totalMasculino += a.aporte.monto;
                } else if (genero == 'femenino' || genero == 'f') {
                  totalFemenino += a.aporte.monto;
                }
              }
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // ---------------------------------------------------
                  // 2. GRADIENT CARDS ROW
                  // ---------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Make cards stack vertically on phones, horizontally on desktop
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            _buildTotalCard(total: totalAportes),
                            const SizedBox(height: 16),
                            _buildMembersCard(activeMembers.length.toString()),
                            const SizedBox(height: 16),
                            _buildActivityCard(aportesEsteMes.toString()),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: _buildTotalCard(total: totalAportes)),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildMembersCard(
                              activeMembers.length.toString(),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildActivityCard(
                              aportesEsteMes.toString(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // ---------------------------------------------------
                  // 4. TOP 5 AND DEMOGRAPHICS ROW
                  // ---------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isStacked = constraints.maxWidth < 800;

                      if (isStacked) {
                        return Column(
                          children: [
                            _buildTop5Card(
                              top5,
                              panelColor,
                              textPrimary,
                              isDark,
                              Theme.of(context).colorScheme,
                              isStacked,
                            ),
                            const SizedBox(height: 24),
                            _buildGenderPieChart(
                              totalMasculino,
                              totalFemenino,
                              panelColor,
                              textPrimary,
                              isDark,
                              isStacked,
                            ),
                          ],
                        );
                      }
                      return SizedBox(
                        height:
                            460, // <-- Altura fija y segura para igualar ambos cuadros
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildTop5Card(
                                top5,
                                panelColor,
                                textPrimary,
                                isDark,
                                Theme.of(context).colorScheme,
                                isStacked,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: _buildGenderPieChart(
                                totalMasculino,
                                totalFemenino,
                                panelColor,
                                textPrimary,
                                isDark,
                                isStacked,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // ---------------------------------------------------
                  // 3. NEON CURVED CHART AREA
                  // ---------------------------------------------------
                  Container(
                    height: 400, // Fixed height for the chart
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chart Header
                        Text(
                          'Tendencia de Aportes Anual',
                          style: GoogleFonts.poppins(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // The Actual Chart
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: maxY / 4 == 0
                                    ? 1
                                    : maxY / 4,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      const style = TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
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
                                      int idx = value.toInt();
                                      if (idx >= 0 && idx < 12) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          child: Text(
                                            months[idx],
                                            style: style,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 45,
                                    getTitlesWidget: (value, meta) {
                                      if (value == maxY || value == 0)
                                        return const SizedBox.shrink();
                                      return Text(
                                        '\$${value.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 11,
                              minY: 0,
                              maxY: maxY,
                              lineBarsData: [
                                // --- REAL DATA LINE ---
                                LineChartBarData(
                                  spots: List.generate(12, (index) {
                                    return FlSpot(
                                      index.toDouble(),
                                      monthlyData[index],
                                    );
                                  }),
                                  isCurved: true,
                                  color: const Color(0xFF00C9FF), // Neon Cyan
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                              radius: 4,
                                              color: panelColor,
                                              strokeWidth: 2,
                                              strokeColor: const Color(
                                                0xFF00C9FF,
                                              ),
                                            ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF00C9FF,
                                        ).withOpacity(0.4),
                                        const Color(
                                          0xFF00C9FF,
                                        ).withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPER: TOP 5 CARD ---
  // --- HELPER: TOP 5 CARD ---
  Widget _buildTop5Card(
    List<MapEntry<String, double>> top5,
    Color panelColor,
    Color textPrimary,
    bool isDark,
    ColorScheme colorScheme,
    bool isStacked, // <-- Nuevo parámetro
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 Aportes (Mes Actual)',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          if (top5.isEmpty)
            // Centrado inteligente dependiendo de la pantalla
            isStacked
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No hay aportes este mes.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  )
                : const Expanded(
                    child: Center(
                      child: Text(
                        'No hay aportes este mes.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  )
          else
            ...top5.asMap().entries.map((entry) {
              int index = entry.key;
              String nameAndType = entry.value.key;
              double amount = entry.value.value;

              Color rankColor = index == 0
                  ? Colors.amber
                  : (index == 1
                        ? Colors.grey.shade400
                        : (index == 2
                              ? Colors.brown.shade300
                              : colorScheme.primary));

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: rankColor.withOpacity(0.2),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  nameAndType.split(' - ').first,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1, // <-- PREVIENE DESBORDAMIENTO VERTICAL
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  nameAndType.split(' - ').last,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  maxLines: 1, // <-- PREVIENE DESBORDAMIENTO VERTICAL
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    fontSize: 16,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // --- HELPER: GENDER PIE CHART ---
  Widget _buildGenderPieChart(
    double masculino,
    double femenino,
    Color panelColor,
    Color textPrimary,
    bool isDark,
    bool isStacked, // <-- Nuevo parámetro
  ) {
    final double total = masculino + femenino;
    final double pctMasc = total == 0 ? 0 : (masculino / total) * 100;
    final double pctFem = total == 0 ? 0 : (femenino / total) * 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aportes por Género (Mes Actual)',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (!isStacked)
            const Spacer(), // <-- Centra dinámicamente el gráfico hacia abajo
          if (isStacked) const SizedBox(height: 30),

          if (total == 0)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No hay datos registrados',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      sections: [
                        if (masculino > 0)
                          PieChartSectionData(
                            value: masculino,
                            color: const Color(0xFF00C9FF),
                            title:
                                '${pctMasc.toStringAsFixed(1)}%\n\$${masculino.toStringAsFixed(2)}',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (femenino > 0)
                          PieChartSectionData(
                            value: femenino,
                            color: const Color(0xFFFF007F),
                            title:
                                '${pctFem.toStringAsFixed(1)}%\n\$${femenino.toStringAsFixed(2)}',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(0)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 30), // <-- Espaciado adicional solicitado
          // <-- FITTEDBOX: PREVIENE EL DESBORDAMIENTO HORIZONTAL REDUCIENDO LA LETRA SI ES NECESARIO
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    'Hombres',
                    const Color(0xFF00C9FF),
                    masculino,
                  ),
                  const SizedBox(width: 24),
                  _buildLegendItem(
                    'Mujeres',
                    const Color(0xFFFF007F),
                    femenino,
                  ),
                ],
              ),
            ),
          ),

          if (!isStacked)
            const Spacer(), // <-- Empuja el gráfico hacia arriba, logrando el centrado perfecto
        ],
      ),
    );
  }

  // Updated legend to accept and display the amount
  Widget _buildLegendItem(String title, Color color, double amount) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          '$title: \$${amount.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Helper widgets for the cards
  Widget _buildTotalCard({double total = 0}) {
    return GradientSummaryCard(
      title: 'Total Histórico',
      value: '\$${total.toStringAsFixed(2)}',
      subtitle: 'Acumulado global',
      gradient: const LinearGradient(
        colors: [Color(0xFF89216B), Color(0xFFDA4453)], // Pink/Purple
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.account_balance_wallet,
    );
  }

  Widget _buildMembersCard(String count) {
    return GradientSummaryCard(
      title: 'Feligreses Activos',
      value: count,
      subtitle: 'Registrados en sistema',
      gradient: const LinearGradient(
        colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)], // Cyan/Green
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.people_alt,
    );
  }

  Widget _buildActivityCard(String count) {
    return GradientSummaryCard(
      title: 'Aportes del Mes',
      value: count,
      subtitle: DateFormat(
        'MMMM yyyy',
        'es',
      ).format(DateTime.now()).toUpperCase(),
      gradient: const LinearGradient(
        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)], // Deep Blue/Cyan
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.trending_up,
    );
  }
}

class GradientSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final LinearGradient gradient;
  final IconData icon;

  const GradientSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.last.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Use Expanded and overflow to prevent the title from breaking
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white, // Changed to pure white
                    fontSize: 14,
                    fontWeight: FontWeight.w600, // Slightly bolder
                    shadows: [
                      // Added shadow for contrast
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 15),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
