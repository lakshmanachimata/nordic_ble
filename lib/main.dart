import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/ble_scanner_viewmodel.dart';
import 'screens/ble_scanner_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BleScannerViewModel(),
      child: MaterialApp(
        title: 'Nordic BLE Scanner',
        theme: AppTheme.lightTheme,
        home: const BleScannerScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
