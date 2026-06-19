import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/dms_result.dart';
import '../services/dms_engine.dart';

class DmsNotifier extends ChangeNotifier {
  CameraController? cameraController;
  CameraDescription? _camera;
  bool isCameraReady = false;
  String cameraError = '';

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isAlarmPlaying = false;

  DmsResult currentResult = DmsResult.normal();

  late final DmsEngine _dmsEngine;
  bool _isProcessingFrame = false;
  int _frameCount = 0;

  DmsNotifier() {
    _dmsEngine = DmsEngine();
    _dmsEngine.init().then((_) => _initCamera());
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        cameraError = "No cameras found on this device";
        notifyListeners();
        return;
      }

      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        _camera!,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await cameraController!.initialize();
      isCameraReady = true;
      notifyListeners();

      cameraController!.startImageStream((image) {
        _processFrame(image);
      });
    } catch (e) {
      debugPrint("Camera init error: $e");
      cameraError = e.toString();
      notifyListeners();
    }
  }

  void _processFrame(CameraImage image) {
    if (_isProcessingFrame) return;

    _frameCount++;
    if (_frameCount % 3 != 0) return;

    _isProcessingFrame = true;
    _processFrameAsync(image).whenComplete(() {
      _isProcessingFrame = false;
    });
  }

  Future<void> _processFrameAsync(CameraImage image) async {
    try {
      final inputImage = _dmsEngine.convertCameraImage(image, _camera!);
      if (inputImage == null) return;

      final result = await _dmsEngine.processFrame(inputImage);

      // Si la alarma NO está sonando, actualizamos la pantalla con lo que diga la IA
      if (!isAlarmPlaying) {
        currentResult = result;
        notifyListeners();

        // Alarm when the engine reports critical events:
        // - Drowsiness (eyes closed > 1.3s)
        // - Smoking detected
        // - Phone distraction
        final statusLower = result.status.toLowerCase();
        if (statusLower.contains('dormido') ||
            statusLower.contains('fumando') ||
            statusLower.contains('telefono')) {
          playAlarma();
        }
      }
    } catch (e) {
      debugPrint("Frame processing error: $e");
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    _dmsEngine.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void playAlarma() async {
    if (!isAlarmPlaying) {
      isAlarmPlaying = true;
      notifyListeners();
      try {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('alarma.wav'));
      } catch (e) {
        debugPrint("Error al reproducir audio: $e");
        try {
          await _audioPlayer.play(AssetSource('assets/alarma.wav'));
        } catch (_) {}
      }
    }
  }

  void stopAlarma() async {
    if (isAlarmPlaying) {
      await _audioPlayer.stop();
      isAlarmPlaying = false;

      // Reseteamos el estado a normal para que la IA pueda volver a evaluar tus ojos de nuevo
      currentResult = DmsResult.normal();
      notifyListeners();
    }
  }
}
