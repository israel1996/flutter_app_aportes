import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date and money formatting
import '../../../providers.dart';
import '../../../core/database/database.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Aportes')),
      body: StreamBuilder<List<AporteConFeligres>>(
        stream: database.watchHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!;

          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  Text('No hay transacciones registradas.'),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: transactions.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (context, index) {
              final item = transactions[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.aporte.tipo == 'Diezmo'
                      ? Colors.blue[100]
                      : Colors.green[100],
                  child: Icon(
                    item.aporte.tipo == 'Diezmo'
                        ? Icons.star
                        : Icons.volunteer_activism,
                    color: Colors.black54,
                  ),
                ),
                title: Text(
                  item.feligres.nombre, // We can see the name now!
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${item.aporte.tipo} • ${dateFormat.format(item.aporte.fecha)}",
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(item.aporte.monto),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    // Small icon to show sync status
                    Icon(
                      item.aporte.syncStatus == 0
                          ? Icons.cloud_off
                          : Icons.cloud_done,
                      size: 14,
                      color: item.aporte.syncStatus == 0
                          ? Colors.orange
                          : Colors.blue,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
