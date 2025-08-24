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
    
    // Configuration différente selon la plateforme
    RecordConfig config;
    String extension;
    
    if (Platform.isIOS) {
      // Configuration optimisée pour iOS
      config = RecordConfig(
        sampleRate: 44100,        // Fréquence d'échantillonnage standard
        bitRate: 128000,          // Bitrate standard
        encoder: AudioEncoder.aacLc, // Encodeur AAC compatible iOS
        numChannels: 1,           // Mono pour éviter les problèmes de conversion
        autoGain: true,           // Gain automatique
        echoCancel: true,         // Annulation d'écho
        noiseSuppress: true,      // Suppression de bruit
      );
      extension = 'm4a'; // Format M4A plus compatible iOS
    } else {
      // Configuration pour Android
      config = RecordConfig(
        sampleRate: 16000,
        bitRate: 128000,
        encoder: AudioEncoder.aacLc,
        numChannels: 1,
      );
      extension = 'aac';
    }
    
    _path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.$extension';
    
    try {
      await _recorder.start(config, path: _path);
      _state = RecorderState.recording;
      setState();
    } catch (e) {
      print('Erreur lors du démarrage de l\'enregistrement: $e');
      // Fallback avec configuration minimale
      try {
        await _recorder.start(
          RecordConfig(
            sampleRate: 44100,
            bitRate: 64000,
            encoder: AudioEncoder.pcm16bits,
            numChannels: 1,
          ),
          path: _path.replaceAll('.$extension', '.wav'),
        );
        _state = RecorderState.recording;
        setState();
      } catch (fallbackError) {
        print('Erreur avec la configuration de fallback: $fallbackError');
        rethrow;
      }
    }
  }

  RecorderState get state => _state;
  String get path => _path;

  Future<String> sendRecord() async {
    await stopRecording();
    print('Fichier enregistré: $_path');
    return _path;
  }

  Future<void> stopRecording() async {
    try {
      await _recorder.stop();
    } catch (e) {
      print('Erreur lors de l\'arrêt de l\'enregistrement: $e');
    } finally {
      await _recorder.dispose();
    }
  }

  Future<void> playRecording() async {
    try {
      await _recorder.resume();
      _state = RecorderState.recording;
      setState();
    } catch (e) {
      print('Erreur lors de la reprise de l\'enregistrement: $e');
    }
  }

  Future<void> pauseRecording() async {
    try {
      await _recorder.pause();
      _state = RecorderState.paused;
      setState();
    } catch (e) {
      print('Erreur lors de la pause de l\'enregistrement: $e');
    }
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
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('Fichier audio introuvable: $path');
      }
      
      final sizeInBytes = file.lengthSync();
      final sizeInMB = sizeInBytes / (1024 * 1024);
      
      return AudioFile(
        path: path, 
        size: sizeInMB, 
        name: file.path.split('/').last, 
        extension: path.split('.').last.toLowerCase()
      );
    } catch (e) {
      print('Erreur lors de la création de AudioFile: $e');
      // Retourner un fichier par défaut en cas d'erreur
      return AudioFile(
        path: path,
        size: 0.0,
        name: 'Fichier audio',
        extension: 'audio'
      );
    }
  }
  
  // Méthode pour obtenir le type MIME du fichier
  String get mimeType {
    switch (extension.toLowerCase()) {
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'wav':
        return 'audio/wav';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'audio/*';
    }
  }
  
  // Méthode pour vérifier si le fichier est valide
  bool get isValid {
    return size > 0 && File(path).existsSync();
  }
}