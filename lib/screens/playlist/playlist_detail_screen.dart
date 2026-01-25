import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../theme/theme.dart';
import '../../models/song.dart';
import '../../models/playlist_detail.dart';
import '../../utils/image_utils.dart';
import '../../services/api/kugou_api_service.dart';
import '../../app.dart';
import '../home/widgets/song_item.dart';
import '../../modules/player/player_controller/player_controller.dart';

/// 歌单详情页面
class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId; // global_collection_id

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  // 歌单详情数据（使用实体类）
  PlaylistDetailData? _playlistDetail;
  bool _isLoading = true;
  final List<Song> _songs = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlaylistDetail();
  }

  /// 加载歌单详情
  Future<void> _loadPlaylistDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = KugouApiService();

      // 使用新的实体类方法获取歌单详情和歌曲
      final detail = await api.getPlaylistDetailWithSongs(widget.playlistId, pagesize: 100);

      if (detail != null && mounted) {
        setState(() {
          _playlistDetail = detail;
          _isLoading = false;
        });

        // 转换歌曲数据为 Song 模型
        _convertSongs();
      } else if (mounted) {
        setState(() {
          _errorMessage = '获取歌单详情失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '获取歌单详情失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 将 PlaylistSongItem 转换为 Song 模型
  void _convertSongs() {
    final songsData = _playlistDetail?.songs;
    if (songsData == null) return;

    _songs.clear();
    for (final item in songsData.songs) {
      // 使用 ImageUtils 动态计算图片尺寸
      // 这里不替换 {size}，保留原始 URL，在显示时根据实际尺寸替换
      _songs.add(Song(
        id: item.hash,
        title: item.name,
        artist: item.artistNames,
        album: item.albumName ?? '未知专辑',
        coverUrl: item.imgurl,
        duration: Duration(milliseconds: item.duration),
      ));
    }
  }

  /// 播放全部
  Future<void> _playAll() async {
    if (_songs.isEmpty) return;

    try {
      final playerController = Get.find<PlayerController>();

      // 直接设置播放列表，PlayerController 会处理获取 URL
      await playerController.setPlaylist(_songs, startIndex: 0);

      // 打开播放器页面
      if (mounted) {
        Get.toNamed(AppRoutes.player);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          '错误',
          '播放失败: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  /// 播放单首歌曲
  Future<void> _playSong(Song song, int index) async {
    try {
      final playerController = Get.find<PlayerController>();

      // 先跳转到播放页面
      if (mounted) {
        Get.toNamed(AppRoutes.player);
      }

      // 然后设置播放列表并播放（异步）
      playerController.setPlaylist(_songs, startIndex: index);
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          '错误',
          '播放失败: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  String _formatPlayCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    } else if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    // 获取封面 URL 用于背景（使用 ImageUtils 动态计算尺寸）
    // 背景图覆盖整个屏幕，使用屏幕宽度计算
    final screenWidth = MediaQuery.of(context).size.width;
    final backgroundCoverUrl = _playlistDetail?.pic != null
        ? ImageUtils.replaceImageSize(_playlistDetail!.pic!, screenWidth)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 背景图片
          if (backgroundCoverUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: backgroundCoverUrl,
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.darken,
                color: Colors.black.withValues(alpha: 0.5),
                placeholder: (context, url) => Container(
                  color: AppColors.background,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.background,
                ),
              ),
            ),
          // 模糊层
          if (backgroundCoverUrl != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
          // 主内容
          Scaffold(
            backgroundColor: Colors.transparent,
            body: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : CustomScrollView(
                        slivers: [
                          // 顶部返回按钮
                          SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppColors.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // 歌单头部信息
                    SliverToBoxAdapter(
                      child: _buildHeader(),
                    ),
                    // 歌曲列表
                    SliverToBoxAdapter(
                      child: _buildSongList(),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (_playlistDetail == null) return const SizedBox();

    // 使用实体类，不再需要手动解析字段
    final detail = _playlistDetail!;
    final name = detail.name;
    final description = detail.intro;
    final playCount = detail.playCount ?? 0;
    final songCount = detail.songCount ?? 0;
    final creatorName = detail.nickname;
    final tags = detail.tags ?? [];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
          // 封面和信息卡片
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceVariant.withValues(alpha: 0.3),
                  AppColors.surface.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 封面图
                    Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: detail.pic != null
                            ? CachedNetworkImage(
                                imageUrl: ImageUtils.replaceImageSize(detail.pic!, 120.w),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(Icons.music_note, color: Colors.white, size: 40),
                                ),
                              )
                            : Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.music_note, color: Colors.white, size: 40),
                              ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // 右侧信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 标签
                          if (tags.isNotEmpty)
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              children: tags.take(3).map((tag) {
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    tag.trim(),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          if (tags.isNotEmpty) SizedBox(height: 8.h),
                          // 歌单名称
                          Text(
                            name,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),
                          // 创建者
                          if (creatorName != null)
                            Text(
                              creatorName,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onSurfaceSecondary,
                              ),
                            ),
                          SizedBox(height: 4.h),
                          // 播放量和歌曲数
                          Row(
                            children: [
                              if (playCount > 0) ...[
                                Icon(
                                  Icons.play_arrow,
                                  size: 12.sp,
                                  color: AppColors.onSurfaceSecondary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  _formatPlayCount(playCount),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onSurfaceSecondary,
                                    fontSize: 11.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                              ],
                              Text(
                                '$songCount 首',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceSecondary,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
            // 简介
            ..._buildDescriptionWidget(description),
            SizedBox(height: 16.h),
            // 操作按钮
            _buildActionBar(),
          ],
        ),
      );
  }

  List<Widget> _buildDescriptionWidget(String? description) {
    if (description == null || description.isEmpty) {
      return [];
    }
    return [
      Container(
        padding: EdgeInsets.all(16.w),
        child: Text(
          description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceSecondary,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];
  }

  Widget _buildActionBar() {
    // 直接使用已转换的 _songs 列表
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // 播放全部按钮
          Expanded(
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: ElevatedButton.icon(
                onPressed: _songs.isNotEmpty ? _playAll : null,
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                label: Text(
                  '播放全部',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // 选择按钮
          Container(
            width: 48.h,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.select_all, color: AppColors.onSurface),
              onPressed: () {},
            ),
          ),
          SizedBox(width: 8.w),
          // 更多按钮
          Container(
            width: 48.h,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.onSurface),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    // 直接使用已转换的 _songs 列表
    if (_songs.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: Column(
          children: [
            Icon(
              Icons.music_note,
              size: 48.sp,
              color: AppColors.onSurfaceSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              '暂无歌曲~',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // 歌曲列表标题
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                Text(
                  '歌曲列表',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${_songs.length}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 歌曲列表
          ...List.generate(_songs.length, (index) {
            return SongItem(
              song: _songs[index],
              index: index + 1,
              onTap: () => _playSong(_songs[index], index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.sp,
              color: AppColors.onSurfaceSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              _errorMessage ?? '加载失败',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadPlaylistDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
