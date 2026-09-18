import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../services/supabase_service.dart';

class PowerBiScreen extends StatefulWidget {
  const PowerBiScreen({super.key});

  @override
  State<PowerBiScreen> createState() => _PowerBiScreenState();
}

class _PowerBiScreenState extends State<PowerBiScreen> {
  String? _selectedReport;
  bool _isGenerating = false;

  String _filterType = 'mes';
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedRange;

  final List<Map<String, dynamic>> _reportes = [
    {
      'id': 'ejecutivo',
      'title': 'Dashboard Ejecutivo / Gerencial',
      'desc': 'Tráfico total, Tasa de conversión y tendencias.',
      'icon': Icons.insights,
    },
    {
      'id': 'asesores',
      'title': 'Rendimiento de Asesores',
      'desc': 'Efectividad, test drives logrados y carga.',
      'icon': Icons.group_work,
    },
    {
      'id': 'operativo',
      'title': 'Mapa de Calor Operativo',
      'desc': 'Horarios pico y análisis de tráfico por hora.',
      'icon': Icons.calendar_month,
    },
    {
      'id': 'experiencia',
      'title': 'Experiencia del Cliente (NPS)',
      'desc': 'Calificaciones y encuestas de satisfacción.',
      'icon': Icons.star_rate,
    },
  ];

  Future<void> _generarReporteMockup() async {
    if (_selectedReport == null) return;
    setState(() {
      _isGenerating = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _isGenerating = false;
    });
  }

  Future<void> _generarPdfReal() async {
    if (_selectedReport == null) return;
    
    setState(() {
      _isGenerating = true;
    });

    try {
      DateTime start;
      DateTime end;

      if (_filterType == 'mes') {
        start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        end = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      } else if (_filterType == 'dia') {
        start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        end = start.add(const Duration(days: 1));
      } else {
        if (_selectedRange == null) throw Exception('Seleccione un rango');
        start = _selectedRange!.start;
        end = _selectedRange!.end.add(const Duration(days: 1));
      }

      List<dynamic> rawData = [];
      
      if (_selectedReport == 'experiencia') {
        final data = await SupabaseService.client
            .from('encuestas')
            .select()
            .gte('fecha', start.toIso8601String())
            .lt('fecha', end.toIso8601String());
        rawData = data as List;
      } else {
        final data = await SupabaseService.client
            .from('atenciones')
            .select()
            .gte('fecha', start.toIso8601String())
            .lt('fecha', end.toIso8601String());
        rawData = data as List;
      }

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final title = _reportes.firstWhere((r) => r['id'] == _selectedReport)['title'];
            final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('POWER BI DASHBOARD - BYD', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text(dateStr, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ]
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Reporte: $title", style: pw.TextStyle(fontSize: 16, color: PdfColors.grey800)),
                pw.Text("Filtro aplicado: ${_getFilterText()}", style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                pw.SizedBox(height: 30),
                
                if (_selectedReport == 'ejecutivo') _buildEjecutivo(rawData),
                if (_selectedReport == 'asesores') _buildAsesores(rawData),
                if (_selectedReport == 'operativo') _buildOperativo(rawData),
                if (_selectedReport == 'experiencia') _buildExperiencia(rawData),
                
                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('Generado automáticamente desde BYD Reception', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                )
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      
      final fileName = "dashboard_${_selectedReport}_${DateTime.now().millisecondsSinceEpoch}.pdf";

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generado exitosamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  pw.Widget _buildEjecutivo(List<dynamic> data) {
    int total = data.length;
    int citas = data.where((e) => e['cita'] == true).length;
    int testDrives = data.where((e) => e['test_drive'] == true).length;
    int walkins = total - citas;
    double conversion = total > 0 ? (testDrives / total) * 100 : 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildKpiCard('TRÁFICO TOTAL', total.toString(), PdfColors.blue),
            _buildKpiCard('TEST DRIVES', testDrives.toString(), PdfColors.orange),
            _buildKpiCard('TASA CONVERSIÓN', "${conversion.toStringAsFixed(1)}%", PdfColors.green),
          ],
        ),
        pw.SizedBox(height: 40),
        pw.Text('Distribución de Tráfico (Walk-ins vs Citas)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.Row(
          children: [
            pw.Container(
              height: 40,
              width: total > 0 ? (walkins / total) * 400 : 0,
              color: PdfColors.blue400,
              child: pw.Center(child: pw.Text("Walk-in ($walkins)", style: const pw.TextStyle(color: PdfColors.white))),
            ),
            pw.Container(
              height: 40,
              width: total > 0 ? (citas / total) * 400 : 0,
              color: PdfColors.purple400,
              child: pw.Center(child: pw.Text("Citas ($citas)", style: const pw.TextStyle(color: PdfColors.white))),
            ),
          ],
        ),
      ]
    );
  }

