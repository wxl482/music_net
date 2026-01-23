import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/local/local_music_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/local/music_scanner_service.dart';
import '../../theme/theme.dart';
import '../../models/song.dart';

/// 本地音乐页面
class LocalMusicScreen extends StatefulWidget {
  const LocalMusicScreen({super.key});

  @override
  State<LocalMusicScreen> createState() => _LocalMusicScreenState();
}

class _LocalMusicScreenState extends State<LocalMusicScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndScan();
    });
  }

  Future<void> _checkAndScan() async {
    final localProvider = context.read<LocalMusicProvider>();
    if (localProvider.localSongs.isEmpty && !localProvider.isScanning) {
      localProvider.scanLocalMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '本地音乐',
          style: AppTextStyles.headlineLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.onSurface),
            onPressed: () {
              showSearch(
                context: context,
                delegate: LocalMusicSearchDelegate(),
              );
            },
          ),
          // 扫描按钮
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onSurface),
            onPressed: () {
              context.read<LocalMusicProvider>().scanLocalMusic();
            },
          ),
          // 手动选择按钮
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.onSurface),
            onPressed: () => _pickAudioFiles(context),
          ),
        ],
      ),
      body: Consumer<LocalMusicProvider>(
        builder: (context, localProvider, child) {
          if (localProvider.isScanning) {
            return _buildScanningView(localProvider);
          }

          return _buildContent(localProvider);
        },
      ),
    );
  }

  /// 根据状态显示内容
  Widget _buildContent(LocalMusicProvider provider) {
    if (provider.localSongs.isEmpty) {
      return _buildEmptyView();
    }
    return _buildMusicList(provider);
  }

  Widget _buildScanningView(LocalMusicProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          SizedBox(height: 24.h),
          Text(
            provider.scanStatus,
            style: AppTextStyles.bodyLarge,
          ),
          if (provider.scanProgress > 0) ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: 200.w,
              child: LinearProgressIndicator(
                value: provider.scanProgress,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 80.sp,
            color: AppColors.onSurfaceSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            '未找到本地音乐',
            style: AppTextStyles.titleLarge,
          ),
          SizedBox(height: 8.h),
          Text(
            '请选择音乐文件或扫描本地音乐',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          // 扫描按钮
          ElevatedButton.icon(
            onPressed: () {
              context.read<LocalMusicProvider>().scanLocalMusic();
            },
            icon: Icon(Icons.folder_open, color: Colors.black),
            label: const Text('扫描本地音乐', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 16.h),
          // 手动选择按钮
          OutlinedButton.icon(
            onPressed: () => _pickAudioFiles(context),
            icon: const Icon(Icons.add_circle_outline, color: AppColors.onSurface),
            label: const Text('选择音乐文件'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  /// 手动选择音频文件
  Future<void> _pickAudioFiles(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
        dialogTitle: '选择音乐文件',
      );

      if (result != null && result.files.isNotEmpty) {
        final localProvider = context.read<LocalMusicProvider>();
        final scanner = MusicScannerService();

        for (final file in result.files) {
          if (file.path != null) {
            final song = await scanner.fileToSong(File(file.path!));
            localProvider.addLocalSong(song);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已添加 ${result.files.length} 首音乐')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  Widget _buildMusicList(LocalMusicProvider provider) {
    final songs = provider.localSongs;

    return Column(
      children: [
        // 顶部操作栏
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Text(
                '共 ${songs.length} 首',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
              const Spacer(),
              // 添加更多按钮
              TextButton.icon(
                onPressed: () => _pickAudioFiles(context),
                icon: Icon(Icons.add, size: 18.sp),
                label: const Text('添加更多'),
              ),
            ],
          ),
        ),
        // 歌曲列表
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return _buildSongItem(songs[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSongItem(Song song, int index) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final isPlaying = playerProvider.currentSong?.id == song.id;

        return GestureDetector(
          onTap: () async {
            await playerProvider.setPlaylist(
              context.read<LocalMusicProvider>().localSongs,
              startIndex: index,
            );
            playerProvider.play();
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                // 索引
                SizedBox(
                  width: 32.w,
                  child: isPlaying
                      ? const Icon(
                          Icons.graphic_eq,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : Text(
                          '${index + 1}',
                          style: isPlaying
                              ? AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.primary,
                                )
                              : AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.onSurfaceSecondary,
                                ),
                        ),
                ),
                SizedBox(width: 12.w),
                // 封面
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: song.coverUrl != null
                      ? Image.file(
                          File(song.coverUrl!),
                          width: 48.w,
                          height: 48.w,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48.w,
                          height: 48.w,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.music_note, color: Colors.white),
                        ),
                ),
                SizedBox(width: 12.w),
                // 标题和艺术家
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: isPlaying
                            ? AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                              )
                            : AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        song.artist,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 更多按钮
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceSecondary),
                  onPressed: () {
                    _showSongOptions(context, song);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: AppColors.primary),
              title: const Text('播放'),
              onTap: () {
                Navigator.pop(context);
                context.read<PlayerProvider>().playSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到播放队列'),
              onTap: () {
                Navigator.pop(context);
                context.read<PlayerProvider>().addToQueue(song);
              },
            ),
            // 移除选项（仅本地音乐）
            if (song.isLocal)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('从列表中移除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  context.read<LocalMusicProvider>().removeLocalSong(song.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已从列表中移除')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// 本地音乐搜索delegate
class LocalMusicSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final localProvider = context.read<LocalMusicProvider>();
    final results = localProvider.searchLocalSongs(query);

    if (results.isEmpty) {
      return Center(
        child: Text(
          '未找到相关音乐',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.onSurfaceSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return ListTile(
          leading: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text(song.title, style: AppTextStyles.titleMedium),
          subtitle: Text(
            '${song.artist} - ${song.album}',
            style: AppTextStyles.bodySmall,
          ),
          onTap: () {
            context.read<PlayerProvider>().playSong(song);
            close(context, null);
          },
        );
      },
    );
  }
}
