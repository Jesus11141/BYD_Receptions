import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/asesor.dart';
import '../models/atencion.dart';
import '../services/supabase_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final nombre = TextEditingController();
  final cedula = TextEditingController();
  final telefono = TextEditingController();
  final correo = TextEditingController();
  final acompanantes = TextEditingController(text: '0');
  final notas = TextEditingController();
  bool testDrive = false;
  bool cita = false;
  String? asesorId;
  List<Asesor> asesores = [];

  Atencion? _clienteEncontrado;
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _cargarAsesores();
  }

  Future<void> _cargarAsesores() async {
    asesores = await SupabaseService.getAsesores();
    if (asesores.isNotEmpty) asesorId = asesores.first.id;
    setState(() {});
  }

  Future<void> _registrar() async {
    if (asesorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un asesor')),
      );
      return;
    }

    final asesorSeleccionado = asesores.firstWhere((a) => a.id == asesorId);

    final textoNombre = nombre.text.trim();
    String n = textoNombre.isEmpty ? 'Sin nombre' : textoNombre;
    String a = '';
    final partes = textoNombre.split(RegExp(r'\s+'));
    if (partes.length > 1) {
      n = partes[0];
      a = partes.sublist(1).join(' ');
    }

    final atencion = Atencion(
      fecha: DateTime.now(),
      clienteNombre: n,
      clienteApellido: a,
      cedula: cedula.text.isEmpty ? 'N/A' : cedula.text,
      telefono: telefono.text.isEmpty ? 'N/A' : telefono.text,
      correo: correo.text.isEmpty ? 'N/A' : correo.text,
      numAcompanantes: int.tryParse(acompanantes.text) ?? 0,
      testDrive: testDrive,
      cita: cita,
      notas: notas.text.isEmpty ? null : notas.text,
      asesorId: asesorId!,
      asesorNombre: asesorSeleccionado.nombre,
    );

    await SupabaseService.addAtencion(atencion);
    
    if (mounted) {
      FocusScope.of(context).unfocus();
      _limpiar();
      _rotarAsesor();
      _mostrarDialogoExitoYWhatsApp(asesorSeleccionado, atencion);
    }
  }

  Future<void> _abrirWhatsApp(String phone, String text) async {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '593${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('593') && cleaned.length == 9) {
      cleaned = '593$cleaned';
    }

    final nativeUri = Uri.parse('whatsapp://send?phone=$cleaned&text=${Uri.encodeComponent(text)}');
    final webUri = Uri.parse('https://wa.me/$cleaned?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
      // Intento directo por si canLaunchUrl reporta falso por permisos de visibilidad
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

  Future<void> _mostrarDialogoExitoYWhatsApp(Asesor asesor, Atencion atencion) async {
    final clienteCompleto = '${atencion.clienteNombre} ${atencion.clienteApellido}'.trim();
    final testDriveTxt = atencion.testDrive ? ' ⚡ Viene por Test Drive.' : '';
    final citaTxt = atencion.cita ? ' 📅 Con Cita agendada.' : '';
    final mensaje = 'Hola ${asesor.nombre}, tu cliente *$clienteCompleto* acaba de llegar a recepción.$testDriveTxt$citaTxt Te está esperando en sala.';

    final telController = TextEditingController(text: asesor.telefono ?? '');
    bool tieneTelefono = asesor.telefono != null && asesor.telefono!.trim().isNotEmpty;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
              SizedBox(width: 10),
              Text('Cliente Registrado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asignado a: ${asesor.nombre}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                'Cliente: $clienteCompleto',
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const Divider(height: 24),
              if (!tieneTelefono) ...[
                Text(
                  '${asesor.nombre} aún no tiene WhatsApp registrado. Escribe su número una sola vez para guardarlo:',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: telController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp del Asesor',
                    hintText: 'Ej. 0991234567',
                    prefixIcon: Icon(Icons.phone, color: Color(0xFF16A34A)),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final numFinal = telController.text.trim();
                    if (numFinal.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Ingresa un número para enviar WhatsApp')),
                      );
                      return;
                    }
                    if (!tieneTelefono) {
                      await SupabaseService.updateAsesorTelefono(asesor.id, numFinal);
                    }
                    Navigator.pop(ctx);
                    await _abrirWhatsApp(numFinal, mensaje);
                  },
                  icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                  label: Text('Avisar a ${asesor.nombre} por WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar / No avisar', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buscarPorCedula(String valor) async {
    final query = valor.trim();
    if (query.isEmpty || query == 'N/A') {
      setState(() => _clienteEncontrado = null);
      return;
    }

    setState(() => _buscando = true);

    try {
      final cliente = await SupabaseService.buscarClientePorCedula(query);
      if (!mounted) return;

      setState(() {
        _clienteEncontrado = cliente;
      });

      if (cliente != null) {
        nombre.text = '${cliente.clienteNombre} ${cliente.clienteApellido}'.trim();
        telefono.text = cliente.telefono;
        correo.text = cliente.correo;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cliente encontrado: ${cliente.clienteNombre} ${cliente.clienteApellido}'),
            backgroundColor: const Color(0xFF0284C7),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error buscando cliente: $e');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _limpiar() {
    nombre.clear();
    cedula.clear();
    telefono.clear();
    correo.clear();
    acompanantes.text = '0';
    notas.clear();
    testDrive = false;
    cita = false;
    _clienteEncontrado = null;
    setState(() {});
  }

  void _rotarAsesor() async {
    if (asesores.length <= 1) return;
    final siguienteIndex = (asesores.indexWhere((a) => a.id == asesorId) + 1) % asesores.length;
    asesorId = asesores[siguienteIndex].id;
    setState(() {});
  }

  Widget _buildTarjetaClienteRecurrente() {
    if (_clienteEncontrado == null) return const SizedBox.shrink();

    final nombreAnterior = _clienteEncontrado!.asesorNombre?.trim() ?? '';
    final nombreLower = nombreAnterior.toLowerCase();

    // Comprobar si el asesor anterior está disponible en la lista de hoy
    final Asesor? asesorDisponible = asesores.cast<Asesor?>().firstWhere(
      (a) => a != null && (
        (a.id == _clienteEncontrado!.asesorId && _clienteEncontrado!.asesorId.isNotEmpty) ||
        (nombreLower.isNotEmpty && nombreLower != 'sin asesor' && a.nombre.trim().toLowerCase() == nombreLower)
      ),
      orElse: () => null,
    );

    final bool yaAsignado = asesorDisponible != null && asesorId == asesorDisponible.id;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF0284C7), size: 18),
              const SizedBox(width: 6),
              const Text(
                'Cliente Recurrente Detectado',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1), fontSize: 13),
              ),
              const Spacer(),
              Text(
                'Última visita: ${DateFormat('dd/MM/yyyy').format(_clienteEncontrado!.fecha)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Último asesor: ${nombreAnterior.isNotEmpty ? nombreAnterior : "No registrado"}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          if (asesorDisponible != null) ...[
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: yaAsignado
                      ? null
                      : () {
                          setState(() => asesorId = asesorDisponible.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Asignado a su asesor anterior: ${asesorDisponible.nombre}'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  icon: Icon(yaAsignado ? Icons.check_circle : Icons.person_pin, size: 16),
                  label: Text(
                    yaAsignado ? 'Asignado a ${asesorDisponible.nombre}' : 'Asignar a ${asesorDisponible.nombre}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yaAsignado ? Colors.green : const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'O puedes elegir otro asesor abajo libremente.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$nombreAnterior no está disponible hoy en la cola (faltó o está ausente). Puedes asignarle cualquier otro asesor en el selector de abajo.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Registro de Clientes', style: TextStyle(fontWeight: FontWeight.bold))),
      body: asesores.isEmpty
          ? const Center(child: Text('No hay asesores disponibles', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. Cédula al principio para búsqueda y autorrelleno
                      TextFormField(
                        controller: cedula,
                        decoration: InputDecoration(
                          labelText: 'Cédula / Documento',
                          prefixIcon: const Icon(Icons.credit_card),
                          suffixIcon: _buscando
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search),
                                  tooltip: 'Buscar cliente',
                                  onPressed: () => _buscarPorCedula(cedula.text),
                                ),
                          hintText: 'Ingresa la cédula para autorrellenar',
                        ),
                        onChanged: (value) {
                          if (value.length >= 10) {
                            _buscarPorCedula(value);
                          } else if (value.isEmpty && _clienteEncontrado != null) {
                            setState(() => _clienteEncontrado = null);
                          }
                        },
                        onFieldSubmitted: (value) => _buscarPorCedula(value),
                      ),

                      // Tarjeta inteligente con asesor previo y botón de 1 clic
                      _buildTarjetaClienteRecurrente(),

                      const SizedBox(height: 12),

                      // 2. Selector de Asesor (siempre editable por si el asesor faltó o se cambia libremente)
                      DropdownButtonFormField<String>(
                        value: asesorId,
                        decoration: const InputDecoration(
                          labelText: 'Asesor asignado',
                          prefixIcon: Icon(Icons.person_outline),
                          helperText: 'Puedes cambiar el asesor en cualquier momento',
                        ),
                        items: asesores.map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.nombre),
                        )).toList(),
                        onChanged: (v) => setState(() => asesorId = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nombre,
                        decoration: const InputDecoration(
                          labelText: 'Nombre y Apellido',
                          hintText: 'Ej. Raul Hidalgo',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: telefono,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: correo,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: acompanantes,
                        decoration: const InputDecoration(
                          labelText: 'Acompañantes',
                          prefixIcon: Icon(Icons.group),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notas,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Test Drive', style: TextStyle(fontWeight: FontWeight.w500)),
                        value: testDrive,
                        onChanged: (v) => setState(() => testDrive = v),
                        activeColor: const Color(0xFF38BDF8),
                      ),
                      SwitchListTile(
                        title: const Text('Cita', style: TextStyle(fontWeight: FontWeight.w500)),
                        value: cita,
                        onChanged: (v) => setState(() => cita = v),
                        activeColor: const Color(0xFF38BDF8),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _registrar,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Registrar Cliente'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
