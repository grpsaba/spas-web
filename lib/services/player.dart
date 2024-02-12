import 'package:audioplayers/audioplayers.dart';
import 'package:text_to_speech/text_to_speech.dart';

import '../generated/assets.dart';
import '../model.dart';

class Audio {
  static var player = AudioPlayer();
  static const audiosource = Assets.assetsSos;
  static late Supervisor? supervisor;

  sos() async {
    if (player.state == AudioPlayerState.STOPPED) {
      try {
        await player.play(audiosource, volume: 1.0);
      } catch (e) {}
    }
  }

  stopSOs() {
    if (player.state == AudioPlayerState.PLAYING) {
      try {
        player.stop();
      } catch (e) {}
    }
  }
}

class TTS {
  static TextToSpeech tts = TextToSpeech()
    ..setLanguage("Fr")
    ..setRate(4.0);

  speetch(String text) {
    tts.speak(text);

    //List<String>? voices = await tts.getVoice();
  }
}
