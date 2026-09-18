import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/atencion.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';
import 'editar_atencion_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  DateTime fecha = DateTime.now();
  List<Atencion> atenciones = [];
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    atenciones = await SupabaseService.getAtencionesByDate(fecha);
    setState(() => cargando = false);
  }

  Future<void> _generarReporteMensual() async {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Reporte Mensual'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: const InputDecoration(labelText: 'Año'),
                items: List.generate(5, (i) => now.year - i)
                    .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                    .toList(),
                onChanged: (v) => setStateDialog(() => selectedYear = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedMonth,
                decoration: const InputDecoration(labelText: 'Mes'),
                items: List.generate(12, (i) => i + 1)
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(DateFormat('MMMM').format(DateTime(2000, m))),
                        ))
                    .toList(),
                onChanged: (v) => setStateDialog(() => selectedMonth = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generar')),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando PDF mensual...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final data = await SupabaseService.getAtencionesByMonth(selectedYear, selectedMonth);
      await PdfService.generarReporteMensual(selectedYear, selectedMonth, data);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte mensual descargado')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _generarPdf() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await PdfService.generarReporte(fecha, atenciones);
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF descargado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalClientes = atenciones.length;
    final totalPersonas = atenciones.fold(0, (sum, a) => sum + a.totalPersonas);
    final totalTestDrives = atenciones.where((a) => a.testDrive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Reporte Mensual',
            onPressed: _generarReporteMensual,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: atenciones.isEmpty ? null : _generarPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(fecha),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      fecha = picked;
                      _cargar();
                    }
                  },
                  child: const Text('Cambiar Fecha'),
                ),
              ],
            ),
          ),
          if (cargando)
            const CircularProgressIndicator()
          else if (atenciones.isEmpty)
            const Expanded(child: Center(child: Text('No hay atenciones')))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Resumen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Clientes: $totalClientes'),
                          Text('Personas: $totalPersonas'),
                          Text('Test Drives: $totalTestDrives'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Detalle de Atenciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  ...atenciones.map((a) => Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('${a.clienteNombre} ${a.clienteApellido}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Asesor: ${a.asesorNombre} - ${a.totalPersonas} persona(s)${a.testDrive ? ' - Test Drive' : ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF334155)),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditarAtencionScreen(atencion: a),
                            ),
                          );
                          if (result == true) _cargar();
                        },
                      ),
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
