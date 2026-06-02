import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/dms_result.dart';
import '../services/dms_engine.dart';

/// Controls the camera and DMS engine — all processing happens on-device.
/// No WebSocket, no server, no IP address needed.
class DmsController extends GetxController {
  CameraController? cameraController;
  CameraDescription? _camera;
  final RxBool isCameraReady = false.obs;
  final RxString cameraError = ''.obs;

  /// The latest DMS analysis result, observed by the UI widgets.
  final Rx<DmsResult> currentResult = DmsResult.normal().obs;

  late final DmsEngine _dmsEngine;
  bool _isProcessingFrame = false;
  int _frameCount = 0;

  @override
  void onInit() {
    super.onInit();
    _dmsEngine = DmsEngine();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        cameraError.value = "No cameras found on this device";
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
        // ML Kit expects NV21 on Android, BGRA8888 on iOS
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await cameraController!.initialize();
      isCameraReady.value = true;

      cameraController!.startImageStream((image) {
        _processFrame(image);
      });
    } catch (e) {
      debugPrint("Camera init error: $e");
      cameraError.value = e.toString();
    }
  }

  void _processFrame(CameraImage image) {
    if (_isProcessingFrame) return;

    _frameCount++;
    // Process 1 frame out of 3 for good balance between responsiveness and CPU usage
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
      currentResult.value = result;
    } catch (e) {
      debugPrint("Frame processing error: $e");
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    _dmsEngine.dispose();
    super.onClose();
  }
}
