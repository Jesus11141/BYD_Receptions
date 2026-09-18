import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/encuesta.dart';
import '../models/atencion.dart';
import '../services/supabase_service.dart';
import '../services/pdf_service.dart';

class EncuestaScreen extends StatefulWidget {
  const EncuestaScreen({super.key});

  @override
  State<EncuestaScreen> createState() => _EncuestaScreenState();
}

class _EncuestaScreenState extends State<EncuestaScreen> {
  // Lista de clientes pendientes
  List<Encuesta> pendientes = [];
  bool cargando = false;
  DateTime fecha = DateTime.now();

  // Buscar clientes de atenciones
  List<Atencion> clientesBuscados = [];
  DateTime fechaBusqueda = DateTime.now();
  bool cargandoBusqueda = false;
  bool mostrarBusqueda = false;

  bool get _esHoy {
    final hoy = DateTime.now();
    return fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
  }

  // Controladores para agregar cliente
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _asesorFormCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _celularCtrl.dispose();
    _asesorFormCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    pendientes = await SupabaseService.getEncuestasPorFecha(fecha);
    setState(() => cargando = false);
  }

  Future<void> _buscarClientesPorFecha() async {
    setState(() => cargandoBusqueda = true);
    clientesBuscados = await SupabaseService.getAtencionesByDate(fechaBusqueda);
    setState(() => cargandoBusqueda = false);
  }

  Future<void> _cambiarFechaBusqueda() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaBusqueda,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      fechaBusqueda = picked;
      _buscarClientesPorFecha();
    }
  }

  Future<void> _cambiarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      fecha = picked;
      _cargar();
    }
  }

  Future<void> _generarPdf() async {
    final respondidas = pendientes.where((e) => !e.pendiente).toList();
    if (respondidas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay encuestas respondidas para generar PDF')),
      );
      return;
    }
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
                Text('Generando PDF...'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      await PdfService.generarReporteEncuestas(fecha, respondidas);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF descargado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }

  Future<void> _agregarCliente() async {
    if (_nombreCtrl.text.isEmpty || _apellidoCtrl.text.isEmpty || _celularCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa nombre, apellido y celular')),
      );
      return;
    }
    await SupabaseService.addEncuestaPendiente(
      _nombreCtrl.text.trim(),
      _apellidoCtrl.text.trim(),
      _celularCtrl.text.trim(),
      asesor: _asesorFormCtrl.text.trim(),
    );
    _nombreCtrl.clear();
    _apellidoCtrl.clear();
    _celularCtrl.clear();
    _asesorFormCtrl.clear();
    _cargar();
  }

  Future<void> _responderEncuesta(Encuesta cliente) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DialogEncuesta(cliente: cliente, onGuardado: _cargar, modoEdicion: false),
    );
  }

  Future<void> _verEncuesta(Encuesta cliente) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DialogEncuesta(cliente: cliente, onGuardado: _cargar, modoEdicion: true),
    );
  }

  Future<void> _eliminarPendiente(String id) async {
    await SupabaseService.deleteEncuesta(id);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Encuestas de Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
            label: Text(
              '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: _cambiarFecha,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generar PDF',
            onPressed: _generarPdf,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Formulario para agregar cliente (solo hoy)
              if (_esHoy)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Registrar cliente para encuesta',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    if (isWeb)
                      Row(children: [
                        Expanded(child: TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _apellidoCtrl, decoration: const InputDecoration(labelText: 'Apellido'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _celularCtrl, decoration: const InputDecoration(labelText: 'Celular'), keyboardType: TextInputType.phone)),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _asesorFormCtrl, decoration: const InputDecoration(labelText: 'Asesor'))),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(onPressed: _agregarCliente, icon: const Icon(Icons.add), label: const Text('Agregar')),
                      ])
                    else ...[
                      TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                      const SizedBox(height: 8),
                      TextField(controller: _apellidoCtrl, decoration: const InputDecoration(labelText: 'Apellido')),
                      const SizedBox(height: 8),
                      TextField(controller: _celularCtrl, decoration: const InputDecoration(labelText: 'Celular'), keyboardType: TextInputType.phone),
                      const SizedBox(height: 8),
                      TextField(controller: _asesorFormCtrl, decoration: const InputDecoration(labelText: 'Asesor')),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _agregarCliente, icon: const Icon(Icons.add), label: const Text('Agregar a lista'))),
                    ],
                  ],
                ),
              ),

              // Buscar clientes de atenciones por fecha
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.search, color: Color(0xFF0F172A)),
                      title: const Text('Buscar clientes registrados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      trailing: Icon(mostrarBusqueda ? Icons.expand_less : Icons.expand_more),
                      onTap: () {
                        setState(() => mostrarBusqueda = !mostrarBusqueda);
                        if (mostrarBusqueda && clientesBuscados.isEmpty) _buscarClientesPorFecha();
                      },
                    ),
                    if (mostrarBusqueda) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(fechaBusqueda),
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _cambiarFechaBusqueda,
                              child: const Text('Cambiar fecha'),
                            ),
                            const SizedBox(width: 8),
                            if (cargandoBusqueda)
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          ],
                        ),
                      ),
                      if (clientesBuscados.isEmpty && !cargandoBusqueda)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text('No hay clientes registrados en esa fecha', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ...clientesBuscados.map((a) => ListTile(
                          dense: true,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF334155),
                            radius: 16,
                            child: Icon(Icons.person, color: Colors.white, size: 16),
                          ),
                          title: Text('${a.clienteNombre} ${a.clienteApellido}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('Tel: ${a.telefono}  ·  Asesor: ${a.asesorNombre ?? '-'}', style: const TextStyle(fontSize: 12)),
                          trailing: Text(DateFormat('HH:mm').format(a.fecha), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          onTap: () {
                            _nombreCtrl.text = a.clienteNombre;
                            _apellidoCtrl.text = a.clienteApellido;
                            _celularCtrl.text = a.telefono;
                            _asesorFormCtrl.text = a.asesorNombre ?? '';
                            setState(() => mostrarBusqueda = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${a.clienteNombre} ${a.clienteApellido} cargado')),
                            );
                          },
                        )),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),

              // Lista encuestas
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      _esHoy ? 'Clientes de hoy' : 'Encuestas del ${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    if (cargando) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (pendientes.isEmpty && !cargando)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No hay clientes', style: TextStyle(color: Colors.grey))),
                )
              else
                ...pendientes.map((c) {
                  final respondido = !c.pendiente;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: respondido ? const Color(0xFFF0FDF4) : Colors.white,
                    child: ListTile(
                      onTap: respondido ? () => _verEncuesta(c) : () => _responderEncuesta(c),
                      leading: CircleAvatar(
                        backgroundColor: respondido ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                        child: Icon(
                          respondido ? Icons.check : Icons.hourglass_empty,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text('${c.nombre} ${c.apellido}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(respondido
                          ? '${c.celular} · ${c.calificacion}${c.asesor != null && c.asesor!.isNotEmpty ? ' · ${c.asesor}' : ''}'
                          : '${c.celular}${c.asesor != null && c.asesor!.isNotEmpty ? ' · ${c.asesor}' : ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!respondido)
                            const Icon(Icons.chevron_right, color: Color(0xFF38BDF8)),
                          if (respondido)
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _eliminarPendiente(c.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogEncuesta extends StatefulWidget {
  final Encuesta cliente;
  final VoidCallback onGuardado;
  final bool modoEdicion;

  const _DialogEncuesta({required this.cliente, required this.onGuardado, required this.modoEdicion});

  @override
  State<_DialogEncuesta> createState() => _DialogEncuestaState();
}

class _DialogEncuestaState extends State<_DialogEncuesta> {
  late String? calificacion;
  late bool? recibiBebida;
  late bool? ofrecieronTestDrive;
  late bool? asesorResolvioDudas;
  late TextEditingController _mejorarCtrl;
  late TextEditingController _asesorCtrl;
  bool guardando = false;
  late bool editando;
  bool _editandoActivo = false;

  @override
  void initState() {
    super.initState();
    editando = widget.modoEdicion;
    _editandoActivo = false;
    final c = widget.cliente;
    calificacion = c.calificacion.isEmpty ? null : c.calificacion;
    recibiBebida = widget.modoEdicion ? c.recibiBebida : null;
    ofrecieronTestDrive = widget.modoEdicion ? c.ofrecieronTestDrive : null;
    asesorResolvioDudas = widget.modoEdicion ? c.asesorResolvioDudas : null;
    _mejorarCtrl = TextEditingController(text: c.comoMejorar ?? '');
    _asesorCtrl = TextEditingController(text: c.asesor ?? '');
  }

  @override
  void dispose() {
    _mejorarCtrl.dispose();
    _asesorCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (calificacion == null || recibiBebida == null || ofrecieronTestDrive == null || asesorResolvioDudas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor responde todas las preguntas')),
      );
      return;
    }
    setState(() => guardando = true);
    final encuesta = Encuesta(
      fecha: widget.cliente.fecha,
      nombre: widget.cliente.nombre,
      apellido: widget.cliente.apellido,
      celular: widget.cliente.celular,
      calificacion: calificacion!,
      recibiBebida: recibiBebida!,
      ofrecieronTestDrive: ofrecieronTestDrive!,
      asesorResolvioDudas: asesorResolvioDudas!,
      comoMejorar: _mejorarCtrl.text.trim().isEmpty ? null : _mejorarCtrl.text.trim(),
      asesor: _asesorCtrl.text.trim().isEmpty ? null : _asesorCtrl.text.trim(),
    );
    await SupabaseService.saveEncuesta(encuesta, widget.cliente.id!);
    widget.onGuardado();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final soloLectura = editando && !_editandoActivo;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${widget.cliente.nombre} ${widget.cliente.apellido}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(widget.cliente.celular, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                if (editando && !_editandoActivo)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                    onPressed: () => setState(() => _editandoActivo = true),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Asesor
            TextField(
              controller: _asesorCtrl,
              readOnly: soloLectura,
              decoration: const InputDecoration(
                labelText: 'Asesor',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Pregunta 1
            const Text('¿Cómo calificaría la atención que recibió en nuestra agencia?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OpcionBtn(label: 'Buena', selected: calificacion == 'Buena',
                    onTap: soloLectura ? () {} : () => setState(() => calificacion = 'Buena')),
                _OpcionBtn(label: 'Muy Buena', selected: calificacion == 'Muy Buena',
                    onTap: soloLectura ? () {} : () => setState(() => calificacion = 'Muy Buena')),
                _OpcionBtn(label: 'Mala', selected: calificacion == 'Mala',
                    onTap: soloLectura ? () {} : () => setState(() => calificacion = 'Mala'), isNegative: true),
              ],
            ),
            const SizedBox(height: 16),

            // Pregunta 2
            _preguntaSiNoConectado(
              '¿Durante su visita recibió una bebida de cortesía?',
              recibiBebida,
              soloLectura,
              (v) => setState(() => recibiBebida = v),
            ),
            // Pregunta 3
            _preguntaSiNoConectado(
              '¿Le ofrecieron realizar un Test Drive?',
              ofrecieronTestDrive,
              soloLectura,
              (v) => setState(() => ofrecieronTestDrive = v),
            ),
            // Pregunta 4
            _preguntaSiNoConectado(
              '¿El asesor resolvió todas sus dudas sobre los vehículos?',
              asesorResolvioDudas,
              soloLectura,
              (v) => setState(() => asesorResolvioDudas = v),
            ),

            // Pregunta 5
            const Text('¿Cómo podemos mejorar nuestro servicio?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _mejorarCtrl,
              maxLines: 3,
              readOnly: soloLectura,
              decoration: InputDecoration(
                hintText: soloLectura ? (widget.cliente.comoMejorar?.isEmpty ?? true ? 'Sin comentarios' : null) : 'Escribe aquí (opcional)...',
              ),
            ),
            const SizedBox(height: 24),

            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                if (!soloLectura)
                  ElevatedButton(
                    onPressed: guardando ? null : _guardar,
                    child: guardando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _preguntaSiNoConectado(String texto, bool? valor, bool soloLectura, ValueChanged<bool> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _OpcionBtn(label: 'Sí', selected: valor == true, onTap: soloLectura ? () {} : () => onChanged(true)),
            _OpcionBtn(label: 'No', selected: valor == false, onTap: soloLectura ? () {} : () => onChanged(false)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _OpcionBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isNegative;

  const _OpcionBtn({required this.label, required this.selected, required this.onTap, this.isNegative = false});

  @override
  Widget build(BuildContext context) {
    final color = isNegative ? const Color(0xFFEF4444) : const Color(0xFF0F172A);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
