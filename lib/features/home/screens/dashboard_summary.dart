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
            final members = membersSnapshot.data ?? [];

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
                            _buildMembersCard(members.length.toString()),
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
                            child: _buildMembersCard(members.length.toString()),
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
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 15),
          // Use FittedBox to automatically shrink the huge numbers if the screen gets too small
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
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
