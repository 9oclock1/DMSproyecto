import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/dms_controller.dart';

/// Central Riverpod provider for the DMS notifier.
///
/// The notifier is created when first watched (i.e. when [MonitorView] opens)
/// and automatically disposed when no widget watches it any more.
final dmsControllerProvider = ChangeNotifierProvider.autoDispose<DmsNotifier>(
  (ref) => DmsNotifier(),
);
