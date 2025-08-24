import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:test_audio_player/controllers/recoder_controller.dart';
import 'package:test_audio_player/player_widget.dart';
import 'package:test_audio_player/recorder_widget.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<AudioFile> _audioList = [];

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
                return ListTile(
                  title: PlayerWidget(audioFile: _audioList[index]),
                  subtitle: Text('${_audioList[index].size} Mo'),
                  leading: IconButton(
                    onPressed: () {
                      _audioList.removeAt(index);
                      setState(() {});
                    },
                    icon: Icon(Icons.delete),
                  ),
                );
              },
            ),
          ),
          if (_isRecording)
          RecorderWidget(
            onSend: (value) {
              AudioFile audioFile = AudioFile.fromPath(value);
              setState(() {
                _audioList.add(audioFile);
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
    if (Platform.isIOS) {
      // Sur iOS, utiliser permission_handler
      PermissionStatus status = await Permission.microphone.status;
      if (status.isDenied) {
        status = await Permission.microphone.request();
      }
      return status.isGranted;
    } else {
      // Sur Android, utiliser record
      AudioRecorder recorder = AudioRecorder();
      return await recorder.hasPermission();
    }
  }
}
