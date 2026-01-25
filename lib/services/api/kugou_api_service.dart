import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../models/playlist_detail.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/banner.dart';
import '../../models/rank.dart';
import '../../models/lyric.dart';

// 导出类型别名方便使用
export '../../models/playlist.dart' show RankItem;

/// 酷狗音乐 API 服务 (本地服务器版本)
class KugouApiService {
  static final KugouApiService _instance = KugouApiService._();
  factory KugouApiService() => _instance;
  KugouApiService._();

  // API 服务器地址
  static const String _baseUrl = 'http://192.168.10.231:3000';

  // Dio 实例（带日志拦截器）
  static final Dio _dio = _createDio();

  // dfid 缓存
  String? _dfid;

  /// 创建带日志的 Dio 实例
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // 添加日志拦截器
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) {
          if (kDebugMode) print('[DIO] $obj');
        },
        ),
      );
    }

    return dio;
  }

  /// 搜索音乐
  /// GET /search?keywords=xxx&type=song
  /// type: special=歌单, lyric=歌词, song=歌曲, album=专辑, author=歌手, mv=视频
  Future<Map<String, dynamic>> search(
    String keywords, {
    String type = 'song',
    int page = 1,
    int pagesize = 30,
  }) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'keywords': keywords,
          'type': type,
          'page': page,
          'pagesize': pagesize,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) print('搜索失败: $e');
    }
    return {};
  }

  /// 搜索音乐（简化版本，返回歌曲列表）
  Future<List<Song>> searchMusic(String keywords, {int page = 1, int pagesize = 30}) async {
    final result = await search(keywords, type: 'song', page: page, pagesize: pagesize);
    final lists = result['data']?['lists'] as List? ?? [];
    return lists.map((item) => _parseSong(item)).toList();
  }

  /// 搜索歌单
  Future<List<Playlist>> searchPlaylists(String keywords, {int page = 1, int pagesize = 20}) async {
    final result = await search(keywords, type: 'special', page: page, pagesize: pagesize);
    final lists = result['data']?['lists'] as List? ?? [];
    return lists.map((item) => _parsePlaylist(item)).toList();
  }

  /// 搜索歌手
  Future<List<Artist>> searchArtists(String keywords, {int page = 1, int pagesize = 20}) async {
    final result = await search(keywords, type: 'author', page: page, pagesize: pagesize);
    final lists = result['data']?['lists'] as List? ?? [];
    return lists.map((item) => _parseArtist(item)).toList();
  }

  /// 搜索专辑
  Future<List<Album>> searchAlbums(String keywords, {int page = 1, int pagesize = 20}) async {
    final result = await search(keywords, type: 'album', page: page, pagesize: pagesize);
    final lists = result['data']?['lists'] as List? ?? [];
    return lists.map((item) => _parseAlbum(item)).toList();
  }

  /// 搜索MV
  Future<List<Map<String, dynamic>>> searchMVs(String keywords, {int page = 1, int pagesize = 20}) async {
    final result = await search(keywords, type: 'mv', page: page, pagesize: pagesize);
    final lists = result['data']?['lists'] as List? ?? [];
    return lists.map((item) => item as Map<String, dynamic>).toList();
  }

  /// 注册设备获取 dfid
  /// POST /register/dev
  Future<String?> _registerDevice() async {
    if (_dfid != null && _dfid!.isNotEmpty) {
      return _dfid;
    }

    try {
      final response = await _dio.post(
        '/register/dev',
        data: {
          'mid': '',
          'uuid': '',
          'userid': '0',
        },
      );

      if (kDebugMode) {
        print('[注册设备] 响应: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        // 从响应中获取 dfid
        if (response.data['data'] != null) {
          _dfid = response.data['data']['dfid'] as String?;
          if (kDebugMode) print('[注册设备] 获取到 dfid: $_dfid');
          return _dfid;
        }
      }
    } catch (e) {
      if (kDebugMode) print('[注册设备] 失败: $e');
    }
    return null;
  }

  /// 获取歌曲播放链接
  /// GET /song/url?hash=xxx
  Future<String?> getSongUrl(String hash, {int quality = 128}) async {
    if (hash.isEmpty) {
      if (kDebugMode) print('[歌曲URL] hash为空');
      return null;
    }

    // 先注册设备获取 dfid
    final dfid = await _registerDevice();
    if (dfid == null || dfid.isEmpty) {
      if (kDebugMode) print('[歌曲URL] 无法获取 dfid');
      return null;
    }

    try {
      final response = await _dio.get(
        '/song/url',
        queryParameters: {
          'hash': hash.toLowerCase(),
          'quality': quality,
        },
        options: Options(
          headers: {
            'Cookie': 'dfid=$dfid',
          },
        ),
      );

      if (kDebugMode) {
        print('[歌曲URL] hash=$hash, dfid=$dfid');
        print('[歌曲URL] 响应状态: ${response.statusCode}');
        print('[歌曲URL] 响应数据: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        // 检查是否有错误
        if (response.data['fail_process'] != null) {
          if (kDebugMode) print('[歌曲URL] 响应包含错误: ${response.data}');
          return null;
        }

        // 查找播放链接 - 响应格式: { url: ["...", "..."] } 或 { data: { url: "..." } }
        // url 可能是一个数组，取第一个有效的 URL
        final urlData = response.data['url'];
        if (urlData != null) {
          if (urlData is String && urlData.isNotEmpty) {
            if (kDebugMode) print('[歌曲URL] 找到播放链接: $urlData');
            return urlData;
          } else if (urlData is List && urlData.isNotEmpty) {
            final url = urlData[0] as String?;
            if (url != null && url.isNotEmpty) {
              if (kDebugMode) print('[歌曲URL] 找到播放链接(数组): $url');
              return url;
            }
          }
        }

        // 检查 backupUrl 备用链接
        final backupUrlData = response.data['backupUrl'];
        if (backupUrlData is List && backupUrlData.isNotEmpty) {
          final url = backupUrlData[0] as String?;
          if (url != null && url.isNotEmpty) {
            if (kDebugMode) print('[歌曲URL] 找到备用播放链接: $url');
            return url;
          }
        }

        if (response.data['data'] != null && response.data['data']['url'] != null) {
          final url = response.data['data']['url'];
          if (kDebugMode) print('[歌曲URL] 找到播放链接(data): $url');
          return url;
        }

        if (kDebugMode) print('[歌曲URL] 响应中未找到url字段');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[DIO错误] 获取播放链接失败: ${e.message}');
        print('[DIO错误] 响应状态: ${e.response?.statusCode}');
        print('[DIO错误] 响应数据: ${e.response?.data}');
      }
    } catch (e) {
      if (kDebugMode) print('[歌曲URL] 异常: $e');
    }

    if (kDebugMode) print('[歌曲URL] 无法获取播放链接');
    return null;
  }

  /// 获取推荐歌单
  /// POST /top/playlist
  Future<List<Playlist>> getRecommendPlaylists({int page = 1, int pagesize = 10}) async {
    try {
      final response = await _dio.post(
        '/top/playlist',
        data: {
          'page': page,
          'pagesize': pagesize,
        },
      );

      if (response.statusCode == 200) {
        final specialList = response.data['data']['special_list'] as List? ?? [];
        return specialList.map((item) => _parsePlaylist(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('获取推荐歌单失败: $e');
    }
    return [];
  }

  /// 获取歌单详情
  /// GET /playlist/detail?ids=xxx
  Future<PlaylistDetail?> getPlaylistDetail(String globalCollectionId) async {
    final data = await getPlaylistDetailRaw(globalCollectionId);
    if (data == null) return null;
    return _parsePlaylistDetail(data['info']);
  }

  /// 获取歌单详情（带歌曲数据）
  /// 同时获取歌单信息和歌曲列表，返回实体类
  Future<PlaylistDetailData?> getPlaylistDetailWithSongs(
    String globalCollectionId, {
    int page = 1,
    int pagesize = 100,
  }) async {
    try {
      // 并行获取歌单信息和歌曲列表
      final results = await Future.wait([
        _dio.get('/playlist/detail', queryParameters: {'ids': globalCollectionId}),
        _dio.get('/playlist/track/all', queryParameters: {
          'id': globalCollectionId,
          'page': page,
          'pagesize': pagesize,
        }),
      ]);

      final detailResponse = results[0];
      final songsResponse = results[1];

      if (detailResponse.statusCode != 200 || songsResponse.statusCode != 200) {
        if (kDebugMode) {
          print('获取歌单详情失败: HTTP ${detailResponse.statusCode} / ${songsResponse.statusCode}');
        }
        return null;
      }

      // 解析歌单基本信息
      final detailData = detailResponse.data['data'];
      Map<String, dynamic> detailJson = {};

      if (detailData == null || (detailData is Map && detailData.isEmpty)) {
        if (kDebugMode) print('获取歌单详情失败: 返回数据为空');
        return null;
      }

      // 如果 data 是数组，取第一个元素
      if (detailData is List && detailData.isNotEmpty) {
        detailJson = detailData[0] as Map<String, dynamic>;
      } else if (detailData is Map) {
        detailJson = detailData as Map<String, dynamic>;
      }

      // 合并歌曲数据
      final songsData = songsResponse.data['data'];
      if (songsData != null && songsData is Map) {
        detailJson['songs'] = songsData;
      }

      return PlaylistDetailData.fromJson(detailJson);
    } catch (e) {
      if (kDebugMode) print('获取歌单详情失败: $e');
      return null;
    }
  }

  /// 获取歌单详情原始数据（保留兼容性）
  /// GET /playlist/detail?ids=xxx
  @deprecated
  Future<Map<String, dynamic>?> getPlaylistDetailRaw(String globalCollectionId) async {
    try {
      final response = await _dio.get(
        '/playlist/detail',
        queryParameters: {'ids': globalCollectionId},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        // 检查 data 是否为空
        if (data == null || (data is Map && data.isEmpty)) {
          if (kDebugMode) print('获取歌单详情失败: 返回数据为空');
          return null;
        }

        // 如果 data 是数组，取第一个元素
        if (data is List && data.isNotEmpty) {
          return data[0] as Map<String, dynamic>;
        }

        // 如果 data 是对象，直接返回
        if (data is Map) {
          return data as Map<String, dynamic>;
        }

        if (kDebugMode) print('获取歌单详情失败: 数据格式错误');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('获取歌单详情失败: $e');
    }
    return null;
  }

  /// 获取歌单所有歌曲（保留兼容性）
  /// GET /playlist/track/all?id=xxx&page=1&pagesize=100
  @deprecated
  Future<Map<String, dynamic>?> getPlaylistSongs(
    String globalCollectionId, {
    int page = 1,
    int pagesize = 100,
  }) async {
    try {
      final response = await _dio.get(
        '/playlist/track/all',
        queryParameters: {
          'id': globalCollectionId,
          'page': page,
          'pagesize': pagesize,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data is Map) {
          return data as Map<String, dynamic>;
        }
        if (kDebugMode) print('获取歌单歌曲失败: data 格式错误');
      } else {
        if (kDebugMode) print('获取歌单歌曲失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('获取歌单歌曲失败: $e');
    }
    return null;
  }

  /// 获取排行榜列表
  /// GET /rank/list
  Future<List<RankItem>> getRankList() async {
    try {
      final response = await _dio.get('/rank/list');

      if (response.statusCode == 200) {
        final info = response.data['data']['info'] as List? ?? [];
        return info.map((item) => _parseRankItem(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('获取排行榜失败: $e');
    }
    return [];
  }

  /// 获取排行榜详情(歌曲列表)
  /// GET /rank/info?rankid=xxx
  Future<List<Song>> getRankDetail(String rankId, {int page = 1, int pagesize = 20}) async {
    try {
      final response = await _dio.get(
        '/rank/info',
        queryParameters: {'rankid': rankId, 'page': page, 'pagesize': pagesize},
      );

      if (response.statusCode == 200) {
        final songs = response.data['data']['songs'] as List? ?? [];
        return songs.map((item) => _parseSong(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('获取排行榜详情失败: $e');
    }
    return [];
  }

  /// 获取新歌速递
  /// POST /top/song
  Future<List<Song>> getNewSongs({int page = 1, int pagesize = 30}) async {
    try {
      final response = await _dio.post(
        '/top/song',
        data: {
          'page': page,
          'pagesize': pagesize,
        },
      );

      if (response.statusCode == 200) {
        // API 返回格式: { "total": 100, "error_code": 0, "data": [...] }
        final lists = response.data['data'] as List? ?? [];
        return lists.map((item) => _parseSong(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('获取新歌失败: $e');
    }
    return [];
  }

  /// 获取歌手列表
  /// GET /artist/list
  Future<List<Artist>> getArtists({int page = 1, int pagesize = 30}) async {
    try {
      final response = await _dio.get(
        '/artist/list',
        queryParameters: {'page': page, 'pagesize': pagesize},
      );

      if (response.statusCode == 200) {
        final list = response.data['data']['list']['info'] as List? ?? [];
        return list.map((item) => _parseArtist(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('获取歌手列表失败: $e');
    }
    return [];
  }

  /// 获取歌手详情
  /// GET /artist/info?artistid=xxx
  Future<ArtistDetail?> getArtistDetail(String artistId) async {
    try {
      final response = await _dio.get(
        '/artist/info',
        queryParameters: {'artistid': artistId},
      );

      if (response.statusCode == 200) {
        return _parseArtistDetail(response.data['data']);
      }
    } catch (e) {
      if (kDebugMode) print('获取歌手详情失败: $e');
    }
    return null;
  }

  /// 获取专辑详情
  /// GET /album/detail?id=xxx
  Future<Album?> getAlbumDetail(String albumId) async {
    try {
      final response = await _dio.get(
        '/album/detail',
        queryParameters: {'id': albumId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List && data.isNotEmpty) {
          return _parseAlbumDetail(data[0]);
        }
      }
    } catch (e) {
      if (kDebugMode) print('获取专辑详情失败: $e');
    }
    return null;
  }

  /// 获取专辑歌曲列表
  /// GET /album/songs?id=xxx
  Future<List<Song>> getAlbumSongs(String albumId, {int page = 1, int pagesize = 50}) async {
    try {
      final response = await _dio.get(
        '/album/songs',
        queryParameters: {
          'id': albumId,
          'page': page,
          'pagesize': pagesize,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data is Map) {
          final list = data['songs'] as List? ?? []; // 专辑歌曲列表
          return list.map((item) => _parseAlbumSong(item)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('获取专辑歌曲失败: $e');
    }
    return [];
  }

  /// 获取歌词
  /// 需要先通过 /search/lyric 获取 id 和 accesskey，然后再获取歌词
  Future<String> getLyric([String? hash]) async {
    try {
      if (hash == null || hash.isEmpty) {
        return '';
      }

      // 第一步：搜索歌词获取 id 和 accesskey
      final searchResponse = await _dio.get(
        '/search/lyric',
        queryParameters: {'hash': hash},
      );

      if (searchResponse.statusCode != 200 || searchResponse.data['status'] != 200) {
        return '';
      }

      final candidates = searchResponse.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return '';
      }

      // 取第一个候选歌词
      final firstLyric = candidates[0] as Map<String, dynamic>?;
      if (firstLyric == null) {
        return '';
      }

      final id = firstLyric['id']?.toString();
      final accesskey = firstLyric['accesskey']?.toString();

      if (id == null || id.isEmpty || accesskey == null || accesskey.isEmpty) {
        return '';
      }

      // 第二步：使用 id 和 accesskey 获取歌词内容
      final lyricResponse = await _dio.get(
        '/lyric',
        queryParameters: {
          'id': id,
          'accesskey': accesskey,
          'fmt': 'lrc',
          'decode': 'true',
        },
      );

      if (lyricResponse.statusCode == 200 && lyricResponse.data['status'] == 200) {
        // 返回解码后的歌词内容，直接从根级别获取
        return lyricResponse.data['decodeContent'] ??
               lyricResponse.data['content'] ?? '';
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取歌词失败: $e');
      }
    }
    return '';
  }

  /// 获取热搜列表
  /// GET /search/hot
  Future<List<String>> getHotSearch() async {
    try {
      final response = await _dio.get('/search/hot');

      if (response.statusCode == 200) {
        final list = response.data['data'] as List? ?? [];
        return list.map((item) => item['keyword'] as String? ?? '').toList();
      }
    } catch (e) {
      if (kDebugMode) print('获取热搜失败: $e');
    }
    return [];
  }

  /// 获取轮播图数据（使用推荐歌单接口）
  /// GET /top/playlist?category_id=0
  Future<List<BannerItem>> getBanners({int pagesize = 5}) async {
    try {
      final response = await _dio.get(
        '/top/playlist',
        queryParameters: {'category_id': 0, 'pagesize': pagesize},
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['special_list'] as List? ?? [];
        return data.map((item) => _parseBannerItem(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('获取轮播图失败: $e');
    }
    return [];
  }

  /// 解析轮播图数据
  BannerItem _parseBannerItem(Map<String, dynamic> item) {
    // 处理封面图片 URL，替换 {size} 占位符
    String? coverUrl = item['imgurl'] ?? item['flexible_cover'] ?? item['pic'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '600');
    }

    return BannerItem(
      id: item['specialid']?.toString() ?? '',
      title: item['specialname'] ?? item['show'] ?? '',
      imageUrl: coverUrl ?? '',
      url: item['global_collection_id']?.toString() ?? '',
      description: item['intro'] ?? '',
      playCount: item['play_count'] ?? 0,
    );
  }

  /// 获取歌手列表 (别名方法)
  Future<List<Artist>> getArtistList({int page = 1, int pagesize = 30}) async {
    return getArtists(page: page, pagesize: pagesize);
  }

  /// 获取歌手单曲
  /// GET /artist/songs?artistid=xxx
  Future<List<Song>> getArtistSongs(String artistId, {int page = 1, int pagesize = 30}) async {
    try {
      final response = await _dio.get(
        '/artist/songs',
        queryParameters: {'artistid': artistId, 'page': page, 'pagesize': pagesize},
      );

      if (response.statusCode == 200) {
        final list = response.data['data']['list'] as List? ?? response.data['data'] as List? ?? [];
        return list.map((item) => _parseSong(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('获取歌手单曲失败: $e');
    }
    return [];
  }

  // ========== 私有方法 - 解析数据 ==========

  /// 解析歌单数据
  Playlist _parsePlaylist(Map<String, dynamic> item) {
    final songs = (item['songs'] as List? ?? [])
        .map((s) => _parseSong(s))
        .toList();

    // 处理封面图片 URL，替换 {size} 占位符
    String? coverUrl = item['imgurl'] ?? item['flexible_cover'] ?? item['cover'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '300');
    }

    return Playlist(
      id: item['specialid']?.toString() ?? '',
      globalCollectionId: item['global_collection_id']?.toString() ?? '',
      name: item['specialname'] ?? item['name'] ?? '未知歌单',
      coverUrl: coverUrl,
      playCount: item['play_count'] ?? item['playCount'] ?? 0,
      trackCount: item['songcount'] ?? songs.length,
      creatorName: item['nickname'],
      description: item['intro'],
      songs: songs,
      tags: (item['tags'] as List? ?? [])
          .map((t) => t['tag_name'] as String? ?? '')
          .toList(),
    );
  }

  /// 解析歌单详情
  PlaylistDetail _parsePlaylistDetail(Map<String, dynamic> item) {
    final songs = (item['songs'] as List? ?? [])
        .map((s) => _parseSong(s))
        .toList();

    // 处理封面图片 URL，替换 {size} 占位符
    String? coverUrl = item['imgurl'] ?? item['cover'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '300');
    }

    return PlaylistDetail(
      id: item['global_collection_id']?.toString() ?? '',
      name: item['specialname'] ?? item['name'] ?? '未知歌单',
      coverUrl: coverUrl,
      description: item['intro'] ?? '',
      playCount: item['play_count'] ?? 0,
      trackCount: songs.length,
      creatorName: item['nickname'],
      creatorAvatar: item['user_avatar'],
      songs: songs,
    );
  }

  /// 解析歌曲数据
  Song _parseSong(Map<String, dynamic> item) {
    final transParam = item['trans_param'] as Map<String, dynamic>? ?? {};

    // 从搜索结果/新歌API中解析 - 支持多种字段名
    final filename = item['FileName'] ?? item['filename'] ?? '';
    final hash = item['FileHash'] ?? item['filehash'] ?? item['hash'] ?? '';

    // 解析歌手名和歌曲名 - 支持多种API格式
    String title = item['songname'] ?? filename;
    String artist = item['author_name'] ?? item['SingerName'] ?? item['singername'] ?? '未知艺术家';
    String album = item['album_name'] ?? item['AlbumName'] ?? item['albumname'] ?? '未知专辑';

    // 处理封面图片 URL，替换 {size} 占位符
    String? coverUrl = item['album_sizable_cover'] ?? item['Image'] ?? item['image'] ?? transParam['union_cover'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '150');
    }

    // 解析时长 - 支持多种格式
    int durationMs = 0;
    if (item['timelength'] != null) {
      // 新歌API: timelength 单位是毫秒
      final durationVal = item['timelength'];
      durationMs = durationVal is int ? durationVal : int.tryParse(durationVal.toString()) ?? 0;
    } else if (item['Duration'] != null) {
      // 搜索API: Duration 单位是秒
      final durationVal = item['Duration'];
      durationMs = (durationVal is int ? durationVal : int.tryParse(durationVal.toString()) ?? 0) * 1000;
    } else if (item['duration'] != null) {
      final durationVal = item['duration'];
      durationMs = (durationVal is int ? durationVal : int.tryParse(durationVal.toString()) ?? 0) * 1000;
    }

    // 如果没有直接的歌曲名，尝试从filename提取
    if (title.isEmpty && filename.contains(' - ')) {
      final parts = filename.split(' - ');
      if (parts.length >= 2) {
        title = parts[1].trim();
      }
    }

    return Song(
      id: hash,
      title: title,
      artist: artist,
      album: album,
      coverUrl: coverUrl,
      audioUrl: null,
      duration: Duration(milliseconds: durationMs),
      isLocal: false,
    );
  }

  /// 解析专辑歌曲数据（专辑详情专用格式）
  Song _parseAlbumSong(Map<String, dynamic> item) {
    // 专辑歌曲 API 返回格式：
    // audio_info: { hash, duration }
    // base: { author_name, audio_name, album_audio_id }
    // album_info: { album_name, cover }
    final audioInfo = item['audio_info'] as Map<String, dynamic>? ?? {};
    final base = item['base'] as Map<String, dynamic>? ?? {};
    final albumInfo = item['album_info'] as Map<String, dynamic>? ?? {};

    final hash = audioInfo['hash']?.toString() ?? '';
    final title = base['audio_name']?.toString() ?? '未知歌曲';
    final artist = base['author_name']?.toString() ?? '未知艺术家';
    final album = albumInfo['album_name']?.toString() ?? '未知专辑';

    // 处理封面图片 URL
    String? coverUrl = albumInfo['cover']?.toString();
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '150');
    }

    // 解析时长（单位：毫秒）
    int durationMs = 0;
    if (audioInfo['duration'] != null) {
      final durationVal = audioInfo['duration'];
      durationMs = durationVal is int ? durationVal : int.tryParse(durationVal.toString()) ?? 0;
    } else if (audioInfo['duration_128'] != null) {
      final durationVal = audioInfo['duration_128'];
      durationMs = durationVal is int ? durationVal : int.tryParse(durationVal.toString()) ?? 0;
    }

    return Song(
      id: hash,
      title: title,
      artist: artist,
      album: album,
      coverUrl: coverUrl,
      audioUrl: null,
      duration: Duration(milliseconds: durationMs),
      isLocal: false,
    );
  }

  /// 解析排行榜数据
  RankItem _parseRankItem(Map<String, dynamic> item) {
    // 打印完整数据以便查看所有可用字段
    if (kDebugMode) {
      print('RankItem keys: ${item.keys.toList()}');
      print('RankItem data: $item');
    }

    // 处理封面图片 URL，替换 {size} 占位符
    String? coverUrl = item['imgurl'] ?? item['img_cover'] ?? item['banner_9'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '300');
    }

    // 优先使用 scheduled_release_conf 中的 latest_rank_cid_publish_date
    String? publishDate;
    if (item['scheduled_release_conf'] != null) {
      final conf = item['scheduled_release_conf'] as Map<String, dynamic>?;
      publishDate = conf?['latest_rank_cid_publish_date'];
    }
    // 如果没有，则使用 rank_id_publish_date
    publishDate ??= item['rank_id_publish_date'];

    // 尝试解析背景颜色
    Color? backgroundColor;
    final bgColorStr = item['background_color'] ?? item['bg_color'] ?? item['color'] ?? item['theme_color'];
    if (bgColorStr != null) {
      backgroundColor = _parseColor(bgColorStr);
    }

    return RankItem(
      id: item['rankid']?.toString() ?? item['id']?.toString() ?? '',
      name: item['rankname'] ?? item['name'] ?? '未知榜单',
      coverUrl: coverUrl,
      songCount: item['songinfo'] != null ? (item['songinfo'] as List).length : 0,
      updateFrequency: item['update_frequency'],
      publishDate: publishDate,
      backgroundColor: backgroundColor,
    );
  }

  /// 解析颜色字符串（支持 #RRGGBB、#AARRGGBB、0xFFRRGGBB 等格式）
  Color? _parseColor(dynamic colorValue) {
    if (colorValue == null) return null;

    String colorStr = colorValue.toString();
    if (colorStr.isEmpty) return null;

    // 移除可能的 0x 前缀
    if (colorStr.startsWith('0x')) {
      colorStr = colorStr.substring(2);
    }
    // 添加 # 前缀（如果没有）
    if (!colorStr.startsWith('#')) {
      colorStr = '#$colorStr';
    }

    return Color(int.parse(colorStr.replaceAll('#', '0xFF')));
  }

  /// 解析歌手数据
  Artist _parseArtist(Map<String, dynamic> item) {
    // 处理头像图片 URL，替换 {size} 占位符
    String? coverUrl = item['Avatar'] ?? item['imgurl'] ?? item['avatar'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '200');
    }

    return Artist(
      id: item['AuthorId']?.toString() ?? item['singerid']?.toString() ?? '',
      name: item['AuthorName'] ?? item['SingerName'] ?? item['singername'] ?? item['name'] ?? '未知歌手',
      coverUrl: coverUrl,
      albumCount: item['AlbumCount'] ?? item['albumcount'] ?? 0,
      songCount: item['AudioCount'] ?? item['SongCount'] ?? item['songcount'] ?? 0,
    );
  }

  /// 解析歌手详情
  ArtistDetail _parseArtistDetail(Map<String, dynamic> item) {
    // 处理头像图片 URL，替换 {size} 占位符
    String? coverUrl = item['imgurl'] ?? item['avatar'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '200');
    }

    return ArtistDetail(
      id: item['singerid']?.toString() ?? '',
      name: item['singername'] ?? '未知歌手',
      coverUrl: coverUrl,
      intro: item['intro'] ?? '',
      albumCount: item['albumcount'] ?? 0,
      songCount: item['songcount'] ?? 0,
      mvCount: item['mvcount'] ?? 0,
    );
  }

  /// 解析专辑数据
  Album _parseAlbum(Map<String, dynamic> item) {
    // 处理封面图片 URL，替换 {size} 占位符
    String? coverUrl = item['img'] ?? item['imgurl'] ?? item['album_img_9'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '300');
    }

    // 获取歌手名称
    String artist = '未知艺术家';
    if (item['singer'] != null && item['singer'].toString().isNotEmpty) {
      artist = item['singer'].toString();
    } else if (item['singers'] != null && item['singers'] is List && (item['singers'] as List).isNotEmpty) {
      final singers = item['singers'] as List;
      artist = singers.map((s) => s is Map ? s['name'] : s).whereType<String>().join(', ');
    } else if (item['singername'] != null) {
      artist = item['singername'].toString();
    } else if (item['artist'] != null) {
      artist = item['artist'].toString();
    }

    return Album(
      id: item['albumid']?.toString() ?? '',
      name: item['albumname'] ?? '未知专辑',
      coverUrl: coverUrl,
      artist: artist,
      publishDate: item['publish_time'] ?? item['publishtime'] ?? item['publishDate'] ?? '',
      songCount: item['songcount'] ?? 0,
    );
  }

  /// 解析专辑详情数据
  Album _parseAlbumDetail(Map<String, dynamic> item) {
    // 处理封面图片 URL
    String? coverUrl = item['sizable_cover'] ?? item['album_img'] ?? item['imgurl'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '400');
    }

    // 获取歌手名称和ID
    String artist = '未知艺术家';
    String artistId = '';
    if (item['author_name'] != null) {
      artist = item['author_name'].toString();
    } else if (item['authors'] != null && item['authors'] is List && (item['authors'] as List).isNotEmpty) {
      final authors = item['authors'] as List;
      final firstAuthor = authors.first;
      if (firstAuthor is Map) {
        artist = firstAuthor['author_name'] ?? artist;
        artistId = firstAuthor['author_id']?.toString() ?? '';
      }
    }

    // 解析发布日期
    String publishDate = '';
    if (item['publish_date'] != null) {
      publishDate = item['publish_date'].toString().substring(0, 10); // 只取日期部分
    }

    return Album(
      id: item['album_id']?.toString() ?? '',
      name: item['album_name'] ?? '未知专辑',
      coverUrl: coverUrl,
      artist: artist,
      artistId: artistId,
      publishDate: publishDate,
      songCount: item['songcount'] ?? 0,
      intro: item['intro'] ?? '',
    );
  }

  /// 解析歌词
  List<LyricLine> parseLyric(String lyricText) {
    final lines = lyricText.split('\n');
    final lyrics = <LyricLine>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // 解析时间标签 [00:12.34]
      final timeRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\]');
      final match = timeRegex.firstMatch(line);

      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!);
        final time = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        // 提取歌词文本（去除时间标签）
        final text = line.replaceFirst(timeRegex, '').trim();
        lyrics.add(LyricLine(time: time, text: text));
      }
    }

    return lyrics;
  }

  // ========== 排行榜相关 ==========

  /// 获取排行榜信息
  Future<Rank?> getRankInfo(String rankId) async {
    try {
      final response = await _dio.get(
        '/rank/info',
        queryParameters: {'rankid': rankId},
      );

      if (response.data['status'] == 1 && response.data['data'] != null) {
        return Rank.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('获取排行榜信息失败: $e');
      return null;
    }
  }

  /// 获取排行榜歌曲列表
  Future<RankSongsResponse?> getRankSongs(
    String rankId, {
    String? rankCid,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'rankid': rankId,
        'page': page,
        'pagesize': pageSize,
      };

      if (rankCid != null) {
        queryParams['rank_cid'] = rankCid;
      }

      final response = await _dio.get(
        '/rank/audio',
        queryParameters: queryParams,
      );

      if (response.data['error_code'] == 0 || response.data['status'] == 1) {
        return RankSongsResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('获取排行榜歌曲列表失败: $e');
      return null;
    }
  }
}
