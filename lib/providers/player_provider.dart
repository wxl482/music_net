import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

enum PlayMode {
  sequential,
  loop,
  single,
}

class PlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Playback state
  List<Song> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayMode _playMode = PlayMode.sequential;

  // Error handling
  String? _errorMessage;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  List<Song> get playlist => _playlist;
  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  PlayMode get playMode => _playMode;
  String? get errorMessage => _errorMessage;

  // Computed
  bool get hasNext => _currentIndex < _playlist.length - 1 || _playMode == PlayMode.loop;
  bool get hasPrevious => _currentIndex > 0 || _playMode == PlayMode.loop;

  PlayerProvider() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    // Handle playback errors - errors are caught in play() method
    _audioPlayer.playbackEventStream.listen((event) {
      // Just track playback state, errors handled via try-catch
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        // Auto play next
        if (hasNext) {
          seekToNext();
        }
      }
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        _errorMessage = null;
        notifyListeners();
      }
    });

    _audioPlayer.sequenceStateStream.listen((state) {
      if (state != null) {
        _currentIndex = state.currentIndex;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> setPlaylist(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;

    _playlist = songs;
    _currentIndex = startIndex.clamp(0, songs.length - 1);
    _errorMessage = null;
    notifyListeners();

    try {
      final audioSource = ConcatenatingAudioSource(
        children: songs.map((song) {
          final uri = _buildUri(song.audioUrl!);
          return AudioSource.uri(
            uri,
            tag: song,
          );
        }).toList(),
      );

      await _audioPlayer.setAudioSource(
        audioSource,
        initialIndex: _currentIndex,
      );
    } catch (e) {
      _errorMessage = '加载播放列表失败: $e';
      notifyListeners();
    }
  }

  Uri _buildUri(String pathOrUrl) {
    // 如果是本地文件路径，确保使用 file:// 协议
    if (pathOrUrl.startsWith('/')) {
      return Uri.file(pathOrUrl);
    } else if (!pathOrUrl.contains('://')) {
      // 假设没有协议的都是本地路径
      return Uri.file(pathOrUrl);
    }
    return Uri.parse(pathOrUrl);
  }

  Future<void> play() async {
    try {
      _errorMessage = null;
      await _audioPlayer.play();
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('unsupported') ||
          errorStr.contains('format') ||
          errorStr.contains('extractor') ||
          errorStr.contains('codec')) {
        _errorMessage = '不支持此音乐格式，请尝试其他格式的文件';
      } else {
        _errorMessage = '播放失败: $e';
      }
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekToNext() async {
    if (hasNext) {
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> seekToPrevious() async {
    if (hasPrevious) {
      await _audioPlayer.seekToPrevious();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void setPlayMode(PlayMode mode) {
    _playMode = mode;
    _audioPlayer.setLoopMode(
      mode == PlayMode.loop
          ? LoopMode.all
          : mode == PlayMode.single
              ? LoopMode.one
              : LoopMode.off,
    );
    notifyListeners();
  }

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    try {
      _errorMessage = null;
      if (playlist != null && playlist.isNotEmpty) {
        await setPlaylist(playlist);
      }

      final index = _playlist.indexWhere((s) => s.id == song.id);
      if (index >= 0) {
        _currentIndex = index;
        await _audioPlayer.seek(Duration.zero, index: index);
      }
      await play();
    } catch (e) {
      _errorMessage = '播放失败: $e';
      notifyListeners();
    }
  }

  void addToQueue(Song song) {
    _playlist.add(song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);
      notifyListeners();
    }
  }

  void clearQueue() {
    _playlist = [];
    _currentIndex = 0;
    _audioPlayer.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
