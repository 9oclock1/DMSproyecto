import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dms_controller.dart';

class MetricsPanel extends StatelessWidget {
  const MetricsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final DmsController controller = Get.find<DmsController>();

    return Obx(() {
      final result = controller.currentResult.value;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricRow(
                "Ojos (prob.):", result.eyeOpenProbability.toStringAsFixed(2)),
            const SizedBox(height: 4),
            _buildMetricRow("MAR (Boca):", result.mar.toStringAsFixed(3)),
            const SizedBox(height: 4),
            _buildMetricRow(
                "Pitch (Cabeza):", result.pitch.toStringAsFixed(1)),
            if (result.objectDetection != null) ...[
              const SizedBox(height: 8),
              _buildMetricRow("Obj:", result.objectDetection!, isAlert: true),
            ]
          ],
        ),
      );
    });
  }

  Widget _buildMetricRow(String label, String value, {bool isAlert = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: isAlert ? Colors.orangeAccent : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
