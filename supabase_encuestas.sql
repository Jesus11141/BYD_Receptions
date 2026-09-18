-- Tabla de encuestas de satisfacción de clientes
CREATE TABLE encuestas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fecha TIMESTAMP WITH TIME ZONE NOT NULL,
  nombre TEXT NOT NULL,
  apellido TEXT NOT NULL,
  celular TEXT NOT NULL,
  pendiente BOOLEAN NOT NULL DEFAULT TRUE,
  calificacion TEXT,           -- 'Buena', 'Muy Buena', 'Mala'
  recibi_bebida BOOLEAN,
  ofrecieron_test_drive BOOLEAN,
  asesor_resolvio_dudas BOOLEAN,
  como_mejorar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_encuestas_fecha ON encuestas(fecha);
CREATE INDEX idx_encuestas_pendiente ON encuestas(pendiente);

-- Habilitar Row Level Security
ALTER TABLE encuestas ENABLE ROW LEVEL SECURITY;

-- Política para permitir todas las operaciones
CREATE POLICY "Permitir todo en encuestas" ON encuestas FOR ALL USING (true);
