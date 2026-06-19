import 'package:flutter/material.dart';

class DmsResult {
  final String status;
  final Color color;
  final double eyeOpenProbability;
  final double mar;
  final double pitch;
  final String? objectDetection;
  final bool seatbeltDetected;

  const DmsResult({
    required this.status,
    required this.color,
    required this.eyeOpenProbability,
    required this.mar,
    required this.pitch,
    this.objectDetection,
    this.seatbeltDetected = true,
  });

  factory DmsResult.normal() => const DmsResult(
    status: 'Estatus: Conduciendo Normal',
    color: Color(0xFF43A047),
    eyeOpenProbability: 1.0,
    mar: 0.0,
    pitch: 0.0,
    seatbeltDetected: true,
  );
}
