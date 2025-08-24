import 'dart:io';

import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class RecorderController {
  RecorderState _state = RecorderState.recording;
  late AudioRecorder _recorder;
  String _path = '';

  Function setState;

  RecorderController({required this.setState}) {
    _recorder = AudioRecorder();
  }

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    _recorder.start(
      RecordConfig(sampleRate: 16000, bitRate: 128000, encoder: AudioEncoder.aacLc),
      path: _path,
    );
    _state = RecorderState.recording;
    setState();
  }

  RecorderState get state => _state;
  String get path => _path;

  Future<String> sendRecord() async {
    await stopRecording();
    print(_path);
    return _path;
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
    await _recorder.dispose();
  }

  Future<void> playRecording() async {
    await _recorder.resume();
    _state = RecorderState.recording;
    setState();
  }

  Future<void> pauseRecording() async {
    await _recorder.pause();
    _state = RecorderState.paused;
    setState();
  }
}

enum RecorderState { recording, paused }

class AudioFile {
  final String path;
  final double size;
  final String name;
  final String extension;

  AudioFile({required this.path, required this.size, required this.name, required this.extension,});

  factory AudioFile.fromPath(String path) {
    final file = File(path);
    return AudioFile(path: path, size: file.lengthSync() / (1024 * 1024), name: file.path.split('/').last, extension: file.path.split('.').last);
  }
}