  pw.Widget _buildAsesores(List<dynamic> data) {
    Map<String, int> asesoresCount = {};
    for (var row in data) {
      String asesor = row['asesor_nombre'] ?? 'Sin asesor';
      asesoresCount[asesor] = (asesoresCount[asesor] ?? 0) + 1;
    }
    
    var sorted = asesoresCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    String topAsesor = sorted.isNotEmpty ? sorted.first.key : 'N/A';
    int totalAtenciones = data.length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildKpiCard('TOTAL ATENCIONES', totalAtenciones.toString(), PdfColors.blue),
            _buildKpiCard('ASESOR TOP', topAsesor, PdfColors.orange),
          ],
        ),
        pw.SizedBox(height: 40),
        pw.Text('Rendimiento por Asesor', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...sorted.map((e) {
          final double width = totalAtenciones > 0 ? (e.value / totalAtenciones) * 350 : 0;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(width: 100, child: pw.Text(e.key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Container(
                  height: 20,
                  width: width > 0 ? width : 1,
                  color: PdfColors.blue400,
                ),
                pw.SizedBox(width: 8),
                pw.Text("${e.value} clientes"),
              ],
            )
          );
        }),
      ]
    );
  }

  pw.Widget _buildOperativo(List<dynamic> data) {
    Map<int, int> trafficByHour = {};
    for (var row in data) {
      DateTime dt = DateTime.tryParse(row['fecha'].toString()) ?? DateTime.now();
      int hour = dt.toLocal().hour;
      trafficByHour[hour] = (trafficByHour[hour] ?? 0) + 1;
    }

    int maxTraffic = 0;
    int peakHour = 0;
    trafficByHour.forEach((hour, count) {
      if (count > maxTraffic) {
        maxTraffic = count;
        peakHour = hour;
      }
    });

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
         pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            _buildKpiCard('TRÁFICO TOTAL', data.length.toString(), PdfColors.blue),
            _buildKpiCard('HORA PICO', "$peakHour:00", PdfColors.red),
          ],
        ),
        pw.SizedBox(height: 40),
        pw.Text('Tráfico por Hora (Mapa de Calor)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: List.generate(12, (index) {
            int h = index + 8; // 8:00 a 19:00
            int count = trafficByHour[h] ?? 0;
            double height = maxTraffic > 0 ? (count / maxTraffic) * 150 : 0;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(count.toString(), style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 4),
                  pw.Container(width: 25, height: height, color: PdfColors.orange400),
                  pw.SizedBox(height: 4),
                  pw.Text("$h:00", style: const pw.TextStyle(fontSize: 8)),
                ]
              )
            );
          }),
        )
      ]
    );
  }

  pw.Widget _buildExperiencia(List<dynamic> data) {
    int total = data.length;
    int testDriveYes = data.where((e) => e['ofrecieron_test_drive'] == true).length;
    int bebidaYes = data.where((e) => e['recibi_bebida'] == true).length;
    
    double tdPercent = total > 0 ? (testDriveYes / total) * 100 : 0;
    double bebPercent = total > 0 ? (bebidaYes / total) * 100 : 0;

    Map<String, int> calificaciones = {};
    for (var row in data) {
      String calif = row['calificacion']?.toString() ?? 'Sin Dato';
      calificaciones[calif] = (calificaciones[calif] ?? 0) + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
         pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildKpiCard('ENCUESTAS', total.toString(), PdfColors.blue),
            _buildKpiCard('T. DRIVE OFRECIDO', "${tdPercent.toStringAsFixed(1)}%", PdfColors.orange),
            _buildKpiCard('BEBIDA OFRECIDA', "${bebPercent.toStringAsFixed(1)}%", PdfColors.green),
          ],
        ),
        pw.SizedBox(height: 40),
        pw.Text('Distribución de Calificaciones (NPS)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        ...calificaciones.entries.map((e) {
          final double width = total > 0 ? (e.value / total) * 350 : 0;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.SizedBox(width: 100, child: pw.Text(e.key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Container(
                  height: 20,
                  width: width > 0 ? width : 1,
                  color: e.key.toLowerCase() == 'excelente' ? PdfColors.green400 : PdfColors.blue400,
                ),
                pw.SizedBox(width: 8),
                pw.Text("${e.value} votos"),
              ],
            )
          );
        }).toList(),
      ]
    );
  }

  pw.Widget _buildKpiCard(String title, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 5),
          pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
        ]
      )
    );
  }

  String _getFilterText() {
    if (_filterType == 'mes') return DateFormat('MMMM yyyy', 'es').format(_selectedDate);
    if (_filterType == 'dia') return DateFormat('dd/MM/yyyy').format(_selectedDate);
    if (_selectedRange != null) {
      return "${DateFormat('dd/MM/yy').format(_selectedRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedRange!.end)}";
    }
    return '';
  }

  Future<void> _selectDate() async {
    if (_filterType == 'rango') {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (range != null) setState(() => _selectedRange = range);
    } else {
      final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (date != null) setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar a Power BI', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtro de Datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'mes', label: Text('Por Mes')),
                      ButtonSegment(value: 'dia', label: Text('Por Día')),
                      ButtonSegment(value: 'rango', label: Text('Rango')),
                    ],
                    selected: {_filterType},
                    onSelectionChanged: (set) => setState(() => _filterType = set.first),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_getFilterText().isEmpty ? 'Seleccionar Fecha' : _getFilterText()),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Seleccione el tipo de reporte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _reportes.length,
                  itemBuilder: (context, index) {
                    final report = _reportes[index];
                    final isSelected = _selectedReport == report['id'];
                    return Card(
                      color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => setState(() {
                          _selectedReport = report['id'];
                        }),
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? const Color(0xFF38BDF8) : const Color(0xFFE2E8F0),
                          child: Icon(report['icon'], color: isSelected ? Colors.white : const Color(0xFF334155)),
                        ),
                        title: Text(report['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(report['desc']),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF38BDF8)) : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_isGenerating)
                const Center(child: CircularProgressIndicator(color: Color(0xFFF2C811)))
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedReport == null ? null : _generarPdfReal,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Generar PDF Real'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedReport == null ? null : _generarReporteMockup,
                        icon: const Icon(Icons.pie_chart),
                        label: const Text('Conectar a Power BI Web'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2C811),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.all(20),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
