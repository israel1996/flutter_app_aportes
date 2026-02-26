import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/features/members/widgets/add_feligres_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/edit_feligres_sheet.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';

class FeligresesScreen extends ConsumerStatefulWidget {
  const FeligresesScreen({super.key});

  @override
  ConsumerState<FeligresesScreen> createState() => _FeligresesScreenState();
}

class _FeligresesScreenState extends ConsumerState<FeligresesScreen> {
  bool _showDeleted = false;

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,

      floatingActionButton: _showDeleted
          ? null
          : Container(
              // Hide button if in trash view
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF00C9FF), const Color(0xFF92FE9D)]
                      : [colorScheme.primary, colorScheme.secondary],
                ),
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00C9FF).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddFeligresSheet(),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.person_add, color: Colors.white),
              ),
            ),

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showDeleted = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showDeleted
                            ? colorScheme.primary.withOpacity(
                                isDark ? 0.2 : 0.1,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Activos',
                          style: GoogleFonts.poppins(
                            color: !_showDeleted
                                ? colorScheme.primary
                                : Colors.grey,
                            fontWeight: !_showDeleted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showDeleted = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showDeleted
                            ? Colors.redAccent.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Papelera',
                          style: GoogleFonts.poppins(
                            color: _showDeleted
                                ? Colors.redAccent
                                : Colors.grey,
                            fontWeight: _showDeleted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- DYNAMIC LIST ---
          Expanded(
            child: StreamBuilder<List<Feligrese>>(
              stream: database.watchAllFeligreses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                final allMembers = snapshot.data ?? [];
                // FILTER THE LIST BASED ON OUR TOGGLE
                final members = allMembers
                    .where((m) => m.activo == (_showDeleted ? 0 : 1))
                    .toList();

                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showDeleted
                              ? Icons.delete_outline
                              : Icons.people_outline,
                          size: 64,
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showDeleted
                              ? 'La papelera está vacía.'
                              : 'No hay feligreses registrados.',
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
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.3 : 0.05,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                EditFeligresSheet(feligres: member),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _showDeleted
                              ? Colors.redAccent.withOpacity(0.1)
                              : colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: _showDeleted
                                ? Colors.redAccent
                                : colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          member.nombre,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          member.telefono ?? 'Sin teléfono',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                      ),
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
