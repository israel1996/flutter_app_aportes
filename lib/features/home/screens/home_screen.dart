import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/features/auth/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';
import '../../../core/database/database.dart';
import '../../members/screens/add_feligres_screen.dart';
import '../../sync/services/sync_service.dart';
import '../../tithes/screens/add_aporte_screen.dart';
import '../../tithes/screens/history_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/local_auth_service.dart';

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
      _checkAndSetupPin();
    });
  }

  Future<void> _checkAndSetupPin() async {
    final authService = LocalAuthService();
    final hasPin = await authService.hasPinConfigured();

    if (!hasPin && mounted) {
      _showSetupPinDialog();
    }
  }

  void _showSetupPinDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text(
            'Configurar PIN de Seguridad',
            style: TextStyle(color: Colors.indigo),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Para acceder a tus datos sin internet en el futuro, por favor crea un PIN de acceso de 4 dígitos para este dispositivo.',
              ),
              const SizedBox(height: 15),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Nuevo PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (pinController.text.length >= 4) {
                  await LocalAuthService().setPin(pinController.text);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PIN configurado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El PIN debe tener al menos 4 dígitos.'),
                    ),
                  );
                }
              },
              child: const Text('GUARDAR PIN'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final stream = database.watchAllFeligreses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Aportes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Sync Button
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
            onPressed: () async {
              final database = ref.read(databaseProvider);
              final syncService = SyncService(database);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 20),
                      Text('Sincronizando...'),
                    ],
                  ),
                  duration: Duration(minutes: 1),
                ),
              );

              try {
                await syncService.syncAll();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sincronización completa'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error de sincronización: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final authService = ref.read(authServiceProvider);

              if (authService.currentUser == null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } else {
                await authService.signOut();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.church, size: 50, color: Colors.indigo),
                const SizedBox(height: 10),
                StreamBuilder<double>(
                  stream: ref.watch(databaseProvider).watchTotalIncome(),
                  builder: (context, snapshot) {
                    final total = snapshot.data ?? 0.0;
                    return Card(
                      color: Colors.indigo,
                      margin: const EdgeInsets.all(20),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddFeligresScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Registrar Feligres'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      // Navigate to the new screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAporteScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.monetization_on),
                    label: const Text('Registrar Aporte'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text(
                      'Ver Historial Completo',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(thickness: 2),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Feligreses Recientes",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Feligrese>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final feligreses = snapshot.data ?? [];

                if (feligreses.isEmpty) {
                  return const Center(
                    child: Text('No hay feligreses registrados!'),
                  );
                }

                return ListView.builder(
                  itemCount: feligreses.length,
                  itemBuilder: (context, index) {
                    final person = feligreses[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(person.nombre[0].toUpperCase()),
                      ),
                      title: Text(person.nombre),
                      subtitle: Text(person.telefono ?? 'Sin telefono'),
                      trailing: person.syncStatus == 0
                          ? const Icon(Icons.cloud_off, color: Colors.orange)
                          : const Icon(Icons.cloud_done, color: Colors.green),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
