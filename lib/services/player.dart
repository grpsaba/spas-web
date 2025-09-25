import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:text_to_speech/text_to_speech.dart';

import '../generated/assets.dart';
import '../model.dart';

class Audio {
  static AudioPlayer player = AudioPlayer();
  static late Supervisor? supervisor;
  
  // Variables pour contrôler le debouncing et l'état
  static bool _isPlaying = false;
  static Timer? _debounceTimer;
  static DateTime? _lastSosTime;
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  static const Duration _minTimeBetweenSos = Duration(seconds: 3);

  // Singleton pour éviter les instances multiples
  static final Audio _instance = Audio._internal();
  factory Audio() => _instance;
  Audio._internal();

  sos() async {
    final now = DateTime.now();
    
    // Vérifier si assez de temps s'est écoulé depuis le dernier SOS
    if (_lastSosTime != null && 
        now.difference(_lastSosTime!) < _minTimeBetweenSos) {
      return; // Trop tôt pour rejouer
    }
    
    // Annuler le timer précédent s'il existe
    _debounceTimer?.cancel();
    
    // Créer un nouveau timer de debounce
    _debounceTimer = Timer(_debounceDuration, () async {
      await _playSos();
    });
  }

  Future<void> _playSos() async {
    if (_isPlaying) {
      return; // Déjà en train de jouer
    }
    
    try {
      _isPlaying = true;
      
      // Arrêter complètement tout son en cours
      await _forceStop();
      
      // Petite pause pour s'assurer que l'arrêt est effectif
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Jouer le son SOS
      var audioSource = AssetSource('sos.mp3');
      await player.play(audioSource);
      
      _lastSosTime = DateTime.now();
      
      // Écouter la fin du son pour remettre à jour l'état
      player.onPlayerComplete.first.then((_) {
        _isPlaying = false;
      });
      
    } catch (e) {
      _isPlaying = false;
      // Log l'erreur si nécessaire
      print('Erreur lors de la lecture du SOS: $e');
    }
  }

  Future<void> _forceStop() async {
    try {
      if (player.state == PlayerState.playing || 
          player.state == PlayerState.paused) {
        await player.stop();
        
        // Attendre que l'état soit réellement arrêté
        while (player.state != PlayerState.stopped) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      print('Erreur lors de l\'arrêt du player: $e');
    }
  }

  stopSOs() async {
    // Annuler le timer de debounce
    _debounceTimer?.cancel();
    
    try {
      await _forceStop();
      _isPlaying = false;
    } catch (e) {
      print('Erreur lors de l\'arrêt du SOS: $e');
    }
  }
  
  // Méthode pour vérifier si un SOS est en cours
  bool get isPlayingSos => _isPlaying;
  
  // Méthode pour nettoyer les ressources
  static void dispose() {
    _debounceTimer?.cancel();
    player.dispose();
  }
}

class TTS {
  static TextToSpeech tts = TextToSpeech()
    ..setLanguage("Fr")
    ..setRate(2.0);

  speetch(String text) {
    tts.speak(text);

    //List<String>? voices = await tts.getVoice();
  }
}
