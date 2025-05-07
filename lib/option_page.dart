import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:sleep_keeper/main.dart';
import 'package:sleep_keeper/overlay_widget.dart';

class OptionPage extends StatefulWidget {
  const OptionPage({super.key});

  @override
  State<OptionPage> createState() => _OptionPageState();
}

class _OptionPageState extends State<OptionPage> {

  @override
  void initState() {
    super.initState();
    _loadOpacity();
  }

  Future<void> _loadOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      opacity = prefs.getDouble('overlay_opacity') ?? 0.4;
    });
  }

  Future<void> _saveOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('overlay_opacity', opacity!);

    // ✅ overlay에 바로 전달
    await FlutterOverlayWindow.shareData('opacity:$opacity');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Option Page')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Slider(
            value: opacity ?? 0.4,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: opacity!.toStringAsFixed(1),
            onChanged: (value) {
              setState(() => opacity = value);
              setState(() {
                opacity;
              });
            },
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveOpacity();
              Navigator.pop(context);
            },
            child: const Text('저장하기'),
          ),
        ],
      ),
    );
  }
}