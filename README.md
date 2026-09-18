# BYD Recepción

Sistema de gestión de recepción para concesionario BYD.

## Características

- ✅ Gestión de cola de asesores
- ✅ Registro de clientes con acompañantes
- ✅ Generación de reportes PDF
- ✅ Sincronización en tiempo real con Supabase
- ✅ Compatible con Web y Android

## Configuración

### 1. Crear proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com)
2. Crea una cuenta y un nuevo proyecto
3. Espera a que se inicialice (2-3 minutos)

### 2. Configurar base de datos

1. En tu proyecto Supabase, ve a **SQL Editor**
2. Copia y pega el contenido de `supabase_setup.sql`
3. Ejecuta el script

### 3. Obtener credenciales

1. Ve a **Settings** > **API**
2. Copia:
   - **Project URL** (ejemplo: https://xxxxx.supabase.co)
   - **anon public key** (empieza con eyJ...)

### 4. Configurar la app

Abre `lib/main.dart` y reemplaza:

```dart
await SupabaseService.init(
  'TU_SUPABASE_URL',        // Pega tu Project URL
  'TU_SUPABASE_ANON_KEY',   // Pega tu anon key
);
```

## Ejecutar

### Web
```bash
flutter run -d chrome
```

### Android
```bash
flutter run
```

## Uso

1. **Cola de Asesores**: Registra el orden de llegada de los asesores
2. **Registrar Cliente**: Captura datos del cliente y asigna al siguiente asesor
3. **Reportes**: Visualiza y genera PDF del reporte diario

## Estructura del Proyecto

```
lib/
├── models/          # Modelos de datos
├── services/        # Lógica de negocio
├── screens/         # Pantallas de la app
└── main.dart        # Punto de entrada
```
