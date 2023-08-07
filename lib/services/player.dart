import 'package:audioplayers/audioplayers.dart';

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
