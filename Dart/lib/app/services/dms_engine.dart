import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../models/dms_result.dart';

class DmsEngine {
  late final FaceDetector _faceDetector;
  late final ObjectDetector _objectDetector;

  // ── Timing state (mirrors server.py logic) ──
  double _tiempoOjosCerrados = 0;
  double _tiempoBostezo = 0;
  double _tiempoCabeceo = 0;
  int _frameCount = 0;
  String? _alertaObjActual;

  // ── Thresholds (matching server.py) ──
  /// Eye-open probability below this → eyes considered closed.
  /// Equivalent to EAR < 0.22 in the Python version.
  static const double _umbralEyeOpen = 0.3;

  /// Mouth Aspect Ratio above this → yawning.
  static const double _umbralMar = 0.65;

  /// Head pitch above this → nodding/head down.
  static const double _umbralPitch = 25.0;

  /// Object detection runs every N processed frames (same as YOLO skip in server.py).
  static const int _saltoFramesObj = 10;

  // ── Alert colors ──
  static const _colorNormal = Color(0xFF43A047);
  static const _colorDanger = Color(0xFFE53935);
  static const _colorWarning = Color(0xFFFB8C00);

  DmsEngine() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true, // needed for MAR computation
        enableClassification: true, // needed for eye-open probability
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Camera → InputImage conversion
  // ═══════════════════════════════════════════════════════

  /// Converts a [CameraImage] to an ML Kit [InputImage].
  ///
  /// - Android: expects NV21 format (single plane).
  /// - iOS: expects BGRA8888 format (single plane).
  InputImage? convertCameraImage(CameraImage image, CameraDescription camera) {
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    final InputImageFormat format;
    if (Platform.isAndroid) {
      format = InputImageFormat.nv21;
    } else if (Platform.isIOS) {
      format = InputImageFormat.bgra8888;
    } else {
      return null; // Desktop not supported for on-device ML Kit
    }

    // Copy bytes to avoid camera buffer recycling issues
    final Uint8List bytes = Uint8List.fromList(image.planes[0].bytes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Main frame processing
  // ═══════════════════════════════════════════════════════

  /// Processes a single frame and returns a [DmsResult].
  /// This is the on-device equivalent of `DmsSession.process_frame()` in server.py.
  Future<DmsResult> processFrame(InputImage inputImage) async {
    _frameCount++;

    String estadoAlerta = 'Estatus: Conduciendo Normal';
    Color colorAlerta = _colorNormal;

    // ── Object detection (every N frames) ──
    String? objectDetection;
    if (_frameCount % _saltoFramesObj == 0) {
      try {
        final objects = await _objectDetector.processImage(inputImage);
        _alertaObjActual = null;

        for (final obj in objects) {
          for (final label in obj.labels) {
            // ML Kit base model categories:
            //   "Fashion good", "Food", "Home good", "Place", "Plant"
            // Mapping: "Home good" → potential phone, "Food" → potential drink.
            // NOTE: For more precise detection (specific "cell phone", "bottle"),
            //       replace the base model with a custom TFLite model.
            if (label.text == 'Home good' && label.confidence > 0.6) {
              _alertaObjActual = '!!! ALERTA: DISTRACCION POR OBJETO !!!';
              objectDetection = 'Objeto';
            } else if (label.text == 'Food' && label.confidence > 0.6) {
              _alertaObjActual = 'WARN: Consumiendo Bebida/Alimento';
              objectDetection = 'Bebida';
            }
          }
        }
      } catch (e) {
        debugPrint('Object detection error: $e');
      }
    }

    // ── Face detection ──
    String? alertaBiometrica;
    Color? colorBiometrica;
    double eyeOpenProb = 1.0;
    double mar = 0.0;
    double pitch = 0.0;

    try {
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;

        // ── Head pose (pitch) ──
        pitch = (face.headEulerAngleX ?? 0.0).abs();
        if (pitch > _umbralPitch) {
          final now = _nowSeconds();
          if (_tiempoCabeceo == 0) _tiempoCabeceo = now;
          if (now - _tiempoCabeceo > 0.5) {
            alertaBiometrica = '!!! ALERTA: CONDUCTOR CABECEANDO !!!';
            colorBiometrica = _colorDanger;
          }
        } else {
          _tiempoCabeceo = 0;
        }

        // ── Yawning (MAR from mouth contours) ──
        mar = _computeMar(face);
        if (mar > _umbralMar) {
          final now = _nowSeconds();
          if (_tiempoBostezo == 0) _tiempoBostezo = now;
          if (now - _tiempoBostezo > 0.8) {
            if (alertaBiometrica == null) {
              alertaBiometrica = '!!! ADVERTENCIA: BOSTEZO DETECTADO !!!';
              colorBiometrica = _colorWarning;
            }
          }
        } else {
          _tiempoBostezo = 0;
        }

        // ── Drowsiness (eye closure) ──
        final leftEye = face.leftEyeOpenProbability ?? 1.0;
        final rightEye = face.rightEyeOpenProbability ?? 1.0;
        eyeOpenProb = (leftEye + rightEye) / 2.0;

        if (eyeOpenProb < _umbralEyeOpen) {
          final now = _nowSeconds();
          if (_tiempoOjosCerrados == 0) _tiempoOjosCerrados = now;
          if (now - _tiempoOjosCerrados > 1.3) {
            // Highest priority alert
            alertaBiometrica = '!!! ALERTA CRITICA: CONDUCTOR DORMIDO !!!';
            colorBiometrica = _colorDanger;
          }
        } else {
          _tiempoOjosCerrados = 0;
        }
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
    }

    // ── Priority: biometric alerts > object alerts > normal ──
    if (alertaBiometrica != null) {
      estadoAlerta = alertaBiometrica;
      colorAlerta = colorBiometrica!;
    } else if (_alertaObjActual != null) {
      estadoAlerta = _alertaObjActual!;
      colorAlerta = _colorWarning;
    }

    return DmsResult(
      status: estadoAlerta,
      color: colorAlerta,
      eyeOpenProbability: eyeOpenProb,
      mar: mar,
      pitch: pitch,
      objectDetection: objectDetection,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Helpers
  // ═══════════════════════════════════════════════════════

  /// Computes the Mouth Aspect Ratio from ML Kit face contours.
  ///
  /// MAR = vertical mouth opening / horizontal mouth width
  /// - upperLipTop: ~11 points, center at index 5
  /// - lowerLipBottom: ~9 points, center at index 4
  double _computeMar(Face face) {
    final upperLipTop = face.contours[FaceContourType.upperLipTop]?.points;
    final lowerLipBottom =
        face.contours[FaceContourType.lowerLipBottom]?.points;

    if (upperLipTop == null || lowerLipBottom == null) return 0.0;
    if (upperLipTop.length < 11 || lowerLipBottom.length < 9) return 0.0;

    // Vertical: center of upper lip top ↔ center of lower lip bottom
    final upperCenter = upperLipTop[5];
    final lowerCenter = lowerLipBottom[4];
    final vertical = _distance(upperCenter, lowerCenter);

    // Horizontal: left corner ↔ right corner of upper lip
    final leftCorner = upperLipTop.first;
    final rightCorner = upperLipTop.last;
    final horizontal = _distance(leftCorner, rightCorner);

    if (horizontal == 0) return 0.0;
    return vertical / horizontal;
  }

  double _distance(Point<int> p1, Point<int> p2) {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
  }

  double _nowSeconds() => DateTime.now().millisecondsSinceEpoch / 1000.0;

  /// Release ML Kit resources.
  void dispose() {
    _faceDetector.close();
    _objectDetector.close();
  }
}
