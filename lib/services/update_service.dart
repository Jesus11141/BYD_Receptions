import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateService {
  /// Compara dos versiones semánticas (ej: "1.0.2" vs "1.0.1").
  /// Retorna true si [remote] es mayor que [local].
  static bool isNewerVersion(String remote, String local) {
    try {
      final remoteClean = remote.split('+').first.trim();
      final localClean = local.split('+').first.trim();

      List<int> rParts = remoteClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> lParts = localClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      while (rParts.length < 3) {
        rParts.add(0);
      }
      while (lParts.length < 3) {
        lParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (rParts[i] > lParts[i]) return true;
        if (rParts[i] < lParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifica si existe una nueva versión en Supabase y pregunta si desea actualizar.
  static Future<void> verificarActualizacion(BuildContext context, {bool silencioso = true}) async {
    if (kIsWeb || !Platform.isAndroid) {
      if (!silencioso && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las actualizaciones automáticas aplican únicamente en la app móvil Android.')),
        );
      }
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Consultar la versión más reciente en Supabase
      final response = await Supabase.instance.client
          .from('app_version')
          .select()
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        if (!silencioso && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay registro de versiones en el servidor.')),
          );
        }
        return;
      }

      final String remoteVersion = (response['version'] ?? '').toString().trim();
      final String apkUrl = (response['apk_url'] ?? '').toString().trim();
      final String novedades = (response['novedades'] ?? 'Mejoras generales y corrección de errores.').toString();

      if (isNewerVersion(remoteVersion, currentVersion)) {
        if (context.mounted) {
          _mostrarDialogoActualizacion(context, currentVersion, remoteVersion, apkUrl, novedades);
        }
      } else {
        if (!silencioso && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ya tienes la versión más reciente (v$currentVersion).')),
          );
        }
      }
    } catch (e) {
      if (!silencioso && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar actualización: $e')),
        );
      }
    }
  }

  static void _mostrarDialogoActualizacion(
    BuildContext context,
    String versionActual,
    String nuevaVersion,
    String apkUrl,
    String novedades,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.system_update_alt, color: Color(0xFF0284C7), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Nueva Versión Disponible',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se encontró la versión v$nuevaVersion (tu versión actual: v$versionActual).',
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
            const SizedBox(height: 12),
            const Text('Novedades:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(novedades, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Más tarde', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Actualizar Ahora'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _iniciarDescargaEInstalacion(context, apkUrl);
            },
          ),
        ],
      ),
    );
  }

  static void _iniciarDescargaEInstalacion(BuildContext context, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (progressCtx) => _DownloadProgressDialog(apkUrl: apkUrl),
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final String apkUrl;
  const _DownloadProgressDialog({required this.apkUrl});

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  int _progress = 0;
  String _statusText = 'Iniciando descarga...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startOta();
  }

  void _startOta() {
    try {
      OtaUpdate().execute(widget.apkUrl, destinationFilename: 'byd_update.apk').listen(
        (OtaEvent event) {
          if (!mounted) return;
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _progress = int.tryParse(event.value ?? '0') ?? 0;
                _statusText = 'Descargando actualización: $_progress%';
                break;
              case OtaStatus.INSTALLING:
                _statusText = '¡Descarga completa! Abriendo instalador...';
                break;
              case OtaStatus.INSTALLATION_DONE:
                _statusText = 'Instalación finalizada.';
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                _errorMessage = 'Ya hay una descarga en proceso.';
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                _errorMessage = 'Permiso no otorgado para instalar aplicaciones desconocidas.';
                break;
              case OtaStatus.INTERNAL_ERROR:
                _errorMessage = 'Error interno al descargar la actualización.';
                break;
              case OtaStatus.DOWNLOAD_ERROR:
                _errorMessage = 'Error de conexión durante la descarga.';
                break;
              case OtaStatus.CHECKSUM_ERROR:
                _errorMessage = 'Error de verificación en el archivo descargado.';
                break;
              case OtaStatus.INSTALLATION_ERROR:
                _errorMessage = 'No se pudo iniciar la instalación del archivo.';
                break;
              default:
                break;
            }
          });

          if (event.status == OtaStatus.INSTALLING) {
            // Se abrirá la pantalla nativa de Android
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.of(context).pop();
            });
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Error al actualizar: $e';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo iniciar la actualización: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        hasError ? 'Error de Actualización' : 'Actualizando BYD Recepción',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasError) ...[
            LinearProgressIndicator(
              value: _progress > 0 ? _progress / 100.0 : null,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF0284C7),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Text(
              _statusText,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        if (hasError)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
            child: const Text('Cerrar'),
          ),
      ],
    );
  }
}
