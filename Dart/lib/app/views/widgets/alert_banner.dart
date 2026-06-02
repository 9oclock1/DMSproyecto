import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dms_controller.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final DmsController controller = Get.find<DmsController>();

    return Obx(() {
      final result = controller.currentResult.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: result.color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: result.color.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Text(
          result.status,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });
  }
}
