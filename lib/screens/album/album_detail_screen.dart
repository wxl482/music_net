import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../modules/player/player_controller/player_controller.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../theme/theme.dart';
import '../../services/api/kugou_api_service.dart';
import '../../utils/image_utils.dart';
import '../../app.dart';

/// 专辑详情页面
class AlbumDetailScreen extends StatefulWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final KugouApiService _api = KugouApiService();
  late final PlayerController _playerController;

  // 专辑信息
  final Rx<Album?> album = Rx<Album?>(null);
  final RxList<Song> songs = <Song>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingSongs = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _playerController = Get.find<PlayerController>();
    _loadAlbumData();
  }

  Future<void> _loadAlbumData() async {
    // 并行加载专辑信息和歌曲列表
    await Future.wait([
      _loadAlbumDetail(),
      _loadAlbumSongs(),
    ]);
  }

  Future<void> _loadAlbumDetail() async {
    isLoading.value = true;
    try {
      final detail = await _api.getAlbumDetail(widget.albumId);
      album.value = detail;
    } catch (e) {
      errorMessage.value = '加载专辑信息失败';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadAlbumSongs() async {
    isLoadingSongs.value = true;
    try {
      final songList = await _api.getAlbumSongs(widget.albumId);
      songs.value = songList;
    } catch (e) {
      errorMessage.value = '加载歌曲列表失败';
    } finally {
      isLoadingSongs.value = false;
    }
  }

  Future<void> _playAll() async {
    if (songs.isEmpty) return;
    await _playerController.setPlaylist(songs);
  }

  Future<void> _playSong(Song song) async {
    // 先跳转到播放页面
    Get.toNamed(AppRoutes.player);
    // 然后开始播放（异步）
    _playerController.playSong(song, newPlaylist: songs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (isLoading.value && album.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (album.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: AppColors.onSurfaceSecondary),
                SizedBox(height: 16),
                Text('加载失败', style: AppTextStyles.titleLarge),
                if (errorMessage.value.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(errorMessage.value, style: AppTextStyles.bodySmall),
                  ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            _buildHeader(context),
            _buildActions(),
            _buildIntro(),
            _buildSongList(),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final albumData = album.value!;

    return SliverAppBar(
      expandedHeight: 400.h,
      pinned: true,
      backgroundColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 封面图
            if (albumData.coverUrl != null)
              CachedNetworkImage(
                imageUrl: ImageUtils.replaceImageSize(albumData.coverUrl!, 600),
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.album, size: 80, color: AppColors.onSurfaceSecondary),
                ),
              )
            else
              Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.album, size: 80, color: AppColors.onSurfaceSecondary),
              ),
            // 渐变遮罩
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                albumData.name,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Text(
                    albumData.artist,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (albumData.publishDate.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    Container(
                      width: 4.w,
                      height: 4.w,
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      albumData.publishDate,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // 播放全部按钮
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _playAll(),
                icon: const Icon(Icons.play_circle_filled, color: AppColors.primary),
                label: Text('播放全部', style: AppTextStyles.titleMedium),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // 收藏按钮
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.favorite_border),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.onSurface,
                padding: EdgeInsets.all(12.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // 下载按钮
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.download),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.onSurface,
                padding: EdgeInsets.all(12.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final albumData = album.value!;

    // 专辑介绍
    if (albumData.intro != null && albumData.intro!.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('专辑介绍', style: AppTextStyles.titleLarge),
              SizedBox(height: 12.h),
              Text(
                albumData.intro!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildSongList() {
    return Obx(() {
      if (isLoadingSongs.value) {
        return const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      if (songs.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Text(
              '暂无歌曲',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          childCount: songs.length + 1,
          addSemanticIndexes: false,
          (context, index) {
            if (index == 0) {
              // 歌曲数量标题
              return Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: Text(
                  '歌曲列表 (${songs.length})',
                  style: AppTextStyles.titleLarge,
                ),
              );
            }

            final song = songs[index - 1];
            return _buildSongItem(song, index - 1);
          },
        ),
      );
    });
  }

  Widget _buildSongItem(Song song, int index) {
    return GestureDetector(
      onTap: () => _playSong(song),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 序号
            SizedBox(
              width: 32.w,
              child: Text(
                '${index + 1}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 12.w),
            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: song.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ImageUtils.replaceImageSize(song.coverUrl!, 48.w),
                      width: 48.w,
                      height: 48.w,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 48.w,
                        height: 48.w,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
                    )
                  : Container(
                      width: 48.w,
                      height: 48.w,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
            ),
            SizedBox(width: 12.w),
            // 歌曲信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: AppTextStyles.titleMedium,
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
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
