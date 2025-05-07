import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleep_keeper/main.dart';
import 'package:sleep_keeper/notificaiton.dart';
import 'main_screen.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'main.dart';

@pragma('vm:entry-point')
void overlayMain() {
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.center,

        child: SizedBox(
          width: 140,   // showOverlay 에 넘긴 width 값
          height: 80,  // showOverlay 에 넘긴 height 값
          child: OverlayContent(),
        ),
      ),
    );
  }
}
class OverlayContent extends StatefulWidget {
  const OverlayContent({super.key});

  @override
  State<OverlayContent> createState() => _OverlayContentState();
}
class _OverlayContentState extends State<OverlayContent> {
   // 기본값


  @override
  void initState() {
    super.initState();
    setState(() {
      opacity;
    });


    //_loadOpacity(); // 초기에만 이걸로 불러줌
    // FlutterOverlayWindow.overlayListener.listen((msg) {
    //   if (msg.toString().startsWith('opacity:')) {
    //     final value = double.tryParse(msg.toString().split(':')[1]);
    //     if (value != null) {
    //       setState(() {
    //         opacity = value;
    //       });
    //     }
    //   }
    // });
  }



  // Future<void> _loadOpacity() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     opacity = prefs.getDouble('overlay_opacity') ?? 0.4;
  //     _opacityLoaded = true;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // if (!_opacityLoaded) {
    //   return const SizedBox(); // 아직 로딩 중
    // }

    return Center(
      child: Stack(
        children: [
          Container(
            width: 210,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(opacity ?? 0.4), // ✅ SharedPreferences 적용!
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 10),
                  Text(
                    '남은 수면시간',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  CountdownWidget(opacity: opacity),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ),
          const Positioned(
            top: -5,
            right: -5,
            child: CloseButtonWidget(),
          ),
        ],
      ),
    );
  }
}

class CountdownWidget extends StatefulWidget {
  final double? opacity;
  const CountdownWidget({super.key, this.opacity});

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late DateTime _wakeUpTime;
  late Timer _timer;

  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    // 1) 메인 앱에서 보낸 시간 수신

    FlutterOverlayWindow.overlayListener.listen((msg) {
      if(msg != "closeOverlay"){
        if (msg.toString().startsWith('opacity:')) {
          final value = double.tryParse(msg.toString().split(':')[1]);
          if (value != null) {
            setState(() {
              opacity = value;
            });
          }
        }

      final data = jsonDecode(msg);
      _wakeUpTime = DateTime.parse(data['wakeUpTime']);
      setState(() {
        opacity;// = (data['opacity'] as num).toDouble();
      });
      _startTimer();

      }

    });
  }

  void _initWakeUpTime() async {
    final prefs = await SharedPreferences.getInstance();
    while (true) {
      final storedTime = prefs.getString('wakeUpTime');
      if (storedTime != null) {
        _wakeUpTime = DateTime.parse(storedTime);
        _startTimer();
        break;
      }
      await Future.delayed(Duration(milliseconds: 100)); // 0.1초마다 polling
    }
  }



  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        // _timer?.cancel(); // 혹시라도 타이머 살아있으면 종료
        return;
      }
      final now = DateTime.now();
      setState(() {
        final diff = _wakeUpTime.difference(now);
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatDuration(_remaining),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 23,
        fontWeight: FontWeight.bold,
      ),
    );




  }
}
class CloseButtonWidget extends StatelessWidget {
  const CloseButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0),           // 반투명 배경
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.close,    // X 아이콘
            color: Colors.white, size: 18),
        splashRadius: 24,
        onPressed: () async {
          await FlutterOverlayWindow.closeOverlay(); // ← 여기를 이렇게!
          await FlutterOverlayWindow.shareData("closeOverlay");
          //cancelCountdownNotification();
        },
      ),
    );
  }
}