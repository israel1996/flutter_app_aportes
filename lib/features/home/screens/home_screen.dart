import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_app_aportes/features/admin/screens/admin_users_screen.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
import 'package:flutter_app_aportes/features/home/screens/dashboard_summary.dart';
import 'package:flutter_app_aportes/features/home/screens/dashboard_secretaria.dart';
import 'package:flutter_app_aportes/features/members/screens/feligreses_screen.dart';
import 'package:flutter_app_aportes/features/sync/services/sync_service.dart';
import 'package:flutter_app_aportes/features/tithes/screens/aportes_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../export/screens/export_screen.dart';
import '../../auth/screens/force_password_screen.dart';

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
        if (mounted)
          CustomSnackBar.showWarning(
            context,
            'Modo Offline: Sin conexión a Internet',
          );
        return;
      }

      final authService = ref.read(authServiceProvider);
      if (authService.currentUser == null) return;

      final database = ref.read(databaseProvider);
      final syncService = SyncService(database);

      await syncService.syncAll();

      if (mounted)
        CustomSnackBar.showSuccess(context, 'Datos sincronizados con la nube');
    } catch (e) {
      if (mounted)
        CustomSnackBar.showError(context, 'Error al sincronizar: $e');
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
    } catch (e) {}

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
    final currentEnv = ref.watch(environmentProvider);
    final isFinance = currentEnv == AppEnvironment.finanzas;

    // --- ESTADO GLOBAL DE NAVEGACIÓN ---
    final selectedIndex = ref.watch(navIndexProvider);

    return userRoleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      ),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error cargando rol: $error'))),
      data: (role) {
        if (role == 'requiere_cambio_clave') return const ForcePasswordScreen();

        final isSuperAdmin = role == 'superadmin';
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isDesktop = MediaQuery.of(context).size.width > 800;

        // --- PÁGINAS AISLADAS POR ENTORNO ---
        final List<Widget> pages = isFinance
            ? [
                const DashboardSummary(), // 0
                const AportesScreen(), // 1 (Reemplazó a Feligreses)
                const ExportScreen(), // 2
                if (isSuperAdmin) const AdminUsersScreen(), // 3
              ]
            : [
                const DashboardSecretaria(), // 0
                const FeligresesScreen(), // 1 (Exclusivo de Secretaría)
                const ExportScreen(), // 2
                if (isSuperAdmin) const AdminUsersScreen(), // 3
              ];

        // Protección contra desbordamiento de índice al cambiar de entorno
        if (selectedIndex >= pages.length) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => ref.read(navIndexProvider.notifier).state = 0,
          );
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
                              isFinance
                                  ? Icons.account_balance
                                  : Icons.analytics_outlined,
                              color: colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isFinance ? 'FINANZAS' : 'SECRETARÍA',
                              style: GoogleFonts.montserrat(
                                color: colorScheme.onSurface,
                                fontSize: 18,
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

                      // --- MENÚ LATERAL DINÁMICO ---
                      _buildNavItem(
                        0,
                        Icons.grid_view_rounded,
                        'Resumen',
                        colorScheme,
                        isDark,
                        selectedIndex,
                      ),
                      if (!isFinance)
                        _buildNavItem(
                          1,
                          Icons.people_alt_outlined,
                          'Feligreses',
                          colorScheme,
                          isDark,
                          selectedIndex,
                        ),
                      if (isFinance)
                        _buildNavItem(
                          1,
                          Icons.account_balance_wallet_outlined,
                          'Aportes',
                          colorScheme,
                          isDark,
                          selectedIndex,
                        ),
                      _buildNavItem(
                        2,
                        Icons.file_download_outlined,
                        'Exportar',
                        colorScheme,
                        isDark,
                        selectedIndex,
                      ),
                      if (isSuperAdmin)
                        _buildNavItem(
                          3,
                          Icons.admin_panel_settings,
                          'Usuarios',
                          colorScheme,
                          isDark,
                          selectedIndex,
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
                      child: isDesktop
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getPageTitle(isFinance, selectedIndex),
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: _buildEnvironmentSwitcher(
                                      currentEnv,
                                      colorScheme,
                                      isDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: _buildActionButtons(
                                    colorScheme,
                                    isDark,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _getPageTitle(isFinance, selectedIndex),
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey,
                                          fontSize: 16,
                                          letterSpacing: 1.2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: _buildActionButtons(
                                        colorScheme,
                                        isDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: _buildEnvironmentSwitcher(
                                      currentEnv,
                                      colorScheme,
                                      isDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: selectedIndex < pages.length
                            ? pages[selectedIndex]
                            : pages[0],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --- BARRA INFERIOR (MÓVIL) DINÁMICA ---
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  backgroundColor: colorScheme.surface,
                  selectedIndex: selectedIndex < pages.length
                      ? selectedIndex
                      : 0,
                  onDestinationSelected: (index) =>
                      ref.read(navIndexProvider.notifier).state = index,
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded),
                      label: 'Resumen',
                    ),
                    if (!isFinance)
                      const NavigationDestination(
                        icon: Icon(Icons.people_alt_outlined),
                        label: 'Feligreses',
                      ),
                    if (isFinance)
                      const NavigationDestination(
                        icon: Icon(Icons.account_balance_wallet_outlined),
                        label: 'Aportes',
                      ),
                    const NavigationDestination(
                      icon: Icon(Icons.file_download_outlined),
                      label: 'Exportar',
                    ),
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

  String _getPageTitle(bool isFinance, int index) {
    if (isFinance) {
      switch (index) {
        case 0:
          return 'RESUMEN FINANCIERO';
        case 1:
          return 'APORTES';
        case 2:
          return 'EXPORTAR';
        case 3:
          return 'PANEL DE APROBACIÓN';
        default:
          return '';
      }
    } else {
      switch (index) {
        case 0:
          return 'RESUMEN DEMOGRÁFICO';
        case 1:
          return 'FELIGRESES';
        case 2:
          return 'EXPORTAR';
        case 3:
          return 'PANEL DE APROBACIÓN';
        default:
          return '';
      }
    }
  }

  Widget _buildActionButtons(ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            icon: RotationTransition(
              turns: _syncAnimationController,
              child: Icon(
                Icons.sync,
                color: _isSyncing
                    ? const Color(0xFF00C9FF)
                    : colorScheme.primary,
              ),
            ),
            onPressed: () {
              if (!_isSyncing) _checkAndSync();
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            color: isDark ? Colors.yellow : colorScheme.primary,
            onPressed: () => ref.read(themeModeProvider.notifier).state = isDark
                ? ThemeMode.light
                : ThemeMode.dark,
          ),
        ),
        const SizedBox(width: 16),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') _handleSecureLogout();
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
            backgroundColor: colorScheme.primary.withOpacity(0.2),
            child: Icon(Icons.person, color: colorScheme.primary),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.redAccent, size: 20),
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
    );
  }

  Widget _buildEnvironmentSwitcher(
    AppEnvironment currentEnv,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            'FINANZAS',
            Icons.attach_money,
            AppEnvironment.finanzas,
            currentEnv,
            colorScheme,
          ),
          _buildToggleOption(
            'SECRETARÍA',
            Icons.analytics_outlined,
            AppEnvironment.secretaria,
            currentEnv,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    IconData icon,
    AppEnvironment target,
    AppEnvironment current,
    ColorScheme colorScheme,
  ) {
    final isSelected = target == current;
    return GestureDetector(
      onTap: () {
        ref.read(environmentProvider.notifier).state = target;
        ref.read(navIndexProvider.notifier).state =
            0; // Regresa al dashboard al cambiar
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String title,
    ColorScheme colorScheme,
    bool isDark,
    int selectedIndex,
  ) {
    bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => ref.read(navIndexProvider.notifier).state = index,
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
