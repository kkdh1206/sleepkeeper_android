import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleep_keeper/notificaiton.dart';
import 'package:sleep_keeper/sleep_state.dart';
import 'main_screen.dart';
import 'overlay_widget.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async{//async{
  final sleepState = SleepState();
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
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);


  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.actionId == 'dismiss') {
        cancelCountdownNotification(); // 🔔 타이머 종료
        await FlutterOverlayWindow.closeOverlay(); // 🔒 오버레이 종료

        sleepState.stopSleep();
      }
      // if (response.actionId == 'restart') {
      //   await startSleep(); // 오버레이 다시 실행 함수
      // }
    },
  );


  runApp(ChangeNotifierProvider.value(
    value: sleepState,
    child: const SleepKeeperApp()));
}

Future<void> showNotification(String contentText) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'sleep_channel', // channel id
    '수면 알림', // channel name
    channelDescription: '수면 타이머 알림',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // notification id
    '수면 타이머', // 제목
    contentText, // 내용
    platformChannelSpecifics,
  );
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("[Overlay] overlayMain 진입 성공");

  runApp(const OverlayApp());
}
class SleepKeeperApp extends StatefulWidget {
  const SleepKeeperApp({super.key});

  @override
  State<SleepKeeperApp> createState() => _SleepKeeperAppState();
}
DateTime? selectedWakeUpTime;
double? opacity;
String? wakeUpTime;
class _SleepKeeperAppState extends State<SleepKeeperApp> {


  @override
  void initState() {
    super.initState();
    getPref();
  }


  Future<void> getPref() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWakeMillis = prefs.getInt('wakeUpTime');
    if (savedWakeMillis != null) {
      setState(() {
        selectedWakeUpTime = DateTime.fromMillisecondsSinceEpoch(savedWakeMillis);
        wakeUpTime = savedWakeMillis.toString();
      });
    }
  }

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