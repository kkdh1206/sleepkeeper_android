import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleep_keeper/notificaiton.dart';
import 'package:sleep_keeper/state/sleep_state.dart';
import 'package:sleep_keeper/theme/colors.dart';
import 'package:sleep_keeper/theme/size.dart';
import 'components/button.dart';
import 'components/cat.dart';
import 'components/option.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double opacity = 0.4;
  DateTime? selectedWakeUpTime; // 기상 시간
  Duration sleepTime = const Duration(hours: 8, minutes: 00); // 목표 수면 시간

  String get wakeUpTimeText {
    if (selectedWakeUpTime == null) return "설정된 시간 없음";
    return "${selectedWakeUpTime!.hour.toString().padLeft(2, '0')}:${selectedWakeUpTime!.minute.toString().padLeft(2, '0')}";
  }

  String get sleepTimeText {
    return "${sleepTime.inHours.toString().padLeft(2, '0')}:${sleepTime.inMinutes.remainder(60).toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _loadOpacity(); // 투명도 설정 불러 오기
    _loadWakeUpTime(); // 기상 시간 & 목표 수면 시간 불러 오기

    requestNotificationPermission();
  }

  /// 투명도 설정 불러 오기
  Future<void> _loadOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      opacity = prefs.getDouble('overlay_opacity') ?? 0.4;
    });
  }

  /// 투명도 설정 저장 하기
  Future<void> _saveOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('overlay_opacity', opacity);

    // ✅ overlay에 바로 전달
    await FlutterOverlayWindow.shareData(jsonEncode({
      'type': 'timer',
      "opacity": opacity,
    }));
  }

  /// 기상 시간 & 목표 수면 시간 불러 오기
  Future<void> _loadWakeUpTime() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWakeMillis = prefs.getInt('wakeUpTime');
    final savedSleepTime = prefs.getInt('sleepTime');
    if (savedWakeMillis != null) {
      setState(() {
        selectedWakeUpTime = DateTime.fromMillisecondsSinceEpoch(savedWakeMillis);
      });
    }
    if (savedSleepTime != null) {
      setState(() {
        sleepTime = Duration(milliseconds: savedSleepTime);
      });
    }
  }

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        // 사용자가 거부
        debugPrint('❌ 알림 권한 거부됨');
      } else if (status.isGranted) {
        // 사용자가 허용
        debugPrint('✅ 알림 권한 허용됨');
      }
    } else {
      debugPrint('✅ 이미 권한 있음');
    }
  }

  Future<void> _startSleepMode() async {
    final sleepState = context.read<SleepState>();

    // 1) 현재 권한 상태 확인
    final bool hasPermission = await FlutterOverlayWindow.isPermissionGranted();

    try {
      // 2) 권한이 없거나 null 이면 requestPermission() 으로 권한 요청
      if (hasPermission != true) {
        final bool? permissionResult = await FlutterOverlayWindow.requestPermission();
        if (permissionResult != true) {
          // 권한이 여전히 없으면 스낵바 띄우고 종료
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('오버레이 권한이 필요합니다. 설정에서 허용해주세요.')),
          );
          return;
        }
        // 권한 화면으로 이동했으니, 사용자가 설정을 마친 뒤 다시 버튼을 눌러 재호출해주세요.
        return;
      }

      // 3) 오버레이 띄우기
      await FlutterOverlayWindow.showOverlay(
        width: overlayWidth.toInt(),
        height: overlayHeight.toInt(),
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.defaultFlag,
        enableDrag: true,
      );

      // 4) 기상 시간 공유 (shareData 방식)
      await FlutterOverlayWindow.shareData(jsonEncode({
        'type': 'timer',
        "wakeUpTime": selectedWakeUpTime!.toIso8601String(),
        "opacity": opacity,
        "sleepTime": sleepTime.inMilliseconds,
      }));

      startCountdownNotification(selectedWakeUpTime!);
      sleepState.startSleep();
    } catch (e) {
      debugPrint("❌ 수면모드 시작 실패: $e");
    }
  }

  Future<void> _startForceSleepMode() async {
    // 1) 현재 권한 상태 확인
    final bool hasPermission = await FlutterOverlayWindow.isPermissionGranted();

    try {
      // 2) 권한이 없거나 null 이면 requestPermission() 으로 권한 요청
      if (hasPermission != true) {
        final bool? permissionResult = await FlutterOverlayWindow.requestPermission();
        if (permissionResult != true) {
          // 권한이 여전히 없으면 스낵바 띄우고 종료
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('오버레이 권한이 필요합니다. 설정에서 허용해주세요.')),
          );
          return;
        }
        // 권한 화면으로 이동했으니, 사용자가 설정을 마친 뒤 다시 버튼을 눌러 재호출해주세요.
        return;
      }

      // 3) 오버레이 띄우기
      await FlutterOverlayWindow.showOverlay(
        width: WindowSize.matchParent,
        height: WindowSize.matchParent,
        alignment: OverlayAlignment.topLeft,
        flag: OverlayFlag.defaultFlag,
        enableDrag: false,
        positionGravity: PositionGravity.none,
        startPosition: const OverlayPosition(0, 0),
      );
      await FlutterOverlayWindow.shareData(jsonEncode({
        'type': 'forceSleep',
        'salt': DateTime.now().millisecond, // 재사용 막기 위한 랜덤 값으로...
      }));
    } catch (e) {
      debugPrint("❌ 강제 수면 모드 시작 실패: $e");
    }
  }

  Duration _pickedDuration = const Duration(hours: 6, minutes: 30);
  /// 기상 시간 설정하기
  Future<void> _showTimerPicker(BuildContext context) async {
    if (selectedWakeUpTime != null) {
      _pickedDuration = Duration(
        hours: selectedWakeUpTime!.hour,
        minutes: selectedWakeUpTime!.minute,
      );
    }
    await showModalBottomSheet(context: context, builder: (_) {
      return Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          color: primaryBackground,
        ),
        child:  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("기상 시간 설정하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Expanded(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: _pickedDuration,
                minuteInterval: 1,
                onTimerDurationChanged: (duration) {
                  setState(() => _pickedDuration = duration);
                },
                backgroundColor: Colors.transparent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Button(onTap: () => Navigator.pop(context), text: '취소', type: ButtonType.tertiary),
                  const SizedBox(width: 24),
                  Button(onTap: () async {
                    final now = DateTime.now();
                    var wake = DateTime(
                      now.year, now.month, now.day,
                      _pickedDuration.inHours,
                      _pickedDuration.inMinutes.remainder(60),
                    );

                    if (wake.isBefore(now)) wake = wake.add(const Duration(days: 1));
                    selectedWakeUpTime = wake;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('wakeUpTime', wake.millisecondsSinceEpoch);
                    setState(() { });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("기상 시간이 설정되었습니다.")),
                    );
                  }, text: '확인', type: ButtonType.primary),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 목표 수면 시간 설정하기
  Future<void> _showTimerPicker2(BuildContext context) async {
    await showModalBottomSheet(context: context, builder: (_) {
      Duration newSleepTime = sleepTime;
      return Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          color: primaryBackground,
        ),
        child:  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("목표 수면 시간 설정하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Expanded(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: sleepTime,
                minuteInterval: 1,
                onTimerDurationChanged: (duration) {
                  setState(() => newSleepTime = duration);
                },
                backgroundColor: Colors.transparent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Button(onTap: () => Navigator.pop(context), text: '취소', type: ButtonType.tertiary),
                  const SizedBox(width: 24),
                  Button(onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('sleepTime', newSleepTime.inMilliseconds);
                    setState(() {
                      sleepTime = newSleepTime;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("목표 수면 시간이 설정되었습니다.")),
                    );
                  }, text: '확인', type: ButtonType.primary),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sleepState = context.watch<SleepState>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Stack(
              children: [
                Cat(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Option("기상 시간",
                    child: GestureDetector(
                      onTap: () {
                        if (sleepState.isActive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("수면 모드 종료 후 변경할 수 있어요.")),
                          );
                          return;
                        }
                        _showTimerPicker(context);
                      },
                      child: Text(wakeUpTimeText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: brandMain)),
                    )
                  ),
                  Option("목표 수면 시간",
                      child: GestureDetector(
                        onTap: () {
                          if (sleepState.isActive) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("수면 모드 종료 후 변경할 수 있어요.")),
                            );
                            return;
                          }
                          _showTimerPicker2(context);
                        },
                        child: Text(sleepTimeText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: brandMain)),
                      )
                  ),
                  const SizedBox(height: 24),
                  Option("투명도 설정",
                    child: Slider(
                      value: opacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      padding: EdgeInsets.zero,
                      label: opacity.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          opacity = value;
                        });
                        _saveOpacity();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Button(onTap: () async {
                    if (selectedWakeUpTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("먼저 기상 시간을 설정해주세요.")),
                      );
                      return;
                    }
                    if(!sleepState.isActive){
                      _startSleepMode();
                    }
                    else {
                      sleepState.stopSleep();
                      cancelCountdownNotification();
                      await FlutterOverlayWindow.closeOverlay();
                    }
                  }, text: (!sleepState.isActive) ? "수면 모드 시작" : "수면 모드 종료", type: ButtonType.primary),
                  const SizedBox(height: 24),
                  Button(onTap: () {
                    _startForceSleepMode();
                  }, text: "강제 수면 시작", type: ButtonType.secondary),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}