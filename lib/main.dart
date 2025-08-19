import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleep_keeper/notificaiton.dart';
import 'package:sleep_keeper/state/sleep_state.dart';
import 'main_screen.dart';
import 'overlay_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  final sleepState = SleepState();
  WidgetsFlutterBinding.ensureInitialized();

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

class _SleepKeeperAppState extends State<SleepKeeperApp> {
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