import 'package:flutter/material.dart';
import '../models/atencion.dart';
import '../services/supabase_service.dart';

class EditarAtencionScreen extends StatefulWidget {
  final Atencion atencion;

  const EditarAtencionScreen({super.key, required this.atencion});

  @override
  State<EditarAtencionScreen> createState() => _EditarAtencionScreenState();
}

class _EditarAtencionScreenState extends State<EditarAtencionScreen> {
  final nombre = TextEditingController();
  final cedula = TextEditingController();
  final telefono = TextEditingController();
  final correo = TextEditingController();
  final acompanantes = TextEditingController();
  final notas = TextEditingController();
  late bool testDrive;
  late bool cita;

  @override
  void initState() {
    super.initState();
    nombre.text = '${widget.atencion.clienteNombre} ${widget.atencion.clienteApellido}'.trim();
    cedula.text = widget.atencion.cedula;
    telefono.text = widget.atencion.telefono;
    correo.text = widget.atencion.correo;
    acompanantes.text = widget.atencion.numAcompanantes.toString();
    testDrive = widget.atencion.testDrive;
    cita = widget.atencion.cita;
    notas.text = widget.atencion.notas ?? '';
  }

  Future<void> _guardar() async {
    final textoNombre = nombre.text.trim();
    String n = textoNombre.isEmpty ? 'Sin nombre' : textoNombre;
    String a = '';
    final partes = textoNombre.split(RegExp(r'\s+'));
    if (partes.length > 1) {
      n = partes[0];
      a = partes.sublist(1).join(' ');
    }

    await SupabaseService.updateAtencionCompleta(
      widget.atencion.id!,
      n,
      a,
      cedula.text.isEmpty ? 'N/A' : cedula.text,
      telefono.text.isEmpty ? 'N/A' : telefono.text,
      correo.text.isEmpty ? 'N/A' : correo.text,
      int.tryParse(acompanantes.text) ?? 0,
      testDrive,
      cita,
      notas.text.isEmpty ? null : notas.text,
    );
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Asesor: ${widget.atencion.asesorNombre}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text('Personas: ${widget.atencion.totalPersonas}',
                          style: const TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                controller: cedula,
                decoration: const InputDecoration(
                  labelText: 'Cédula',
                  prefixIcon: Icon(Icons.credit_card),
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
                maxLines: 3,
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
                onPressed: _guardar,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
