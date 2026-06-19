import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/dms_controller.dart';

final dmsControllerProvider = ChangeNotifierProvider.autoDispose<DmsNotifier>(
  (ref) => DmsNotifier(),
);
