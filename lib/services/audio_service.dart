import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> init() async {
    await _audioPlayer.setLoopMode(LoopMode.off);
  }

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    try {
      final uri = Uri.parse(song.audioUrl!);
      await _audioPlayer.setAudioSource(
        AudioSource.uri(uri, tag: song),
      );
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  Future<void> playPlaylist(Playlist playlist, {int startIndex = 0}) async {
    try {
      final audioSource = ConcatenatingAudioSource(
        children: playlist.songs.map((song) {
          return AudioSource.uri(
            Uri.parse(song.audioUrl!),
            tag: song,
          );
        }).toList(),
      );

      await _audioPlayer.setAudioSource(audioSource, initialIndex: startIndex);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing playlist: $e');
    }
  }

  Future<void> play() => _audioPlayer.play();
  Future<void> pause() => _audioPlayer.pause();
  Future<void> stop() => _audioPlayer.stop();
  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  Future<void> seekToNext() => _audioPlayer.seekToNext();
  Future<void> seekToPrevious() => _audioPlayer.seekToPrevious();

  void setLoopMode(LoopMode mode) => _audioPlayer.setLoopMode(
        mode == LoopMode.all
            ? LoopMode.all
            : mode == LoopMode.one
                ? LoopMode.one
                : LoopMode.off,
      );

  void dispose() => _audioPlayer.dispose();
}
