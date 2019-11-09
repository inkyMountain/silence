import 'package:audioplayers/audioplayers.dart';

AudioPlayer player;

getPlayerInstance() async {
  if (player == null) {
    // AudioPlayer.logEnabled = true;
    player = new AudioPlayer();
    await player.setReleaseMode(ReleaseMode.STOP);
  }
  return player;
}
