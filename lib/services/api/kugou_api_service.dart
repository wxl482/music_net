import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../models/album.dart';
import '../../models/artist.dart';

// 导出类型别名方便使用
export '../../models/playlist.dart' show RankItem;

/// 酷狗音乐 API 服务 (本地服务器版本)
class KugouApiService {
  static final KugouApiService _instance = KugouApiService._();
  factory KugouApiService() => _instance;
  KugouApiService._();

  // API 服务器地址
  static const String _baseUrl = 'http://192.168.2.5:3000';

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
          logPrint: (obj) => print('[DIO] $obj'),
        ),
      );
    }

    return dio;
  }

  /// 搜索音乐
  /// POST /search?keyword=xxx
  Future<List<Song>> searchMusic(String keywords, {int page = 1, int pagesize = 30}) async {
    try {
      final response = await _dio.post(
        '/search',
        data: {
          'keywords': keywords,
          'page': page,
          'pagesize': pagesize,
        },
      );

      if (response.statusCode == 200) {
        final lists = response.data['data']['lists'] as List? ?? [];
        return lists.map((item) => _parseSong(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('搜索失败: $e');
    }
    return [];
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
    }

    try {
      // 将 dfid 放到 cookie 中
      final options = Options(
        headers: {
          if (dfid != null && dfid.isNotEmpty) 'Cookie': 'dfid=$dfid',
        },
      );

      final response = await _dio.get(
        '/song/url',
        queryParameters: {
          'hash': hash.toLowerCase(),
          'quality': quality,
        },
        options: options,
      );

      if (kDebugMode) {
        print('[歌曲URL] hash=$hash, dfid=$dfid');
        print('[歌曲URL] 响应状态: ${response.statusCode}');
        print('[歌曲URL] 响应数据: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        // 支持多种响应格式

        // 格式1: { data: { url: "..." } } 或 { data: { url: ["..."] } }
        if (response.data['data'] != null) {
          final dataUrl = response.data['data']['url'];
          if (dataUrl != null) {
            if (dataUrl is String && dataUrl.isNotEmpty) {
              if (kDebugMode) print('[歌曲URL] 找到播放链接(格式1-字符串): $dataUrl');
              return dataUrl;
            } else if (dataUrl is List && dataUrl.isNotEmpty) {
              final url = dataUrl[0] as String?;
              if (url != null && url.isNotEmpty) {
                if (kDebugMode) print('[歌曲URL] 找到播放链接(格式1-数组): $url');
                return url;
              }
            }
          }
        }

        // 格式2: { url: ["...", "..."] } 或 { url: "..." }
        if (response.data['url'] != null) {
          final urlField = response.data['url'];
          if (urlField is String && urlField.isNotEmpty) {
            if (kDebugMode) print('[歌曲URL] 找到播放链接(格式2-字符串): $urlField');
            return urlField;
          } else if (urlField is List && urlField.isNotEmpty) {
            final url = urlField[0] as String?;
            if (url != null && url.isNotEmpty) {
              if (kDebugMode) print('[歌曲URL] 找到播放链接(格式2-数组): $url');
              return url;
            }
          }
        }

        // 格式3: { backupUrl: ["...", "..."] } - 备用链接
        if (response.data['backupUrl'] != null) {
          final backupUrl = response.data['backupUrl'];
          if (backupUrl is List && backupUrl.isNotEmpty) {
            final url = backupUrl[0] as String?;
            if (url != null && url.isNotEmpty) {
              if (kDebugMode) print('[歌曲URL] 找到播放链接(备用): $url');
              return url;
            }
          }
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
    try {
      final response = await _dio.get(
        '/playlist/detail',
        queryParameters: {'ids': globalCollectionId},
      );

      if (response.statusCode == 200) {
        final detail = response.data['data']['info'];
        return _parsePlaylistDetail(detail);
      }
    } catch (e) {
      if (kDebugMode) print('获取歌单详情失败: $e');
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
  /// GET /album/detail?albumid=xxx
  Future<Album?> getAlbumDetail(String albumId) async {
    try {
      final response = await _dio.get(
        '/album/detail',
        queryParameters: {'albumid': albumId},
      );

      if (response.statusCode == 200) {
        return _parseAlbum(response.data['data']);
      }
    } catch (e) {
      if (kDebugMode) print('获取专辑详情失败: $e');
    }
    return null;
  }

  /// 获取歌词
  /// GET /lyric?hash=xxx
  Future<String> getLyric([String? hash]) async {
    try {
      final response = await _dio.get(
        '/lyric',
        queryParameters: {'hash': hash ?? ''},
      );

      if (response.statusCode == 200) {
        return response.data['data']?['lyrics'] ?? '';
      }
    } catch (e) {
      if (kDebugMode) print('获取歌词失败: $e');
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

  /// 获取专辑歌曲
  /// GET /album/songs?albumid=xxx
  Future<List<Song>> getAlbumSongs(String albumId, {int page = 1, int pagesize = 50}) async {
    try {
      final response = await _dio.get(
        '/album/songs',
        queryParameters: {'albumid': albumId, 'page': page, 'pagesize': pagesize},
      );

      if (response.statusCode == 200) {
        final list = response.data['data']['list'] as List? ?? response.data['data'] as List? ?? [];
        return list.map((item) => _parseSong(item)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('获取专辑歌曲失败: $e');
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

  /// 解析排行榜数据
  RankItem _parseRankItem(Map<String, dynamic> item) {
    // 处理封面图片 URL，替换 {size} 占位符
    String? coverUrl = item['imgurl'] ?? item['img_cover'] ?? item['banner_9'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '300');
    }

    return RankItem(
      id: item['rankid']?.toString() ?? item['id']?.toString() ?? '',
      name: item['rankname'] ?? item['name'] ?? '未知榜单',
      coverUrl: coverUrl,
      songCount: item['songinfo'] != null ? (item['songinfo'] as List).length : 0,
    );
  }

  /// 解析歌手数据
  Artist _parseArtist(Map<String, dynamic> item) {
    // 处理头像图片 URL，替换 {size} 占位符
    String? coverUrl = item['imgurl'] ?? item['avatar'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '200');
    }

    return Artist(
      id: item['singerid']?.toString() ?? '',
      name: item['singername'] ?? item['name'] ?? '未知歌手',
      coverUrl: coverUrl,
      albumCount: item['albumcount'] ?? 0,
      songCount: item['songcount'] ?? 0,
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
    String? coverUrl = item['imgurl'] ?? item['album_img_9'];
    if (coverUrl != null && coverUrl.contains('{size}')) {
      coverUrl = coverUrl.replaceAll('{size}', '300');
    }

    return Album(
      id: item['albumid']?.toString() ?? '',
      name: item['albumname'] ?? '未知专辑',
      coverUrl: coverUrl,
      artist: item['singername'] ?? item['artist'] ?? '未知艺术家',
      publishDate: item['publishtime'] ?? item['publishDate'] ?? '',
      songCount: item['songcount'] ?? 0,
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
}
