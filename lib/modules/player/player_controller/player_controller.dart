import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../../models/song.dart';
import '../../../theme/theme.dart';
import '../../../services/api/kugou_api_service.dart';

/// 播放模式
enum PlayMode {
  sequential, // 顺序播放
  loop,       // 循环播放
  single,     // 单曲循环
}

/// 播放器控制器 - 使用 GetX 管理
class PlayerController extends GetxController with GetSingleTickerProviderStateMixin {
  // ========== 核心播放控制 ==========

  final AudioPlayer _audioPlayer = AudioPlayer();
  final KugouApiService _api = KugouApiService();

  // ========== 响应式状态 ==========

  // 播放状态
  final RxBool isPlaying = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final Rx<Song?> currentSong = Rx<Song?>(null);
  final Rx<PlayMode> playMode = PlayMode.sequential.obs;

  // 播放列表
  final RxList<Song> playlist = <Song>[].obs;
  final RxInt currentIndex = 0.obs;

  // 错误信息
  final RxString errorMessage = ''.obs;

  // 加载状态
  final RxBool isLoadingUrl = false.obs;

  // 动画控制器
  late AnimationController rotationController;

  @override
  void onInit() {
    super.onInit();

    // 初始化动画控制器
    rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // 监听 just_audio 状态
    _initAudioPlayer();
  }

  @override
  void onClose() {
    rotationController.dispose();
    _audioPlayer.dispose();
    super.onClose();
  }

