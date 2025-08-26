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
  String _selectedEncoder = 'aacLc'; // Encodeur par défaut

  // Liste des encodeurs disponibles avec leurs descriptions
  final Map<String, String> _availableEncoders =
      Map.fromEntries(configs.map((config) => MapEntry(config['key']!, config['description']!)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
              selectedEncoder: _selectedEncoder,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedEncoder,
                      isExpanded: true, // Permet au texte de se comporter correctement à l'intérieur
                      decoration: InputDecoration(
                        labelText: 'Format d\'enregistrement',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _availableEncoders.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedEncoder = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      _checkPermission().then((value) {
                        if (!value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Permission denied')),
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
            ),
        ],
      ),
    );
  }

  Future<bool> _checkPermission() async {
    // Demander la permission directement.
    // request() vérifie d'abord le statut. S'il est 'denied', il demande.
    // S'il est 'permanentlyDenied', il ne fait rien et renvoie le statut.
    PermissionStatus status = await Permission.microphone.request();
    print('Status de la permission microphone: $status');

    if (status.isGranted) {
      return true;
    }

    // Si la permission est refusée de façon permanente (ou restreinte),
    // on propose à l'utilisateur d'aller dans les paramètres.
    if (status.isPermanentlyDenied || status.isRestricted) {
      bool shouldShowSettings = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Permission requise'),
                content: Text(
                  'L\'accès au microphone est nécessaire pour enregistrer de l\'audio. '
                  'Veuillez l\'activer dans les paramètres de l\'application.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Paramètres'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (shouldShowSettings) {
        await openAppSettings();
        // On revérifie le statut après le retour des paramètres
        status = await Permission.microphone.status;
        print('Nouveau statut après retour des paramètres: $status');
      }
    }

    // On retourne le statut final.
    return status.isGranted;
  }
}
