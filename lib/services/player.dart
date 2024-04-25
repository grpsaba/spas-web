import 'package:audioplayers/audioplayers.dart';
import 'package:text_to_speech/text_to_speech.dart';

import '../generated/assets.dart';
import '../model.dart';

class Audio {
  static AudioPlayer player = AudioPlayer();
  static late Supervisor? supervisor;

  sos() async {
    var audiosource =  AssetSource('sos.mp3');
    if (player.state == PlayerState.stopped) {
      try {
        await player.play(audiosource);
      } catch (e) {}
    }
  }

  stopSOs() {
    if (player.state == PlayerState.playing) {
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
