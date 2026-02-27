import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_app_aportes/features/admin/screens/admin_users_screen.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
import 'package:flutter_app_aportes/features/home/screens/dashboard_summary.dart';
import 'package:flutter_app_aportes/features/members/screens/feligreses_screen.dart';
import 'package:flutter_app_aportes/features/sync/services/sync_service.dart';
import 'package:flutter_app_aportes/features/tithes/screens/aportes_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../export/screens/export_screen.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../providers.dart';
import '../../auth/screens/login_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSyncing = false;

  late AnimationController _syncAnimationController;

  @override
  void initState() {
    super.initState();
    _syncAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSync();
    });
  }

  @override
  void dispose() {
    _syncAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkAndSync() async {
    setState(() => _isSyncing = true);
    _syncAnimationController.repeat();

    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet =
          connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);

      if (!hasInternet) {
        if (mounted) {
          CustomSnackBar.showWarning(
            context,
            'Modo Offline: Sin conexión a Internet',
          );
        }
        return;
      }

      final authService = ref.read(authServiceProvider);
      if (authService.currentUser == null) return;

      debugPrint("🚀 Home cargado: Verificando datos pendientes...");

      final database = ref.read(databaseProvider);
      final syncService = SyncService(database);

      await syncService.syncAll();
      debugPrint("✅ Sincronización completa.");

      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Datos sincronizados con la nube');
      }
    } catch (e) {
      debugPrint("❌ Error de sincronización: $e");
      if (mounted) {
        CustomSnackBar.showError(context, 'Error al sincronizar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _syncAnimationController.stop();
      }
    }
  }

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
    final userRoleAsync = ref.watch(userRoleProvider);

    return userRoleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      ),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error cargando rol: $error'))),
      data: (role) {
        final isSuperAdmin = role == 'superadmin';

        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isDesktop = MediaQuery.of(context).size.width > 800;

        final List<Widget> pages = [
          const DashboardSummary(),
          const FeligresesScreen(),
          const AportesScreen(),
          const ExportScreen(),
          if (isSuperAdmin) const AdminUsersScreen(),
        ];

        if (_selectedIndex >= pages.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _selectedIndex = 0);
          });
        }

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
                      _buildNavItem(
                        3,
                        Icons.file_download_outlined,
                        'Exportar',
                        colorScheme,
                        isDark,
                      ),

                      // 2. Conditionally add the 5th sidebar item
                      if (isSuperAdmin)
                        _buildNavItem(
                          4,
                          Icons.admin_panel_settings,
                          'Usuarios',
                          colorScheme,
                          isDark,
                        ),

                      const Spacer(),

                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: OutlinedButton.icon(
                          onPressed: _handleSecureLogout,
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
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
                          // 3. Dynamic Title Updates
                          Text(
                            _selectedIndex == 0
                                ? 'RESUMEN'
                                : _selectedIndex == 1
                                ? 'FELIGRESES'
                                : _selectedIndex == 2
                                ? 'APORTES'
                                : _selectedIndex == 3
                                ? 'EXPORTAR'
                                : _selectedIndex == 4
                                ? 'PANEL DE APROBACIÓN'
                                : '',
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
                                margin: const EdgeInsets.only(right: 16),
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
                                  icon: RotationTransition(
                                    turns: _syncAnimationController,
                                    child: Icon(
                                      Icons.sync,
                                      // Glows Cyan when syncing, normal color when idle
                                      color: _isSyncing
                                          ? const Color(0xFF00C9FF)
                                          : colorScheme.primary,
                                    ),
                                  ),
                                  // The fix: We pass a function instead of 'null' to prevent the grey box
                                  onPressed: () {
                                    if (!_isSyncing) {
                                      _checkAndSync();
                                    }
                                  },
                                ),
                              ),

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
                                        .state = isDark
                                        ? ThemeMode.light
                                        : ThemeMode.dark;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),

                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'logout') {
                                    _handleSecureLogout();
                                  }
                                },
                                color: colorScheme.surface,
                                offset: const Offset(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.redAccent.withOpacity(0.2)
                                        : Colors.black.withOpacity(0.05),
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: colorScheme.primary
                                      .withOpacity(0.2),
                                  child: Icon(
                                    Icons.person,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.logout,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Cerrar Sesión',
                                          style: GoogleFonts.poppins(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        // Safe index lookup
                        child: _selectedIndex < pages.length
                            ? pages[_selectedIndex]
                            : pages[0],
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
                  selectedIndex: _selectedIndex < pages.length
                      ? _selectedIndex
                      : 0,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded),
                      label: 'Resumen',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.people_alt_outlined),
                      label: 'Feligreses',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      label: 'Aportes',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.file_download_outlined),
                      label: 'Exportar',
                    ),
                    // 4. Conditionally add the 5th mobile navigation item
                    if (isSuperAdmin)
                      const NavigationDestination(
                        icon: Icon(Icons.admin_panel_settings),
                        label: 'Usuarios',
                      ),
                  ],
                ),
        );
      },
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
