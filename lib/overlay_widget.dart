import 'dart:async';
import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

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

class OverlayContent extends StatelessWidget {
  const OverlayContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [

          Container(
            width: 210,         // 원하는 너비
            height: 110,
            // padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(height: 10,)
                ,
                Text(
                  '남은 수면시간',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                CountdownWidget(),
                SizedBox(height: 12),

              ],
                              ),
            ),
          ),
          Positioned(
            top: -5,    // 컨테이너 위로 살짝 올리기
            right:-5,
            child: CloseButtonWidget(),),
        ],
      ),
    );
  }
}

class CountdownWidget extends StatefulWidget {
  const CountdownWidget({super.key});

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
      _wakeUpTime = DateTime.parse(msg);
      _startTimer();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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
        },
      ),
    );
  }
}