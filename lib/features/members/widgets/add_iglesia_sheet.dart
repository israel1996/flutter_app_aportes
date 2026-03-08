import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app_aportes/core/utils/custom_snackbar.dart';

import '../../../core/database/database.dart';
import '../../../providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sync/services/sync_service.dart';

class AddIglesiaSheet extends ConsumerStatefulWidget {
  final Iglesia? iglesiaParaEditar; // Parameter to know if we are editing

  const AddIglesiaSheet({super.key, this.iglesiaParaEditar});

  @override
  ConsumerState<AddIglesiaSheet> createState() => _AddIglesiaSheetState();
}

class _AddIglesiaSheetState extends ConsumerState<AddIglesiaSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;

  int? _distritoSeleccionado;
  String? _categoriaSeleccionada;
  DateTime? _fechaLlegada;
  DateTime? _fechaSalida;
  bool _isSaving = false;

  final List<int> _distritos = List.generate(16, (i) => i + 1);
  final List<String> _categorias = [
    'Misionera',
    'En formación',
    'Formada',
    'Consolidada',
    'Emblemática',
  ];

  @override
  void initState() {
    super.initState();
    // If we are editing, preload the data
    _nombreController = TextEditingController(
      text: widget.iglesiaParaEditar?.nombre ?? '',
    );
    _distritoSeleccionado = widget.iglesiaParaEditar?.distrito;
    _categoriaSeleccionada = widget.iglesiaParaEditar?.categoria;
    _fechaLlegada = widget.iglesiaParaEditar?.fechaLlegada;
    _fechaSalida = widget.iglesiaParaEditar?.fechaSalida;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  void _guardarIglesia() async {
    if (_formKey.currentState!.validate()) {
      if (_distritoSeleccionado == null) {
        CustomSnackBar.showWarning(context, 'Por favor selecciona un distrito');
        return;
      }

      setState(() => _isSaving = true);

      // Capture the navigator BEFORE async operations
      final navigator = Navigator.of(context);

      final database = ref.read(databaseProvider);
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUser?.id ?? '';

      try {
        if (widget.iglesiaParaEditar == null) {
          // MODE: CREATE NEW
          final nuevaIglesia = IglesiasCompanion.insert(
            id: const Uuid().v4(),
            userId: userId,
            nombre: _nombreController.text.trim(),
            distrito: _distritoSeleccionado!,
            categoria: drift.Value(_categoriaSeleccionada),
            fechaLlegada: drift.Value(_fechaLlegada),
            fechaSalida: drift.Value(_fechaSalida),
            syncStatus: const drift.Value(0), // Mark for cloud sync
          );
          await database.into(database.iglesias).insert(nuevaIglesia);
          ref.read(currentIglesiaProvider.notifier).state =
              nuevaIglesia as Iglesia?;
        } else {
          // MODE: EDIT EXISTING
          await database
              .update(database.iglesias)
              .replace(
                widget.iglesiaParaEditar!.copyWith(
                  nombre: _nombreController.text.trim(),
                  distrito: _distritoSeleccionado!,
                  categoria: drift.Value(_categoriaSeleccionada),
                  fechaLlegada: drift.Value(_fechaLlegada),
                  fechaSalida: drift.Value(_fechaSalida),
                  syncStatus: 0, // Mark for sync again
                ),
              );
        }

        // Attempt background sync (without stopping the flow)
        final syncService = SyncService(database);
        syncService.syncAll().catchError(
          (e) => debugPrint("Background sync failed: $e"),
        );

        // Close window using the safe variable
        navigator.pop();
        CustomSnackBar.showSuccess(
          context,
          widget.iglesiaParaEditar == null
              ? 'Sede registrada correctamente'
              : 'Sede actualizada correctamente',
        );
      } catch (e) {
        CustomSnackBar.showError(context, 'Error al guardar: $e');
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _seleccionarFecha(bool isLlegada) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2050),
    );
    if (date != null) {
      setState(() {
        if (isLlegada)
          _fechaLlegada = date;
        else
          _fechaSalida = date;
      });
    }
  }

  Future<void> _eliminarIglesia() async {
    if (widget.iglesiaParaEditar == null) return;

    final database = ref.read(databaseProvider);

    // 1. SAFEGUARD: Check if there are linked parishioners
    final feligresesVinculados =
        await (database.select(database.feligreses)..where(
              (tbl) => tbl.iglesiaId.equals(widget.iglesiaParaEditar!.id),
            ))
            .get();

    if (feligresesVinculados.isNotEmpty) {
      if (mounted) {
        CustomSnackBar.showWarning(
          context,
          'No se puede eliminar. Hay ${feligresesVinculados.length} feligrés(es) vinculado(s) a esta sede. Transfiérelos o elimínalos primero.',
        );
      }
      return;
    }

    // 2. CONFIRMATION DIALOG
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Sede?'),
        content: const Text(
          'Esta acción eliminará la iglesia de forma permanente. ¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      // 1. Check internet connection
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet =
          connectivity.contains(ConnectivityResult.mobile) ||
          connectivity.contains(ConnectivityResult.wifi) ||
          connectivity.contains(ConnectivityResult.ethernet);

      if (!hasInternet) {
        throw Exception(
          'Se requiere conexión a internet para eliminar una Sede.',
        );
      }

      // 2. DELTA SYNC FLAG: Soft delete from Supabase FIRST
      final supabase = Supabase.instance.client;
      await supabase
          .from('iglesias')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', widget.iglesiaParaEditar!.id);

      // 3. Hard delete from local SQLite
      await (database.delete(
        database.iglesias,
      )..where((tbl) => tbl.id.equals(widget.iglesiaParaEditar!.id))).go();

      // 4. If the user deleted the church they currently had selected, reset the state
      final currentSelected = ref.read(currentIglesiaProvider);
      if (currentSelected?.id == widget.iglesiaParaEditar!.id) {
        ref.read(currentIglesiaProvider.notifier).state = null;
      }

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showWarning(context, 'Sede eliminada permanentemente');
      }

      // 5. Trigger background sync
      Future.microtask(() {
        final authService = ref.read(authServiceProvider);
        if (authService.currentUser != null) {
          SyncService(
            database,
          ).syncAll().catchError((e) => debugPrint("Sync error: $e"));
        }
      });
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, 'Error al eliminar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.iglesiaParaEditar == null
                          ? 'Registrar Sede (Iglesia)'
                          : 'Editar Sede',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.iglesiaParaEditar !=
                        null) // Close button only if not mandatory
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name (Required)
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la Iglesia *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.church),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'El nombre es requerido'
                      : null,
                ),
                const SizedBox(height: 24),

                // Aesthetic District Selector (Wrap with Chips)
                Text(
                  'Distrito Asignado *',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _distritos.map((distrito) {
                      final isSelected = _distritoSeleccionado == distrito;
                      return ChoiceChip(
                        label: Text('$distrito'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _distritoSeleccionado = distrito);
                        },
                        selectedColor: colorScheme.primary,
                        backgroundColor: isDark
                            ? Colors.black12
                            : Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.all(8),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Category (Optional)
                DropdownButtonFormField<String>(
                  value: _categoriaSeleccionada,
                  decoration: InputDecoration(
                    labelText: 'Categoría (Opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: _categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _categoriaSeleccionada = val),
                ),
                const SizedBox(height: 16),

                // Dates (Optional)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _seleccionarFecha(true),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _fechaLlegada == null
                              ? 'F. Llegada'
                              : DateFormat('dd MMM yy').format(_fechaLlegada!),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _seleccionarFecha(false),
                        icon: const Icon(Icons.event_busy, size: 16),
                        label: Text(
                          _fechaSalida == null
                              ? 'F. Salida'
                              : DateFormat('dd MMM yy').format(_fechaSalida!),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving ? null : _guardarIglesia,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.iglesiaParaEditar == null
                                ? 'GUARDAR IGLESIA'
                                : 'ACTUALIZAR IGLESIA',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                if (widget.iglesiaParaEditar != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _isSaving ? null : _eliminarIglesia,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      label: Text(
                        'Eliminar Sede',
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
