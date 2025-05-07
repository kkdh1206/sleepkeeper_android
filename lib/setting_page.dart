import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'main.dart';
import 'package:intl/intl.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  Duration _pickedDuration = const Duration(hours: 7, minutes: 30); // 초기값

  Future<void> _showTimerPicker(BuildContext context) async {
    if (selectedWakeUpTime != null) {
      // DateTime → Duration(시분) 으로 변환
      final wake = selectedWakeUpTime!;
      _pickedDuration = Duration(
        hours: wake.hour,
        minutes: wake.minute,
      );
    }

    await showDialog(
      context: context,
      barrierColor: Colors.black54,      // 배경 어둡게
      builder: (_) {
        return Center(
          child: Container(
            width: 300,
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // 상단 확인/취소


                // 중앙에 TimerPicker
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
                // const Divider(color: Colors.white38),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소', style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () async{
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
                        setState(() {

                        });
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("기상 시간이 설정되었습니다.")),
                        );
                      },
                      child: const Text('확인', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = selectedWakeUpTime == null
        ? '설정된 시간 없음'
        : '${selectedWakeUpTime!.hour.toString().padLeft(2, '0')}:'
        '${selectedWakeUpTime!.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text("시간 설정")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('현재 기상시간: $display', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showTimerPicker(context),
              child: const Text("기상시간 설정"),
            ),
          ],
        ),
      ),
    );
  }
}