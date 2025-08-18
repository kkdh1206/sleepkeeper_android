import 'dart:async';
import 'dart:convert';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        child: OverlayContent(),
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
  var opacity = 0.4;
  DateTime? wakeUpTime;
  Duration? sleepTime;

  bool needSleep = false;

  @override
  void initState() {
    super.initState();

    _loadOpacity();
    FlutterOverlayWindow.overlayListener.listen((msg) {
      if (msg.toString().startsWith('opacity:')) {
        final value = double.tryParse(msg.toString().split(':')[1]);
        if (value != null) {
          setState(() {
            opacity = value;
          });
        }
        return;
      }
      final data = jsonDecode(msg);
      setState(() {
        needSleep = false;
        wakeUpTime = DateTime.parse(data['wakeUpTime']);
        sleepTime = Duration(milliseconds: data['sleepTime']);
      });
    });
  }

  Future<void> _loadOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      opacity = prefs.getDouble('overlay_opacity') ?? 0.4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        const intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.LAUNCHER',
          package: 'com.sleep.sleep_keeper',
          componentName: 'com.sleep.sleep_keeper.MainActivity',
          flags: <int>[
            Flag.FLAG_ACTIVITY_NEW_TASK,
            Flag.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED,
            Flag.FLAG_ACTIVITY_SINGLE_TOP,
            Flag.FLAG_ACTIVITY_CLEAR_TOP,
            Flag.FLAG_ACTIVITY_REORDER_TO_FRONT,
          ],
        );
        await intent.launch();
      },
      child: Center(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: needSleep ? Colors.red.withAlpha((255.0 * opacity).round()) : Colors.black.withAlpha((255.0 * opacity).round()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '남은 수면 시간',
                      style: TextStyle(color: Colors.white70,fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    if (wakeUpTime != null && sleepTime != null)
                      CountdownWidget(wakeUpTime: wakeUpTime!, sleepTime: sleepTime!, needSleep: () {
                        setState(() {
                          needSleep = true;
                        });
                    }),
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
      ),
    );
  }
}

class CountdownWidget extends StatefulWidget {
  final DateTime wakeUpTime;
  final Duration sleepTime;
  final Function() needSleep;
  const CountdownWidget({super.key, required this.wakeUpTime, required this.needSleep, required this.sleepTime});

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      final now = DateTime.now();
      setState(() {
        final diff = widget.wakeUpTime.difference(now);
        _remaining = diff.isNegative ? Duration.zero : diff;
        if (_remaining.inMinutes < widget.sleepTime.inMinutes) {
          widget.needSleep();
        }
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
        color: Colors.black.withAlpha(0),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 18),
        splashRadius: 24,
        onPressed: () async {
          await FlutterOverlayWindow.closeOverlay();
        },
      ),
    );
  }
}