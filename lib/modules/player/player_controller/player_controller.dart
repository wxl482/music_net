import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../providers/player_provider.dart';
import '../../../models/song.dart';

/// 播放器控制器
/// 桥接 GetX 和现有的 PlayerProvider
class PlayerController extends GetxController with SingleGetTickerProviderMixin {
  // PlayerProvider 实例
  late PlayerProvider _playerProvider;

  // 响应式状态
  final RxBool isPlaying = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final Rx<Song?> currentSong = Rx<Song?>(null);
  final Rx<PlayMode> playMode = PlayMode.sequential.obs;

  // 播放列表
  final RxList<Song> playlist = <Song>[].obs;
  final RxInt currentIndex = 0.obs;

  // 动画控制器
  late AnimationController rotationController;

  // 错误信息
  final RxString errorMessage = ''.obs;

  // 定时器用于同步状态
  Timer? _syncTimer;

  @override
  void onInit() {
    super.onInit();
    // 获取现有的 PlayerProvider
    _playerProvider = Get.find<PlayerProvider>();

    // 初始化动画控制器
    rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // 同步初始状态
    _syncState();

    // 监听状态变化并更新旋转状态
    ever(isPlaying, (_) => _updateRotationState());

    // 启动定时同步，确保 UI 实时更新
    _startPeriodicSync();
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    rotationController.dispose();
    super.onClose();
  }

  /// 启动定时同步
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _syncState();
    });
  }

  /// 同步状态
  void _syncState() {
    isPlaying.value = _playerProvider.isPlaying;
    position.value = _playerProvider.position;
    duration.value = _playerProvider.duration;
    currentSong.value = _playerProvider.currentSong;
    playMode.value = _playerProvider.playMode;

    // 只在列表变化时更新
    final providerPlaylist = _playerProvider.playlist;
    if (playlist.length != providerPlaylist.length ||
        currentIndex.value != _playerProvider.currentIndex) {
      playlist.assignAll(providerPlaylist);
      currentIndex.value = _playerProvider.currentIndex;
    }

    errorMessage.value = _playerProvider.errorMessage ?? '';

    // 根据播放状态控制旋转
    if (_playerProvider.isPlaying && !rotationController.isAnimating) {
      rotationController.repeat();
    } else if (!_playerProvider.isPlaying && rotationController.isAnimating) {
      rotationController.stop();
    }
  }

  /// 更新旋转状态
  void _updateRotationState() {
    if (isPlaying.value && !rotationController.isAnimating) {
      rotationController.repeat();
    } else if (!isPlaying.value && rotationController.isAnimating) {
      rotationController.stop();
    }
  }

  // ========== 播放控制 ==========

  /// 播放/暂停切换
  Future<void> togglePlay() async {
    await _playerProvider.togglePlay();
    _syncState();
  }

  /// 下一曲
  Future<void> next() async {
    await _playerProvider.seekToNext();
    _syncState();
  }

  /// 上一曲
  Future<void> previous() async {
    await _playerProvider.seekToPrevious();
    _syncState();
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _playerProvider.seek(position);
    _syncState();
  }

  /// 切换播放模式
  void switchPlayMode() {
    final modes = PlayMode.values;
    final currentIndex = modes.indexOf(playMode.value);
    final nextIndex = (currentIndex + 1) % modes.length;
    _playerProvider.setPlayMode(modes[nextIndex]);
    _syncState();
  }

  /// 播放指定歌曲
  Future<void> playSong(Song song, {List<Song>? newPlaylist}) async {
    await _playerProvider.playSong(song, playlist: newPlaylist);
    _syncState();
  }

  /// 设置播放列表
  Future<void> setPlaylist(List<Song> songs, {int startIndex = 0}) async {
    await _playerProvider.setPlaylist(songs, startIndex: startIndex);
    _syncState();
  }

  // ========== 计算属性 ==========

  /// 是否有下一曲
  bool get hasNext => _playerProvider.hasNext;

  /// 是否有上一曲
  bool get hasPrevious => _playerProvider.hasPrevious;

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
        ? const Color(0xFFFF6B6B)
        : Colors.grey;
  }

  /// 是否显示迷你播放器
  bool get showMiniPlayer => currentSong.value != null;
}
