import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../services/api/kugou_api_service.dart';

/// 在线音乐控制器 - 使用 GetX 管理在线音乐状态
class OnlineMusicController extends GetxController {
  final KugouApiService _api = KugouApiService();

  // 搜索相关
  final RxString searchQuery = ''.obs;
  final RxList<Song> searchResults = <Song>[].obs;
  final RxList<Playlist> searchPlaylistResults = <Playlist>[].obs;
  final RxList<Artist> searchArtistResults = <Artist>[].obs;
  final RxList<Album> searchAlbumResults = <Album>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool hasMore = true.obs;
  final RxInt searchPage = 1.obs;

  // 推荐歌单
  final RxList<Playlist> recommendPlaylists = <Playlist>[].obs;
  final RxBool isLoadingPlaylists = false.obs;

  // 排行榜
  final RxList<RankItem> rankList = <RankItem>[].obs;
  final RxBool isLoadingRank = false.obs;

  // 歌词相关
  final RxString currentLyric = ''.obs;
  final RxList<LyricLine> lyricLines = <LyricLine>[].obs;

  /// 搜索音乐
  Future<void> searchMusic(String query, {bool loadMore = false}) async {
    if (query.isEmpty) return;

    if (!loadMore) {
      searchQuery.value = query;
      searchResults.clear();
      searchPage.value = 1;
      hasMore.value = true;
      isSearching.value = true;
    }

    try {
      final results = await _api.searchMusic(query, page: searchPage.value, pagesize: 30);

      if (loadMore) {
        searchResults.addAll(results);
        searchPage.value++;
      } else {
        searchResults.value = results;
        searchPage.value = 2;
      }

      hasMore.value = results.length >= 30;
    } catch (e) {
      if (kDebugMode) print('搜索失败: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// 搜索歌单
  Future<void> searchPlaylists(String query, {bool loadMore = false}) async {
    if (query.isEmpty) return;

    if (!loadMore) {
      searchQuery.value = query;
      searchPlaylistResults.clear();
      searchPage.value = 1;
      hasMore.value = true;
      isSearching.value = true;
    }

    try {
      final results = await _api.searchPlaylists(query, page: searchPage.value, pagesize: 20);

      if (loadMore) {
        searchPlaylistResults.addAll(results);
        searchPage.value++;
      } else {
        searchPlaylistResults.value = results;
        searchPage.value = 2;
      }

      hasMore.value = results.length >= 20;
    } catch (e) {
      if (kDebugMode) print('搜索歌单失败: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// 搜索歌手
  Future<void> searchArtists(String query, {bool loadMore = false}) async {
    if (query.isEmpty) return;

    if (!loadMore) {
      searchQuery.value = query;
      searchArtistResults.clear();
      searchPage.value = 1;
      hasMore.value = true;
      isSearching.value = true;
    }

    try {
      final results = await _api.searchArtists(query, page: searchPage.value, pagesize: 20);

      if (loadMore) {
        searchArtistResults.addAll(results);
        searchPage.value++;
      } else {
        searchArtistResults.value = results;
        searchPage.value = 2;
      }

      hasMore.value = results.length >= 20;
    } catch (e) {
      if (kDebugMode) print('搜索歌手失败: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// 搜索专辑
  Future<void> searchAlbums(String query, {bool loadMore = false}) async {
    if (query.isEmpty) return;

    if (!loadMore) {
      searchQuery.value = query;
      searchAlbumResults.clear();
      searchPage.value = 1;
      hasMore.value = true;
      isSearching.value = true;
    }

    try {
      final results = await _api.searchAlbums(query, page: searchPage.value, pagesize: 20);

      if (loadMore) {
        searchAlbumResults.addAll(results);
        searchPage.value++;
      } else {
        searchAlbumResults.value = results;
        searchPage.value = 2;
      }

      hasMore.value = results.length >= 20;
    } catch (e) {
      if (kDebugMode) print('搜索专辑失败: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// 加载更多搜索结果
  Future<void> loadMoreSearch() async {
    if (isSearching.value || !hasMore.value) return;
    await searchMusic(searchQuery.value, loadMore: true);
  }

  /// 获取推荐歌单
  Future<void> fetchRecommendPlaylists({int page = 1, int pagesize = 10}) async {
    if (isLoadingPlaylists.value) return;

    isLoadingPlaylists.value = true;

    try {
      recommendPlaylists.value = await _api.getRecommendPlaylists(page: page, pagesize: pagesize);
    } catch (e) {
      if (kDebugMode) print('获取推荐歌单失败: $e');
    } finally {
      isLoadingPlaylists.value = false;
    }
  }

  /// 获取排行榜列表
  Future<void> fetchRankList() async {
    if (isLoadingRank.value) return;

    isLoadingRank.value = true;

    try {
      rankList.value = await _api.getRankList();
    } catch (e) {
      if (kDebugMode) print('获取排行榜失败: $e');
    } finally {
      isLoadingRank.value = false;
    }
  }

  /// 获取排行榜详情
  Future<List<Song>> getRankSongs(String rankId, {int page = 1, int pagesize = 20}) async {
    return await _api.getRankDetail(rankId, page: page, pagesize: pagesize);
  }

  /// 获取歌词
  Future<void> fetchLyric(String hash) async {
    try {
      final lyricText = await _api.getLyric();
      currentLyric.value = lyricText;
      lyricLines.value = _api.parseLyric(lyricText);
    } catch (e) {
      if (kDebugMode) print('获取歌词失败: $e');
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
    searchQuery.value = '';
    searchResults.clear();
    searchPage.value = 1;
    hasMore.value = true;
  }

  /// 清除当前歌词
  void clearLyrics() {
    currentLyric.value = '';
    lyricLines.clear();
  }
}
