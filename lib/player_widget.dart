import 'package:flutter/material.dart';
import 'package:test_audio_player/controllers/player_controller.dart';
import 'package:test_audio_player/controllers/recoder_controller.dart';


class PlayerWidget extends StatefulWidget {
  final AudioFile audioFile;

  PlayerWidget({super.key, required this.audioFile});

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  late PlayerController playerController;

  @override
  void initState() {
    super.initState();
    playerController = PlayerController(setState: ()=>setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.audioFile.name),
        Slider(
          value: (playerController.position?.inSeconds.toDouble() ?? 0).clamp(0.0, (playerController.duration?.inSeconds.toDouble() ?? 1.0)),
          min: 0.0,
          max: (playerController.duration?.inSeconds.toDouble() ?? 1.0),
          onChanged: (value) {
            playerController.seekTo(Duration(seconds: value.toInt()));
          },
        ),
        Text('${playerController.position?.inSeconds} / ${playerController.duration?.inSeconds}'),
        Row(
          children: [
            IconButton(onPressed: () {
              playerController.play(widget.audioFile.path);
            }, icon: Icon(Icons.play_arrow)),
            IconButton(onPressed: () {
              playerController.pause();
            }, icon: Icon(Icons.pause)),
            IconButton(onPressed: () {
              playerController.stop();
            }, icon: Icon(Icons.stop)),
            IconButton(onPressed: () {
              playerController.seekTo(Duration(seconds: 0));
            }, icon: Icon(Icons.replay)),
          ],
        ),
      ],
    );
  }
}