import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/song.dart';
import '../api/kugou_api_service.dart';

/// 音频处理器 - 用于后台播放和通知栏控制
class PlaybackAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final KugouApiService _api = KugouApiService();

  PlaybackAudioHandler() {
    // 初始化空播放列表
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.sequenceStateStream.listen((state) {
      if (state?.currentIndex != null) {
        mediaItem.add(state?.currentSource?.tag as MediaItem?);
      }
    });
  }

  /// 转换播放事件
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    );
  }

  /// 播放
  @override
  Future<void> play() async {
    _player.play();
  }

  /// 暂停
  @override
  Future<void> pause() async {
    _player.pause();
  }

  /// 停止
  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  /// 下一曲
  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  /// 上一曲
  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  /// 跳转到指定位置
  @override
  Future<void> seek(Duration position) async {
    _player.seek(position);
  }

  /// 设置播放速度
  @override
  Future<void> setSpeed(double speed) async {
    _player.setSpeed(speed);
  }

  /// 从歌曲列表播放
  Future<void> playSongs(List<Song> songs, int startIndex) async {
    // 获取每首歌曲的播放链接
    final audioSources = <AudioSource>[];
    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      String? url;

      if (song.isLocal && song.audioUrl != null && song.audioUrl!.isNotEmpty) {
        url = song.audioUrl;
      } else if (song.id.isNotEmpty) {
        url = await _api.getSongUrl(song.id);
      }

      if (url != null && url.isNotEmpty) {
        audioSources.add(
          AudioSource.uri(
            Uri.parse(url),
            tag: _songToMediaItem(song),
          ),
        );
      }
    }

    if (audioSources.isNotEmpty) {
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: startIndex.clamp(0, audioSources.length - 1),
      );
      await _player.play();
    }
  }

  /// 播放单首歌曲
  Future<void> playSong(Song song) async {
    String? url;

    if (song.isLocal && song.audioUrl != null && song.audioUrl!.isNotEmpty) {
      url = song.audioUrl;
    } else if (song.id.isNotEmpty) {
      url = await _api.getSongUrl(song.id);
    }

    if (url != null && url.isNotEmpty) {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: _songToMediaItem(song),
        ),
      );
      await _player.play();
    }
  }

  /// 将歌曲转换为 MediaItem
  MediaItem _songToMediaItem(Song song) {
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album ?? '',
      artUri: song.coverUrl != null && song.coverUrl!.isNotEmpty
          ? Uri.parse(song.coverUrl!)
          : null,
      duration: song.duration,
    );
  }

  /// 获取播放器实例（用于与 PlayerController 集成）
  AudioPlayer get player => _player;
}
