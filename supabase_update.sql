-- Script para actualizar la tabla atenciones
-- Ejecuta esto en el SQL Editor de Supabase

-- Agregar columna para guardar el nombre del asesor
ALTER TABLE atenciones ADD COLUMN IF NOT EXISTS asesor_nombre TEXT;

-- Actualizar registros existentes (opcional, si tienes datos)
UPDATE atenciones 
SET asesor_nombre = asesores.nombre 
FROM asesores 
WHERE atenciones.asesor_id = asesores.id 
AND atenciones.asesor_nombre IS NULL;
