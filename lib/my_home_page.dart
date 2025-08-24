import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:test_audio_player/recorder_widget.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> _audioList = [];

  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _audioList.length,
              itemBuilder: (context, index) {
                return Text(_audioList[index]);
              },
            ),
          ),
          if (_isRecording)
          RecorderWidget(
            onSend: (value) {
              File file = File(value);
              print(file.path);
              double tailleMb = file.lengthSync() / (1024 * 1024);
              print('Taille du fichier : ${tailleMb.toStringAsFixed(2)} Mo');
              
              setState(() {
                _audioList.add(value);
                _isRecording = false;
              });
            },
            onStop: () {
              setState(() {
                _isRecording = false;
              });
            },
          ),
          if (!_isRecording)
            ElevatedButton(
              onPressed: () {
                _checkPermission().then((value) {
                  if (!value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Permission denied'),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _isRecording = true;
                  });
                });
              },
              child: Text('Start Recording'),
            ),
        ],
      ),
    );
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    } else {
      return false;
    }
  }
}
