import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/supabase_service.dart';
import 'screens/asesores_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/editar_atencion_screen.dart';
import 'screens/encuesta_screen.dart';
import 'screens/powerbi_screen.dart';
import 'services/update_service.dart';
import 'models/atencion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  await SupabaseService.init(
    'https://avkxyphfrdjboifenukr.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2a3h5cGhmcmRqYm9pZmVudWtyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MTU1NjksImV4cCI6MjA4ODQ5MTU2OX0.wMsolfbuMstn-7Aa6bG33w37jbDzjpcwYr_s2BTnyKw',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0A101D); // Carbón obsidiana BYD
    const secondaryColor = Color(0xFF1E293B);
    const accentColor = Color(0xFF0284C7); // Azul eléctrico BYD

    return MaterialApp(
      title: 'BYD Reception',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.montserratTextTheme(),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accentColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Atencion> atenciones = [];
  DateTimeRange? _filtroRango;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UpdateService.verificarActualizacion(context, silencioso: true);
      });
    }
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      if (_filtroRango != null) {
        atenciones = await SupabaseService.getAtencionesByRange(_filtroRango!.start, _filtroRango!.end);
      } else {
        atenciones = await SupabaseService.getAtencionesByDate(DateTime.now());
      }
    } catch (e) {
      debugPrint('Error cargando atenciones: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarRangoFechas() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _filtroRango,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A101D),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() => _filtroRango = range);
      _cargar();
    }
  }

  String _getIniciales(String nombre, String apellido) {
    final n = nombre.trim().isNotEmpty ? nombre.trim()[0].toUpperCase() : '';
    final a = apellido.trim().isNotEmpty ? apellido.trim()[0].toUpperCase() : '';
    final res = n + a;
    return res.isNotEmpty ? res : 'BY';
  }

  Future<void> _confirmarLimpiarAsesores(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Reiniciar Cola'),
        content: const Text('¿Deseas reiniciar el turno de los asesores?\n\nLos registros de clientes se mantendrán intactos para tus reportes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.limpiarAsesores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cola de asesores reiniciada')),
        );
      }
    }
  }

  Future<void> _abrirWhatsAppCliente(Atencion a) async {
    final tel = a.telefono.trim();
    if (tel.isEmpty || tel == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este cliente no tiene teléfono registrado')),
      );
      return;
    }
    String cleaned = tel.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '593${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('593') && cleaned.length == 9) {
      cleaned = '593$cleaned';
    }
    final nombre = a.clienteNombre.trim();
    final mensaje = 'Hola estimado/a $nombre, le saluda la recepción de BYD. ¿En qué podemos ayudarle hoy?';
    final nativeUri = Uri.parse('whatsapp://send?phone=$cleaned&text=${Uri.encodeComponent(mensaje)}');
    final webUri = Uri.parse('https://wa.me/$cleaned?text=${Uri.encodeComponent(mensaje)}');

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(nativeUri);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir WhatsApp. Verifica que la app esté instalada.')),
          );
        }
      }
    }
  }

  Future<void> _llamarCliente(String telefono) async {
    final cleaned = telefono.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar la llamada')),
        );
      }
    }
  }

  void _contactarCliente(Atencion a) {
    final tel = a.telefono.trim();
    if (tel.isEmpty || tel == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este cliente no tiene número de teléfono registrado')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.phone_in_talk, color: Color(0xFF16A34A), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a.clienteNombre} ${a.clienteApellido}'.trim(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Tel: ${a.telefono}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat, color: Color(0xFF16A34A), size: 20),
              ),
              title: const Text('Enviar WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Abre el chat con saludo oficial de BYD'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () {
                Navigator.pop(ctx);
                _abrirWhatsAppCliente(a);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.call, color: Color(0xFF0284C7), size: 20),
              ),
              title: const Text('Llamar por Teléfono', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Abre la aplicación de llamadas'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () {
                Navigator.pop(ctx);
                _llamarCliente(a.telefono);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalClientes = atenciones.length;
    final totalPersonas = atenciones.fold(0, (sum, a) => sum + a.totalPersonas);
    final totalTestDrives = atenciones.where((a) => a.testDrive).length;
    final totalCitas = atenciones.where((a) => a.cita).length;
    final isWeb = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isWeb ? 70 : 56,
        title: isWeb
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset('assets/img/images.png', height: 38),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'BYD',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              letterSpacing: 2.0,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'RECEPTION',
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 16,
                              letterSpacing: 1.5,
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'SISTEMA DE CONTROL DE ATENCIÓN',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 14),
                        SizedBox(width: 8),
                        Text(
                          'Hoy es un gran día para brillar y dar lo mejor de ti',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/img/images.png', height: 26),
                  const SizedBox(width: 8),
                  const Text(
                    'BYD',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                      ),
                      child: const Text(
                        'v1.0.3',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34D399),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        actions: [
          // Botón selector de fecha con cápsula moderna
          InkWell(
            onTap: _seleccionarRangoFechas,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isWeb ? 12 : 8, vertical: 5),
              decoration: BoxDecoration(
                color: _filtroRango == null
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFF0284C7).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _filtroRango == null
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFF38BDF8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 13,
                    color: _filtroRango == null ? Colors.white70 : const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _filtroRango == null
                        ? 'Hoy'
                        : '${DateFormat('dd/MM').format(_filtroRango!.start)} - ${DateFormat('dd/MM').format(_filtroRango!.end)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _filtroRango == null ? Colors.white : const Color(0xFF38BDF8),
                    ),
                  ),
                  if (_filtroRango != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() => _filtroRango = null);
                        _cargar();
                      },
                      child: const Icon(Icons.close, size: 12, color: Color(0xFF38BDF8)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // En Web: Botón completo 'Nuevo Cliente'. En Móvil: Ícono rápido de agregar
          if (isWeb) ...[
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistroScreen()),
                );
                _cargar();
              },
              icon: const Icon(Icons.person_add_alt_1, size: 17),
              label: const Text('Nuevo Cliente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 6),
            _HeaderIconButton(
              icon: Icons.people_outline,
              tooltip: 'Cola de Asesores',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AsesoresScreen()),
              ),
            ),
            _HeaderIconButton(
              icon: Icons.pie_chart_outline,
              tooltip: 'Exportar Power BI',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PowerBiScreen()),
              ),
            ),
            _HeaderIconButton(
              icon: Icons.assessment_outlined,
              tooltip: 'Reportes Mensuales',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportesScreen()),
                );
                _cargar();
              },
            ),
            _HeaderIconButton(
              icon: Icons.star_border_rounded,
              tooltip: 'Encuestas NPS',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EncuestaScreen()),
              ),
            ),
            _HeaderIconButton(
              icon: Icons.cleaning_services_outlined,
              tooltip: 'Reiniciar Cola de Asesores',
              onPressed: () => _confirmarLimpiarAsesores(context),
            ),
          ] else ...[
            // En móvil: Ícono estilizado de Asesores
            IconButton(
              icon: const Icon(Icons.people_outline, size: 20, color: Colors.white),
              tooltip: 'Cola de Asesores',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AsesoresScreen()),
              ),
            ),
            // En móvil: Menú emergente de 3 puntos
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.more_vert, size: 18, color: Colors.white),
              ),
              onSelected: (value) async {
                if (value == 'nuevo') {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroScreen()));
                  _cargar();
                } else if (value == 'powerbi') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PowerBiScreen()));
                } else if (value == 'reportes') {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportesScreen()));
                  _cargar();
                } else if (value == 'encuestas') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EncuestaScreen()));
                } else if (value == 'actualizar') {
                  UpdateService.verificarActualizacion(context, silencioso: false);
                } else if (value == 'limpiar') {
                  _confirmarLimpiarAsesores(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'nuevo',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_alt_1, size: 18, color: Color(0xFF0284C7)),
                      SizedBox(width: 10),
                      Text('Registrar Cliente'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'powerbi',
                  child: Row(
                    children: [
                      Icon(Icons.pie_chart_outline, size: 18, color: Color(0xFF0F172A)),
                      SizedBox(width: 10),
                      Text('Exportar Power BI'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reportes',
                  child: Row(
                    children: [
                      Icon(Icons.assessment_outlined, size: 18, color: Color(0xFF0F172A)),
                      SizedBox(width: 10),
                      Text('Reportes Mensuales'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'encuestas',
                  child: Row(
                    children: [
                      Icon(Icons.star_border_rounded, size: 18, color: Color(0xFF0F172A)),
                      SizedBox(width: 10),
                      Text('Encuestas NPS'),
                    ],
                  ),
                ),
                if (!kIsWeb)
                  const PopupMenuItem(
                    value: 'actualizar',
                    child: Row(
                      children: [
                        Icon(Icons.system_update_alt, size: 18, color: Color(0xFF0284C7)),
                        SizedBox(width: 10),
                        Text('Buscar Actualización'),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'limpiar',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services_outlined, size: 18, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text('Reiniciar Cola Asesores', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 6),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
          child: Column(
            children: [
              // Sección Superior de Estadísticas Ejecutivas (KPIs)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: isWeb
                    ? Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              label: 'Clientes Registrados',
                              valor: totalClientes.toString(),
                              icon: Icons.badge_outlined,
                              iconColor: const Color(0xFF0284C7),
                              bgColor: const Color(0xFFE0F2FE),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _KpiCard(
                              label: 'Total Personas',
                              valor: totalPersonas.toString(),
                              icon: Icons.groups_outlined,
                              iconColor: const Color(0xFF6366F1),
                              bgColor: const Color(0xFFEEF2FF),
                              subtitulo: 'Incluye acompañantes',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _KpiCard(
                              label: 'Test Drives',
                              valor: totalTestDrives.toString(),
                              icon: Icons.electric_car_outlined,
                              iconColor: const Color(0xFF10B981),
                              bgColor: const Color(0xFFD1FAE5),
                              badge: totalClientes > 0
                                  ? '${((totalTestDrives / totalClientes) * 100).toStringAsFixed(0)}% conv.'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _KpiCard(
                              label: 'Citas Previas',
                              valor: totalCitas.toString(),
                              icon: Icons.event_available_outlined,
                              iconColor: const Color(0xFFF59E0B),
                              bgColor: const Color(0xFFFEF3C7),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _KpiCard(
                                  label: 'Clientes',
                                  valor: totalClientes.toString(),
                                  icon: Icons.badge_outlined,
                                  iconColor: const Color(0xFF0284C7),
                                  bgColor: const Color(0xFFE0F2FE),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiCard(
                                  label: 'Personas',
                                  valor: totalPersonas.toString(),
                                  icon: Icons.groups_outlined,
                                  iconColor: const Color(0xFF6366F1),
                                  bgColor: const Color(0xFFEEF2FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _KpiCard(
                                  label: 'Test Drives',
                                  valor: totalTestDrives.toString(),
                                  icon: Icons.electric_car_outlined,
                                  iconColor: const Color(0xFF10B981),
                                  bgColor: const Color(0xFFD1FAE5),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _KpiCard(
                                  label: 'Citas',
                                  valor: totalCitas.toString(),
                                  icon: Icons.event_available_outlined,
                                  iconColor: const Color(0xFFF59E0B),
                                  bgColor: const Color(0xFFFEF3C7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),

              // Barra de información del período actual
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      _filtroRango == null
                          ? 'Atenciones de Hoy (${DateFormat('dd MMMM yyyy', 'es').format(DateTime.now())})'
                          : 'Período: ${DateFormat('dd/MM/yyyy').format(_filtroRango!.start)} al ${DateFormat('dd/MM/yyyy').format(_filtroRango!.end)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF64748B)),
                      tooltip: 'Actualizar lista',
                      onPressed: _cargar,
                    ),
                  ],
                ),
              ),

              // Lista de Clientes con Diseño Ejecutivo
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                    : atenciones.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _filtroRango == null
                                      ? 'Aún no hay clientes registrados hoy'
                                      : 'No se encontraron atenciones en este rango',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Haz clic en "Nuevo Cliente" para comenzar a registrar visitas.',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: atenciones.length,
                            itemBuilder: (context, i) {
                              final a = atenciones[i];
                              final horaStr = DateFormat('HH:mm').format(a.fecha.toLocal());
                              final fechaStr = DateFormat('dd/MM').format(a.fecha.toLocal());

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      // Avatar con iniciales
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getIniciales(a.clienteNombre, a.clienteApellido),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Información del cliente
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '${a.clienteNombre} ${a.clienteApellido}'.trim(),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 15,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _filtroRango == null ? horaStr : '$fechaStr $horaStr',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF94A3B8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                // Asesor asignado
                                                _InfoChip(
                                                  icon: Icons.person_outline,
                                                  label: (a.asesorNombre != null && a.asesorNombre!.isNotEmpty) ? a.asesorNombre! : 'Sin asesor',
                                                  color: const Color(0xFF475569),
                                                  bgColor: const Color(0xFFF1F5F9),
                                                ),

                                                // Test drive
                                                if (a.testDrive)
                                                  const _InfoChip(
                                                    icon: Icons.electric_bolt,
                                                    label: 'Test Drive',
                                                    color: Color(0xFF15803D),
                                                    bgColor: Color(0xFFDCFCE7),
                                                  ),

                                                // Cita
                                                if (a.cita)
                                                  const _InfoChip(
                                                    icon: Icons.event,
                                                    label: 'Con Cita',
                                                    color: Color(0xFF0369A1),
                                                    bgColor: Color(0xFFE0F2FE),
                                                  ),

                                                // Acompañantes
                                                if (a.numAcompanantes > 0)
                                                  _InfoChip(
                                                    icon: Icons.group_outlined,
                                                    label: '+${a.numAcompanantes} pers.',
                                                    color: const Color(0xFFB45309),
                                                    bgColor: const Color(0xFFFEF3C7),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Acciones: Contactar, Editar y Eliminar
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.phone_in_talk_outlined, size: 19, color: Color(0xFF16A34A)),
                                            tooltip: 'Contactar al cliente',
                                            onPressed: () => _contactarCliente(a),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 19, color: Color(0xFF64748B)),
                                            tooltip: 'Editar información',
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
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 19, color: Color(0xFFEF4444)),
                                            tooltip: 'Eliminar registro',
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Eliminar Cliente'),
                                                  content: Text('¿Estás seguro de eliminar el registro de ${a.clienteNombre} ${a.clienteApellido}?\nEsta acción actualizará tus métricas de inmediato.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Cancelar'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                                      child: const Text('Eliminar'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await SupabaseService.deleteAtencion(a.id!);
                                                _cargar();
                                              }
                                            },
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
      ),
      floatingActionButton: isWeb
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistroScreen()),
                );
                _cargar();
              },
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }
}

// Botón de ícono elegante para la barra superior
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// Tarjeta KPI Ejecutiva
class _KpiCard extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String? subtitulo;
  final String? badge;

  const _KpiCard({
    required this.label,
    required this.valor,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.subtitulo,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Chip de Información en la lista de clientes
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
