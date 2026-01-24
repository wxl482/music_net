import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/local_music_controller.dart';
import '../../modules/player/player_controller/player_controller.dart';
import '../../services/local/music_scanner_service.dart';
import '../../theme/theme.dart';
import '../../models/song.dart';
import '../../app.dart';

/// 本地音乐页面
class LocalMusicScreen extends StatefulWidget {
  const LocalMusicScreen({super.key});

  @override
  State<LocalMusicScreen> createState() => _LocalMusicScreenState();
}

class _LocalMusicScreenState extends State<LocalMusicScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final LocalMusicController _localController;
  late final PlayerController _playerController;

  @override
  void initState() {
    super.initState();
    _localController = Get.find<LocalMusicController>();
    _playerController = Get.find<PlayerController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndScan();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAndScan() async {
    if (_localController.localSongs.isEmpty && !_localController.isScanning.value) {
      _localController.scanLocalMusic();
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
              _localController.scanLocalMusic();
            },
          ),
          // 手动选择按钮
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.onSurface),
            onPressed: () => _pickAudioFiles(),
          ),
        ],
      ),
      body: Obx(() {
        if (_localController.isScanning.value) {
          return _buildScanningView();
        }

        return _buildContent();
      }),
    );
  }

  /// 根据状态显示内容
  Widget _buildContent() {
    if (_localController.localSongs.isEmpty) {
      return _buildEmptyView();
    }
    return _buildMusicList();
  }

  Widget _buildScanningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          SizedBox(height: 24.h),
          Obx(() => Text(
            _localController.scanStatus.value,
            style: AppTextStyles.bodyLarge,
          )),
          Obx(() {
            if (_localController.scanProgress.value > 0) {
              return Column(
                children: [
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: 200.w,
                    child: LinearProgressIndicator(
                      value: _localController.scanProgress.value,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
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
              _localController.scanLocalMusic();
            },
            icon: const Icon(Icons.folder_open, color: Colors.black),
            label: const Text('扫描本地音乐', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 16.h),
          // 手动选择按钮
          OutlinedButton.icon(
            onPressed: () => _pickAudioFiles(),
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
  Future<void> _pickAudioFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
        dialogTitle: '选择音乐文件',
      );

      if (result != null && result.files.isNotEmpty) {
        final scanner = MusicScannerService();

        for (final file in result.files) {
          if (file.path != null) {
            final song = await scanner.fileToSong(File(file.path!));
            _localController.addLocalSong(song);
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

  Widget _buildMusicList() {
    return Column(
      children: [
        // 顶部操作栏
        Obx(() => Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Text(
                '共 ${_localController.localSongs.length} 首',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
              const Spacer(),
              // 添加更多按钮
              TextButton.icon(
                onPressed: () => _pickAudioFiles(),
                icon: Icon(Icons.add, size: 18.sp),
                label: const Text('添加更多'),
              ),
            ],
          ),
        )),
        // 歌曲列表
        Obx(() => Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _localController.localSongs.length,
            itemBuilder: (context, index) {
              return _buildSongItem(_localController.localSongs[index], index);
            },
          ),
        )),
      ],
    );
  }

  Widget _buildSongItem(Song song, int index) {
    return Obx(() {
      final isPlaying = _playerController.currentSong.value?.id == song.id;

      return GestureDetector(
        onTap: () async {
          await _playerController.setPlaylist(
            _localController.localSongs,
            startIndex: index,
          );
          await _playerController.play();
          // 跳转到播放页面
          Get.toNamed(AppRoutes.player);
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
    });
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
              onTap: () async {
                Navigator.pop(context);
                await _playerController.playSong(song);
                // 跳转到播放页面
                Get.toNamed(AppRoutes.player);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到播放队列'),
              onTap: () async {
                Navigator.pop(context);
                _playerController.setPlaylist([..._playerController.playlist, song]);
                await _playerController.play();
                // 跳转到播放页面
                Get.toNamed(AppRoutes.player);
              },
            ),
            // 移除选项（仅本地音乐）
            if (song.isLocal)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('从列表中移除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _localController.removeLocalSong(song.id);
                  Get.snackbar(
                    '成功',
                    '已从列表中移除',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green.withValues(alpha: 0.8),
                    colorText: Colors.white,
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
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final localController = Get.find<LocalMusicController>();
    final results = localController.searchLocalSongs(query);

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
          onTap: () async {
            await Get.find<PlayerController>().playSong(song);
            close(context, null);
            // 跳转到播放页面
            Get.toNamed(AppRoutes.player);
          },
        );
      },
    );
  }
}
