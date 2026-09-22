-- ========================================================
-- TABLA DE CONTROL DE VEHICULOS (SHOWROOM, TEST DRIVE, TERRAZA)
-- ========================================================

CREATE TABLE IF NOT EXISTS vehiculos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  modelo TEXT NOT NULL,
  color TEXT NOT NULL,
  chasis TEXT NOT NULL UNIQUE,
  placa TEXT DEFAULT '',
  kilometraje INT NOT NULL DEFAULT 0,
  ubicacion TEXT NOT NULL DEFAULT 'Showroom', -- 'Showroom', 'Test Drive', 'Terraza'
  novedades TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indices para busqueda rapida y filtros
CREATE INDEX IF NOT EXISTS idx_vehiculos_ubicacion ON vehiculos(ubicacion);
CREATE INDEX IF NOT EXISTS idx_vehiculos_chasis ON vehiculos(chasis);

-- Habilitar Row Level Security (RLS)
ALTER TABLE vehiculos ENABLE ROW LEVEL SECURITY;

-- Politica para permitir lectura, insercion, actualizacion y borrado anonimo
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'vehiculos' AND policyname = 'Permitir todo en vehiculos'
  ) THEN
    CREATE POLICY "Permitir todo en vehiculos" ON vehiculos FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ========================================================
-- INSERCION DE LA FLOTA INICIAL (TERRAZA, TEST DRIVE, SHOWROOM)
-- ========================================================

INSERT INTO vehiculos (modelo, color, chasis, kilometraje, ubicacion, novedades)
VALUES
  -- TERRAZA
  ('BYD Atto 8', 'Plomo', 'LGXCE4CB2T2013783', 250, 'Terraza', 'NO SE PUEDE UTILIZAR'),
  ('BYD Atto 8', 'Blanco', 'LGXC74C46T0103543', 163, 'Terraza', 'NO SE PUEDE UTILIZAR'),
  ('BYD Song Plus', 'Blanco', 'LGXC74C4XT0076427', 114, 'Terraza', 'NO SE PUEDE UTILIZAR'),
  ('BYD E5', 'Blanco', 'LGXCE6CC4T0160171', 65, 'Terraza', ''),
  ('BYD Yuan Pro', 'Verde', 'LC0CE4CB7V4001185', 46, 'Terraza', ''),
  ('BYD Sealion', 'Negro', 'LGXCF4CD3V2022493', 62, 'Terraza', ''),
  ('BYD Yuan Pro DM-i', 'Negro', 'LC0C74C41V4005633', 75, 'Terraza', ''),
  ('BYD Yuan Pro', 'Blanco', 'LC0CE4CB7V4020013', 60, 'Terraza', ''),

  -- TEST DRIVE
  ('BYD Seagull', 'Negro', 'LGXCE4CC2S0082170', 7735, 'Test Drive', ''),
  ('BYD Yuan Pro', 'Negro', 'LC0CE4CB6T4007525', 5819, 'Test Drive', ''),
  ('BYD E5', 'Blanco', 'LGXCE66XT0160112', 3241, 'Test Drive', 'Prestado a un cliente de Alex - Karina Delgado'),
  ('BYD Shark', 'Blanco', 'LPE19W2A0TF027585', 6157, 'Test Drive', 'Esta en la Mitad del Mundo'),
  ('BYD Yuan Plus', 'Negro', 'LGXCE4CB1T2013774', 1866, 'Test Drive', 'Prestado a cliente de Andrea - Anita Ojeda'),
  ('BYD Song Plus', 'Blanco', 'LGXC74C44S0089706', 3974, 'Test Drive', ''),
  ('BYD Yuan Pro DM-i', 'Verde', 'LC0C74C44T4109496', 811, 'Test Drive', ''),
  ('BYD Atto 8', 'Plomo', 'LGXCD4C43T0127629', 8245, 'Test Drive', 'Tiene Marisol'),
  ('BYD Dolphin', 'Negro', 'LC0CE4CB5TH013745', 819, 'Test Drive', 'Prestado a cliente de Tomas - Ivonne de Montalvo'),
  ('BYD Tang TI 7', 'Blanco', 'LC0CD4C45V7009868', 1285, 'Test Drive', ''),
  ('BYD Sealion 7', 'Blanco', 'LGXCF4CD0T2011609', 15377, 'Test Drive', ''),

  -- SHOWROOM
  ('BYD Song Plus', 'Plomo', 'LGXC74C4XT0096354', 151, 'Showroom', ''),
  ('BYD Sealion 7', 'Negro', 'LGXCF4CD1T2129300', 131, 'Showroom', ''),
  ('BYD Atto 8', 'Plomo', 'LGXCD4C43V0029459', 106, 'Showroom', ''),
  ('BYD Yuan Plus', 'Negro', 'LGXCE4CB4V2012377', 63, 'Showroom', ''),
  ('BYD Dolphin', 'Plomo', 'LC0CE4CBXV0033149', 65, 'Showroom', ''),
  ('BYD Shark', 'Blanca', 'LPE19W2A0VF011678', 51, 'Showroom', ''),
  ('BYD Seagull', 'Azul', 'LGXCE4CC4V2026837', 44, 'Showroom', '')
ON CONFLICT (chasis) DO UPDATE SET
  kilometraje = EXCLUDED.kilometraje,
  ubicacion = EXCLUDED.ubicacion,
  novedades = EXCLUDED.novedades,
  updated_at = NOW();
