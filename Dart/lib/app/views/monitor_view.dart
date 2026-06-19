import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import 'widgets/alert_banner.dart';
import 'widgets/metrics_panel.dart';
import 'widgets/lodging_tab.dart';

class MonitorView extends ConsumerWidget {
  const MonitorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(dmsControllerProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                        color: Constants.dangerColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }
              if (!controller.isCameraReady ||
                  controller.cameraController == null) {
                return Center(
                  child: CircularProgressIndicator(color: Constants.accent),
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
                      ? Constants.dangerColor.withValues(alpha: 0.6)
                      : Constants.accent.withValues(alpha: 0.15),
                  width: controller.isAlarmPlaying ? 6 : 3,
                ),
              ),
            ),
          ),

          // 2. Panel de métricas (EAR / MAR)
          const Positioned(top: 50, left: 20, child: MetricsPanel()),

          // Indicador "IA ACTIVA"
          Positioned(
            top: 55,
            right: 70,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Constants.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Constants.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Constants.successColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "IA ACTIVA",
                    style: TextStyle(
                      color: Constants.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                    color: Constants.successColor,
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
                    color: Constants.dangerColor,
                    borderRadius: BorderRadius.circular(30),
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
                          color: Constants.dangerColor,
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
          const Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: AlertBanner(),
          ),

          // ── Lodging tab: visible only during red alert ──
          if (controller.isAlarmPlaying)
            const Positioned(
              bottom: 220,
              right: 16,
              child: LodgingTab(),
            ),

          Positioned(
            top: 45,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Constants.surface,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Constants.textPrimary,
                  size: 26,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
