import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/dms_result.dart';

const String _kModelAsset = 'assets/models/best_float16.tflite';

class DmsEngine {
  late final FaceDetector _faceDetector;
  ObjectDetector? _objectDetector;

  double _tiempoOjosCerrados = 0;
  double _tiempoBostezo = 0;
  double _tiempoCabeceo = 0;
  double _tiempoFumando = 0;
  double _tiempoComiendo = 0;
  double _tiempoTelefono = 0;
  int _frameCount = 0;
  String? _alertaObjActual;
  bool _cinturonVisto = false;
  int _framesSinCinturon = 0;
  static const int _maxFramesSinCinturon = 30;

  static const double _umbralEyeOpen = 0.3;

  static const double _umbralMar = 0.65;

  static const double _umbralPitch = 25.0;

  static const int _saltoFramesObj = 10;

  static const _colorNormal = Color(0xFF43A047);
  static const _colorDanger = Color(0xFFE53935);
  static const _colorWarning = Color(0xFFFB8C00);

  static const _phoneLabels = {
    'cell phone',
    'phone',
    'mobile phone',
    'celular',
    'laptop',
    'tablet',
  };
  static const _smokingLabels = {
    'cigarette',
    'cigar',
    'smoking',
    'cigarro',
    'vape',
    'e-cigarette',
  };
  static const _foodLabels = {
    'cup',
    'bottle',
    'wine glass',
    'fork',
    'knife',
    'spoon',
    'bowl',
    'food',
    'bebida',
    'sandwich',
    'pizza',
    'hamburger',
    'hot dog',
    'donut',
    'cake',
    'apple',
    'orange',
    'banana',
    'carrot',
    'broccoli',
  };
  static const _seatbeltLabels = {
    'seatbelt',
    'seat belt',
    'cinturon',
    'cinturón',
    'belt',
  };

  DmsEngine() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  Future<void> init() async {
    final modelPath = await _extractModelAsset();
    _objectDetector = ObjectDetector(
      options: LocalObjectDetectorOptions(
        modelPath: modelPath,
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
        maximumLabelsPerObject: 3,
        confidenceThreshold: 0.5,
      ),
    );
    debugPrint('[DmsEngine] Custom model loaded from: $modelPath');
  }

  Future<String> _extractModelAsset() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelFile = File(p.join(dir.path, 'best_float16.tflite'));

    if (!await modelFile.exists()) {
      final byteData = await rootBundle.load(_kModelAsset);
      await modelFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
      debugPrint('[DmsEngine] Model extracted to ${modelFile.path}');
    } else {
      debugPrint('[DmsEngine] Model already exists at ${modelFile.path}');
    }
    return modelFile.path;
  }

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

  Future<DmsResult> processFrame(InputImage inputImage) async {
    _frameCount++;

    String estadoAlerta = 'Estatus: Conduciendo Normal';
    Color colorAlerta = _colorNormal;

    // ── Object detection (every N frames) ──
    String? objectDetection;
    bool seatbeltDetected = true; // optimistic default

    if (_frameCount % _saltoFramesObj == 0 && _objectDetector != null) {
      try {
        final objects = await _objectDetector!.processImage(inputImage);

        // Reset object alert and seatbelt state for this detection pass
        _alertaObjActual = null;
        bool beltSeenThisFrame = false;

        for (final obj in objects) {
          for (final label in obj.labels) {
            final labelLower = label.text.toLowerCase().trim();

            // ── Seatbelt check ──
            if (_seatbeltLabels.contains(labelLower)) {
              beltSeenThisFrame = true;
              _cinturonVisto = true;
              _framesSinCinturon = 0;
            }

            // ── Phone / device ──
            if (_phoneLabels.contains(labelLower)) {
              final now = _nowSeconds();
              if (_tiempoTelefono == 0) _tiempoTelefono = now;
              if (now - _tiempoTelefono > 0.8) {
                _alertaObjActual = '!!! ALERTA: DISTRACCION CON TELEFONO !!!';
                objectDetection = label.text;
              }
            } else if (!_phoneLabels.contains(labelLower)) {
              _tiempoTelefono = 0;
            }

            // ── Smoking ──
            if (_smokingLabels.contains(labelLower) &&
                _alertaObjActual == null) {
              final now = _nowSeconds();
              if (_tiempoFumando == 0) _tiempoFumando = now;
              if (now - _tiempoFumando > 1.0) {
                _alertaObjActual = '!!! ALERTA: CONDUCTOR FUMANDO !!!';
                objectDetection = label.text;
              }
            } else if (!_smokingLabels.contains(labelLower)) {
              _tiempoFumando = 0;
            }

            // ── Eating / drinking ──
            if (_foodLabels.contains(labelLower) && _alertaObjActual == null) {
              final now = _nowSeconds();
              if (_tiempoComiendo == 0) _tiempoComiendo = now;
              if (now - _tiempoComiendo > 1.5) {
                _alertaObjActual = 'WARN: Conductor Comiendo/Bebiendo';
                objectDetection = label.text;
              }
            } else if (!_foodLabels.contains(labelLower)) {
              _tiempoComiendo = 0;
            }
          }
        }

        // ── Seatbelt absence tracking ──
        // Only start counting missing frames once we've confirmed the belt was
        // visible at least once (avoids false alarm at startup).
        if (_cinturonVisto && !beltSeenThisFrame) {
          _framesSinCinturon++;
        }
        if (_framesSinCinturon >= _maxFramesSinCinturon) {
          seatbeltDetected = false;
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

    // ── Priority: drowsy > nodding > smoking > phone > eating > seatbelt > yawn > normal ──
    if (alertaBiometrica != null) {
      estadoAlerta = alertaBiometrica;
      colorAlerta = colorBiometrica!;
    } else if (_alertaObjActual != null) {
      estadoAlerta = _alertaObjActual!;
      // Smoking and phone = danger; eating = warning
      colorAlerta =
          (_alertaObjActual!.contains('FUMANDO') ||
              _alertaObjActual!.contains('TELEFONO'))
          ? _colorDanger
          : _colorWarning;
    } else if (!seatbeltDetected) {
      estadoAlerta = '⚠ CINTURON DE SEGURIDAD NO DETECTADO';
      colorAlerta = _colorWarning;
    }

    return DmsResult(
      status: estadoAlerta,
      color: colorAlerta,
      eyeOpenProbability: eyeOpenProb,
      mar: mar,
      pitch: pitch,
      objectDetection: objectDetection,
      seatbeltDetected: seatbeltDetected,
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
    _objectDetector?.close();
  }
}
