import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class DashboardSecretaria extends ConsumerStatefulWidget {
  const DashboardSecretaria({super.key});

  @override
  ConsumerState<DashboardSecretaria> createState() => _DashboardSecretariaState();
}

class _DashboardSecretariaState extends ConsumerState<DashboardSecretaria> {
  late Stream<List<Feligrese>> _membersStream;

  @override
  void initState() {
    super.initState();
    _membersStream = ref.read(databaseProvider).watchAllFeligreses();
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

    return StreamBuilder<List<Feligrese>>(
      stream: _membersStream, 
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allMembers = snapshot.data ?? [];
        final activeMembers = allMembers.where((m) => m.activo == 1 && m.iglesiaId == currentIglesia.id).toList();

        int ambosBautismos = 0, soloAgua = 0, soloEspiritu = 0, noBautizados = 0, discapacitados = 0;
        double solteros = 0, casados = 0, divorciados = 0, viudos = 0, unionLibre = 0;
        int simpatizantes = 0, feligreses = 0, visitas = 0;

        for (var m in activeMembers) {
          if (m.bautizadoAgua && m.bautizadoEspiritu) ambosBautismos++;
          else if (m.bautizadoAgua) soloAgua++;
          else if (m.bautizadoEspiritu) soloEspiritu++;
          else noBautizados++;

          if (m.poseeDiscapacidad) discapacitados++;

          final ec = m.estadoCivil?.toLowerCase() ?? '';
          if (ec.contains('soltero')) solteros++;
          else if (ec.contains('casado')) casados++;
          else if (ec.contains('divorciado')) divorciados++;
          else if (ec.contains('viudo')) viudos++;
          else if (ec.contains('unión libre') || ec.contains('union libre')) unionLibre++;

          switch (m.tipoFeligres?.toLowerCase()) {
            case 'simpatizante': simpatizantes++; break;
            case 'feligres': feligreses++; break;
            case 'visita': visitas++; break;
          }
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return Column(
                      children: [
                        _buildStatCard('Total de Personas', activeMembers.length.toDouble(), 'En la base de datos', const [Color(0xFF89216B), Color(0xFFDA4453)], Icons.groups),
                        const SizedBox(height: 16),
                        _buildStatCard('Feligreses Oficiales', feligreses.toDouble(), 'Membresía activa', const [Color(0xFF00C9FF), Color(0xFF92FE9D)], Icons.card_membership),
                        const SizedBox(height: 16),
                        _buildStatCard('Bautizados (Agua)', (ambosBautismos + soloAgua).toDouble(), 'Paso de obediencia', const [Color(0xFF4FACFE), Color(0xFF00F2FE)], Icons.water_drop),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: _buildStatCard('Total de Personas', activeMembers.length.toDouble(), 'En la base de datos', const [Color(0xFF89216B), Color(0xFFDA4453)], Icons.groups)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildStatCard('Feligreses Oficiales', feligreses.toDouble(), 'Membresía activa', const [Color(0xFF00C9FF), Color(0xFF92FE9D)], Icons.card_membership)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildStatCard('Bautizados (Agua)', (ambosBautismos + soloAgua).toDouble(), 'Paso de obediencia', const [Color(0xFF4FACFE), Color(0xFF00F2FE)], Icons.water_drop)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isStacked = constraints.maxWidth < 800;
                  
                  final maritalWidget = RepaintBoundary(
                    child: _VisibilityAnimator(
                      id: 'maritalPie',
                      builder: (context, isVisible) => _buildMaritalStatusChart(solteros, casados, divorciados, viudos, unionLibre, panelColor, textPrimary, isDark, isStacked, isVisible),
                    ),
                  );
                  final spiritualWidget = RepaintBoundary(
                    child: _VisibilityAnimator(
                      id: 'spiritualBar',
                      builder: (context, isVisible) => _buildSpiritualBarChart(ambosBautismos, soloAgua, soloEspiritu, noBautizados, panelColor, textPrimary, isDark, isVisible),
                    ),
                  );

                  if (isStacked) {
                    return Column(
                      children: [
                        maritalWidget,
                        const SizedBox(height: 24),
                        spiritualWidget,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: maritalWidget),
                      const SizedBox(width: 24),
                      Expanded(child: spiritualWidget),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isStacked = constraints.maxWidth < 800;
                  final membershipWidget = _VisibilityAnimator(
                    id: 'membershipCard',
                    builder: (context, isVisible) => _buildMembershipCard(simpatizantes, feligreses, visitas, panelColor, textPrimary, isDark, isVisible),
                  );
                  final disabilityWidget = _VisibilityAnimator(
                    id: 'disabilityCard',
                    builder: (context, isVisible) => _buildDisabilityCard(discapacitados, activeMembers.length, panelColor, textPrimary, isDark, isVisible),
                  );

                  if (isStacked) {
                    return Column(
                      children: [
                        membershipWidget,
                        const SizedBox(height: 24),
                        disabilityWidget,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: membershipWidget),
                      const SizedBox(width: 24),
                      Expanded(child: disabilityWidget),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, double targetValue, String subtitle, List<Color> colors, IconData icon) {
    return _GradientSummaryCardSecretaria(
      title: title,
      targetValue: targetValue,
      subtitle: subtitle,
      gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      icon: icon,
    );
  }

  Widget _buildMaritalStatusChart(double solteros, double casados, double divorciados, double viudos, double unionLibre, Color panelColor, Color textPrimary, bool isDark, bool isStacked, bool isVisible) {
    final double total = solteros + casados + divorciados + viudos + unionLibre;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estado Civil', style: GoogleFonts.poppins(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          if (total == 0)
            SizedBox(height: 200, child: Center(child: Text('Sin datos', style: GoogleFonts.poppins(color: Colors.grey))))
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
                            if (solteros > 0) PieChartSectionData(value: solteros, color: const Color(0xFF00C9FF), title: '${solteros.toInt()}\n(${((solteros / total) * 100).toStringAsFixed(1)}%)', radius: 45, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                            if (casados > 0) PieChartSectionData(value: casados, color: const Color(0xFFFF007F), title: '${casados.toInt()}\n(${((casados / total) * 100).toStringAsFixed(1)}%)', radius: 45, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                            if (divorciados > 0) PieChartSectionData(value: divorciados, color: Colors.orangeAccent, title: '${divorciados.toInt()}\n(${((divorciados / total) * 100).toStringAsFixed(1)}%)', radius: 45, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                            if (viudos > 0) PieChartSectionData(value: viudos, color: Colors.purpleAccent, title: '${viudos.toInt()}\n(${((viudos / total) * 100).toStringAsFixed(1)}%)', radius: 45, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                            if (unionLibre > 0) PieChartSectionData(value: unionLibre, color: Colors.greenAccent, title: '${unionLibre.toInt()}\n(${((unionLibre / total) * 100).toStringAsFixed(1)}%)', radius: 45, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Registros', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                          Text('${total.toInt()}', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
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
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildLegend('Solteros', const Color(0xFF00C9FF)),
                _buildLegend('Casados', const Color(0xFFFF007F)),
                _buildLegend('Divorciados', Colors.orangeAccent),
                _buildLegend('Viudos', Colors.purpleAccent),
                _buildLegend('Unión Libre', Colors.greenAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpiritualBarChart(int ambos, int soloAgua, int soloEspiritu, int ninguno, Color panelColor, Color textPrimary, bool isDark, bool isVisible) {
    final double total = (ambos + soloAgua + soloEspiritu + ninguno).toDouble();

    Widget buildBar(String label, int count, Color color) {
      double targetPct = total == 0 ? 0 : count / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: isVisible ? targetPct : 0.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutQuart,
          builder: (context, val, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                    Text('$count (${(val * 100).toStringAsFixed(1)}%)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(10))),
                    FractionallySizedBox(widthFactor: val, child: Container(height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)))),
                  ],
                ),
              ],
            );
          }
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.05), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estado Espiritual', style: GoogleFonts.poppins(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          if (total == 0)
            SizedBox(height: 200, child: Center(child: Text('Sin datos', style: GoogleFonts.poppins(color: Colors.grey))))
          else
            Column(
              children: [
                buildBar('Agua y Espíritu', ambos, Colors.blueAccent),
                buildBar('Solo Agua', soloAgua, Colors.cyan),
                buildBar('Solo Espíritu', soloEspiritu, Colors.deepOrangeAccent),
                buildBar('No Bautizados', ninguno, Colors.grey),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(int simpatizantes, int feligreses, int visitas, Color panelColor, Color textPrimary, bool isDark, bool isVisible) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.05), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tipos de Membresía', style: GoogleFonts.poppins(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildInfoRow('Feligreses', feligreses, const Color(0xFF00C9FF), Icons.star, isVisible),
          const SizedBox(height: 20),
          _buildInfoRow('Simpatizantes', simpatizantes, Colors.orangeAccent, Icons.favorite, isVisible),
          const SizedBox(height: 20),
          _buildInfoRow('Visitas', visitas, Colors.greenAccent, Icons.waving_hand, isVisible),
        ],
      ),
    );
  }

  Widget _buildDisabilityCard(int discapacitados, int total, Color panelColor, Color textPrimary, bool isDark, bool isVisible) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.05), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Necesidades Especiales', style: GoogleFonts.poppins(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildInfoRow('Con Discapacidad', discapacitados, Colors.purpleAccent, Icons.accessible, isVisible),
          const SizedBox(height: 20),
          _buildInfoRow('Sin Discapacidad', total - discapacitados, Colors.grey, Icons.accessibility_new, isVisible),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, int count, Color color, IconData icon, bool isVisible) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500))),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: isVisible ? count.toDouble() : 0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutQuart,
          builder: (context, val, child) {
            return Text(val.toInt().toString(), style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold));
          }
        ),
      ],
    );
  }

  Widget _buildLegend(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }
}

class _GradientSummaryCardSecretaria extends StatelessWidget {
  final String title;
  final double targetValue;
  final String subtitle;
  final LinearGradient gradient;
  final IconData icon;

  const _GradientSummaryCardSecretaria({
    required this.title,
    required this.targetValue,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: gradient.colors.last.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]), overflow: TextOverflow.ellipsis)),
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
                return Text(val.toInt().toString(), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]));
              },
            ),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

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
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: widget.builder(context, _isVisible),
    );
  }
}