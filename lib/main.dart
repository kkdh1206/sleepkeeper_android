import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'main_screen.dart';
import 'overlay_widget.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // final overlayEntry = OverlayEntry();
  // Overlay.of(context).insert(overlayEntry)
  // FlutterOverlayWindow.initOverlay(
  //   entrypoint: 'overlayMain', // isolate 이름으로 등록
  // );
  // FlutterOverlayWindow.setPluginRegistrant((registry) {
  //   // Android 전용 registrar를 이용해 SharedPreferences 플러그인 등록
  //   SharedPreferencesAndroid.registerWith(
  //     registry.registrarFor(SharedPreferencesAndroid.kPluginKey),
  //   );
  // });

  runApp(const SleepKeeperApp());
}

@pragma('vm:entry-point')
void overlayMain() {
  debugPrint("[Overlay] overlayMain 진입 성공");

  runApp(const OverlayApp());
}

class SleepKeeperApp extends StatelessWidget {
  const SleepKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SleepKeeper',
      theme: ThemeData.dark(),
      home: const MainScreen(),
    );
  }
}