  /// 初始化音频播放器监听
  void _initAudioPlayer() {
    // 监听播放状态
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;

      // 播放完成时切换下一曲（跳过无法播放的歌曲）
      if (state.processingState == ProcessingState.completed) {
        seekToNext();
      }

      // 更新旋转动画
      if (state.playing && !rotationController.isAnimating) {
        rotationController.repeat();
      } else if (!state.playing && rotationController.isAnimating) {
        rotationController.stop();
      }
    });

    // 监听播放进度
    _audioPlayer.positionStream.listen((pos) {
      position.value = pos;
    });

    // 监听总时长
    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        duration.value = dur;
        errorMessage.value = '';
      }
    });

    // 监听当前索引变化
    _audioPlayer.sequenceStateStream.listen((state) {
      if (state != null && state.currentIndex >= 0) {
        currentIndex.value = state.currentIndex;
        if (state.currentSource != null) {
          final tag = state.currentSource!.tag;
          if (tag is Song) {
            currentSong.value = tag;
          }
        }
        errorMessage.value = '';
      }
    });
  }

  // ========== 播放控制 ==========

  /// 播放/暂停切换
  Future<void> togglePlay() async {
    if (isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  /// 播放
  Future<void> play() async {
    try {
      errorMessage.value = '';
      await _audioPlayer.play();
    } catch (e) {
      _handleError(e);
    }
  }

  /// 暂停
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      _handleError(e);
    }
  }

  /// 下一曲（跳过无法播放的歌曲）
  Future<void> seekToNext() async {
    if (playlist.isEmpty) return;

    // 先停止当前播放
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    int nextIndex = currentIndex.value + 1;
    int checkedCount = 0;
    final maxChecks = playlist.length;

    // 循环查找下一首可播放的歌曲
    while (checkedCount < maxChecks) {
      // 处理索引越界
      if (nextIndex >= playlist.length) {
        if (playMode.value == PlayMode.loop) {
          nextIndex = 0;
        } else {
          break;
        }
      }

      final nextSong = playlist[nextIndex];

      // 检查是否是本地歌曲且有音频URL，或者是在线歌曲
      bool canPlay = false;
      if (nextSong.isLocal && nextSong.audioUrl != null && nextSong.audioUrl!.isNotEmpty) {
        canPlay = true;
      } else if (!nextSong.isLocal && nextSong.id.isNotEmpty) {
        // 对于在线歌曲，先尝试获取播放链接
        try {
          isLoadingUrl.value = true;
          final url = await _api.getSongUrl(nextSong.id);
          if (url != null && url.isNotEmpty) {
            final updatedSong = nextSong.copyWith(audioUrl: url);
            _updateSongInPlaylist(updatedSong);
            canPlay = true;
            // 播放这首歌
            await _playDirectUrl(updatedSong, url);
            currentIndex.value = nextIndex;
            currentSong.value = updatedSong;
            isLoadingUrl.value = false;
            return;
          }
        } catch (e) {
          canPlay = false;
        } finally {
          isLoadingUrl.value = false;
        }
      } else if (nextSong.audioUrl != null && nextSong.audioUrl!.isNotEmpty) {
        // 使用已有的音频URL
        canPlay = true;
        await _playDirectUrl(nextSong, nextSong.audioUrl!);
        currentIndex.value = nextIndex;
        currentSong.value = nextSong;
        return;
      }

      if (canPlay) {
        return;
      }

      // 这首歌无法播放，继续找下一首
      nextIndex++;
      checkedCount++;
    }

    // 没有找到可播放的歌曲 - 清除播放状态
    currentSong.value = null;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    isPlaying.value = false;
    rotationController.stop();
  }

  /// 上一曲
  Future<void> seekToPrevious() async {
    if (playlist.isEmpty) return;

    // 先停止当前播放
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    int prevIndex = currentIndex.value - 1;
    int checkedCount = 0;
    final maxChecks = playlist.length;

    // 循环查找上一首可播放的歌曲
    while (checkedCount < maxChecks) {
      // 处理索引越界
      if (prevIndex < 0) {
        if (playMode.value == PlayMode.loop) {
          prevIndex = playlist.length - 1;
        } else {
          break;
        }
      }

      final prevSong = playlist[prevIndex];

      // 检查是否可以播放
      bool canPlay = false;
      if (prevSong.isLocal && prevSong.audioUrl != null && prevSong.audioUrl!.isNotEmpty) {
        canPlay = true;
      } else if (!prevSong.isLocal && prevSong.id.isNotEmpty) {
        try {
          isLoadingUrl.value = true;
          final url = await _api.getSongUrl(prevSong.id);
          if (url != null && url.isNotEmpty) {
            final updatedSong = prevSong.copyWith(audioUrl: url);
            _updateSongInPlaylist(updatedSong);
            canPlay = true;
            await _playDirectUrl(updatedSong, url);
            currentIndex.value = prevIndex;
            currentSong.value = updatedSong;
            isLoadingUrl.value = false;
            return;
          }
        } catch (e) {
          canPlay = false;
        } finally {
          isLoadingUrl.value = false;
        }
      } else if (prevSong.audioUrl != null && prevSong.audioUrl!.isNotEmpty) {
        canPlay = true;
        await _playDirectUrl(prevSong, prevSong.audioUrl!);
        currentIndex.value = prevIndex;
        currentSong.value = prevSong;
        return;
      }

      if (canPlay) {
        return;
      }

      // 这首歌无法播放，继续找上一首
      prevIndex--;
      checkedCount++;
    }

    // 没有找到可播放的歌曲 - 清除播放状态
    currentSong.value = null;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    isPlaying.value = false;
    rotationController.stop();
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _handleError(e);
    }
  }

  /// 切换播放模式
  void switchPlayMode() {
    final modes = PlayMode.values;
    final idx = modes.indexOf(playMode.value);
    final nextIdx = (idx + 1) % modes.length;
    final newMode = modes[nextIdx];
    playMode.value = newMode;

    // 设置 just_audio 循环模式
    switch (newMode) {
      case PlayMode.loop:
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case PlayMode.single:
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case PlayMode.sequential:
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
  }

  /// 播放指定歌曲（主入口）
  Future<void> playSong(Song song, {List<Song>? newPlaylist}) async {
    try {
      errorMessage.value = '';
      isLoadingUrl.value = true;

      // 如果有新播放列表，先更新播放列表
      if (newPlaylist != null && newPlaylist.isNotEmpty) {
        playlist.value = newPlaylist;
        // 找到歌曲在列表中的索引
        final index = newPlaylist.indexWhere((s) => s.id == song.id);
        if (index >= 0) {
          currentIndex.value = index;
        }
      }

      // 如果是本地歌曲（有 audioUrl），直接播放
      if (song.isLocal && song.audioUrl != null && song.audioUrl!.isNotEmpty) {
        await _playDirectUrl(song, song.audioUrl!);
        currentSong.value = song;
        isLoadingUrl.value = false;
        return;
      }

      // 在线歌曲：id 就是 hash，使用它来获取播放链接
      final hash = song.id;
      if (hash.isNotEmpty) {
        final url = await _api.getSongUrl(hash);
        if (url != null && url.isNotEmpty) {
          // 更新歌曲的播放链接
          final updatedSong = song.copyWith(audioUrl: url);
          // 更新播放列表中的歌曲
          _updateSongInPlaylist(updatedSong);
          // 更新 currentSong 为包含 audioUrl 的版本
          currentSong.value = updatedSong;
          await _playDirectUrl(updatedSong, url);
          isLoadingUrl.value = false;
          return;
        }
      }

      // 如果没有获取到播放链接，尝试使用现有的 audioUrl
      if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
        await _playDirectUrl(song, song.audioUrl!);
        currentSong.value = song;
        isLoadingUrl.value = false;
        return;
      }

      // 无法获取播放链接 - 清除播放状态
      await _audioPlayer.stop();
      currentSong.value = null;
      position.value = Duration.zero;
      duration.value = Duration.zero;
      isPlaying.value = false;
      rotationController.stop();
      isLoadingUrl.value = false;
      errorMessage.value = '暂时无法播放';

    } catch (e) {
      // 播放失败 - 清除播放状态
      await _audioPlayer.stop();
      position.value = Duration.zero;
      duration.value = Duration.zero;
      isPlaying.value = false;
      rotationController.stop();
      isLoadingUrl.value = false;
      errorMessage.value = '暂时无法播放';
    }
  }

  /// 直接播放URL
  Future<void> _playDirectUrl(Song song, String url) async {
    try {
      final uri = _buildUri(url);
      await _audioPlayer.setUrl(uri.toString());

      // 更新当前歌曲
      currentSong.value = song;

      // 开始播放
      await play();
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// 更新播放列表中的歌曲
  void _updateSongInPlaylist(Song updatedSong) {
    final index = playlist.indexWhere((s) => s.id == updatedSong.id);
    if (index >= 0) {
      playlist[index] = updatedSong;
      playlist.refresh(); // 触发 UI 更新
    }
  }

  /// 设置播放列表
  Future<void> setPlaylist(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;

    try {
      errorMessage.value = '';

      // 更新播放列表状态
      playlist.value = List.from(songs); // 创建新列表
      currentIndex.value = startIndex.clamp(0, songs.length - 1);

      final song = songs[currentIndex.value];

      // 播放指定的歌曲
      await playSong(song);
    } catch (e) {
      _handleError(e);
    }
  }

  /// 清空播放列表
  Future<void> clearPlaylist() async {
    await _audioPlayer.stop();
    playlist.clear();
    currentIndex.value = 0;
    currentSong.value = null;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    isPlaying.value = false;
    rotationController.stop();
  }

  // ========== 计算属性 ==========

  /// 是否有下一曲
  bool get hasNext {
    if (playlist.isEmpty) return false;
    return currentIndex.value < playlist.length - 1 || playMode.value == PlayMode.loop;
  }

  /// 是否有上一曲
  bool get hasPrevious {
    if (playlist.isEmpty) return false;
    return currentIndex.value > 0 || playMode.value == PlayMode.loop;
  }

  /// 格式化时间
  String formatTime(Duration time) {
    final minutes = time.inMinutes;
    final seconds = time.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// 获取当前播放进度（0-1）
  double get progress {
    if (duration.value.inMilliseconds == 0) return 0;
    return position.value.inMilliseconds / duration.value.inMilliseconds;
  }

  /// 获取播放模式图标
  IconData get playModeIcon {
    switch (playMode.value) {
      case PlayMode.loop:
        return Icons.repeat;
      case PlayMode.single:
        return Icons.repeat_one;
      case PlayMode.sequential:
        return Icons.shuffle;
    }
  }

  /// 获取播放模式颜色
  Color get playModeColor {
    return playMode.value != PlayMode.sequential
        ? AppColors.primary
        : Colors.grey;
  }

  /// 是否显示迷你播放器
  bool get showMiniPlayer => currentSong.value != null;

  // ========== 私有方法 ==========

  /// 构建 URI
  Uri _buildUri(String pathOrUrl) {
    // 处理 HTTP/HTTPS URL
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Uri.parse(pathOrUrl);
    }
    // 处理本地文件路径
    if (pathOrUrl.startsWith('/')) {
      return Uri.file(pathOrUrl);
    }
    // 默认作为文件路径处理
    return Uri.file(pathOrUrl);
  }

  /// 处理错误
  void _handleError(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('unsupported') ||
        errorStr.contains('format') ||
        errorStr.contains('extractor') ||
        errorStr.contains('codec')) {
      errorMessage.value = '不支持此音乐格式';
    } else {
      errorMessage.value = '播放失败: $e';
    }

    _showErrorSnackbar(errorMessage.value);
  }

  /// 显示错误提示
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      '播放错误',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }
}
