import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';
import 'dashboard_summary.dart';

class DashboardSecretaria extends ConsumerWidget {
  const DashboardSecretaria({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;

    return StreamBuilder<List<Feligrese>>(
      stream: database.watchAllFeligreses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allMembers = snapshot.data ?? [];
        final activeMembers = allMembers.where((m) => m.activo == 1).toList();

        // --- 1. CALCULATE DEMOGRAPHICS ---
        int ambosBautismos = 0;
        int soloAgua = 0;
        int soloEspiritu = 0;
        int noBautizados = 0;
        int discapacitados = 0;

        // Marital Status
        double solteros = 0,
            casados = 0,
            divorciados = 0,
            viudos = 0,
            unionLibre = 0;
        // Membership Type
        int simpatizantes = 0, feligreses = 0, visitas = 0;

        for (var m in activeMembers) {
          // Spiritual Status (Mutually Exclusive)
          if (m.bautizadoAgua && m.bautizadoEspiritu) {
            ambosBautismos++;
          } else if (m.bautizadoAgua) {
            soloAgua++;
          } else if (m.bautizadoEspiritu) {
            soloEspiritu++;
          } else {
            noBautizados++;
          }

          // Disability
          if (m.poseeDiscapacidad) discapacitados++;

          // Marital Status
          switch (m.estadoCivil?.toLowerCase()) {
            case 'soltero':
              solteros++;
              break;
            case 'casado':
              casados++;
              break;
            case 'divorciado':
              divorciados++;
              break;
            case 'viudo':
              viudos++;
              break;
            case 'unión libre':
              unionLibre++;
              break;
          }

          // Membership Type
          switch (m.tipoFeligres?.toLowerCase()) {
            case 'simpatizante':
              simpatizantes++;
              break;
            case 'feligres':
              feligreses++;
              break;
            case 'visita':
              visitas++;
              break;
          }
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 2. TOP GRADIENT CARDS ---
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return Column(
                      children: [
                        _buildStatCard(
                          'Total de Personas',
                          activeMembers.length.toString(),
                          'En la base de datos',
                          const [Color(0xFF89216B), Color(0xFFDA4453)],
                          Icons.groups,
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Feligreses Oficiales',
                          feligreses.toString(),
                          'Membresía activa',
                          const [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                          Icons.card_membership,
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Bautizados (Agua)',
                          (ambosBautismos + soloAgua).toString(),
                          'Paso de obediencia',
                          const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                          Icons.water_drop,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total de Personas',
                          activeMembers.length.toString(),
                          'En la base de datos',
                          const [Color(0xFF89216B), Color(0xFFDA4453)],
                          Icons.groups,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildStatCard(
                          'Feligreses Oficiales',
                          feligreses.toString(),
                          'Membresía activa',
                          const [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                          Icons.card_membership,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildStatCard(
                          'Bautizados (Agua)',
                          (ambosBautismos + soloAgua).toString(),
                          'Paso de obediencia',
                          const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                          Icons.water_drop,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // --- 3. PIE CHARTS ROW (MARITAL STATUS & SPIRITUAL STATUS) ---
              LayoutBuilder(
                builder: (context, constraints) {
                  final isStacked = constraints.maxWidth < 800;
                  final maritalWidget = _buildMaritalStatusChart(
                    solteros,
                    casados,
                    divorciados,
                    viudos,
                    unionLibre,
                    panelColor,
                    textPrimary,
                    isDark,
                    isStacked,
                  );
                  final spiritualWidget = _buildSpiritualPieChart(
                    ambosBautismos,
                    soloAgua,
                    soloEspiritu,
                    noBautizados,
                    panelColor,
                    textPrimary,
                    isDark,
                    isStacked,
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

              // --- 4. LIST CARDS ROW (MEMBERSHIP & DISABILITY) ---
              LayoutBuilder(
                builder: (context, constraints) {
                  final isStacked = constraints.maxWidth < 800;
                  final membershipWidget = _buildMembershipCard(
                    simpatizantes,
                    feligreses,
                    visitas,
                    panelColor,
                    textPrimary,
                    isDark,
                  );
                  final disabilityWidget = _buildDisabilityCard(
                    discapacitados,
                    activeMembers.length,
                    panelColor,
                    textPrimary,
                    isDark,
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

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    List<Color> colors,
    IconData icon,
  ) {
    return GradientSummaryCard(
      title: title,
      value: value,
      subtitle: subtitle,
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: icon,
    );
  }

  Widget _buildMaritalStatusChart(
    double solteros,
    double casados,
    double divorciados,
    double viudos,
    double unionLibre,
    Color panelColor,
    Color textPrimary,
    bool isDark,
    bool isStacked,
  ) {
    final double total = solteros + casados + divorciados + viudos + unionLibre;
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
            'Estado Civil',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          if (total == 0)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Sin datos',
                  style: GoogleFonts.poppins(color: Colors.grey),
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
                        if (solteros > 0)
                          PieChartSectionData(
                            value: solteros,
                            color: const Color(0xFF00C9FF),
                            title:
                                '${solteros.toInt()}\n(${((solteros / total) * 100).toStringAsFixed(1)}%)',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        if (casados > 0)
                          PieChartSectionData(
                            value: casados,
                            color: const Color(0xFFFF007F),
                            title:
                                '${casados.toInt()}\n(${((casados / total) * 100).toStringAsFixed(1)}%)',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        if (divorciados > 0)
                          PieChartSectionData(
                            value: divorciados,
                            color: Colors.orangeAccent,
                            title:
                                '${divorciados.toInt()}\n(${((divorciados / total) * 100).toStringAsFixed(1)}%)',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        if (viudos > 0)
                          PieChartSectionData(
                            value: viudos,
                            color: Colors.purpleAccent,
                            title:
                                '${viudos.toInt()}\n(${((viudos / total) * 100).toStringAsFixed(1)}%)',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        if (unionLibre > 0)
                          PieChartSectionData(
                            value: unionLibre,
                            color: Colors.greenAccent,
                            title:
                                '${unionLibre.toInt()}\n(${((unionLibre / total) * 100).toStringAsFixed(1)}%)',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Registros',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${total.toInt()}',
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

  Widget _buildSpiritualPieChart(
    int ambos,
    int soloAgua,
    int soloEspiritu,
    int ninguno,
    Color panelColor,
    Color textPrimary,
    bool isDark,
    bool isStacked,
  ) {
    final double total = (ambos + soloAgua + soloEspiritu + ninguno).toDouble();
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
            'Estado Espiritual',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          if (total == 0)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Sin datos',
                  style: GoogleFonts.poppins(color: Colors.grey),
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
                        if (ambos > 0)
                          PieChartSectionData(
                            value: ambos.toDouble(),
                            color: Colors.blueAccent,
                            title:
                                '${ambos}\n(${((ambos / total) * 100).toStringAsFixed(1)}%)',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        if (soloAgua > 0)
                          PieChartSectionData(
                            value: soloAgua.toDouble(),
                            color: Colors.cyan,
                            title:
                                '${soloAgua}\n(${((soloAgua / total) * 100).toStringAsFixed(1)}%)',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        if (soloEspiritu > 0)
                          PieChartSectionData(
                            value: soloEspiritu.toDouble(),
                            color: Colors.deepOrangeAccent,
                            title:
                                '${soloEspiritu}\n(${((soloEspiritu / total) * 100).toStringAsFixed(1)}%)',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        if (ninguno > 0)
                          PieChartSectionData(
                            value: ninguno.toDouble(),
                            color: Colors.grey,
                            title:
                                '${ninguno}\n(${((ninguno / total) * 100).toStringAsFixed(1)}%)',
                            radius: 45,
                            titleStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Registros',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${total.toInt()}',
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
          const SizedBox(height: 30),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildLegend('Agua y Espíritu', Colors.blueAccent),
                _buildLegend('Solo Agua', Colors.cyan),
                _buildLegend('Solo Espíritu', Colors.deepOrangeAccent),
                _buildLegend('No Bautizados', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(
    int simpatizantes,
    int feligreses,
    int visitas,
    Color panelColor,
    Color textPrimary,
    bool isDark,
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
            'Tipos de Membresía',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          _buildInfoRow(
            'Feligreses',
            feligreses,
            const Color(0xFF00C9FF),
            Icons.star,
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            'Simpatizantes',
            simpatizantes,
            Colors.orangeAccent,
            Icons.favorite,
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            'Visitas',
            visitas,
            Colors.greenAccent,
            Icons.waving_hand,
          ),
        ],
      ),
    );
  }

  Widget _buildDisabilityCard(
    int discapacitados,
    int total,
    Color panelColor,
    Color textPrimary,
    bool isDark,
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
            'Necesidades Especiales',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          _buildInfoRow(
            'Con Discapacidad',
            discapacitados,
            Colors.purpleAccent,
            Icons.accessible,
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            'Sin Discapacidad',
            total - discapacitados,
            Colors.grey,
            Icons.accessibility_new,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, int count, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }
}
