class Atencion {
  final String? id;
  final DateTime fecha;
  final String clienteNombre;
  final String clienteApellido;
  final String cedula;
  final String telefono;
  final String correo;
  final int numAcompanantes;
  final bool testDrive;
  final bool cita;
  final String? notas;
  final String asesorId;
  final String? asesorNombre;

  Atencion({
    this.id,
    required this.fecha,
    required this.clienteNombre,
    required this.clienteApellido,
    required this.cedula,
    required this.telefono,
    required this.correo,
    required this.numAcompanantes,
    required this.testDrive,
    required this.cita,
    this.notas,
    required this.asesorId,
    this.asesorNombre,
  });

  int get totalPersonas => 1 + numAcompanantes;

  Map<String, dynamic> toJson() => {
    'fecha': fecha.toIso8601String(),
    'cliente_nombre': clienteNombre,
    'cliente_apellido': clienteApellido,
    'cedula': cedula,
    'telefono': telefono,
    'correo': correo,
    'num_acompanantes': numAcompanantes,
    'total_personas': totalPersonas,
    'test_drive': testDrive,
    'cita': cita,
    'notas': notas,
    'asesor_id': asesorId,
    'asesor_nombre': asesorNombre,
  };

  factory Atencion.fromJson(Map<String, dynamic> json) => Atencion(
    id: json['id'],
    fecha: DateTime.parse(json['fecha']),
    clienteNombre: json['cliente_nombre'],
    clienteApellido: json['cliente_apellido'],
    cedula: json['cedula'],
    telefono: json['telefono'],
    correo: json['correo'],
    numAcompanantes: json['num_acompanantes'],
    testDrive: json['test_drive'],
    cita: json['cita'] ?? false,
    notas: json['notas'],
    asesorId: json['asesor_id'],
    asesorNombre: json['asesor_nombre'],
  );
}
