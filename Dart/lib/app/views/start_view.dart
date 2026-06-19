import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/constants.dart';
import 'monitor_view.dart';

class StartView extends ConsumerStatefulWidget {
  const StartView({super.key});

  @override
  ConsumerState<StartView> createState() => _StartViewState();
}

class _StartViewState extends ConsumerState<StartView>
    with TickerProviderStateMixin {
  late final AnimationController pulseController;
  late final AnimationController fadeController;
  late final Animation<double> pulseAnimation;
  late final Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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
  void dispose() {
    pulseController.dispose();
    fadeController.dispose();
    super.dispose();
  }

  void _startDms() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MonitorView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ── Logo icon (solid color, no gradient) ──
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Constants.accent,
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
                      color: Constants.textPrimary,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle (solid color, no ShaderMask)
                  const Text(
                    'Driver Monitoring System',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Constants.accent,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Monitoreo de somnolencia y distracción\nen tiempo real',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Constants.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // On-device badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Constants.accent.withValues(alpha: 0.3),
                      ),
                      color: Constants.accent.withValues(alpha: 0.08),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 14,
                          color: Constants.accent.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Procesamiento 100% en dispositivo',
                          style: TextStyle(
                            fontSize: 11,
                            color: Constants.accent.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Pulsing start button (solid color, no gradient) ──
                  ScaleTransition(
                    scale: pulseAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.accent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _startDms,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
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

                  const Text(
                    'No requiere conexión a servidor',
                    style: TextStyle(
                      fontSize: 12,
                      color: Constants.textTertiary,
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
