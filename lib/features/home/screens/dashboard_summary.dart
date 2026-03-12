import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: '\$ ',
  decimalDigits: 2,
);
final _axisFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: '\$ ',
  decimalDigits: 0,
);

class DashboardSummary extends ConsumerStatefulWidget {
  const DashboardSummary({super.key});

  @override
  ConsumerState<DashboardSummary> createState() => _DashboardSummaryState();
}

class _DashboardSummaryState extends ConsumerState<DashboardSummary> {
  late Stream<List<AporteConFeligres>> _historyStream;
  late Stream<List<Feligrese>> _membersStream;

  @override
  void initState() {
    super.initState();
    final database = ref.read(databaseProvider);
    _historyStream = database.watchHistory();
    _membersStream = database.watchAllFeligreses();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final currentIglesia = ref.watch(currentIglesiaProvider);

    if (currentIglesia == null) {
      return Center(
        child: Text(
          'Por favor, selecciona o registra una sede en la parte superior.',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<List<AporteConFeligres>>(
      stream: _historyStream,
      builder: (context, historySnapshot) {
        return StreamBuilder<List<Feligrese>>(
          stream: _membersStream,
          builder: (context, membersSnapshot) {
            final rawAportes = historySnapshot.data ?? [];
            final aportes = rawAportes
                .where((a) => a.feligres.iglesiaId == currentIglesia.id)
                .toList();

            double totalAportes = 0;
            double dineroEsteMes = 0;
            final now = DateTime.now();
            int aportesEsteMes = 0;
            List<double> monthlyData = List.filled(12, 0.0);

            for (var a in aportes) {
              totalAportes += a.aporte.monto;
              if (a.aporte.fecha.year == now.year) {
                monthlyData[a.aporte.fecha.month - 1] += a.aporte.monto;
              }
              if (a.aporte.fecha.year == now.year &&
                  a.aporte.fecha.month == now.month) {
                aportesEsteMes++;
                dineroEsteMes += a.aporte.monto;
              }
            }

            final totalAnual = monthlyData.fold<double>(
              0,
              (prev, amount) => prev + amount,
            );
            double maxY = 10;
            if (aportes.isNotEmpty) {
              maxY = monthlyData.reduce(
                (curr, next) => curr > next ? curr : next,
              );
              maxY = maxY == 0 ? 10 : maxY * 1.2;
            }

            // TOP 5
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

            // GENDER
            double totalMasculino = 0;
            double totalFemenino = 0;
            for (var a in aportes) {
              if (a.aporte.fecha.year == now.year &&
                  a.aporte.fecha.month == now.month) {
                final genero = a.feligres.genero?.toLowerCase() ?? '';
                if (genero == 'masculino' || genero == 'm')
                  totalMasculino += a.aporte.monto;
                else if (genero == 'femenino' || genero == 'f')
                  totalFemenino += a.aporte.monto;
              }
            }

            // AGES
            double ninos = 0,
                adolescentes = 0,
                jovenes = 0,
                adultos = 0,
                mayores = 0;
            for (var a in aportes) {
              if (a.aporte.fecha.year == now.year &&
                  a.aporte.fecha.month == now.month) {
                final birthDate = a.feligres.fechaNacimiento;
                if (birthDate != null) {
                  int age = now.year - birthDate.year;
                  if (now.month < birthDate.month ||
                      (now.month == birthDate.month && now.day < birthDate.day))
                    age--;

                  if (age <= 11)
                    ninos += a.aporte.monto;
                  else if (age <= 17)
                    adolescentes += a.aporte.monto;
                  else if (age <= 29)
                    jovenes += a.aporte.monto;
                  else if (age <= 59)
                    adultos += a.aporte.monto;
                  else
                    mayores += a.aporte.monto;
                }
              }
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            _buildTotalCard(total: totalAportes),
                            const SizedBox(height: 16),
                            _buildMonthlyIncomeCard(dineroEsteMes),
                            const SizedBox(height: 16),
                            _buildActivityCard(aportesEsteMes.toDouble()),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: _buildTotalCard(total: totalAportes)),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildMonthlyIncomeCard(dineroEsteMes),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildActivityCard(
                              aportesEsteMes.toDouble(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isStacked = constraints.maxWidth < 800;

                      final top5Widget = _VisibilityAnimator(
                        id: 'top5',
                        builder: (context, isVisible) => _buildTop5Card(
                          top5,
                          panelColor,
                          textPrimary,
                          isDark,
                          Theme.of(context).colorScheme,
                          isStacked,
                          isVisible,
                        ),
                      );

                      final genderPieWidget = RepaintBoundary(
                        child: _VisibilityAnimator(
                          id: 'genderPie',
                          builder: (context, isVisible) => _buildGenderPieChart(
                            totalMasculino,
                            totalFemenino,
                            panelColor,
                            textPrimary,
                            isDark,
                            isStacked,
                            isVisible,
                          ),
                        ),
                      );

                      if (isStacked) {
                        return Column(
                          children: [
                            top5Widget,
                            const SizedBox(height: 24),
                            genderPieWidget,
                          ],
                        );
                      }
                      return SizedBox(
                        height: 460,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: top5Widget),
                            const SizedBox(width: 24),
                            Expanded(flex: 4, child: genderPieWidget),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  RepaintBoundary(
                    child: _VisibilityAnimator(
                      id: 'ageBar',
                      builder: (context, isVisible) => _buildAgeBracketChart(
                        ninos,
                        adolescentes,
                        jovenes,
                        adultos,
                        mayores,
                        panelColor,
                        textPrimary,
                        isDark,
                        Theme.of(context).colorScheme,
                        isVisible,
                        maxY,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  RepaintBoundary(
                    child: _VisibilityAnimator(
                      id: 'annualLine',
                      builder: (context, isVisible) => _buildAnnualTrendChart(
                        monthlyData,
                        totalAnual,
                        maxY,
                        panelColor,
                        textPrimary,
                        isDark,
                        isVisible,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTop5Card(
    List<MapEntry<String, double>> top5,
    Color panelColor,
    Color textPrimary,
    bool isDark,
    ColorScheme colorScheme,
    bool isStacked,
    bool isVisible,
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
            Column(
              children: top5.asMap().entries.map((entry) {
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

                return AnimatedOpacity(
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 400 + (index * 200)),
                  child: AnimatedSlide(
                    offset: isVisible ? Offset.zero : const Offset(0, 0.3),
                    duration: Duration(milliseconds: 400 + (index * 200)),
                    curve: Curves.easeOutQuart,
                    child: ListTile(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        nameAndType.split(' - ').last,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _currencyFormat.format(amount),
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderPieChart(
    double masculino,
    double femenino,
    Color panelColor,
    Color textPrimary,
    bool isDark,
    bool isStacked,
    bool isVisible,
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
          if (!isStacked) const Spacer(),
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
            AnimatedScale(
              scale: isVisible ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: SizedBox(
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
                                    '${pctMasc.toStringAsFixed(1)}%\n${_currencyFormat.format(masculino)}',
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
                                    '${pctFem.toStringAsFixed(1)}%\n${_currencyFormat.format(femenino)}',
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
                            _currencyFormat.format(total),
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 30),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildLegendItem('Hombres', const Color(0xFF00C9FF), masculino),
                _buildLegendItem('Mujeres', const Color(0xFFFF007F), femenino),
              ],
            ),
          ),
          if (!isStacked) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          '$title: ${_currencyFormat.format(amount)}',
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAnnualTrendChart(
    List<double> monthlyData,
    double totalAnual,
    double maxY,
    Color panelColor,
    Color textPrimary,
    bool isDark,
    bool isVisible,
  ) {
    return Container(
      height: 400,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tendencia de Aportes Anual',
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: isVisible ? totalAnual : 0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutQuart,
                builder: (context, val, _) {
                  return Text(
                    _currencyFormat.format(val),
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF00C9FF),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots
                          .map(
                            (spot) => LineTooltipItem(
                              _currencyFormat.format(spot.y),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          )
                          .toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
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
                        if (idx >= 0 && idx < 12)
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(months[idx], style: style),
                          );
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        if (value == maxY || value == 0)
                          return const SizedBox.shrink();
                        return Text(
                          _axisFormat.format(value),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                  LineChartBarData(
                    // Aquí la animación desliza la gráfica desde 0
                    spots: List.generate(
                      12,
                      (index) => FlSpot(
                        index.toDouble(),
                        isVisible ? monthlyData[index] : 0.0,
                      ),
                    ),
                    isCurved: true,
                    color: const Color(0xFF00C9FF),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: panelColor,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF00C9FF),
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00C9FF).withOpacity(0.4),
                          const Color(0xFF00C9FF).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutQuart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeBracketChart(
    double ninos,
    double adolescentes,
    double jovenes,
    double adultos,
    double mayores,
    Color panelColor,
    Color textPrimary,
    bool isDark,
    ColorScheme colorScheme,
    bool isVisible,
    double globalMaxY,
  ) {
    final double maxVal = [
      ninos,
      adolescentes,
      jovenes,
      adultos,
      mayores,
    ].reduce((a, b) => a > b ? a : b);
    final double chartMaxY = maxVal == 0 ? 100 : maxVal * 1.2;

    return Container(
      height: 400,
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
          Text(
            'Aportes por Grupos de Edad (Mes Actual)',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          _currencyFormat.format(rod.toY),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
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
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Niños\n(0-11)';
                            break;
                          case 1:
                            text = 'Adolesc.\n(12-17)';
                            break;
                          case 2:
                            text = 'Jóvenes\n(18-29)';
                            break;
                          case 3:
                            text = 'Adultos\n(30-59)';
                            break;
                          case 4:
                            text = 'Mayores\n(60+)';
                            break;
                          default:
                            text = '';
                            break;
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 12,
                          child: Text(
                            text,
                            style: style,
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                      reservedSize: 45,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value >= chartMaxY)
                          return const SizedBox.shrink();
                        return Text(
                          _axisFormat.format(value),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBarGroup(
                    0,
                    isVisible ? ninos : 0,
                    const Color(0xFF92FE9D),
                  ),
                  _buildBarGroup(
                    1,
                    isVisible ? adolescentes : 0,
                    const Color(0xFF00C9FF),
                  ),
                  _buildBarGroup(
                    2,
                    isVisible ? jovenes : 0,
                    const Color(0xFF4FACFE),
                  ),
                  _buildBarGroup(
                    3,
                    isVisible ? adultos : 0,
                    const Color(0xFF89216B),
                  ),
                  _buildBarGroup(
                    4,
                    isVisible ? mayores : 0,
                    const Color(0xFFFF007F),
                  ),
                ],
              ),
              swapAnimationDuration: const Duration(milliseconds: 1000),
              swapAnimationCurve: Curves.easeOutQuart,
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 24,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard({double total = 0}) {
    return GradientSummaryCard(
      title: 'Total Histórico',
      targetValue: total,
      valueFormatter: (val) => _currencyFormat.format(val),
      subtitle: 'Acumulado global',
      gradient: const LinearGradient(
        colors: [Color(0xFF89216B), Color(0xFFDA4453)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.account_balance_wallet,
    );
  }

  Widget _buildMonthlyIncomeCard(double amount) {
    return GradientSummaryCard(
      title: 'Ingresos del Mes',
      targetValue: amount,
      valueFormatter: (val) => _currencyFormat.format(val),
      subtitle: 'Recaudado este mes',
      gradient: const LinearGradient(
        colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.monetization_on_outlined,
    );
  }

  Widget _buildActivityCard(double count) {
    return GradientSummaryCard(
      title: 'Aportes del Mes',
      targetValue: count,
      valueFormatter: (val) => val.toInt().toString(),
      subtitle: DateFormat(
        'MMMM yyyy',
        'es',
      ).format(DateTime.now()).toUpperCase(),
      gradient: const LinearGradient(
        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.trending_up,
    );
  }
}

// --- WIDGET PARA ANIMAR NÚMEROS EN LAS TARJETAS ---
class GradientSummaryCard extends StatelessWidget {
  final String title;
  final double targetValue;
  final String Function(double) valueFormatter;
  final String subtitle;
  final LinearGradient gradient;
  final IconData icon;

  const GradientSummaryCard({
    super.key,
    required this.title,
    required this.targetValue,
    required this.valueFormatter,
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    shadows: [
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
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: targetValue),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutQuart,
              builder: (context, val, child) {
                return Text(
                  valueFormatter(val),
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
                );
              },
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

// --- CLASE AYUDANTE PARA DETECTAR EL SCROLL ---
class _VisibilityAnimator extends StatefulWidget {
  final String id;
  final Widget Function(BuildContext context, bool isVisible) builder;

  const _VisibilityAnimator({required this.id, required this.builder});

  @override
  __VisibilityAnimatorState createState() => __VisibilityAnimatorState();
}

class __VisibilityAnimatorState extends State<_VisibilityAnimator> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.id),
      onVisibilityChanged: (info) {
        if (!_isVisible && info.visibleFraction > 0.05) {
          // Se activa cuando se ve al menos un 5%
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: widget.builder(context, _isVisible),
    );
  }
}
