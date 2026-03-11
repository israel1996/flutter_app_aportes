import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_aportes/core/database/database.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';
import 'package:flutter_app_aportes/features/admin/screens/admin_users_screen.dart';
import 'package:flutter_app_aportes/features/auth/providers/auth_provider.dart';
import 'package:flutter_app_aportes/features/home/screens/dashboard_summary.dart';
import 'package:flutter_app_aportes/features/home/screens/dashboard_secretaria.dart';
import 'package:flutter_app_aportes/features/members/screens/feligreses_screen.dart';
import 'package:flutter_app_aportes/features/members/widgets/add_iglesia_sheet.dart';
import 'package:flutter_app_aportes/features/reports/screens/reports_secretaria.dart';
import 'package:flutter_app_aportes/features/sync/services/sync_service.dart';
import 'package:flutter_app_aportes/features/tithes/screens/aportes_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/screens/force_password_screen.dart';
import '../../reports/screens/reports_screen.dart';

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
  bool _hasPromptedSede = false;
  late AnimationController _syncAnimationController;

  late Stream<List<Iglesia>> _iglesiasStream;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();

    _syncAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    final database = ref.read(databaseProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _iglesiasStream = (database.select(
      database.iglesias,
    )..where((tbl) => tbl.userId.equals(userId))).watch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkIfUserNeedsChurch();
        _checkAndSync();
      }
    });
  }

  Future<void> _checkUserStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final userData = await Supabase.instance.client
          .from('usuarios_app')
          .select('estado')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (userData != null) {
        final estado = userData['estado'];
        if (estado == 'inactivo' ||
            estado == 'bloqueado' ||
            estado == 'pendiente' ||
            estado == 'solicita_reseteo') {
          await Supabase.instance.client.auth.signOut();
        }
      }
    } catch (e) {
      debugPrint("Error verificando estado en vivo: $e");
    }
  }

  @override
  void dispose() {
    _syncAnimationController.dispose();
    super.dispose();
  }

  Future<void> _cargarIglesiaPreferida({required bool offline}) async {
    try {
      final database = ref.read(databaseProvider);
      String? targetId;

      if (offline) {
        final prefs = await SharedPreferences.getInstance();
        targetId = prefs.getString('ultima_iglesia_id_local');
      } else {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final userData = await Supabase.instance.client
              .from('usuarios_app')
              .select('ultima_iglesia_id')
              .eq('id', user.id)
              .maybeSingle();

          if (userData != null && userData['ultima_iglesia_id'] != null) {
            targetId = userData['ultima_iglesia_id'].toString();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ultima_iglesia_id_local', targetId);
          }
        }
      }

      if (!mounted) return;

      if (targetId != null) {
        final savedChurch = await (database.select(
          database.iglesias,
        )..where((tbl) => tbl.id.equals(targetId!))).getSingleOrNull();

        if (!mounted) return;

        if (savedChurch != null) {
          ref.read(currentIglesiaProvider.notifier).state = savedChurch;
          return;
        }
      }

      if (ref.read(currentIglesiaProvider) == null && mounted) {
        final user = Supabase.instance.client.auth.currentUser;
        final firstChurch =
            await (database.select(database.iglesias)
                  ..where((tbl) => tbl.userId.equals(user?.id ?? ''))
                  ..limit(1))
                .getSingleOrNull();

        if (!mounted) return;

        if (firstChurch != null) {
          ref.read(currentIglesiaProvider.notifier).state = firstChurch;
        }
      }
    } catch (e) {
      debugPrint('Error loading church preference: $e');
    }
  }

  Future<void> _checkIfUserNeedsChurch() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final database = ref.read(databaseProvider);

      final localChurches = await (database.select(
        database.iglesias,
      )..where((tbl) => tbl.userId.equals(user.id))).get();

      if (localChurches.isNotEmpty) return;

      final response = await supabase
          .from('iglesias')
          .select('id')
          .eq('user_id', user.id)
          .isFilter('is_deleted', false)
          .limit(1);

      if (!mounted) return;

      if (response.isEmpty) {
        if (!_hasPromptedSede) {
          _hasPromptedSede = true;
          showModalBottomSheet(
            context: context,
            isDismissible: false,
            enableDrag: false,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddIglesiaSheet(),
          ).then((_) => _hasPromptedSede = false);
        }
      }
    } catch (e) {
      debugPrint('Error verifying cloud churches: $e');
    }
  }

  Future<void> _checkAndSync() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    _syncAnimationController.repeat();

    try {
      await _cargarIglesiaPreferida(offline: true);
      if (!mounted) return;

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

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final database = ref.read(databaseProvider);
      final syncService = SyncService(database);

      await syncService.syncAll();
      if (!mounted) return;

      await _cargarIglesiaPreferida(offline: false);
      if (!mounted) return;

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

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_sync_time');
      await prefs.remove('ultima_iglesia_id_local');

      await database.delete(database.aportes).go();
      await database.delete(database.feligreses).go();
      await database.delete(database.iglesias).go();

      if (mounted) ref.read(currentIglesiaProvider.notifier).state = null;

      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRoleAsync = ref.watch(userRoleProvider);
    final currentEnv = ref.watch(environmentProvider);
    final isFinance = currentEnv == AppEnvironment.finanzas;

    final selectedIndex = ref.watch(navIndexProvider);
    final currentIglesia = ref.watch(currentIglesiaProvider);

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

        final List<Widget> pages = isFinance
            ? [
                const DashboardSummary(),
                const AportesScreen(),
                const ReportesScreen(),
                if (isSuperAdmin) const AdminUsersScreen(),
              ]
            : [
                const DashboardSecretaria(),
                const FeligresesScreen(),
                const ReportesSecretariaScreen(),
                if (isSuperAdmin) const AdminUsersScreen(),
              ];

        if (selectedIndex >= pages.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ref.read(navIndexProvider.notifier).state = 0;
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
                        padding: const EdgeInsets.only(left: 24, bottom: 5),
                        child: Text(
                          'SEDE ACTUAL',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _buildSidebarIglesiaSelector(colorScheme, isDark),
                      const SizedBox(height: 20),

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
                        Icons.analytics,
                        'Reportes',
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
                                const SizedBox(width: 16),
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

                    if (!isDesktop)
                      _buildMobileIglesiaSelector(colorScheme, isDark),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: currentIglesia == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.church_outlined,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Bienvenido al Sistema.\nPara comenzar a trabajar, debe registrar una Sede.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          isDismissible: false,
                                          enableDrag: false,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) =>
                                              const AddIglesiaSheet(),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                      icon: const Icon(Icons.add),
                                      label: Text(
                                        'Registrar Primera Sede',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            // --- OPTIMIZACIÓN 1: INDEXED STACK ---
                            : IndexedStack(
                                index: selectedIndex < pages.length
                                    ? selectedIndex
                                    : 0,
                                children: pages,
                              ),
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
                      icon: Icon(Icons.analytics),
                      label: 'Reportes',
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
          return 'REPORTES';
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
          return 'REPORTES';
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
        // --- OPTIMIZACIÓN 2: REPAINT BOUNDARY ---
        RepaintBoundary(
          child: Container(
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

  Widget _buildMobileIglesiaSelector(ColorScheme colorScheme, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final currentIglesia = ref.watch(currentIglesiaProvider);

        return StreamBuilder<List<Iglesia>>(
          stream: _iglesiasStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SizedBox(height: 56);
            }

            final iglesias = snapshot.data ?? [];
            Iglesia? validDropdownValue;

            if (iglesias.isEmpty) {
              return const SizedBox.shrink();
            }

            if (currentIglesia != null &&
                iglesias.any((i) => i.id == currentIglesia.id)) {
              validDropdownValue = iglesias.firstWhere(
                (i) => i.id == currentIglesia.id,
              );
            } else {
              validDropdownValue = iglesias.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted)
                  ref.read(currentIglesiaProvider.notifier).state =
                      iglesias.first;
              });
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  Icon(Icons.church, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Iglesia>(
                        value: validDropdownValue,
                        isExpanded: true,
                        hint: Text(
                          'Seleccione Sede',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                        icon: const Icon(Icons.arrow_drop_down),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        items: iglesias.map((iglesia) {
                          return DropdownMenuItem(
                            value: iglesia,
                            child: Text(
                              '${iglesia.nombre} (D${iglesia.distrito})',
                            ),
                          );
                        }).toList(),
                        onChanged: (Iglesia? nueva) async {
                          if (nueva == null) return;
                          ref.read(currentIglesiaProvider.notifier).state =
                              nueva;

                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                              'ultima_iglesia_id_local',
                              nueva.id,
                            );

                            final userId =
                                Supabase.instance.client.auth.currentUser?.id ??
                                '';
                            await Supabase.instance.client
                                .from('usuarios_app')
                                .update({'ultima_iglesia_id': nueva.id})
                                .eq('id', userId);
                          } catch (e) {
                            debugPrint('Error saving mobile preference: $e');
                          }
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: Colors.green,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 35),
                    tooltip: 'Registrar Nueva Sede',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddIglesiaSheet(),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      if (validDropdownValue != null) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddIglesiaSheet(
                            iglesiaParaEditar: validDropdownValue,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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
        ref.read(navIndexProvider.notifier).state = 0;
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

  Widget _buildSidebarIglesiaSelector(ColorScheme colorScheme, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final currentIglesia = ref.watch(currentIglesiaProvider);

        return StreamBuilder<List<Iglesia>>(
          stream: _iglesiasStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SizedBox(height: 56);
            }

            final iglesias = snapshot.data ?? [];
            Iglesia? validDropdownValue;

            if (iglesias.isEmpty) {
              return const SizedBox.shrink();
            }

            if (currentIglesia != null &&
                iglesias.any((i) => i.id == currentIglesia.id)) {
              validDropdownValue = iglesias.firstWhere(
                (i) => i.id == currentIglesia.id,
              );
            } else {
              validDropdownValue = iglesias.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted)
                  ref.read(currentIglesiaProvider.notifier).state =
                      iglesias.first;
              });
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.church, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Iglesia>(
                          value: validDropdownValue,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          isExpanded: true,
                          dropdownColor: colorScheme.surface,
                          hint: Text(
                            'Seleccione Sede',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          items: iglesias.map((iglesia) {
                            return DropdownMenuItem(
                              value: iglesia,
                              child: Text(
                                iglesia.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (Iglesia? nueva) async {
                            if (nueva == null) return;
                            ref.read(currentIglesiaProvider.notifier).state =
                                nueva;

                            try {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                'ultima_iglesia_id_local',
                                nueva.id,
                              );

                              final userId =
                                  Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser
                                      ?.id ??
                                  '';
                              await Supabase.instance.client
                                  .from('usuarios_app')
                                  .update({'ultima_iglesia_id': nueva.id})
                                  .eq('id', userId);
                            } catch (e) {
                              debugPrint('Error saving desktop preference: $e');
                            }
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: Colors.green,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 35),
                      tooltip: 'Registrar Nueva Sede',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const AddIglesiaSheet(),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        size: 18,
                        color: Colors.grey,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Administrar Sede',
                      onPressed: () {
                        if (validDropdownValue != null) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AddIglesiaSheet(
                              iglesiaParaEditar: validDropdownValue,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
