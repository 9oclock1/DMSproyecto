import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pro_mov/app/views/dms_menu_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DmsApp());
}

class DmsApp extends StatelessWidget {
  const DmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DMS Híbrido',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFF03DAC6),
        ),
      ),
      home: const DmsMenuView(),
    );
  }
}
