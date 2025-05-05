import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'setting_page.dart';


DateTime? selectedWakeUpTime; // 설정된 기상 시간 (글로벌 변수)

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String get wakeUpTimeText {
    if (selectedWakeUpTime == null) return "설정된 시간 없음";
    return "${selectedWakeUpTime!.hour.toString().padLeft(2, '0')}:${selectedWakeUpTime!.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _startSleepMode() async {
    // 1) 현재 권한 상태 확인 (bool? 리턴)
    final bool? hasPermission = await FlutterOverlayWindow.isPermissionGranted();

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

    // 2) 기상 시간 공유 (shareData 방식)
    if (selectedWakeUpTime != null) {
      await FlutterOverlayWindow.shareData(
        selectedWakeUpTime!.toIso8601String(),
      );
    }


    // 3) 오버레이 띄우기
    await FlutterOverlayWindow.showOverlay(
      width: 510,
      height: 250,
      alignment: OverlayAlignment.center,
      flag: OverlayFlag.defaultFlag,
      enableDrag: true,
    );
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
                ElevatedButton(
                  onPressed: _startSleepMode,
                  child: const Text("수면 모드 시작"),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _goToSettings,
                  child: const Text("시간 설정하기"),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}