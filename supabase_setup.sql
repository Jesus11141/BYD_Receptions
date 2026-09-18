-- Script SQL para configurar las tablas en Supabase
-- Ejecuta esto en el SQL Editor de tu proyecto Supabase

-- Tabla de asesores
CREATE TABLE asesores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre TEXT NOT NULL,
  orden_llegada TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de atenciones
CREATE TABLE atenciones (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fecha TIMESTAMP WITH TIME ZONE NOT NULL,
  cliente_nombre TEXT NOT NULL,
  cliente_apellido TEXT NOT NULL,
  cedula TEXT NOT NULL,
  telefono TEXT NOT NULL,
  correo TEXT NOT NULL,
  num_acompanantes INTEGER NOT NULL DEFAULT 0,
  total_personas INTEGER NOT NULL,
  test_drive BOOLEAN NOT NULL DEFAULT FALSE,
  notas TEXT,
  asesor_id UUID REFERENCES asesores(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX idx_asesores_orden ON asesores(orden_llegada);
CREATE INDEX idx_atenciones_fecha ON atenciones(fecha);
CREATE INDEX idx_atenciones_asesor ON atenciones(asesor_id);

-- Habilitar Row Level Security (RLS)
ALTER TABLE asesores ENABLE ROW LEVEL SECURITY;
ALTER TABLE atenciones ENABLE ROW LEVEL SECURITY;

-- Políticas para permitir todas las operaciones (ajusta según tus necesidades de seguridad)
CREATE POLICY "Permitir todo en asesores" ON asesores FOR ALL USING (true);
CREATE POLICY "Permitir todo en atenciones" ON atenciones FOR ALL USING (true);
