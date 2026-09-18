import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/asesor.dart';
import '../services/supabase_service.dart';

class AsesoresScreen extends StatefulWidget {
  const AsesoresScreen({super.key});

  @override
  State<AsesoresScreen> createState() => _AsesoresScreenState();
}

class _AsesoresScreenState extends State<AsesoresScreen> {
  List<Asesor> asesores = [];
  final controllerNombre = TextEditingController();
  final controllerTelefono = TextEditingController();
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    controllerNombre.dispose();
    controllerTelefono.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    try {
      asesores = await SupabaseService.getAsesores();
    } catch (e) {
      debugPrint('Error cargando asesores: $e');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _agregar() async {
    final nombre = controllerNombre.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el nombre del asesor')),
      );
      return;
    }

    final telefono = controllerTelefono.text.trim();
    await SupabaseService.addAsesor(nombre, telefono: telefono.isNotEmpty ? telefono : null);
    controllerNombre.clear();
    controllerTelefono.clear();
    FocusScope.of(context).unfocus();
    _cargar();
  }

  Future<void> _editarTelefono(Asesor asesor) async {
    final telController = TextEditingController(text: asesor.telefono ?? '');
    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('WhatsApp de ${asesor.nombre}'),
        content: TextField(
          controller: telController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Celular / WhatsApp',
            hintText: 'Ej. 0991234567',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (guardado == true && telController.text.trim().isNotEmpty) {
      await SupabaseService.updateAsesorTelefono(asesor.id, telController.text.trim());
      _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp de ${asesor.nombre} actualizado')),
        );
      }
    }
  }

  Future<void> _eliminar(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Asesor'),
        content: Text('¿Eliminar a $nombre de la cola?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.deleteAsesor(id);
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cola de Asesores', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWeb ? 800 : double.infinity),
          child: Column(
            children: [
              // Formulario para agregar asesor con nombre y WhatsApp
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nuevo Asesor en Cola',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    if (isWeb)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: controllerNombre,
                              decoration: const InputDecoration(
                                labelText: 'Nombre del asesor',
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: controllerTelefono,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'WhatsApp / Celular',
                                hintText: 'Ej. 0991234567',
                                prefixIcon: Icon(Icons.phone),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _agregar,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          TextField(
                            controller: controllerNombre,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del asesor',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: controllerTelefono,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp / Celular',
                              hintText: 'Ej. 0991234567',
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _agregar,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar a la Cola'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Lista de asesores
              Expanded(
                child: cargando
                    ? const Center(child: CircularProgressIndicator())
                    : asesores.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay asesores en la cola actualmente',
                              style: TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: asesores.length,
                            itemBuilder: (context, i) {
                              final a = asesores[i];
                              final tieneTel = a.telefono != null && a.telefono!.isNotEmpty;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF0F172A),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    a.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        'Turno: ${DateFormat('HH:mm').format(a.ordenLlegada)}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(width: 10),
                                      InkWell(
                                        onTap: () => _editarTelefono(a),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 13,
                                              color: tieneTel ? const Color(0xFF16A34A) : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              tieneTel ? a.telefono! : 'Añadir WhatsApp',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: tieneTel ? const Color(0xFF16A34A) : Colors.blueGrey,
                                                decoration: tieneTel ? null : TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                                        tooltip: 'Editar WhatsApp',
                                        onPressed: () => _editarTelefono(a),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                        tooltip: 'Eliminar de la cola',
                                        onPressed: () => _eliminar(a.id, a.nombre),
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
    );
  }
}
