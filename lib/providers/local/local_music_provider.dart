import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/song.dart';
import '../../services/local/music_scanner_service.dart';
import 'package:flutter/services.dart';

/// 本地音乐Provider - 管理本地音乐库
class LocalMusicProvider with ChangeNotifier {
  final MusicScannerService _scanner = MusicScannerService();

  List<Song> _localSongs = [];
  List<Song> _recentScanned = [];
  bool _isScanning = false;
  String _scanStatus = '';
  double _scanProgress = 0;

  // Getters
  List<Song> get localSongs => _localSongs;
  List<Song> get recentScanned => _recentScanned;
  bool get isScanning => _isScanning;
  String get scanStatus => _scanStatus;
  double get scanProgress => _scanProgress;

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
    if (_isScanning) return;

    // 清空旧数据，确保重新扫描完全替换
    _localSongs = [];
    _recentScanned = [];
    notifyListeners();

    // 检查权限
    _scanStatus = '正在请求权限...';
    notifyListeners();

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      _scanStatus = '需要存储权限才能扫描本地音乐';
      notifyListeners();
      return;
    }

    _isScanning = true;
    _scanStatus = '正在扫描...';
    _scanProgress = 0;
    notifyListeners();

    try {
      // 获取扫描目录
      final directories = await _scanner.getMusicDirectories();

      if (directories.isEmpty) {
        _scanStatus = '未找到可扫描的目录';
        _isScanning = false;
        notifyListeners();
        return;
      }

      _scanStatus = '正在扫描 ${directories.length} 个目录...';
      notifyListeners();

      // 扫描音乐文件
      final files = await _scanner.scanMusicFiles(directories);
      final totalFiles = files.length;
      _scanStatus = '找到 $totalFiles 首音乐';
      notifyListeners();

      // 转换文件为Song对象
      final songs = <Song>[];
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final song = await _scanner.fileToSong(file);
        songs.add(song);

        // 更新进度
        _scanProgress = (i + 1) / totalFiles;
        _scanStatus = '正在处理 ${i + 1}/$totalFiles';
        if (i % 10 == 0) {
          notifyListeners();
        }
      }

      // 按标题排序
      songs.sort((a, b) => a.title.compareTo(b.title));

      _localSongs = songs;
      _recentScanned = songs.take(50).toList();
      _scanStatus = '扫描完成，共 ${songs.length} 首本地音乐';
    } catch (e) {
      _scanStatus = '扫描出错: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// 获取所有本地音乐
  List<Song> getAllLocalSongs() {
    return _localSongs;
  }

  /// 按歌手分组
  Map<String, List<Song>> getSongsByArtist() {
    final Map<String, List<Song>> grouped = {};
    for (final song in _localSongs) {
      grouped.putIfAbsent(song.artist, () => []).add(song);
    }
    return grouped;
  }

  /// 按专辑分组
  Map<String, List<Song>> getSongsByAlbum() {
    final Map<String, List<Song>> grouped = {};
    for (final song in _localSongs) {
      grouped.putIfAbsent(song.album, () => []).add(song);
    }
    return grouped;
  }

  /// 搜索本地音乐
  List<Song> searchLocalSongs(String query) {
    if (query.isEmpty) return _localSongs;
    final lowerQuery = query.toLowerCase();
    return _localSongs
        .where((song) =>
            song.title.toLowerCase().contains(lowerQuery) ||
            song.artist.toLowerCase().contains(lowerQuery) ||
            song.album.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// 添加本地音乐到播放列表
  List<Song> addToPlaylist(List<String> songIds) {
    return _localSongs
        .where((song) => songIds.contains(song.id))
        .toList();
  }

  /// 清空本地音乐
  void clearLocalMusic() {
    _localSongs = [];
    _recentScanned = [];
    _scanStatus = '';
    _scanProgress = 0;
    notifyListeners();
  }

  /// 添加单个本地音乐
  void addLocalSong(Song song) {
    if (_localSongs.any((s) => s.id == song.id)) return;

    _localSongs.add(song);
    _localSongs.sort((a, b) => a.title.compareTo(b.title));
    _scanStatus = '已添加 ${_localSongs.length} 首本地音乐';
    notifyListeners();
  }

  /// 添加多个本地音乐
  void addLocalSongs(List<Song> songs) {
    for (final song in songs) {
      if (!_localSongs.any((s) => s.id == song.id)) {
        _localSongs.add(song);
      }
    }
    _localSongs.sort((a, b) => a.title.compareTo(b.title));
    _scanStatus = '已添加 ${_localSongs.length} 首本地音乐';
    notifyListeners();
  }

  /// 从列表中移除本地音乐
  void removeLocalSong(String songId) {
    _localSongs.removeWhere((song) => song.id == songId);
    if (_localSongs.isEmpty) {
      _scanStatus = '';
    } else {
      _scanStatus = '共 ${_localSongs.length} 首本地音乐';
    }
    notifyListeners();
  }
}
