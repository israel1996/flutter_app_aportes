import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class AportesScreen extends ConsumerWidget {
  const AportesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Allows the main Dashboard color to show through
      // NEON GRADIENT FLOATING BUTTON
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF89216B),
                    const Color(0xFFDA4453),
                  ] // Pink/Purple Neon
                : [colorScheme.secondary, Colors.redAccent],
          ),
          shape: BoxShape.circle,
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFFDA4453).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: FloatingActionButton(
          onPressed: () {
            // TODO: Open contribution registration form
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_card, color: Colors.white),
        ),
      ),

      // DYNAMIC LIST
      body: StreamBuilder<List<AporteConFeligres>>(
        stream: database.watchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final aportesList = snapshot.data ?? [];

          if (aportesList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: colorScheme.secondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay aportes registrados.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: aportesList.length,
            itemBuilder: (context, index) {
              final item = aportesList[index];
              final aporte = item.aporte;
              final feligres = item.feligres;

              // Format the date nicely
              final formattedDate = DateFormat(
                'dd MMM yyyy, hh:mm a',
                'es',
              ).format(aporte.fecha);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.monetization_on,
                      color: colorScheme.secondary,
                    ),
                  ),
                  title: Text(
                    feligres.nombre,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aporte.tipo,
                          style: GoogleFonts.poppins(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    '\$${aporte.monto.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark
                          ? const Color(0xFF92FE9D)
                          : Colors.green.shade700, // Neon green in dark mode
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
