import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/song.dart';

/// 本地音乐扫描服务
class MusicScannerService {
  static final MusicScannerService _instance = MusicScannerService._();
  factory MusicScannerService() => _instance;
  MusicScannerService._();

  /// 扫描目录获取所有音乐文件
  Future<List<File>> scanMusicFiles(List<Directory> directories) async {
    List<File> musicFiles = [];

    // 只扫描音频格式
    final audioExtensions = {
      'mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg',
      'wma', 'opus', 'aiff', 'mid', 'midi',
    };

    for (final directory in directories) {
      if (!await directory.exists()) continue;

      try {
        await for (final entity in directory.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            final extension = path.split('.').last;
            if (audioExtensions.contains(extension)) {
              musicFiles.add(entity);
            }
          }
        }
      } catch (e) {
        // 忽略目录扫描错误
      }
    }

    return musicFiles;
  }

  /// 获取默认音乐目录
  Future<List<Directory>> getMusicDirectories() async {
    final directories = <Directory>[];

    // 只扫描系统音乐目录
    if (Platform.isAndroid) {
      final paths = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Audio',
        '/storage/sdcard1/Music',
        '/sdcard/Music',
      ];

      for (final path in paths) {
        try {
          final dir = Directory(path);
          if (await dir.exists()) {
            directories.add(dir);
          }
        } catch (e) {
          // 忽略访问错误
        }
      }
    } else if (Platform.isIOS) {
      // iOS 使用系统音乐库
      final musicDir = await getApplicationDocumentsDirectory();
      directories.add(musicDir);
    }

    return directories;
  }

  /// 从文件路径创建Song对象
  Future<Song> fileToSong(File file) async {
    final path = file.path;
    final fileName = path.split('/').last;

    // 移除文件后缀
    String cleanName = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    // 移除常见前缀: "01 - ", "[02] ", "3. " 等
    cleanName = cleanName.replaceAll(RegExp(r'^\d+[\.\s\-]\s*'), '');
    cleanName = cleanName.replaceAll(RegExp(r'^\[\d+\]\s*'), '');

    String title = cleanName;
    String artist = '未知艺术家';

    // 解析 "歌手名 - 歌曲名" 格式
    if (cleanName.contains(' - ')) {
      final parts = cleanName.split(' - ');
      if (parts.length >= 2) {
        artist = parts[0].trim();
        title = parts.sublist(1).join(' - ').trim();
      }
    }

    return Song.fromLocal(
      id: path.hashCode.toString(),
      title: title,
      artist: artist,
      album: '未知专辑',
      coverPath: null,
      audioPath: path,
      duration: Duration.zero,
    );
  }
}
