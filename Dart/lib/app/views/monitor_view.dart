import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../providers/providers.dart';
import 'widgets/alert_banner.dart';
import 'widgets/metrics_panel.dart';

class MonitorView extends ConsumerWidget {
  const MonitorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(dmsControllerProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Capa de fondo: Previsualización de la cámara
          Builder(
            builder: (_) {
              if (controller.cameraError.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      "Error con la cámara:\n${controller.cameraError}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }
              if (!controller.isCameraReady ||
                  controller.cameraController == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                );
              }
              return CameraPreview(controller.cameraController!);
            },
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: controller.isAlarmPlaying
                      ? Colors.redAccent.withOpacity(
                          0.6,
                        ) // Parpadeo rojo en emergencia
                      : Colors.cyanAccent.withOpacity(
                          0.15,
                        ), // Brillo sutil normal
                  width: controller.isAlarmPlaying ? 6 : 3,
                ),
              ),
            ),
          ),

          // 2. Capa superior izquierda: Panel de métricas (EAR / MAR)
          const Positioned(top: 50, left: 20, child: MetricsPanel()),

          // 🔥 DETALLE PREMIUM 2: Indicador "IA ACTIVA" arriba a la derecha (Estilo Tesla)
          Positioned(
            top: 55,
            right: 70, // Espacio para que no choque con el botón de cerrar
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "IA ACTIVA",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Capa Dinámica: Slider inteligente para deslindar/apagar la alarma
          if (controller.isAlarmPlaying)
            Positioned(
              bottom: 140,
              left: 20,
              right: 20,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.startToEnd,
                onDismissed: (direction) {
                  controller.stopAlarma();
                },
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.shade700.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.check, color: Colors.white, size: 28),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 5),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.redAccent,
                          size: 26,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "DESLIZAR PARA APAGAR",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 55),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Capa inferior: Banner de alertas (Fatiga, Distracción, Normal)
          const Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: AlertBanner(),
          ),

          // 5. Capa superior derecha: Botón flotante para salir/volver atrás (Estilizado)
          Positioned(
            top: 45,
            right: 20,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 26),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
