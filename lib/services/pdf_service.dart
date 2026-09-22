import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/atencion.dart';
import '../models/encuesta.dart';
import '../models/vehiculo.dart';
import 'package:universal_html/html.dart' as html;
import 'package:printing/printing.dart';

class PdfService {
  static pw.MemoryImage? _logoCache;

  static Future<void> generarReporte(DateTime fecha, List<Atencion> atenciones) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy');
    
    // Cargar logo con cache
    _logoCache ??= pw.MemoryImage(
      (await rootBundle.load('assets/img/images.png')).buffer.asUint8List(),
    );
    final logoImage = _logoCache!;
    
    final Map<String, List<Atencion>> porAsesor = {};
    for (var a in atenciones) {
      porAsesor.putIfAbsent(a.asesorNombre ?? 'Sin asesor', () => []).add(a);
    }

    final totalClientes = atenciones.length;
    final totalPersonas = atenciones.fold(0, (sum, a) => sum + a.totalPersonas);
    final totalTestDrives = atenciones.where((a) => a.testDrive).length;
    final totalCitas = atenciones.where((a) => a.cita).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header con logo
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, height: 60),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Reporte de Atención al Cliente',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.SizedBox(height: 4),
                  pw.Text(dateFormat.format(fecha),
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.blue900, thickness: 2),
          pw.SizedBox(height: 24),
          
          // Resumen General con colores
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Resumen General',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Clientes', totalClientes.toString(), PdfColors.blue),
                    _buildStatCard('Acompañantes', totalPersonas.toString(), PdfColors.green),
                    _buildStatCard('Test Drives', totalTestDrives.toString(), PdfColors.orange),
                    _buildStatCard('Citas', totalCitas.toString(), PdfColors.purple),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          
          // Detalle por Asesor
          pw.Text('Detalle por Asesor',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headers: ['Asesor', 'Clientes', 'Acompañantes', 'Test Drive', 'Citas'],
            data: [
              ...porAsesor.entries.map((e) => [
                e.key,
                e.value.length.toString(),
                e.value.fold(0, (sum, a) => sum + a.numAcompanantes).toString(),
                e.value.where((a) => a.testDrive).length.toString(),
                e.value.where((a) => a.cita).length.toString(),
              ]),
              [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(totalClientes.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(totalPersonas.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(totalTestDrives.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(totalCitas.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ],
          ),
          pw.SizedBox(height: 24),
          
          // Desglose de Clientes
          pw.Text('Desglose de Clientes',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 12),

          // Seccion Citas
          if (atenciones.any((a) => a.cita)) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('Citas (${atenciones.where((a) => a.cita).length})',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
            ),
            pw.SizedBox(height: 8),
            ...atenciones.where((a) => a.cita).toList().asMap().entries.map((entry) =>
              _buildClienteRow(entry.key, entry.value, PdfColors.purple50)
            ),
            pw.SizedBox(height: 16),
          ],

          // Seccion Test Drives
          if (atenciones.any((a) => a.testDrive)) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('Test Drives (${atenciones.where((a) => a.testDrive).length})',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
            ),
            pw.SizedBox(height: 8),
            ...atenciones.where((a) => a.testDrive).toList().asMap().entries.map((entry) =>
              _buildClienteRow(entry.key, entry.value, PdfColors.orange50)
            ),
            pw.SizedBox(height: 16),
          ],

          // Seccion clientes sin cita ni test drive
          if (atenciones.any((a) => !a.cita && !a.testDrive)) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('Clientes (${atenciones.where((a) => !a.cita && !a.testDrive).length})',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            ),
            pw.SizedBox(height: 8),
            ...atenciones.where((a) => !a.cita && !a.testDrive).toList().asMap().entries.map((entry) =>
              _buildClienteRow(entry.key, entry.value, entry.key % 2 == 0 ? PdfColors.grey100 : PdfColors.white)
            ),
            pw.SizedBox(height: 16),
          ],

          // Total final
          pw.Divider(color: PdfColors.blue900, thickness: 2),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildTotalItem('Total Clientes', totalClientes.toString()),
                _buildTotalItem('Acompañantes', totalPersonas.toString()),
                _buildTotalItem('Test Drives', totalTestDrives.toString()),
                _buildTotalItem('Citas', totalCitas.toString()),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ),
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'reporte_byd_${fecha.year}_${fecha.month}_${fecha.day}.pdf';

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
  }

  static Future<void> generarReporteMensual(int year, int month, List<Atencion> atenciones) async {
    final pdf = pw.Document();
    final monthFormat = DateFormat('MMMM yyyy', 'es');
    final mesLabel = monthFormat.format(DateTime(year, month));

    _logoCache ??= pw.MemoryImage(
      (await rootBundle.load('assets/img/images.png')).buffer.asUint8List(),
    );
    final logoImage = _logoCache!;

    final totalClientes = atenciones.length;
    final totalPersonas = atenciones.fold(0, (sum, a) => sum + a.totalPersonas);
    final totalTestDrives = atenciones.where((a) => a.testDrive).length;
    final totalCitas = atenciones.where((a) => a.cita).length;

    // Agrupar por nombre normalizado (el asesorId cambia cada vez que se agrega a la cola)
    String normalizarNombre(String nombre) =>
        nombre.trim().toLowerCase()
            .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i')
            .replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ü', 'u');

    final Map<String, List<Atencion>> porAsesor = {};
    final Map<String, String> nombreMostrar = {};
    for (var a in atenciones) {
      final nombre = a.asesorNombre ?? 'Sin asesor';
      final clave = normalizarNombre(nombre);
      porAsesor.putIfAbsent(clave, () => []).add(a);
      nombreMostrar.putIfAbsent(clave, () => nombre);
    }

    // Agrupar por día
    final Map<int, List<Atencion>> porDia = {};
    for (var a in atenciones) {
      porDia.putIfAbsent(a.fecha.day, () => []).add(a);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, height: 60),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Reporte Mensual de Atención al Cliente',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.SizedBox(height: 4),
                  pw.Text(mesLabel,
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.blue900, thickness: 2),
          pw.SizedBox(height: 20),

          // Resumen general
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Resumen del Mes',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Clientes', totalClientes.toString(), PdfColors.blue),
                    _buildStatCard('Acompañantes', totalPersonas.toString(), PdfColors.green),
                    _buildStatCard('Test Drives', totalTestDrives.toString(), PdfColors.orange),
                    _buildStatCard('Citas', totalCitas.toString(), PdfColors.purple),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Resumen por asesor
          pw.Text('Resumen por Asesor',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellPadding: const pw.EdgeInsets.all(8),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headers: ['Asesor', 'Clientes', 'Acompañantes', 'Test Drive', 'Citas'],
            data: [
              ...porAsesor.entries.map((e) => [
                nombreMostrar[e.key] ?? e.key,
                e.value.length.toString(),
                e.value.fold(0, (sum, a) => sum + a.numAcompanantes).toString(),
                e.value.where((a) => a.testDrive).length.toString(),
                e.value.where((a) => a.cita).length.toString(),
              ]),
              [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(totalClientes.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(totalPersonas.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(totalTestDrives.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(totalCitas.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ],
          ),
          pw.SizedBox(height: 20),

          // Detalle por día
          pw.Text('Detalle por Día',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),
          ...(() {
            final dias = porDia.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
            return dias.expand((entry) {
              final dia = entry.key;
              final lista = entry.value;
              final fechaDia = DateTime(year, month, dia);
              return [
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue900,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(DateFormat('EEEE dd', 'es').format(fechaDia),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11)),
                      pw.Text('${lista.length} cliente${lista.length != 1 ? 's' : ''}',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                    ],
                  ),
                ),
                ...lista.asMap().entries.map((e) => _buildClienteRow(e.key, e.value,
                    e.key % 2 == 0 ? PdfColors.grey100 : PdfColors.white)),
                pw.SizedBox(height: 12),
              ];
            }).toList();
          })(),

          pw.Divider(color: PdfColors.blue900, thickness: 2),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildTotalItem('Total Clientes', totalClientes.toString()),
                _buildTotalItem('Acompañantes', totalPersonas.toString()),
                _buildTotalItem('Test Drives', totalTestDrives.toString()),
                _buildTotalItem('Citas', totalCitas.toString()),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ),
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'reporte_mensual_byd_${year}_${month.toString().padLeft(2, '0')}.pdf';

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
  }

  static Future<void> generarReporteEncuestas(DateTime fecha, List<Encuesta> encuestas) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy');

    _logoCache ??= pw.MemoryImage(
      (await rootBundle.load('assets/img/images.png')).buffer.asUint8List(),
    );
    final logoImage = _logoCache!;

    final total = encuestas.length;
    final buena = encuestas.where((e) => e.calificacion == 'Buena').length;
    final muyBuena = encuestas.where((e) => e.calificacion == 'Muy Buena').length;
    final mala = encuestas.where((e) => e.calificacion == 'Mala').length;
    final bebida = encuestas.where((e) => e.recibiBebida).length;
    final testDrive = encuestas.where((e) => e.ofrecieronTestDrive).length;
    final dudas = encuestas.where((e) => e.asesorResolvioDudas).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, height: 60),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Reporte de Encuestas de Satisfacción',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.SizedBox(height: 4),
                  pw.Text(dateFormat.format(fecha),
                      style: pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.blue900, thickness: 2),
          pw.SizedBox(height: 16),

          // Resumen
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Resumen General',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', total.toString(), PdfColors.blue),
                    _buildStatCard('Muy Buena', muyBuena.toString(), PdfColors.green),
                    _buildStatCard('Buena', buena.toString(), PdfColors.teal),
                    _buildStatCard('Mala', mala.toString(), PdfColors.red),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Bebida', bebida.toString(), PdfColors.orange),
                    _buildStatCard('Test Drive', testDrive.toString(), PdfColors.purple),
                    _buildStatCard('Dudas\nResueltas', dudas.toString(), PdfColors.indigo),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Detalle
          pw.Text('Detalle de Encuestas',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 10),

          ...encuestas.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final bgColor = i % 2 == 0 ? PdfColors.grey100 : PdfColors.white;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: bgColor,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${e.nombre} ${e.apellido}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: e.calificacion == 'Muy Buena'
                              ? PdfColors.green100
                              : e.calificacion == 'Buena'
                                  ? PdfColors.teal100
                                  : PdfColors.red100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(e.calificacion,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: e.calificacion == 'Muy Buena'
                                  ? PdfColors.green900
                                  : e.calificacion == 'Buena'
                                      ? PdfColors.teal900
                                      : PdfColors.red900,
                            )),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Tel: ${e.celular}',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  if (e.asesor != null && e.asesor!.isNotEmpty)
                    pw.Text('Asesor: ${e.asesor}',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      _buildChip('Bebida', e.recibiBebida),
                      pw.SizedBox(width: 6),
                      _buildChip('Test Drive', e.ofrecieronTestDrive),
                      pw.SizedBox(width: 6),
                      _buildChip('Dudas resueltas', e.asesorResolvioDudas),
                    ],
                  ),
                  if (e.comoMejorar != null && e.comoMejorar!.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text('Sugerencia: ${e.comoMejorar}',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700,
                            fontStyle: pw.FontStyle.italic)),
                  ],
                ],
              ),
            );
          }),

          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.blue900, thickness: 2),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildTotalItem('Total', total.toString()),
                _buildTotalItem('Muy Buena', muyBuena.toString()),
                _buildTotalItem('Buena', buena.toString()),
                _buildTotalItem('Mala', mala.toString()),
              ],
            ),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ),
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'encuestas_byd_${fecha.year}_${fecha.month}_${fecha.day}.pdf';

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
  }

  static pw.Widget _buildChip(String label, bool value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: value ? PdfColors.green100 : PdfColors.red100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        '$label: ${value ? 'Sí' : 'No'}',
        style: pw.TextStyle(
          fontSize: 8,
          color: value ? PdfColors.green900 : PdfColors.red900,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildClienteRow(int index, Atencion a, PdfColor bgColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 26,
            height: 26,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(13),
            ),
            child: pw.Center(
              child: pw.Text('${index + 1}',
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${a.clienteNombre} ${a.clienteApellido}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 3),
                pw.Text(
                    'Asesor: ${a.asesorNombre} | ${a.numAcompanantes} acompañante${a.numAcompanantes != 1 ? 's' : ''}${a.testDrive ? ' | Test Drive' : ''}${a.cita ? ' | Cita' : ''}${a.notas != null && a.notas!.isNotEmpty ? ' | ${a.notas}' : ''}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
      ],
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static Future<void> generarReporteVehiculos(List<Vehiculo> vehiculos) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat("dd 'de' MMMM, yyyy - HH:mm", 'es');
    final now = DateTime.now();

    _logoCache ??= pw.MemoryImage(
      (await rootBundle.load('assets/img/images.png')).buffer.asUint8List(),
    );
    final logoImage = _logoCache!;

    final totalVehiculos = vehiculos.length;
    final totalShowroom = vehiculos.where((v) => v.ubicacion == 'Showroom').length;
    final totalTestDrive = vehiculos.where((v) => v.ubicacion == 'Test Drive').length;
    final totalTerraza = vehiculos.where((v) => v.ubicacion == 'Terraza').length;

    final numberFormat = NumberFormat('#,###', 'es');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logoImage, height: 48),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'REPORTE DE CONTROL DE VEHÍCULOS',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF0A101D),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Showroom • Test Drive • Terraza',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF0284C7),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Generado: ${dateFormat.format(now)}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColor.fromInt(0xFF0284C7), thickness: 1.5),
          pw.SizedBox(height: 12),

          // Resumen Cards
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildVehiculoMetric('TOTAL FLOTA', totalVehiculos.toString(), PdfColors.blueGrey900),
                _buildVehiculoMetric('SHOWROOM', totalShowroom.toString(), PdfColors.green800),
                _buildVehiculoMetric('TEST DRIVE', totalTestDrive.toString(), PdfColors.blue800),
                _buildVehiculoMetric('TERRAZA', totalTerraza.toString(), PdfColors.orange800),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Tabla de Vehículos
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A101D)),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),  // #
              1: const pw.FlexColumnWidth(2.5), // Modelo
              2: const pw.FlexColumnWidth(1.8), // Color
              3: const pw.FlexColumnWidth(2.8), // Chasis
              4: const pw.FlexColumnWidth(1.6), // Placa
              5: const pw.FlexColumnWidth(1.8), // Km
              6: const pw.FlexColumnWidth(2.0), // Ubicación
              7: const pw.FlexColumnWidth(3.5), // Novedades
            },
            headers: [
              '#',
              'Modelo',
              'Color',
              'Chasis (VIN)',
              'Placa',
              'Kilometraje',
              'Ubicación',
              'Novedades / Observaciones',
            ],
            data: List.generate(vehiculos.length, (index) {
              final v = vehiculos[index];
              return [
                '${index + 1}',
                v.modelo,
                v.color,
                v.chasis,
                (v.placa != null && v.placa!.trim().isNotEmpty) ? v.placa! : 'S/P',
                '${numberFormat.format(v.kilometraje)} km',
                v.ubicacion,
                (v.novedades != null && v.novedades!.trim().isNotEmpty) ? v.novedades! : 'Sin novedades',
              ];
            }),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'BYD Auto Ecuador • Sistema Integrado de Control de Flota y Recepción',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'reporte_vehiculos_byd_${now.year}_${now.month}_${now.day}.pdf';

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
  }

  static pw.Widget _buildVehiculoMetric(String title, String count, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          count,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }
}
