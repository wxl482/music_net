import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'app.dart';
import 'services/audio/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化音频服务
  final audioHandler = await AudioService.init(
    builder: () => PlaybackAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'music.net.channel.audio',
      androidNotificationChannelName: 'Music Net',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: false,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(App(audioHandler: audioHandler));
}
