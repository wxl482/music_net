import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/song.dart';

/// 播放历史记录服务
class PlaybackHistoryService extends GetxController {
  static const String _historyKey = 'playback_history';
  static const int _maxHistorySize = 100; // 最多保存100条历史记录

  final RxList<Song> history = <Song>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  /// 从本地存储加载播放历史
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey);

      if (historyJson != null && historyJson.isNotEmpty) {
        final songs = historyJson
            .map((json) => Song.fromJson(jsonDecode(json)))
            .where((song) => song.id.isNotEmpty)
            .toList();
        history.value = songs;
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  /// 保存播放历史到本地存储
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = history
          .map((song) => jsonEncode(song.toJson()))
          .toList();
      await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      // 静默处理错误
    }
  }

  /// 添加歌曲到播放历史
  Future<void> addToHistory(Song song) async {
    if (song.id.isEmpty) return;

    // 移除已存在的相同歌曲
    history.removeWhere((s) => s.id == song.id);

    // 添加到开头
    history.insert(0, song);

    // 限制历史记录数量
    if (history.length > _maxHistorySize) {
      history.removeRange(_maxHistorySize, history.length);
    }

    await _saveHistory();
  }

  /// 清空播放历史
  Future<void> clearHistory() async {
    history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// 删除指定歌曲的历史记录
  Future<void> removeFromHistory(String songId) async {
    history.removeWhere((s) => s.id == songId);
    await _saveHistory();
  }

  /// 获取最近播放的歌曲（不包括当前歌曲）
  List<Song> getRecentSongs({String? excludeSongId, int limit = 10}) {
    var songs = history.toList();
    if (excludeSongId != null && excludeSongId.isNotEmpty) {
      songs = songs.where((s) => s.id != excludeSongId).toList();
    }
    return songs.take(limit).toList();
  }

  /// 检查歌曲是否在历史记录中
  bool isInHistory(String songId) {
    return history.any((s) => s.id == songId);
  }

  /// 获取历史记录数量
  int get historyCount => history.length;
}
