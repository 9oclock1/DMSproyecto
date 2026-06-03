import 'package:flutter/material.dart';

/// Represents the result of a single DMS frame analysis.
/// Replaces the Map that was received from the Python WebSocket.
class DmsResult {
  final String status;
  final Color color;
  final double eyeOpenProbability; // replaces EAR (0.0 = closed, 1.0 = open)
  final double mar; // Mouth Aspect Ratio
  final double pitch; // Head pitch angle in degrees
  final String? objectDetection; // detected distraction label (e.g., "cell phone")
  final bool seatbeltDetected;   // false = no seatbelt visible

  const DmsResult({
    required this.status,
    required this.color,
    required this.eyeOpenProbability,
    required this.mar,
    required this.pitch,
    this.objectDetection,
    this.seatbeltDetected = true, // assume OK until detected otherwise
  });

  /// Default "driving normally" state.
  factory DmsResult.normal() => const DmsResult(
        status: 'Estatus: Conduciendo Normal',
        color: Color(0xFF43A047),
        eyeOpenProbability: 1.0,
        mar: 0.0,
        pitch: 0.0,
        seatbeltDetected: true,
      );
}
