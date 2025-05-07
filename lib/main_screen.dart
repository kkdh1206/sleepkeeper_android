import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleep_keeper/notificaiton.dart';
import 'package:sleep_keeper/option_page.dart';
import 'package:sleep_keeper/sleep_state.dart';
import 'setting_page.dart';
import 'main.dart';


//DateTime? selectedWakeUpTime; // 설정된 기상 시간 (글로벌 변수)

class MainScreen extends StatefulWidget {

  const MainScreen({super.key});



  @override
  State<MainScreen> createState() => _MainScreenState();
}
//const platform = MethodChannel('overlay_channel');

// bool isActive = false;
class _MainScreenState extends State<MainScreen> {

  String get wakeUpTimeText {
    if (selectedWakeUpTime == null) return "설정된 시간 없음";
    return "${selectedWakeUpTime!.hour.toString().padLeft(2, '0')}:${selectedWakeUpTime!.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _loadSavedWakeUpTime();  // 앱 시작할 때 SharedPreferences 값 불러오기
    _loadInitialOpacity();
    requestNotificationPermission();
    //isActive = false;
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   FlutterOverlayWindow.overlayListener.listen((msg) {
    //     print("📩 메시지 수신: $msg");
    //     if (msg == "closeOverlay") {
    //       setState(() {
    //         isActive = false;
    //       });
    //       cancelCountdownNotification(); // 알림 제거
    //     }
    //   });
    // });

  }



  Future<void> _loadSavedWakeUpTime() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWakeMillis = prefs.getInt('wakeUpTime');
    if (savedWakeMillis != null) {
      setState(() {
        selectedWakeUpTime = DateTime.fromMillisecondsSinceEpoch(savedWakeMillis);
      });
    }
  }

  void _loadInitialOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      opacity = prefs.getDouble('overlay_opacity') ?? 0.4;
    });
  }

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        // 사용자가 거부
        print('❌ 알림 권한 거부됨');
      } else if (status.isGranted) {
        // 사용자가 허용
        print('✅ 알림 권한 허용됨');
      }
    } else {
      print('✅ 이미 권한 있음');
    }
  }


  Future<void> _startSleepMode() async {
    final sleepState = context.read<SleepState>();
    // 1) 현재 권한 상태 확인 (bool? 리턴)
    final bool? hasPermission = await FlutterOverlayWindow.isPermissionGranted();

    // 2) 권한이 없거나 null 이면 requestPermission() 으로 권한 요청
    try{
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



    final prefs = await SharedPreferences.getInstance();
    final opacity = prefs.getDouble('overlay_opacity') ?? 0.4;
    // 3) 오버레이 띄우기
    await FlutterOverlayWindow.showOverlay(
      // overlayContent: opacity.toString(),
      width: 510,
      height: 250,
      alignment: OverlayAlignment.center,
      flag: OverlayFlag.defaultFlag,
      enableDrag: true,
    );


    // 2) 기상 시간 공유 (shareData 방식)
    if (selectedWakeUpTime != null) {
      try{
      await FlutterOverlayWindow.shareData(jsonEncode({
        "wakeUpTime": selectedWakeUpTime!.toIso8601String(),
        "opacity": opacity  // 예시값
      })
      );}catch(e){}
    }
    else{
      await Future.delayed(const Duration(seconds: 1));
      if (selectedWakeUpTime != null) {
        await FlutterOverlayWindow.shareData(
          selectedWakeUpTime!.toIso8601String(),
        );
      }

    }

    startCountdownNotification(selectedWakeUpTime!);
    setState(() => sleepState.startSleep); // ✅ 여기로 이동
  } catch (e) {
  print("❌ 수면모드 시작 실패: $e");
  }
  }



  void _goToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingPage()),
    );
    setState(() {}); // 돌아오면 UI 갱신
  }

  @override
  Widget build(BuildContext context) {
    final sleepState = context.watch<SleepState>();
    return Scaffold(
      appBar: AppBar(title: const Text('SleepKeeper')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start
              ,
              children: [

                Container(
                  child: Image.asset('assets/images/sleeping.jpeg'),
                  width: 200,
                  height: 300,

                )
                ,
                Text("설정된 기상 시간: $wakeUpTimeText", style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 24),
                // ElevatedButton(onPressed: (){setState(() {
                //   isActive=false;
                // });}, child: Text("active")),

                ElevatedButton(
                  onPressed: () async{
                    if(!sleepState.isActive){
                      _startSleepMode();
                    }
                    else {
                      setState(() {
                        sleepState.startSleep();
                        print("!!!");
                      });
                      cancelCountdownNotification();

                      await FlutterOverlayWindow.closeOverlay();
                      // cancelCountdownNotification(); // ✅ 여기가 핵심

                    }

                    },
                  child: (!sleepState.isActive) ? const Text("수면 모드 시작"): const Text("수면 모드 종료") ,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _goToSettings,
                  child: const Text("시간 설정하기"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OptionPage()),
                    );
                  },
                  child: Text('투명도 설정'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}