class Asesor {
  final String id;
  final String nombre;
  final String? telefono;
  final DateTime ordenLlegada;

  Asesor({
    required this.id,
    required this.nombre,
    this.telefono,
    required this.ordenLlegada,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'telefono': telefono,
    'orden_llegada': ordenLlegada.toIso8601String(),
  };

  factory Asesor.fromJson(Map<String, dynamic> json) => Asesor(
    id: json['id'],
    nombre: json['nombre'],
    telefono: json['telefono']?.toString(),
    ordenLlegada: DateTime.parse(json['orden_llegada']),
  );
}
