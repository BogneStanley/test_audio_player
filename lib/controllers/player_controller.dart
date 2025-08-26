import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class PlayerController {
  
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  Duration? _duration;
  Duration? _position;
  Function setState;

  PlayerController({required this.setState}) {
    _player.onPlayerComplete.listen((event) {
      _timer?.cancel();
      _position = Duration.zero;
      _duration = Duration.zero;
      setState();
    });
    _player.onDurationChanged.listen((event) {
      _duration = event;
      setState();
    });
    _player.onPositionChanged.listen((event) {
      _position = event;
      setState();
    });
  }

  Duration? get duration => _duration;
  Duration? get position => _position;

  Future<void> play(String path) async {
    try {
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      print(e);
    }
  }

  Future<void> seekTo(Duration duration) async {
    await _player.seek(duration);
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }
}