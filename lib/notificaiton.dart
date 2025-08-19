import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sleep_keeper/main.dart';

int notificationId = 0;
Timer? timer;

void startCountdownNotification(DateTime wakeUpTime) {
  debugPrint("🔔 startCountdownNotification called");
  timer?.cancel(); // 기존 타이머 정리
  timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
    final now = DateTime.now();
    final remaining = wakeUpTime.difference(now);
    final display = formatDuration(remaining);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sleep_channel',
      '수면 알림',
      channelDescription: '수면 타이머 알림',
      importance: Importance.max,
      priority: Priority.high,
      onlyAlertOnce: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'dismiss', // 식별자
          '수면 종료', // 버튼에 보일 이름
          showsUserInterface: true,
          cancelNotification: true
        ),
      ],
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      notificationId, // 같은 ID → 같은 notification 갱신됨
      '남은 수면 시간',
      // if (wakeUpTime이 올 때)
      display,
      platformDetails,
    );

    if (remaining.isNegative) {
      timer.cancel();
    }
  });
}

void cancelCountdownNotification() {
  timer?.cancel(); // ✅ 타이머 정지
  timer = null;
  flutterLocalNotificationsPlugin.cancel(notificationId); // ✅ 알림 제거
}

String formatDuration(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}