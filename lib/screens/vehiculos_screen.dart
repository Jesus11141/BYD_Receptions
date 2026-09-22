import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/vehiculo.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';

class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  List<Vehiculo> _vehiculos = [];
  bool _cargando = false;
  String _filtroUbicacion = 'Todos';
  String _filtroTexto = '';
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime _fechaSeleccionada = DateTime.now();

  bool get _esHoy {
    final now = DateTime.now();
    return _fechaSeleccionada.year == now.year &&
        _fechaSeleccionada.month == now.month &&
        _fechaSeleccionada.day == now.day;
  }

  static const List<String> _ubicaciones = ['Showroom', 'Test Drive', 'Terraza'];
  static const List<String> _modelosSugeridos = [
    'BYD Dolphin Mini',
    'BYD Dolphin',
    'BYD Yuan Plus',
    'BYD Seal',
    'BYD Song Plus DM-i',
    'BYD Shark',
    'BYD Han',
    'BYD Tang',
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final list = await SupabaseService.getVehiculosPorFecha(_fechaSeleccionada);
      if (mounted) {
        setState(() {
          _vehiculos = list;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar vehículos: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  List<Vehiculo> get _vehiculosFiltrados {
    return _vehiculos.where((v) {
      final cumpleUbicacion = _filtroUbicacion == 'Todos' || v.ubicacion == _filtroUbicacion;
      if (!cumpleUbicacion) return false;

      if (_filtroTexto.trim().isEmpty) return true;
      final query = _filtroTexto.toLowerCase();
      final modelo = v.modelo.toLowerCase();
      final chasis = v.chasis.toLowerCase();
      final placa = (v.placa ?? '').toLowerCase();
      final color = v.color.toLowerCase();

      return modelo.contains(query) ||
          chasis.contains(query) ||
          placa.contains(query) ||
          color.contains(query);
    }).toList();
  }

  Color _getColorUbicacion(String ubicacion) {
    switch (ubicacion) {
      case 'Showroom':
        return const Color(0xFF059669); // Esmeralda
      case 'Test Drive':
        return const Color(0xFF0284C7); // Azul eléctrico
      case 'Terraza':
        return const Color(0xFFD97706); // Ámbar cálido
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getBgColorUbicacion(String ubicacion) {
    switch (ubicacion) {
      case 'Showroom':
        return const Color(0xFFECFDF5);
      case 'Test Drive':
        return const Color(0xFFF0F9FF);
      case 'Terraza':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  IconData _getIconUbicacion(String ubicacion) {
    switch (ubicacion) {
      case 'Showroom':
        return Icons.storefront_outlined;
      case 'Test Drive':
        return Icons.electric_car_outlined;
      case 'Terraza':
        return Icons.roofing_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  Future<void> _generarPdf() async {
    if (_vehiculos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay vehículos para generar el reporte.')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Generando reporte PDF de vehículos...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Si hay filtro activo, preguntamos o generamos todos
      await PdfService.generarReporteVehiculos(_vehiculos, fecha: _fechaSeleccionada);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // Actualización rápida de kilometraje, ubicación y novedades (5 segundos)
  Future<void> _mostrarModalActualizacionRapida(Vehiculo vehiculo) async {
    final kmCtrl = TextEditingController(text: vehiculo.kilometraje.toString());
    final novCtrl = TextEditingController(text: vehiculo.novedades ?? '');
    String ubicacionSeleccionada = vehiculo.ubicacion;

    final actualizado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed, color: Color(0xFF0284C7), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehiculo.modelo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'VIN: ${vehiculo.chasis}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Text(
                  'Ubicación Actual:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ubicaciones.map((ub) {
                    final isSelected = ubicacionSeleccionada == ub;
                    final color = _getColorUbicacion(ub);
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconUbicacion(ub),
                            size: 16,
                            color: isSelected ? Colors.white : color,
                          ),
                          const SizedBox(width: 6),
                          Text(ub),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? color : const Color(0xFFCBD5E1),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() => ubicacionSeleccionada = ub);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: kmCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Kilometraje Actual (km)',
                    hintText: 'Ej. 1250',
                    prefixIcon: const Icon(Icons.speed, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: novCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Novedades / Observaciones',
                    hintText: 'Ej. Lavado pendiente, en óptimas condiciones, etc.',
                    prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );

    if (actualizado == true) {
      final nuevoKm = int.tryParse(kmCtrl.text.trim()) ?? vehiculo.kilometraje;
      final nuevasNovedades = novCtrl.text.trim();

      try {
        await SupabaseService.updateEstadoVehiculo(
          id: vehiculo.id ?? vehiculo.chasis,
          chasis: vehiculo.chasis,
          modelo: vehiculo.modelo,
          color: vehiculo.color,
          placa: vehiculo.placa,
          kilometraje: nuevoKm,
          ubicacion: ubicacionSeleccionada,
          novedades: nuevasNovedades,
          fecha: _fechaSeleccionada,
        );
        _cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _esHoy
                    ? 'Estado de vehículo actualizado correctamente.'
                    : 'Registro histórico actualizado para el ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}.',
              ),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  // Registrar un nuevo vehículo (solo cuando llega un carro nuevo)
  Future<void> _mostrarModalNuevoVehiculo({Vehiculo? vehiculoEditar}) async {
    final esEdicion = vehiculoEditar != null;
    final modeloCtrl = TextEditingController(text: vehiculoEditar?.modelo ?? '');
    final colorCtrl = TextEditingController(text: vehiculoEditar?.color ?? '');
    final chasisCtrl = TextEditingController(text: vehiculoEditar?.chasis ?? '');
    final placaCtrl = TextEditingController(text: vehiculoEditar?.placa ?? '');
    final kmCtrl = TextEditingController(
      text: vehiculoEditar != null ? vehiculoEditar.kilometraje.toString() : '0',
    );
    final novCtrl = TextEditingController(text: vehiculoEditar?.novedades ?? '');
    String ubicacion = vehiculoEditar?.ubicacion ?? 'Showroom';

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  esEdicion ? Icons.edit_note : Icons.directions_car_filled,
                  color: const Color(0xFF0284C7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                esEdicion ? 'Editar Datos del Vehículo' : 'Registrar Nuevo Vehículo',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  // Modelo sugerido o libre
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: modeloCtrl.text),
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _modelosSugeridos;
                      }
                      return _modelosSugeridos.where((option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (selection) {
                      modeloCtrl.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      controller.addListener(() {
                        modeloCtrl.text = controller.text;
                      });
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Modelo *',
                          hintText: 'Ej. BYD Yuan Plus',
                          prefixIcon: const Icon(Icons.directions_car_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: colorCtrl,
                          decoration: InputDecoration(
                            labelText: 'Color *',
                            hintText: 'Ej. Blanco, Gris',
                            prefixIcon: const Icon(Icons.palette_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: placaCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Placa (Opcional)',
                            hintText: 'Ej. PBX-1234',
                            prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: chasisCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Chasis (VIN) *',
                      hintText: 'Ej. LC0CE4EC8P0123456',
                      prefixIcon: const Icon(Icons.fingerprint, size: 20),
                      helperText: 'Identificador único e irrepetible del auto',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: kmCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Kilometraje',
                            hintText: '0',
                            prefixIcon: const Icon(Icons.speed, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ubicación inicial:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ubicaciones.map((ub) {
                      final isSelected = ubicacion == ub;
                      final color = _getColorUbicacion(ub);
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIconUbicacion(ub),
                              size: 16,
                              color: isSelected ? Colors.white : color,
                            ),
                            const SizedBox(width: 6),
                            Text(ub),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? color : const Color(0xFFCBD5E1),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => ubicacion = ub);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: novCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Novedades / Observaciones',
                      hintText: 'Opcional (ej. Requiere pulitura, batería al 100%)',
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (modeloCtrl.text.trim().isEmpty ||
                    colorCtrl.text.trim().isEmpty ||
                    chasisCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa Modelo, Color y Chasis.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(esEdicion ? 'Actualizar Datos' : 'Registrar Vehículo'),
            ),
          ],
        ),
      ),
    );

    if (guardado == true) {
      final modelo = modeloCtrl.text.trim();
      final color = colorCtrl.text.trim();
      final chasis = chasisCtrl.text.trim().toUpperCase();
      final placa = placaCtrl.text.trim().toUpperCase();
      final km = int.tryParse(kmCtrl.text.trim()) ?? 0;
      final nov = novCtrl.text.trim();

      try {
        if (esEdicion) {
          final vehiculoActualizado = vehiculoEditar.copyWith(
            modelo: modelo,
            color: color,
            chasis: chasis,
            placa: placa,
            kilometraje: km,
            ubicacion: ubicacion,
            novedades: nov,
          );
          await SupabaseService.updateVehiculoCompleto(vehiculoActualizado);
        } else {
          final nuevoVehiculo = Vehiculo(
            modelo: modelo,
            color: color,
            chasis: chasis,
            placa: placa.isNotEmpty ? placa : null,
            kilometraje: km,
            ubicacion: ubicacion,
            novedades: nov.isNotEmpty ? nov : null,
          );
          await SupabaseService.addVehiculo(nuevoVehiculo);
        }

        _cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                esEdicion
                    ? 'Vehículo actualizado exitosamente.'
                    : 'Vehículo registrado exitosamente en la flota.',
              ),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar vehículo: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmarEliminar(Vehiculo vehiculo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar Vehículo?'),
        content: Text(
          '¿Estás seguro de que deseas eliminar el vehículo "${vehiculo.modelo}" (VIN: ${vehiculo.chasis}) de la flota?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && vehiculo.id != null) {
      try {
        await SupabaseService.deleteVehiculo(vehiculo.id!);
        _cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehículo eliminado de la flota.'),
              backgroundColor: Colors.black87,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalVehiculos = _vehiculos.length;
    final totalShowroom = _vehiculos.where((v) => v.ubicacion == 'Showroom').length;
    final totalTestDrive = _vehiculos.where((v) => v.ubicacion == 'Test Drive').length;
    final totalTerraza = _vehiculos.where((v) => v.ubicacion == 'Terraza').length;
    final vehiculosMostrados = _vehiculosFiltrados;
    final numFormat = NumberFormat('#,###', 'es');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control de Vehículos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Showroom | Test Drive | Terraza',
              style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
            tooltip: 'Generar Reporte PDF',
            onPressed: _generarPdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refrescar',
            onPressed: _cargar,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _esHoy
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarModalNuevoVehiculo(),
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Nuevo Vehículo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: Column(
          children: [
            // Barra de Navegación por Fecha (Historial Diario)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF0A101D),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                    tooltip: 'Día anterior',
                    onPressed: () {
                      setState(() {
                        _fechaSeleccionada = _fechaSeleccionada.subtract(const Duration(days: 1));
                      });
                      _cargar();
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fechaSeleccionada,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _fechaSeleccionada = picked);
                          _cargar();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _esHoy ? const Color(0xFF0284C7) : Colors.white24,
                            width: _esHoy ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _esHoy ? Icons.today : Icons.event,
                              size: 16,
                              color: _esHoy ? const Color(0xFF38BDF8) : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _esHoy
                                    ? 'Hoy (${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)})'
                                    : DateFormat("dd/MM/yyyy - EEEE", 'es').format(_fechaSeleccionada),
                                style: TextStyle(
                                  color: _esHoy ? const Color(0xFF38BDF8) : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: _esHoy ? Colors.white24 : Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Día siguiente',
                    onPressed: _esHoy
                        ? null
                        : () {
                            setState(() {
                              _fechaSeleccionada = _fechaSeleccionada.add(const Duration(days: 1));
                            });
                            _cargar();
                          },
                  ),
                  if (!_esHoy)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() => _fechaSeleccionada = DateTime.now());
                          _cargar();
                        },
                        icon: const Icon(Icons.restore, size: 14, color: Color(0xFF38BDF8)),
                        label: const Text(
                          'Hoy',
                          style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Banner informativo para fechas históricas
            if (!_esHoy)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFFEF3C7),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 16, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reporte histórico del ${DateFormat("dd 'de' MMMM, yyyy", 'es').format(_fechaSeleccionada)}. Al pulsar el botón PDF, se descargará el reporte de este día.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // Barra de filtros y contadores KPI
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                children: [
                  // KPI Chips interactivos
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill(
                          label: 'Todos',
                          count: totalVehiculos,
                          isSelected: _filtroUbicacion == 'Todos',
                          color: const Color(0xFF0A101D),
                          onTap: () => setState(() => _filtroUbicacion = 'Todos'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: 'Showroom',
                          count: totalShowroom,
                          isSelected: _filtroUbicacion == 'Showroom',
                          color: const Color(0xFF059669),
                          icon: Icons.storefront_outlined,
                          onTap: () => setState(() => _filtroUbicacion = 'Showroom'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: 'Test Drive',
                          count: totalTestDrive,
                          isSelected: _filtroUbicacion == 'Test Drive',
                          color: const Color(0xFF0284C7),
                          icon: Icons.electric_car_outlined,
                          onTap: () => setState(() => _filtroUbicacion = 'Test Drive'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          label: 'Terraza',
                          count: totalTerraza,
                          isSelected: _filtroUbicacion == 'Terraza',
                          color: const Color(0xFFD97706),
                          icon: Icons.roofing_outlined,
                          onTap: () => setState(() => _filtroUbicacion = 'Terraza'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Buscador
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _filtroTexto = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar por modelo, chasis (VIN), placa o color...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                      suffixIcon: _filtroTexto.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _filtroTexto = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : vehiculosMostrados.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                          itemCount: vehiculosMostrados.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final v = vehiculosMostrados[index];
                            final colorUbicacion = _getColorUbicacion(v.ubicacion);
                            final bgUbicacion = _getBgColorUbicacion(v.ubicacion);
                            final iconUbicacion = _getIconUbicacion(v.ubicacion);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(14),
                                  ).color != null
                                      ? BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.03),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      : const BoxShadow(),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Fila Superior: Modelo, Color y Ubicación
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      v.modelo,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                                    ),
                                                    child: Text(
                                                      v.color,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF475569),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.fingerprint,
                                                    size: 15,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'VIN: ${v.chasis}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF334155),
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                  if (v.placa != null && v.placa!.trim().isNotEmpty) ...[
                                                    const SizedBox(width: 10),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFEF3C7),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                                      ),
                                                      child: Text(
                                                        v.placa!,
                                                        style: const TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF92400E),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Badge Ubicación
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: bgUbicacion,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: colorUbicacion.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(iconUbicacion, size: 14, color: colorUbicacion),
                                              const SizedBox(width: 5),
                                              Text(
                                                v.ubicacion,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorUbicacion,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                    const SizedBox(height: 10),

                                    // Fila Central: Kilometraje y Novedades
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.speed, size: 16, color: Color(0xFF0284C7)),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${numFormat.format(v.kilometraje)} km',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: (v.novedades != null && v.novedades!.trim().isNotEmpty)
                                                  ? const Color(0xFFFFFBEB)
                                                  : const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: (v.novedades != null && v.novedades!.trim().isNotEmpty)
                                                    ? const Color(0xFFFDE68A)
                                                    : const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  (v.novedades != null && v.novedades!.trim().isNotEmpty)
                                                      ? Icons.warning_amber_rounded
                                                      : Icons.check_circle_outline,
                                                  size: 14,
                                                  color: (v.novedades != null && v.novedades!.trim().isNotEmpty)
                                                      ? const Color(0xFFD97706)
                                                      : const Color(0xFF10B981),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    (v.novedades != null && v.novedades!.trim().isNotEmpty)
                                                        ? v.novedades!
                                                        : 'Sin novedades registradas',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: (v.novedades != null && v.novedades!.trim().isNotEmpty)
                                                          ? const Color(0xFF92400E)
                                                          : const Color(0xFF64748B),
                                                      fontWeight: (v.novedades != null && v.novedades!.trim().isNotEmpty)
                                                          ? FontWeight.w500
                                                          : FontWeight.normal,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Fila de Botones de Acción
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _mostrarModalActualizacionRapida(v),
                                            icon: const Icon(Icons.edit_calendar, size: 16),
                                            label: Text(
                                              _esHoy ? 'Actualizar Estado Diario' : 'Modificar Registro del Día',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0A101D),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        PopupMenuButton<String>(
                                          tooltip: 'Más opciones',
                                          icon: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                            ),
                                            child: const Icon(
                                              Icons.more_vert,
                                              size: 18,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                          onSelected: (val) {
                                            if (val == 'editar') {
                                              _mostrarModalNuevoVehiculo(vehiculoEditar: v);
                                            } else if (val == 'eliminar') {
                                              _confirmarEliminar(v);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'editar',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                                                  SizedBox(width: 8),
                                                  Text('Editar Datos Completos'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'eliminar',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Eliminar de la Flota',
                                                    style: TextStyle(color: Colors.red.shade700),
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
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 56,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _vehiculos.isEmpty
                  ? 'Aún no hay vehículos registrados'
                  : 'No se encontraron vehículos con ese filtro',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _vehiculos.isEmpty
                  ? 'Registra los autos del Showroom, Test Drive y Terraza una sola vez para gestionar su kilometraje diario sin volver a escribirlos.'
                  : 'Prueba cambiando los términos de búsqueda o el filtro de ubicación.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            if (_vehiculos.isEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _mostrarModalNuevoVehiculo(),
                icon: const Icon(Icons.add),
                label: const Text('Registrar Primer Vehículo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
