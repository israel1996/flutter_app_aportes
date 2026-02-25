import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../sync/services/sync_service.dart';
import '../../tithes/screens/add_aporte_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSync();
    });
  }

  Future<void> _checkAndSync() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet =
        connectivity.contains(ConnectivityResult.mobile) ||
        connectivity.contains(ConnectivityResult.wifi) ||
        connectivity.contains(ConnectivityResult.ethernet);

    if (!hasInternet) return;

    final authService = ref.read(authServiceProvider);
    if (authService.currentUser == null) return;

    try {
      final database = ref.read(databaseProvider);
      await SyncService(database).syncAll();
      debugPrint("✅ Auto-Sync inicial completado.");
    } catch (e) {
      debugPrint("❌ Auto-Sync falló: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final historyStream = database.watchHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Principal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar Manualmente',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sincronizando con la nube...')),
              );
              try {
                await SyncService(database).syncAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Sincronización completa'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              try {
                await authService.signOut();
              } catch (_) {}
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
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

          final allAportes = snapshot.data ?? [];

          final now = DateTime.now();
          final aportesMes = allAportes
              .where(
                (a) =>
                    a.aporte.fecha.year == now.year &&
                    a.aporte.fecha.month == now.month,
              )
              .toList();

          final double totalMes = aportesMes.fold(
            0.0,
            (sum, item) => sum + item.aporte.monto,
          );
          final double diezPorciento = totalMes * 0.10;
          final double primerRestante = totalMes - diezPorciento;
          final double cincoPorciento = primerRestante * 0.05;
          final double saldoFinal = primerRestante - cincoPorciento;

          final top5 = List<AporteConFeligres>.from(aportesMes)
            ..sort((a, b) => b.aporte.monto.compareTo(a.aporte.monto));
          final top5List = top5.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.indigo,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddAporteScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle),
                        label: const Text(
                          'Registrar Aporte',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Módulo de reportes en construcción',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bar_chart),
                        label: const Text('Ver Reportes'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Módulo de exportación en construcción',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.import_export),
                        label: const Text('Exportar Datos'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                Text(
                  'Resumen: ${DateFormat('MMMM yyyy', 'es').format(now).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildMathRow(
                          'Ingreso Total del Mes:',
                          totalMes,
                          isBold: true,
                          size: 18,
                        ),
                        const Divider(height: 30),
                        _buildMathRow(
                          'Retención (10% del Total):',
                          diezPorciento,
                          color: Colors.red.shade700,
                        ),
                        _buildMathRow(
                          'Fondo (5% del Restante):',
                          cincoPorciento,
                          color: Colors.orange.shade800,
                        ),
                        const Divider(height: 30),
                        _buildMathRow(
                          'Saldo Final Disponible:',
                          saldoFinal,
                          isBold: true,
                          size: 22,
                          color: Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🏆 Top 5 Aportes del Mes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (top5List.isNotEmpty)
                      Text(
                        'De ${aportesMes.length} registros',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (top5List.isEmpty)
                  Card(
                    color: Colors.grey.shade100,
                    child: const Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Center(
                        child: Text(
                          'No hay aportes registrados este mes.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: top5List.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = top5List[index];
                        final isFirst = index == 0;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isFirst
                                ? Colors.amber
                                : Colors.indigo.shade100,
                            foregroundColor: isFirst
                                ? Colors.white
                                : Colors.indigo,
                            child: isFirst
                                ? const Icon(Icons.star)
                                : Text('${index + 1}'),
                          ),
                          title: Text(
                            item.feligres.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.aporte.tipo} • ${DateFormat('dd MMM', 'es').format(item.aporte.fecha)}',
                          ),
                          trailing: Text(
                            '\$${item.aporte.monto.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMathRow(
    String label,
    double amount, {
    bool isBold = false,
    double size = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: size - 2,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: size,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
