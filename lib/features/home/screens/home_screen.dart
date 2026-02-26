import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../providers.dart';
import '../../auth/screens/login_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> _handleSecureLogout() async {
    final database = ref.read(databaseProvider);
    final hasPending = await database.hasPendingSyncs();

    if (hasPending && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(child: Text('Datos sin sincronizar')),
            ],
          ),
          content: const Text(
            'Tienes registros locales que no se han guardado en la nube.\n\nSi cierras sesión ahora, estos datos se eliminarán permanentemente por seguridad.\n\n¿Deseas intentar sincronizar primero o cerrar sesión y perder los datos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar y Sincronizar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cerrar y Perder Datos'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    final authService = ref.read(authServiceProvider);
    try {
      await database.clearAllData();
      await authService.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDesktop = MediaQuery.of(context).size.width > 800;

    final List<Widget> pages = [
      const Center(child: Text('Dashboard Component Will Go Here')), // Phase 3
      const Center(child: Text('Feligreses Component Will Go Here')),
      const Center(child: Text('Aportes Component Will Go Here')),
    ];

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 260,
              color: colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.church,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'DASHBOARD',
                          style: GoogleFonts.montserrat(
                            color: colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 10),
                    child: Text(
                      'MAIN',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  _buildNavItem(
                    0,
                    Icons.grid_view_rounded,
                    'Resumen',
                    colorScheme,
                    isDark,
                  ),
                  _buildNavItem(
                    1,
                    Icons.people_alt_outlined,
                    'Feligreses',
                    colorScheme,
                    isDark,
                  ),
                  _buildNavItem(
                    2,
                    Icons.account_balance_wallet_outlined,
                    'Aportes',
                    colorScheme,
                    isDark,
                  ),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: OutlinedButton.icon(
                      onPressed: _handleSecureLogout,
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 24.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedIndex == 0
                            ? 'SUMMARY'
                            : _selectedIndex == 1
                            ? 'FELIGRESES'
                            : 'APORTES',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 16,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                isDark ? Icons.light_mode : Icons.dark_mode,
                              ),
                              color: isDark
                                  ? Colors.yellow
                                  : colorScheme.primary,
                              onPressed: () {
                                ref
                                    .read(themeModeProvider.notifier)
                                    .toggleTheme();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),

                          CircleAvatar(
                            backgroundColor: colorScheme.primary.withOpacity(
                              0.2,
                            ),
                            child: Icon(
                              Icons.person,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              backgroundColor: colorScheme.surface,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Resumen',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_alt_outlined),
                  label: 'Feligreses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Aportes',
                ),
              ],
            ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String title,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border(left: BorderSide(color: colorScheme.primary, width: 4))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: isSelected ? colorScheme.onSurface : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
