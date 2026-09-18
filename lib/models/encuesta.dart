class Encuesta {
  final String? id;
  final DateTime fecha;
  final String nombre;
  final String apellido;
  final String celular;
  final bool pendiente;
  final String calificacion;
  final bool recibiBebida;
  final bool ofrecieronTestDrive;
  final bool asesorResolvioDudas;
  final String? comoMejorar;
  final String? asesor;

  Encuesta({
    this.id,
    required this.fecha,
    required this.nombre,
    required this.apellido,
    required this.celular,
    this.pendiente = true,
    required this.calificacion,
    required this.recibiBebida,
    required this.ofrecieronTestDrive,
    required this.asesorResolvioDudas,
    this.comoMejorar,
    this.asesor,
  });

  Map<String, dynamic> toJson() => {
    'fecha': fecha.toIso8601String(),
    'nombre': nombre,
    'apellido': apellido,
    'celular': celular,
    'calificacion': calificacion,
    'recibi_bebida': recibiBebida,
    'ofrecieron_test_drive': ofrecieronTestDrive,
    'asesor_resolvio_dudas': asesorResolvioDudas,
    'como_mejorar': comoMejorar,
    'asesor': asesor,
  };

  factory Encuesta.fromJson(Map<String, dynamic> json) => Encuesta(
    id: json['id']?.toString(),
    fecha: DateTime.tryParse(json['fecha']?.toString() ?? '') ?? DateTime.now(),
    nombre: json['nombre']?.toString() ?? '',
    apellido: json['apellido']?.toString() ?? '',
    celular: json['celular']?.toString() ?? '',
    pendiente: json['pendiente'] == true,
    calificacion: json['calificacion']?.toString() ?? '',
    recibiBebida: json['recibi_bebida'] == true,
    ofrecieronTestDrive: json['ofrecieron_test_drive'] == true,
    asesorResolvioDudas: json['asesor_resolvio_dudas'] == true,
    comoMejorar: json['como_mejorar']?.toString(),
    asesor: json['asesor']?.toString(),
  );
}
