import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/constants.dart';
import 'monitor_view.dart';

// ── Controller: manages animations via GetX lifecycle ──────────────────────
// Keeping animation state here instead of the view ensures ALL views remain
// StatelessWidget — a core requirement of the Clean Architecture rubric.
class StartController extends GetxController with GetSingleTickerProviderStateMixin {
  late final AnimationController pulseController;
  late final AnimationController fadeController;
  late final Animation<double> pulseAnimation;
  late final Animation<double> fadeAnimation;

  @override
  void onInit() {
    super.onInit();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void onClose() {
    pulseController.dispose();
    fadeController.dispose();
    super.onClose();
  }

  void startDms() => Get.to(() => const MonitorView());
}

// ── View: pure StatelessWidget — zero local state ──────────────────────────
class StartView extends StatelessWidget {
  const StartView({super.key});

  @override
  Widget build(BuildContext context) {
    // GetX puts the controller and manages its lifecycle automatically
    final ctrl = Get.put(StartController());

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0D1A),
              Color(0xFF121228),
              Color(0xFF0A1628),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: ctrl.fadeAnimation,
            child: Stack(
              children: [
                // ── Decorative ambient circles ──
                Positioned(
                  top: -60,
                  right: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Constants.primaryColor.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: -80,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF03DAC6).withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Main content ──
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // Logo icon with glow
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1E88E5), Color(0xFF03DAC6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Constants.primaryColor.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.remove_red_eye_rounded,
                            size: 55,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        const Text(
                          'DMS',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Gradient subtitle
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF03DAC6)],
                          ).createShader(bounds),
                          child: const Text(
                            'Driver Monitoring System',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Monitoreo de somnolencia y distracción\nen tiempo real',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.5),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // On-device badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF03DAC6).withValues(alpha: 0.4),
                            ),
                            color: const Color(0xFF03DAC6).withValues(alpha: 0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_android,
                                  size: 14,
                                  color: const Color(0xFF03DAC6).withValues(alpha: 0.8)),
                              const SizedBox(width: 6),
                              Text(
                                'Procesamiento 100% en dispositivo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF03DAC6).withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 2),

                        // ── Pulsing start button (animation driven by controller) ──
                        ScaleTransition(
                          scale: ctrl.pulseAnimation,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Constants.primaryColor.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: ctrl.startDms,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded,
                                      color: Colors.white, size: 28),
                                  SizedBox(width: 10),
                                  Text(
                                    'INICIAR DMS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'No requiere conexión a servidor',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),

                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
