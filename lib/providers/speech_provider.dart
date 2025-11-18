

import 'package:flutter/material.dart';

class SpeechProvider extends ChangeNotifier {
  DateTime _lastSpeechTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool canSpeak() =>
      (DateTime.now().difference(_lastSpeechTime).compareTo(_speechCooldown)) > 0;
  static const Duration _speechCooldown = Duration(seconds: 15);

  DateTime get lastSpeechTime => _lastSpeechTime;

  void updateLastSpeechTime() {
    _lastSpeechTime = DateTime.now();
    notifyListeners();
  }
  // final FlutterTts _flutterTts = FlutterTts();

  // Future<void> speetch(String text) async {
  //   await _flutterTts.setLanguage("fr-FR");
  //   await _flutterTts.setPitch(1);
  //   await _flutterTts.speak(text);
  // }
}