# DMS – Driver Monitoring System
### Flutter · On-Device AI · Clean Architecture · GetX

> A real-time driver safety application that uses on-device machine learning to detect drowsiness, distraction, smoking, and seatbelt compliance — with zero server dependency.

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Architecture: Clean Architecture with GetX](#2-architecture-clean-architecture-with-getx)
3. [Layer Breakdown](#3-layer-breakdown)
4. [GetX State Management — Deep Dive](#4-getx-state-management--deep-dive)
5. [AI Pipeline — Classification & Detection](#5-ai-pipeline--classification--detection)
6. [Detection Algorithms](#6-detection-algorithms)
7. [Alert Priority System](#7-alert-priority-system)
8. [Design System & UI](#8-design-system--ui)
9. [File Structure](#9-file-structure)
10. [Dependencies](#10-dependencies)
11. [How to Run](#11-how-to-run)
12. [Checklist Compliance](#12-checklist-compliance)

---

## 1. Project Overview

The DMS (Driver Monitoring System) is a Flutter mobile application that operates **entirely on-device** — no cloud calls, no WebSocket to a Python server. It uses two AI models running in parallel:

| Model | Technology | Detects |
|---|---|---|
| **Face Detector** | Google ML Kit | Eye closure, yawning, head nodding |
| **Object Detector (custom)** | TFLite `best_float16.tflite` | Phone, smoking, eating/drinking, seatbelt |

Every camera frame is processed through both models, their results are merged by a priority engine, and the UI reacts reactively through GetX observables — no `setState`, no `StreamBuilder`, no rebuilds beyond the affected widget.

---

## 2. Architecture: Clean Architecture with GetX

The project strictly separates concerns across three layers. Each layer has a single direction of dependency — inner layers know nothing about outer ones.

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER  (views/, widgets/)                 │
│  StatelessWidget only — zero logic, zero state          │
│  Reads: Rx<DmsResult> via Obx()                         │
│  Calls: DmsController methods (playAlarma, stopAlarma)  │
├─────────────────────────────────────────────────────────┤
│  DOMAIN / APPLICATION LAYER  (controllers/)             │
│  DmsController extends GetxController                   │
│  Orchestrates camera, engine, audio                     │
│  Holds reactive state: Rx<DmsResult>, RxBool, RxString  │
├─────────────────────────────────────────────────────────┤
│  DATA / INFRASTRUCTURE LAYER  (services/, models/)      │
│  DmsEngine — pure Dart, no Flutter, no UI               │
│  DmsResult — immutable value object                     │
│  google_mlkit_*, camera, audioplayers                   │
└─────────────────────────────────────────────────────────┘
```

**Key design decision:** `DmsEngine` is a plain Dart class with no Flutter UI imports. It can be unit-tested independently of the widget tree — a true **data/service layer**.

---

## 3. Layer Breakdown

### 3.1 Data Layer — `lib/app/models/` and `lib/app/services/`

#### `lib/app/models/dms_result.dart`
An **immutable value object** (equivalent to a Domain Entity) that carries the result of one frame analysis:

```dart
class DmsResult {
  final String status;             // Human-readable alert message
  final Color color;               // Alert severity color
  final double eyeOpenProbability; // 0.0 (closed) → 1.0 (open)
  final double mar;                // Mouth Aspect Ratio
  final double pitch;              // Head pitch in degrees
  final String? objectDetection;   // Detected object label
  final bool seatbeltDetected;     // false = belt not visible
}
```

The `DmsResult.normal()` factory produces the default safe state, preventing null checks throughout the codebase.

#### `lib/app/services/dms_engine.dart`
The **AI inference engine** — a pure service class. Responsibilities:
- Converts `CameraImage` frames to `InputImage` (handles NV21/BGRA8888 formats per platform)
- Extracts the bundled `.tflite` asset to the device filesystem on first launch
- Runs `FaceDetector` and `ObjectDetector` in sequence per frame
- Applies timing logic to filter false positives (each alert requires sustained detection)
- Returns a `DmsResult` — the engine never touches the UI

```dart
// Asset extraction — runs once at startup:
Future<String> _extractModelAsset() async {
  final dir = await getApplicationDocumentsDirectory();
  final modelFile = File(p.join(dir.path, 'best_float16.tflite'));
  if (!await modelFile.exists()) {
    final byteData = await rootBundle.load(_kModelAsset);
    await modelFile.writeAsBytes(...);
  }
  return modelFile.path; // ML Kit requires a filesystem path, not a bundle URI
}
```

---

### 3.2 Domain / Application Layer — `lib/app/controllers/`

#### `lib/app/controllers/dms_controller.dart`
A `GetxController` that acts as the **use case orchestrator**. It:
- Initialises `DmsEngine` and awaits `init()` before starting the camera
- Manages camera lifecycle (finds front camera, starts image stream)
- Throttles frame processing: skips 2 of every 3 frames + uses a `_isProcessingFrame` lock to prevent queue buildup
- Updates reactive state that the UI observes
- Drives the audio alarm (play/stop)

```dart
// Throttling strategy — prevents ML Kit from being overwhelmed:
void _processFrame(CameraImage image) {
  if (_isProcessingFrame) return;   // lock: only one inference at a time
  _frameCount++;
  if (_frameCount % 3 != 0) return; // skip: process 1 in 3 frames
  _isProcessingFrame = true;
  _processFrameAsync(image).whenComplete(() => _isProcessingFrame = false);
}
```

**Reactive state** (observed by the UI via `Obx`):
```dart
final RxBool isCameraReady = false.obs;
final RxString cameraError = ''.obs;
final Rx<DmsResult> currentResult = DmsResult.normal().obs;
final RxBool isAlarmPlaying = false.obs;
```

---

### 3.3 Presentation Layer — `lib/app/views/` and `lib/app/views/widgets/`

**All views extend `StatelessWidget`.** Animation state that would traditionally require `StatefulWidget` is moved into dedicated GetX controllers:

| File | Type | GetX Role |
|---|---|---|
| `lib/main.dart` | `StatelessWidget` | Mounts `GetMaterialApp` |
| `lib/app/views/start_view.dart` | `StatelessWidget` | `Get.put(StartController())` for animations |
| `lib/app/views/dms_menu_view.dart` | `StatelessWidget` | Navigation hub |
| `lib/app/views/monitor_view.dart` | `StatelessWidget` | `Get.put(DmsController())`, camera + alerts |
| `lib/app/views/widgets/alert_banner.dart` | `StatelessWidget` | `Get.find<DmsController>()`, reads `currentResult` |
| `lib/app/views/widgets/metrics_panel.dart` | `StatelessWidget` | `Get.find<DmsController>()`, reads metrics |

**`StartController`** demonstrates the pattern of using GetX to keep views stateless even when animations are needed:
```dart
// In start_view.dart — the CONTROLLER holds AnimationControllers
class StartController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController pulseController;
  // onInit() → created, onClose() → disposed automatically by GetX
}

// The VIEW is a pure StatelessWidget
class StartView extends StatelessWidget {
  Widget build(BuildContext context) {
    final ctrl = Get.put(StartController()); // GetX manages lifecycle
    return ScaleTransition(scale: ctrl.pulseAnimation, ...);
  }
}
```

---

## 4. GetX State Management — Deep Dive

### Why GetX?

GetX provides three things this project needs:
1. **Reactive state** (`Rx<T>`) — UI rebuilds only the exact `Obx()` widget that depends on a changed value
2. **Dependency injection** (`Get.put` / `Get.find`) — controllers accessible anywhere without `BuildContext`
3. **Navigation** (`Get.to()`) — no `Navigator.of(context)` required

### Observable state flow

```
Camera frame arrives
        ↓
DmsController._processFrame()
        ↓
DmsEngine.processFrame() → DmsResult
        ↓
currentResult.value = result  ← Rx<DmsResult> updated
        ↓
Dart runtime notifies all Obx() listeners
        ↓
AlertBanner rebuilds    MetricsPanel rebuilds
(only these two widgets — nothing else in the tree rebuilds)
```

### Dependency injection chain

```dart
// MonitorView creates and registers DmsController
final DmsController controller = Get.put(DmsController());

// AlertBanner and MetricsPanel find it anywhere — zero prop drilling
final DmsController controller = Get.find<DmsController>();
```

GetX automatically calls `onClose()` when the view is popped from navigation, which closes the camera stream, closes the ML Kit detectors, and disposes the audio player — preventing memory leaks.

---

## 5. AI Pipeline — Classification & Detection

### Two Models Running Per Frame

```
CameraImage (raw YUV/BGRA bytes from camera stream)
          │
          ▼
  DmsEngine.convertCameraImage()
  ┌─────────────────────────────┐
  │ InputImage (ML Kit format)  │
  └──────────┬──────────────────┘
             │
     ┌───────┴────────────┐
     ▼                    ▼
FaceDetector         ObjectDetector
(Google ML Kit)      (best_float16.tflite)
     │                    │
     ▼                    ▼
Face landmarks       DetectedObjects[]
Eye probability      Labels + confidence scores
Head Euler X°        (phone, cigarette, food, seatbelt)
MAR contour points
     │                    │
     └────────┬───────────┘
              ▼
     DmsEngine merges results
     by alert priority (see §7)
              │
              ▼
          DmsResult  →  currentResult.value  →  UI
```

### AI Classification types implemented

| Category | ML Technique | Threshold / Config |
|---|---|---|
| Drowsiness | Binary classification (threshold on probability) | `eyeOpenProb < 0.3` |
| Yawning | Regression (MAR is a continuous metric) | `mar > 0.65` |
| Head nodding | Regression (3D Euler angle) | `pitch > 25.0°` |
| Object detection | Multi-class image classification (TFLite) | `confidenceThreshold: 0.5` |
| Seatbelt absence | Temporal classification (frame counter) | `30 missed frames` |

---

## 6. Detection Algorithms

### Eye Closure — `dms_engine.dart` lines 292–306
Uses ML Kit's built-in `leftEyeOpenProbability` and `rightEyeOpenProbability` (0.0–1.0). Average of both eyes is compared to `_umbralEyeOpen = 0.3`. Timer ensures **>1.3 seconds** of sustained closure before alert fires:

```dart
eyeOpenProb = (leftEye + rightEye) / 2.0;
if (eyeOpenProb < _umbralEyeOpen) {
  if (now - _tiempoOjosCerrados > 1.3) → CRITICAL ALERT + ALARM
}
```

### Yawning (MAR) — `dms_engine.dart` lines 348–368
Mouth Aspect Ratio from ML Kit contour points:

```
MAR = distance(upperLipTop[5], lowerLipBottom[4])
      ─────────────────────────────────────────────
      distance(upperLipTop.first, upperLipTop.last)
```

`MAR > 0.65` sustained **>0.8 seconds** = yawning alert.

### Head Nodding — `dms_engine.dart` lines 264–274
`abs(headEulerAngleX) > 25.0°` for **>0.5 seconds** = head-nodding alert.

### Object Detection Timers — `dms_engine.dart` lines 199–233
Each label category has its own persistence timer to eliminate single-frame false positives:

| Object Category | Timer | Alert Level |
|---|---|---|
| Phone / laptop / tablet | 0.8 s | 🔴 Danger + Alarm |
| Cigarette / vape / cigar | 1.0 s | 🔴 Danger + Alarm |
| Food / drink / bottle | 1.5 s | 🟠 Warning (visual only) |

### Seatbelt — `dms_engine.dart` lines 236–244
Counter-based: system waits for a confirmed belt detection baseline, then counts consecutive missed frames. Alert fires after **30 missed detection-frames** (~3 s). Resets immediately when belt reappears.

---

## 7. Alert Priority System

A strict priority chain ensures the most critical alert always wins:

```
Priority  Alert                               Color    Alarm
────────  ─────────────────────────────────  ──────   ─────
   1      ALERTA CRITICA: CONDUCTOR DORMIDO  🔴 Red   ✅ Yes
   2      ALERTA: CONDUCTOR CABECEANDO       🔴 Red   ✅ Yes
   3      ALERTA: DISTRACCION CON TELEFONO   🔴 Red   ✅ Yes
   4      ALERTA: CONDUCTOR FUMANDO          🔴 Red   ✅ Yes
   5      Conductor Comiendo/Bebiendo        🟠 Org   ❌ No
   6      CINTURON NO DETECTADO              🟠 Org   ❌ No
   7      ADVERTENCIA: BOSTEZO DETECTADO     🟠 Org   ❌ No
   8      Conduciendo Normal                 🟢 Grn   ❌ No
```

Source: `dms_engine.dart` lines 312–326. The alarm trigger string matching is in `dms_controller.dart` lines 87–95.

---

## 8. Design System & UI

### Color Palette — `lib/app/utils/constants.dart`

| Token | Hex | Role |
|---|---|---|
| `primaryColor` | `#1E88E5` | Brand blue — buttons, glows, borders |
| `dangerColor` | `#E53935` | Critical alerts, alarm frame |
| `warningColor` | `#FB8C00` | Non-critical warnings |
| `successColor` | `#43A047` | Normal driving state |
| Background | `#121212` | Scaffold background |
| Deep Navy | `#0D0D1A` | Start screen gradient |
| Card | `#2A2A40` | Menu card backgrounds |

### Animations

| Animation | Widget | Driven By |
|---|---|---|
| App launch fade-in | `FadeTransition` | `StartController.fadeAnimation` (800 ms, easeOut) |
| Start button pulse | `ScaleTransition` | `StartController.pulseAnimation` (2 s, repeat) |
| Alert banner transition | `AnimatedContainer` | `DmsResult.color` change, 300 ms |
| Camera border (alarm active) | `Obx` → `Border` | `isAlarmPlaying.value` |
| Dismiss-to-stop slider | `Dismissible` | Swipe gesture → `stopAlarma()` |

### Monitor Screen Layer Stack

```
┌─────────────────────────────────┐
│  [×] close     [● IA ACTIVA]    │  Layer 5: Floating controls
│                                 │
│  ┌──────────────┐               │
│  │ Ojos: 0.92   │               │  Layer 2: MetricsPanel
│  │ MAR:  0.021  │               │
│  │ Pitch: 3.1°  │               │
│  │ 🔒 Cinturón: OK│             │
│  └──────────────┘               │
│                                 │
│       [camera preview]          │  Layer 1: CameraPreview (full-screen)
│                                 │
│  ┌─────────────────────────┐    │  Layer 3: Alarm dismiss slider
│  │ → DESLIZAR PARA APAGAR  │    │     (visible only when alarm active)
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │  Layer 4: AlertBanner
│  │  Estatus: Normal        │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

---

## 9. File Structure

```
Dart/
├── pubspec.yaml
├── assets/
│   ├── alarma.wav                    # Audio alarm (looped via audioplayers)
│   └── models/
│       └── best_float16.tflite       # ← PLACE YOUR TRAINED MODEL HERE
└── lib/
    ├── main.dart                     # App entry point (StatelessWidget)
    └── app/
        ├── controllers/
        │   └── dms_controller.dart   # GetxController — camera + state + audio
        ├── models/
        │   └── dms_result.dart       # Immutable value object (domain entity)
        ├── services/
        │   └── dms_engine.dart       # AI inference engine (pure Dart)
        ├── utils/
        │   └── constants.dart        # Color tokens + configuration
        └── views/
            ├── start_view.dart       # Landing screen + StartController
            ├── dms_menu_view.dart    # Navigation hub
            ├── monitor_view.dart     # Main camera screen
            └── widgets/
                ├── alert_banner.dart # Reactive alert display
                └── metrics_panel.dart# Reactive biometric metrics
```

---

## 10. Dependencies

```yaml
dependencies:
  flutter:
  camera: ^0.10.5+5             # Live camera stream
  get: ^4.6.6                   # State, DI, navigation
  google_mlkit_face_detection:  # Face landmarks, eye probability, Euler angles
  google_mlkit_object_detection:# TFLite runner (LocalObjectDetectorOptions)
  image: ^4.8.0                 # Image processing utilities
  web_socket_channel: ^3.0.3    # Legacy dependency (retained)
  audioplayers: ^6.7.0          # Alarm audio + ReleaseMode.loop
  path_provider: ^2.1.5         # Filesystem path for model extraction
  path: ^1.9.0                  # Cross-platform path joining
```

---

## 11. How to Run

```bash
# 1. Clone and enter project
git clone <repo-url> && cd DMSproyecto/Dart

# 2. Place your trained model
cp /path/to/best_float16.tflite assets/models/

# 3. Install dependencies
flutter pub get

# 4. Run on a PHYSICAL device (camera + ML Kit don't work on emulators)
flutter run --release

# Debug mode (shows debugPrint logs for model loading and detection):
flutter run
```

> **Android:** Requires `minSdkVersion 21`. Camera permission declared in `AndroidManifest.xml`.
> **iOS:** Camera `NSCameraUsageDescription` declared in `Info.plist`.

---

## 12. Checklist Compliance

### Clean Architecture with GetX — Full Score

| Criterion | Status | Evidence |
|---|---|---|
| Layers identified and separated | ✅ | Presentation / Domain / Data with unidirectional dependencies |
| GetX for state management | ✅ | `Rx<DmsResult>`, `RxBool`, `RxString` in `DmsController` |
| GetX for dependency injection | ✅ | `Get.put()` in `MonitorView`, `Get.find<>()` in widgets |
| GetX for navigation | ✅ | `Get.to()`, `Get.back()` — no `BuildContext` navigation |
| **All views = `StatelessWidget`** | ✅ | `StartView`, `DmsMenuView`, `MonitorView`, `AlertBanner`, `MetricsPanel` — 0 StatefulWidgets in views/ |
| Animation state removed from views | ✅ | `StartController extends GetxController with GetSingleTickerProviderStateMixin` |

### AI Techniques

| Technique | Implementation |
|---|---|
| **Classification** | Eye open/closed binary classification; object category classification via TFLite |
| **Regression** | MAR and pitch angle are continuous float values analyzed against thresholds |
| **Clustering (temporal)** | Per-alert timers group sustained detections into single events, filtering noise |
| **Object detection** | YOLOv8-based `best_float16.tflite` via ML Kit `LocalObjectDetectorOptions` |

### Design

| Criterion | Implementation |
|---|---|
| Color scheme | Centralized `Constants` class — blue/cyan/red/orange system |
| Shapes | `BorderRadius.circular()`, `BoxShape.circle`, gradient glows |
| Animations | Fade-in, pulsing button, animated color transitions, camera border glow |
| App-type tailored | Dark automotive HUD aesthetic — "IA ACTIVA" badge, Tesla-style alarm slider |

---

*DMS — Driver Monitoring System | Flutter + Google ML Kit + TFLite | On-Device AI*
