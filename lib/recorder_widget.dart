import 'package:flutter/material.dart';
import 'package:test_audio_player/controllers/recoder_controller.dart';

class RecorderWidget extends StatefulWidget {
  const RecorderWidget({super.key, required this.onSend, required this.onStop});
  final Function(String) onSend;
  final Function() onStop;

  @override
  State<RecorderWidget> createState() => _RecorderWidgetState();
}

class _RecorderWidgetState extends State<RecorderWidget> {
  late RecorderController _recorderController;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController(setState: () {
      setState(() {});
    });
    _recorderController.init();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _recorderController.stopRecording().then((value) => widget.onStop());
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: Icon(Icons.stop),
          ),
          Expanded(
            child: Text(_recorderController.state.name, style: TextStyle(fontSize: 16),),
          ),
          IconButton(
            onPressed: () {
              if (_recorderController.state == RecorderState.recording) {
                _recorderController.pauseRecording();
              } else {
                _recorderController.playRecording();
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: Icon(_recorderController.state == RecorderState.recording ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            onPressed: () {
              _recorderController.sendRecord().then((value) => widget.onSend(value));
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
