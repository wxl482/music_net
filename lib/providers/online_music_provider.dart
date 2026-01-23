import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../services/api/kugou_api_service.dart';

/// 在线音乐 Provider
class OnlineMusicProvider with ChangeNotifier {
  final _api = KugouApiService();

  // 搜索相关
  String _searchQuery = '';
  List<Song> _searchResults = [];
  bool _isSearching = false;
  bool _hasMore = true;
  int _searchPage = 1;

  // 推荐歌单
  List<Playlist> _recommendPlaylists = [];
  bool _isLoadingPlaylists = false;

  // 排行榜
  List<RankItem> _rankList = [];
  bool _isLoadingRank = false;

  // 当前播放的在线歌曲
  Song? _currentOnlineSong;
  String? _currentLyric;
  List<LyricLine> _lyricLines = [];

  // Getters
  List<Song> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get hasMore => _hasMore;
  List<Playlist> get recommendPlaylists => _recommendPlaylists;
  bool get isLoadingPlaylists => _isLoadingPlaylists;
  List<RankItem> get rankList => _rankList;
  bool get isLoadingRank => _isLoadingRank;
  Song? get currentOnlineSong => _currentOnlineSong;
  String? get currentLyric => _currentLyric;
  List<LyricLine> get lyricLines => _lyricLines;

  /// 搜索音乐
  Future<void> searchMusic(String query, {bool loadMore = false}) async {
    if (query.isEmpty) return;

    if (!loadMore) {
      _searchQuery = query;
      _searchResults = [];
      _searchPage = 1;
      _hasMore = true;
      _isSearching = true;
      notifyListeners();
    }

    try {
      final results = await _api.searchMusic(query, page: _searchPage, pagesize: 30);

      if (loadMore) {
        _searchResults.addAll(results);
        _searchPage++;
      } else {
        _searchResults = results;
        _searchPage = 2;
      }

      _hasMore = results.length >= 30;
    } catch (e) {
      print('搜索失败: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// 加载更多搜索结果
  Future<void> loadMoreSearch() async {
    if (_isSearching || !_hasMore) return;
    await searchMusic(_searchQuery, loadMore: true);
  }

  /// 获取推荐歌单
  Future<void> fetchRecommendPlaylists({int page = 1, int pagesize = 10}) async {
    if (_isLoadingPlaylists) return;

    _isLoadingPlaylists = true;
    notifyListeners();

    try {
      _recommendPlaylists = await _api.getRecommendPlaylists(page: page, pagesize: pagesize);
    } catch (e) {
      print('获取推荐歌单失败: $e');
    } finally {
      _isLoadingPlaylists = false;
      notifyListeners();
    }
  }

  /// 获取排行榜列表
  Future<void> fetchRankList() async {
    if (_isLoadingRank) return;

    _isLoadingRank = true;
    notifyListeners();

    try {
      _rankList = await _api.getRankList();
    } catch (e) {
      print('获取排行榜失败: $e');
    } finally {
      _isLoadingRank = false;
      notifyListeners();
    }
  }

  /// 获取排行榜详情
  Future<List<Song>> getRankSongs(String rankId, {int page = 1, int pagesize = 20}) async {
    return await _api.getRankDetail(rankId, page: page, pagesize: pagesize);
  }

  /// 播放歌曲（获取播放链接）
  Future<String?> playSong(Song song) async {
    _currentOnlineSong = song;

    // 获取歌词
    if (song.id.isNotEmpty) {
      await fetchLyric(song.id);
    }

    // 获取播放链接
    if (song.id.isNotEmpty) {
      final url = await _api.getSongUrl(song.id);
      if (url != null) {
        // 更新歌曲的播放链接
        _currentOnlineSong = song.copyWith(audioUrl: url);
        return url;
      }
    }

    return null;
  }

  /// 获取歌词
  Future<void> fetchLyric(String hash) async {
    try {
      // 注意：获取歌词需要先获取accesskey，这里简化处理
      final lyricText = await _api.getLyric();
      _currentLyric = lyricText;
      _lyricLines = _api.parseLyric(lyricText);
      notifyListeners();
    } catch (e) {
      print('获取歌词失败: $e');
    }
  }

  /// 获取热搜列表
  Future<List<String>> fetchHotSearch() async {
    return await _api.getHotSearch();
  }

  /// 获取新歌速递
  Future<List<Song>> fetchNewSongs({int page = 1, int pagesize = 30}) async {
    return await _api.getNewSongs(page: page, pagesize: pagesize);
  }

  /// 获取歌手列表
  Future<List<Artist>> fetchArtistList({int page = 1, int pagesize = 30}) async {
    return await _api.getArtistList(page: page, pagesize: pagesize);
  }

  /// 获取歌手详情
  Future<ArtistDetail?> fetchArtistDetail(String singerId) async {
    return await _api.getArtistDetail(singerId);
  }

  /// 获取歌手单曲
  Future<List<Song>> fetchArtistSongs(String singerId, {int page = 1, int pagesize = 30}) async {
    return await _api.getArtistSongs(singerId, page: page, pagesize: pagesize);
  }

  /// 获取专辑详情
  Future<Album?> fetchAlbumDetail(String albumId) async {
    return await _api.getAlbumDetail(albumId);
  }

  /// 获取专辑歌曲
  Future<List<Song>> fetchAlbumSongs(String albumId, {int page = 1, int pagesize = 50}) async {
    return await _api.getAlbumSongs(albumId, page: page, pagesize: pagesize);
  }

  /// 清除搜索结果
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _searchPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  /// 清除当前播放
  void clearCurrentSong() {
    _currentOnlineSong = null;
    _currentLyric = null;
    _lyricLines = [];
    notifyListeners();
  }
}
