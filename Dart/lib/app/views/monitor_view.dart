import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/dms_controller.dart';
import 'widgets/alert_banner.dart';
import 'widgets/metrics_panel.dart';

class MonitorView extends StatelessWidget {
  const MonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    final DmsController controller = Get.put(DmsController());

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          Obx(() {
            if (controller.cameraError.value.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    "Error con la cámara:\n${controller.cameraError.value}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  ),
                ),
              );
            }
            if (!controller.isCameraReady.value || controller.cameraController == null) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            return CameraPreview(controller.cameraController!);
          }),
          
          // Metrics UI Overlay
          Positioned(
            top: 50,
            left: 20,
            child: const MetricsPanel(),
          ),
          
          // Alert Banner Overlay
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: const AlertBanner(),
          ),
          
          // Back Button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Get.back(),
            ),
          )
        ],
      ),
    );
  }
}
