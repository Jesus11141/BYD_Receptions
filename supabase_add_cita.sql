-- Script para agregar columna cita
-- Ejecuta esto en el SQL Editor de Supabase

ALTER TABLE atenciones ADD COLUMN IF NOT EXISTS cita BOOLEAN NOT NULL DEFAULT FALSE;
