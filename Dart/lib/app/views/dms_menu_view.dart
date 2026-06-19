import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'monitor_view.dart';

class DmsMenuView extends ConsumerWidget {
  const DmsMenuView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Colores premium para el diseño automotriz (Dark Mode)
    const primaryColor = Color(0xFF1E1E2E);
    const accentColor = Colors.cyanAccent;
    const cardColor = Color(0xFF2A2A40);

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Encabezado de la App
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SISTEMA DMS",
                        style: TextStyle(
                          color: accentColor.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Panel de Control",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.shield, color: accentColor, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 2. Botón Principal: INICIAR ESCANEO
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MonitorView()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.center_focus_strong, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "INICIAR MONITOREO",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Activar cámara e IA en tiempo real",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),

              // 3. SECCIÓN: "El Porqué del Proyecto"
              const Text(
                "PROPÓSITO DEL PROYECTO",
                style: TextStyle(
                  color: Colors.white70,
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
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: accentColor, size: 22),
                        SizedBox(width: 10),
                        Text(
                          "Prevención Inteligente",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Este sistema DMS (Driver Monitoring System) fue diseñado para mitigar los riesgos viales causados por el factor humano. "
                      "Utilizando algoritmos avanzados de Visión Artificial, el software analiza los vectores del rostro del conductor "
                      "para medir el nivel de apertura ocular (EAR) y gesticulación bucal (MAR).\n\n"
                      "Ante cualquier signo crítico de fatiga, somnolencia o distracción prolongada, el sistema emite una alerta auditiva restrictiva "
                      "que obliga al conductor a reaccionar para salvaguardar su vida.",
                      style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 4. SECCIÓN: Características del Sistema
              const Text(
                "MÓDULOS DE SEGURIDAD",
                style: TextStyle(
                  color: Colors.white70,
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
                    accentColor: accentColor,
                    cardColor: cardColor,
                  ),
                  const SizedBox(width: 16),
                  _buildFeatureCard(
                    icon: Icons.face, 
                    title: "Detector MAR",
                    desc: "Identificación de bostezos frecuentes.",
                    accentColor: Colors.purpleAccent,
                    cardColor: cardColor,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Pie de página elegante
              const Center(
                child: Text(
                  "Desarrollado para Ingeniería • v1.0.0",
                  style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 1.0),
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
    required Color cardColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}