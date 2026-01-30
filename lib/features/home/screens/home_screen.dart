import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';
import '../../../core/database/database.dart';
import '../../members/screens/add_feligres_screen.dart';
import '../../sync/services/sync_service.dart';
import '../../tithes/screens/add_aporte_screen.dart';
import '../../tithes/screens/history_screen.dart';
import '../../auth/providers/auth_provider.dart';

// We change to ConsumerWidget to "consume" the database stream
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. We ask the database for the live stream of members
    final database = ref.watch(databaseProvider);
    final stream = database.watchAllFeligreses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // SYNC BUTTON
          IconButton(
            icon: const Icon(Icons.sync), // Changed icon to 'sync'
            tooltip: 'Sync Data',
            onPressed: () async {
              final database = ref.read(databaseProvider);
              final syncService = SyncService(database);

              // Show "Processing" snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 20),
                      Text('Synchronizing Cloud & Local...'),
                    ],
                  ),
                  duration: Duration(minutes: 1), // Keep it open
                ),
              );

              try {
                // RUN THE FULL SYNC
                await syncService.syncAll();

                if (context.mounted) {
                  // Hide previous snackbar
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  // Show Success
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sync Complete! Data is up to date.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sync Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          // LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- TOP SECTION: BUTTONS ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.church, size: 50, color: Colors.indigo),
                const SizedBox(height: 10),
                // --- FINANCIAL SUMMARY CARD ---
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
                              'Recaudación Total',
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
                    label: const Text('Register Member'),
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
                    label: const Text('Register Tithe/Offering'),
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
              "Recent Members (Local DB)",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          // --- BOTTOM SECTION: THE LIST ---
          Expanded(
            child: StreamBuilder<List<Feligrese>>(
              stream: stream,
              builder: (context, snapshot) {
                // Case 1: Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Case 2: Error
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Case 3: Data received
                final feligreses = snapshot.data ?? [];

                if (feligreses.isEmpty) {
                  return const Center(child: Text('No members yet. Add one!'));
                }

                return ListView.builder(
                  itemCount: feligreses.length,
                  itemBuilder: (context, index) {
                    final person = feligreses[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          person.nombre[0].toUpperCase(),
                        ), // First letter of name
                      ),
                      title: Text(person.nombre),
                      subtitle: Text(person.telefono ?? 'No phone'),
                      trailing: person.syncStatus == 0
                          ? const Icon(
                              Icons.cloud_off,
                              color: Colors.orange,
                            ) // Not synced
                          : const Icon(
                              Icons.cloud_done,
                              color: Colors.green,
                            ), // Synced
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
