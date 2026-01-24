import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/song.dart';
import '../services/local/music_scanner_service.dart';

/// 本地音乐控制器 - 使用 GetX 管理本地音乐库
class LocalMusicController extends GetxController {
  final MusicScannerService _scanner = MusicScannerService();

  // 响应式状态
  final RxList<Song> localSongs = <Song>[].obs;
  final RxList<Song> recentScanned = <Song>[].obs;
  final RxBool isScanning = false.obs;
  final RxString scanStatus = ''.obs;
  final RxDouble scanProgress = 0.0.obs;

  /// 检查并请求存储权限
  Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      try {
        // 检查 Android 13+ (API 33+)
        final sdkVersion = await const MethodChannel('flutter.permission/SDK_VERSION')
            .invokeMethod<int>('getSDKVersion') ?? 0;

        if (sdkVersion >= 33) {
          // Android 13+ 使用 READ_MEDIA_AUDIO
          final status = await const MethodChannel('flutter.permission/permission')
              .invokeMethod<String>('requestPermission', {'permission': 'android.permission.READ_MEDIA_AUDIO'});
          return status == 'granted';
        } else {
          // Android 12 及以下使用 READ_EXTERNAL_STORAGE
          final status = await const MethodChannel('flutter.permission/permission')
              .invokeMethod<String>('requestPermission', {'permission': 'android.permission.READ_EXTERNAL_STORAGE'});
          return status == 'granted';
        }
      } catch (e) {
        // 如果平台通道失败，假设有权限
        return true;
      }
    }
    return true;
  }

  /// 扫描本地音乐
  Future<void> scanLocalMusic() async {
    if (isScanning.value) return;

    // 清空旧数据，确保重新扫描完全替换
    localSongs.clear();
    recentScanned.clear();

    // 检查权限
    scanStatus.value = '正在请求权限...';

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      scanStatus.value = '需要存储权限才能扫描本地音乐';
      return;
    }

    isScanning.value = true;
    scanStatus.value = '正在扫描...';
    scanProgress.value = 0;

    try {
      // 获取扫描目录
      final directories = await _scanner.getMusicDirectories();

      if (directories.isEmpty) {
        scanStatus.value = '未找到可扫描的目录';
        isScanning.value = false;
        return;
      }

      scanStatus.value = '正在扫描 ${directories.length} 个目录...';

      // 扫描音乐文件
      final files = await _scanner.scanMusicFiles(directories);
      final totalFiles = files.length;
      scanStatus.value = '找到 $totalFiles 首音乐';

      // 转换文件为Song对象
      final songs = <Song>[];
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final song = await _scanner.fileToSong(file);
        songs.add(song);

        // 更新进度
        scanProgress.value = (i + 1) / totalFiles;
        scanStatus.value = '正在处理 ${i + 1}/$totalFiles';
      }

      // 按标题排序
      songs.sort((a, b) => a.title.compareTo(b.title));

      localSongs.value = songs;
      recentScanned.value = songs.take(50).toList();
      scanStatus.value = '扫描完成，共 ${songs.length} 首本地音乐';
    } catch (e) {
      scanStatus.value = '扫描出错: $e';
    } finally {
      isScanning.value = false;
    }
  }

  /// 获取所有本地音乐
  List<Song> getAllLocalSongs() {
    return localSongs.toList();
  }

  /// 按歌手分组
  Map<String, List<Song>> getSongsByArtist() {
    final Map<String, List<Song>> grouped = {};
    for (final song in localSongs) {
      grouped.putIfAbsent(song.artist, () => []).add(song);
    }
    return grouped;
  }

  /// 按专辑分组
  Map<String, List<Song>> getSongsByAlbum() {
    final Map<String, List<Song>> grouped = {};
    for (final song in localSongs) {
      grouped.putIfAbsent(song.album, () => []).add(song);
    }
    return grouped;
  }

  /// 搜索本地音乐
  List<Song> searchLocalSongs(String query) {
    if (query.isEmpty) return localSongs.toList();
    final lowerQuery = query.toLowerCase();
    return localSongs
        .where((song) =>
            song.title.toLowerCase().contains(lowerQuery) ||
            song.artist.toLowerCase().contains(lowerQuery) ||
            song.album.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// 添加本地音乐到播放列表
  List<Song> addToPlaylist(List<String> songIds) {
    return localSongs
        .where((song) => songIds.contains(song.id))
        .toList();
  }

  /// 清空本地音乐
  void clearLocalMusic() {
    localSongs.clear();
    recentScanned.clear();
    scanStatus.value = '';
    scanProgress.value = 0;
  }

  /// 添加单个本地音乐
  void addLocalSong(Song song) {
    if (localSongs.any((s) => s.id == song.id)) return;

    localSongs.add(song);
    localSongs.sort((a, b) => a.title.compareTo(b.title));
    scanStatus.value = '已添加 ${localSongs.length} 首本地音乐';
  }

  /// 添加多个本地音乐
  void addLocalSongs(List<Song> songs) {
    for (final song in songs) {
      if (!localSongs.any((s) => s.id == song.id)) {
        localSongs.add(song);
      }
    }
    localSongs.sort((a, b) => a.title.compareTo(b.title));
    scanStatus.value = '已添加 ${localSongs.length} 首本地音乐';
  }

  /// 从列表中移除本地音乐
  void removeLocalSong(String songId) {
    localSongs.removeWhere((song) => song.id == songId);
    if (localSongs.isEmpty) {
      scanStatus.value = '';
    } else {
      scanStatus.value = '共 ${localSongs.length} 首本地音乐';
    }
  }
}
