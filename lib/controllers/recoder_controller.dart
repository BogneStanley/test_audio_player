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
      // Utiliser la méthode alternative pour iOS
      try {
        await _initIOSRecording();
        return; // Sortir directement si succès
      } catch (e) {
        print('Toutes les méthodes iOS ont échoué: $e');
        rethrow;
      }
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
      print('Enregistrement démarré avec succès: $_path');
    } catch (e) {
      print('Erreur lors du démarrage de l\'enregistrement: $e');
      // Fallback avec configuration minimale
      try {
        print('Tentative avec configuration de fallback...');
        await _recorder.start(
          RecordConfig(
            sampleRate: 22050,    // Fréquence réduite
            bitRate: 352800,      // Bitrate pour PCM 16-bit mono (22050 * 16 * 1)
            encoder: AudioEncoder.pcm16bits,
            numChannels: 1,
          ),
          path: _path.replaceAll('.$extension', '.wav'),
        );
        _path = _path.replaceAll('.$extension', '.wav');
        _state = RecorderState.recording;
        setState();
        print('Enregistrement démarré avec configuration de fallback: $_path');
      } catch (fallbackError) {
        print('Erreur avec la configuration de fallback: $fallbackError');
        rethrow;
      }
    }
  }

  // Méthode alternative pour iOS avec essais multiples
  Future<void> _initIOSRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    
    // Liste des configurations à essayer sur iOS - toutes les options disponibles
    final List<Map<String, dynamic>> configs = [
      // Configurations PCM (les plus compatibles)
      {
        'sampleRate': 44100,
        'bitRate': 705600,
        'encoder': AudioEncoder.pcm16bits,
        'extension': 'pcm',
        'description': 'PCM 16-bit 44.1kHz'
      },
      {
        'sampleRate': 22050,
        'bitRate': 352800,
        'encoder': AudioEncoder.pcm16bits,
        'extension': 'pcm',
        'description': 'PCM 16-bit 22.05kHz'
      },
      {
        'sampleRate': 16000,
        'bitRate': 256000,
        'encoder': AudioEncoder.pcm16bits,
        'extension': 'pcm',
        'description': 'PCM 16-bit 16kHz'
      },
      {
        'sampleRate': 8000,
        'bitRate': 128000,
        'encoder': AudioEncoder.pcm16bits,
        'extension': 'pcm',
        'description': 'PCM 16-bit 8kHz'
      },
      
      // Configuration WAV (Waveform Audio avec headers)
      {
        'sampleRate': 44100,
        'bitRate': 705600,
        'encoder': AudioEncoder.wav,
        'extension': 'wav',
        'description': 'WAV 44.1kHz'
      },
      {
        'sampleRate': 22050,
        'bitRate': 352800,
        'encoder': AudioEncoder.wav,
        'extension': 'wav',
        'description': 'WAV 22.05kHz'
      },
      
      // Configuration FLAC (Free Lossless Audio Codec)
      {
        'sampleRate': 44100,
        'bitRate': 128000,
        'encoder': AudioEncoder.flac,
        'extension': 'flac',
        'description': 'FLAC 44.1kHz'
      },
      {
        'sampleRate': 22050,
        'bitRate': 64000,
        'encoder': AudioEncoder.flac,
        'extension': 'flac',
        'description': 'FLAC 22.05kHz'
      },
      
      // Configuration Opus (très efficace, supporté sur iOS 11+)
      {
        'sampleRate': 48000,
        'bitRate': 64000,
        'encoder': AudioEncoder.opus,
        'extension': 'opus',
        'description': 'Opus 48kHz'
      },
      {
        'sampleRate': 24000,
        'bitRate': 32000,
        'encoder': AudioEncoder.opus,
        'extension': 'opus',
        'description': 'Opus 24kHz'
      },
      
      // Configuration AAC (essayer malgré les problèmes précédents)
      {
        'sampleRate': 44100,
        'bitRate': 128000,
        'encoder': AudioEncoder.aacLc,
        'extension': 'm4a',
        'description': 'AAC-LC 44.1kHz'
      },
      {
        'sampleRate': 22050,
        'bitRate': 64000,
        'encoder': AudioEncoder.aacLc,
        'extension': 'm4a',
        'description': 'AAC-LC 22.05kHz'
      },
      
      // Configuration AAC Enhanced Low Delay
      {
        'sampleRate': 44100,
        'bitRate': 128000,
        'encoder': AudioEncoder.aacEld,
        'extension': 'm4a',
        'description': 'AAC-ELD 44.1kHz'
      },
      
      // Configuration AAC High Efficiency
      {
        'sampleRate': 44100,
        'bitRate': 64000,
        'encoder': AudioEncoder.aacHe,
        'extension': 'm4a',
        'description': 'AAC-HE 44.1kHz'
      },
      
      // Configuration AMR Narrow Band (8kHz requis)
      {
        'sampleRate': 8000,
        'bitRate': 12800,
        'encoder': AudioEncoder.amrNb,
        'extension': '3gp',
        'description': 'AMR-NB 8kHz'
      },
      
      // Configuration AMR Wide Band (16kHz requis)
      {
        'sampleRate': 16000,
        'bitRate': 23800,
        'encoder': AudioEncoder.amrWb,
        'extension': '3gp',
        'description': 'AMR-WB 16kHz'
      },
    ];
    
    Exception? lastError;
    
    for (int i = 0; i < configs.length; i++) {
      final config = configs[i];
      try {
        print('Essai ${i + 1}/${configs.length}: ${config['description']}');
        
        _path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.${config['extension']}';
        
        final recordConfig = RecordConfig(
          sampleRate: config['sampleRate'],
          bitRate: config['bitRate'],
          encoder: config['encoder'],
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        );
        
        await _recorder.start(recordConfig, path: _path);
        _state = RecorderState.recording;
        setState();
        if (await _recorder.isRecording()) {
          print('Enregistrement démarré avec succès: ${config['description']}');
          print('Fichier: $_path');
          return; // Succès, sortir de la boucle
        } else {
          print('Enregistrement échoué: ${config['description']}');
          throw Exception('L\'enregistrement n\'a pas démarré');
        }
        
      } catch (e) {
        lastError = e as Exception;
        print('Échec avec ${config['description']}: $e');
        
        // Essayer de nettoyer avant le prochain essai
        try {
          await _recorder.dispose();
          _recorder = AudioRecorder();
        } catch (cleanupError) {
          print('Erreur lors du nettoyage: $cleanupError');
        }
      }
    }
    
    // Si toutes les configurations ont échoué
    throw Exception('Toutes les configurations audio ont échoué. Dernière erreur: $lastError');
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
      case 'pcm':
        return 'audio/pcm';
      case 'flac':
        return 'audio/flac';
      case 'opus':
        return 'audio/opus';
      case '3gp':
        return 'audio/3gpp';
      default:
        return 'audio/*';
    }
  }

}