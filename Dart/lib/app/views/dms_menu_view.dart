import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import 'monitor_view.dart';

class DmsMenuView extends ConsumerWidget {
  const DmsMenuView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Constants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SISTEMA DMS",
                        style: TextStyle(
                          color: Constants.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Panel de Control",
                        style: TextStyle(
                          color: Constants.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Constants.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Constants.border),
                    ),
                    child: Icon(
                      Icons.shield,
                      color: Constants.accent,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ── Botón Principal: INICIAR MONITOREO (solid, no gradient) ──
              GestureDetector(
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const MonitorView())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Constants.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.center_focus_strong,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "INICIAR MONITOREO",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Activar cámara e IA en tiempo real",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),

              const Text(
                "PROPÓSITO DEL PROYECTO",
                style: TextStyle(
                  color: Constants.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Constants.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Constants.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: Constants.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Prevención Inteligente",
                          style: TextStyle(
                            color: Constants.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Este sistema DMS (Driver Monitoring System) fue diseñado para mitigar los riesgos viales causados por el factor humano. "
                      "Utilizando algoritmos avanzados de Visión Artificial, el software analiza los vectores del rostro del conductor "
                      "para medir el nivel de apertura ocular (EAR) y gesticulación bucal (MAR).\n\n"
                      "Ante cualquier signo crítico de fatiga, somnolencia o distracción prolongada, el sistema emite una alerta auditiva restrictiva "
                      "que obliga al conductor a reaccionar para salvaguardar su vida.",
                      style: TextStyle(
                        color: Constants.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ── MÓDULOS DE SEGURIDAD ──
              const Text(
                "MÓDULOS DE SEGURIDAD",
                style: TextStyle(
                  color: Constants.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFeatureCard(
                    icon: Icons.remove_red_eye,
                    title: "Detector EAR",
                    desc: "Análisis de parpadeo y ojos cerrados.",
                    accentColor: Constants.accent,
                  ),
                  const SizedBox(width: 16),
                  _buildFeatureCard(
                    icon: Icons.face,
                    title: "Detector MAR",
                    desc: "Identificación de bostezos frecuentes.",
                    accentColor: const Color(0xFF9575CD),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Pie de página
              const Center(
                child: Text(
                  "Desarrollado para Ingeniería • v1.0.0",
                  style: TextStyle(
                    color: Constants.textTertiary,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Constants.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Constants.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Constants.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(
                color: Constants.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
