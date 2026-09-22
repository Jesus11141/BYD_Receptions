class Vehiculo {
  final String? id;
  final String modelo;
  final String color;
  final String chasis;
  final String? placa;
  final int kilometraje;
  final String ubicacion; // 'Showroom', 'Test Drive', 'Terraza'
  final String? novedades;
  final DateTime? fecha;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vehiculo({
    this.id,
    required this.modelo,
    required this.color,
    required this.chasis,
    this.placa,
    this.kilometraje = 0,
    this.ubicacion = 'Showroom',
    this.novedades,
    this.fecha,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'modelo': modelo,
    'color': color,
    'chasis': chasis.toUpperCase().trim(),
    'placa': placa?.toUpperCase().trim() ?? '',
    'kilometraje': kilometraje,
    'ubicacion': ubicacion,
    'novedades': novedades ?? '',
    if (fecha != null) 'fecha': "${fecha!.year.toString().padLeft(4, '0')}-${fecha!.month.toString().padLeft(2, '0')}-${fecha!.day.toString().padLeft(2, '0')}",
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
    id: json['id']?.toString(),
    modelo: json['modelo']?.toString() ?? '',
    color: json['color']?.toString() ?? '',
    chasis: (json['chasis']?.toString() ?? '').toUpperCase(),
    placa: json['placa']?.toString(),
    kilometraje: json['kilometraje'] is int
        ? json['kilometraje']
        : int.tryParse(json['kilometraje']?.toString() ?? '0') ?? 0,
    ubicacion: json['ubicacion']?.toString() ?? 'Showroom',
    novedades: json['novedades']?.toString(),
    fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha']) : null,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
  );

  Vehiculo copyWith({
    String? id,
    String? modelo,
    String? color,
    String? chasis,
    String? placa,
    int? kilometraje,
    String? ubicacion,
    String? novedades,
    DateTime? fecha,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehiculo(
      id: id ?? this.id,
      modelo: modelo ?? this.modelo,
      color: color ?? this.color,
      chasis: chasis ?? this.chasis,
      placa: placa ?? this.placa,
      kilometraje: kilometraje ?? this.kilometraje,
      ubicacion: ubicacion ?? this.ubicacion,
      novedades: novedades ?? this.novedades,
      fecha: fecha ?? this.fecha,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
