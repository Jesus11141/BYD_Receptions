import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asesor.dart';
import '../models/atencion.dart';
import '../models/encuesta.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static Future<void> init(String url, String anonKey) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  // Asesores
  static Future<List<Asesor>> getAsesores() async {
    final data = await client.from('asesores').select().order('orden_llegada', ascending: true);
    return (data as List).map((e) => Asesor.fromJson(e)).toList();
  }

  static Future<void> addAsesor(String nombre, {String? telefono}) async {
    await client.from('asesores').insert({
      'nombre': nombre,
      if (telefono != null && telefono.trim().isNotEmpty) 'telefono': telefono.trim(),
      'orden_llegada': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateAsesorTelefono(String id, String telefono) async {
    await client.from('asesores').update({
      'telefono': telefono.trim(),
    }).eq('id', id);
  }

  static Future<void> deleteAsesor(String id) async {
    await client.from('asesores').delete().eq('id', id);
  }

  static Future<void> limpiarAsesores() async {
    await client.from('asesores').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  }

  static Future<void> limpiarAtencionesDia(DateTime fecha) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    await client.from('atenciones').delete()
        .gte('fecha', inicio.toIso8601String())
        .lt('fecha', fin.toIso8601String());
  }

  // Atenciones
  static Future<void> addAtencion(Atencion atencion) async {
    await client.from('atenciones').insert(atencion.toJson());
  }

  static Future<void> updateAtencion(String id, bool testDrive, String? notas) async {
    await client.from('atenciones').update({
      'test_drive': testDrive,
      'notas': notas,
    }).eq('id', id);
  }

  static Future<void> updateAtencionCompleta(
    String id,
    String nombre,
    String apellido,
    String cedula,
    String telefono,
    String correo,
    int numAcompanantes,
    bool testDrive,
    bool cita,
    String? notas,
  ) async {
    await client.from('atenciones').update({
      'cliente_nombre': nombre,
      'cliente_apellido': apellido,
      'cedula': cedula,
      'telefono': telefono,
      'correo': correo,
      'num_acompanantes': numAcompanantes,
      'total_personas': 1 + numAcompanantes,
      'test_drive': testDrive,
      'cita': cita,
      'notas': notas,
    }).eq('id', id);
  }

  static Future<void> deleteAtencion(String id) async {
    await client.from('atenciones').delete().eq('id', id);
  }

  static Future<Atencion?> buscarClientePorCedula(String cedula) async {
    if (cedula.isEmpty || cedula == 'N/A') return null;
    
    final data = await client
        .from('atenciones')
        .select()
        .eq('cedula', cedula)
        .order('fecha', ascending: false)
        .limit(1);
    
    if (data.isEmpty) return null;
    
    return Atencion(
      id: data[0]['id']?.toString(),
      fecha: DateTime.parse(data[0]['fecha']),
      clienteNombre: data[0]['cliente_nombre']?.toString() ?? '',
      clienteApellido: data[0]['cliente_apellido']?.toString() ?? '',
      cedula: data[0]['cedula']?.toString() ?? '',
      telefono: data[0]['telefono']?.toString() ?? '',
      correo: data[0]['correo']?.toString() ?? '',
      numAcompanantes: data[0]['num_acompanantes'] ?? 0,
      testDrive: data[0]['test_drive'] ?? false,
      cita: data[0]['cita'] ?? false,
      notas: data[0]['notas']?.toString(),
      asesorId: data[0]['asesor_id']?.toString() ?? '',
      asesorNombre: data[0]['asesor_nombre']?.toString() ?? 'Sin asesor',
    );
  }

  // Encuestas
  static Future<void> addEncuestaPendiente(String nombre, String apellido, String celular, {String? asesor}) async {
    await client.from('encuestas').insert({
      'fecha': DateTime.now().toIso8601String(),
      'nombre': nombre,
      'apellido': apellido,
      'celular': celular,
      'pendiente': true,
      if (asesor != null && asesor.isNotEmpty) 'asesor': asesor,
    });
  }

  static Future<List<Encuesta>> getEncuestasPorFecha(DateTime fecha) async {
    final inicioDelDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));
    final data = await client
        .from('encuestas')
        .select()
        .or('and(pendiente.eq.true,fecha.gte.${inicioDelDia.toIso8601String()},fecha.lt.${finDelDia.toIso8601String()}),and(pendiente.eq.false,fecha_respuesta.gte.${inicioDelDia.toIso8601String()},fecha_respuesta.lt.${finDelDia.toIso8601String()})')
        .order('fecha', ascending: true);
    return (data as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['pendiente'] = map['pendiente'] == true;
      map['recibi_bebida'] = map['recibi_bebida'] == true;
      map['ofrecieron_test_drive'] = map['ofrecieron_test_drive'] == true;
      map['asesor_resolvio_dudas'] = map['asesor_resolvio_dudas'] == true;
      return Encuesta.fromJson(map);
    }).toList();
  }

  static Future<void> saveEncuesta(Encuesta encuesta, String id) async {
    await client.from('encuestas').update({
      'calificacion': encuesta.calificacion,
      'recibi_bebida': encuesta.recibiBebida,
      'ofrecieron_test_drive': encuesta.ofrecieronTestDrive,
      'asesor_resolvio_dudas': encuesta.asesorResolvioDudas,
      'como_mejorar': encuesta.comoMejorar,
      'asesor': encuesta.asesor,
      'pendiente': false,
      'fecha_respuesta': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> deleteEncuesta(String id) async {
    await client.from('encuestas').delete().eq('id', id);
  }

  static Future<List<Atencion>> getAtencionesByMonth(int year, int month) async {
    final inicio = DateTime(year, month, 1);
    final fin = DateTime(year, month + 1, 1);

    final data = await client
        .from('atenciones')
        .select()
        .gte('fecha', inicio.toIso8601String())
        .lt('fecha', fin.toIso8601String())
        .order('fecha');

    return (data as List).map((e) {
      return Atencion(
        id: e['id']?.toString(),
        fecha: DateTime.parse(e['fecha']),
        clienteNombre: e['cliente_nombre']?.toString() ?? '',
        clienteApellido: e['cliente_apellido']?.toString() ?? '',
        cedula: e['cedula']?.toString() ?? '',
        telefono: e['telefono']?.toString() ?? '',
        correo: e['correo']?.toString() ?? '',
        numAcompanantes: e['num_acompanantes'] ?? 0,
        testDrive: e['test_drive'] ?? false,
        cita: e['cita'] ?? false,
        notas: e['notas']?.toString(),
        asesorId: e['asesor_id']?.toString() ?? '',
        asesorNombre: e['asesor_nombre']?.toString() ?? 'Sin asesor',
      );
    }).toList();
  }

  static Future<List<Atencion>> getAtencionesByDate(DateTime fecha) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    
    final data = await client
        .from('atenciones')
        .select()
        .gte('fecha', inicio.toIso8601String())
        .lt('fecha', fin.toIso8601String())
        .order('fecha');

    return (data as List).map((e) {
      return Atencion(
        id: e['id']?.toString(),
        fecha: DateTime.parse(e['fecha']),
        clienteNombre: e['cliente_nombre']?.toString() ?? '',
        clienteApellido: e['cliente_apellido']?.toString() ?? '',
        cedula: e['cedula']?.toString() ?? '',
        telefono: e['telefono']?.toString() ?? '',
        correo: e['correo']?.toString() ?? '',
        numAcompanantes: e['num_acompanantes'] ?? 0,
        testDrive: e['test_drive'] ?? false,
        cita: e['cita'] ?? false,
        notas: e['notas']?.toString(),
        asesorId: e['asesor_id']?.toString() ?? '',
        asesorNombre: e['asesor_nombre']?.toString() ?? 'Sin asesor',
      );
    }).toList();
  }

  static Future<List<Atencion>> getAtencionesByRange(DateTime start, DateTime end) async {
    final fin = end.add(const Duration(days: 1)); // Incluir el último día completo
    
    final data = await client
        .from('atenciones')
        .select()
        .gte('fecha', start.toIso8601String())
        .lt('fecha', fin.toIso8601String())
        .order('fecha', ascending: false);

    return (data as List).map((e) {
      return Atencion(
        id: e['id']?.toString(),
        fecha: DateTime.parse(e['fecha']),
        clienteNombre: e['cliente_nombre']?.toString() ?? '',
        clienteApellido: e['cliente_apellido']?.toString() ?? '',
        cedula: e['cedula']?.toString() ?? '',
        telefono: e['telefono']?.toString() ?? '',
        correo: e['correo']?.toString() ?? '',
        numAcompanantes: e['num_acompanantes'] ?? 0,
        testDrive: e['test_drive'] ?? false,
        cita: e['cita'] ?? false,
        notas: e['notas']?.toString(),
        asesorId: e['asesor_id']?.toString() ?? '',
        asesorNombre: e['asesor_nombre']?.toString() ?? 'Sin asesor',
      );
    }).toList();
  }
}
