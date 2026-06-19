import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_mov/app/utils/constants.dart';
import 'package:pro_mov/app/views/dms_menu_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DmsApp()));
}

class DmsApp extends StatelessWidget {
  const DmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DMS Híbrido',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Constants.background,
        colorScheme: ColorScheme.dark(
          primary: Constants.accent,
          secondary: Constants.textSecondary,
          surface: Constants.surface,
        ),
      ),
      home: const DmsMenuView(),
    );
  }
}

