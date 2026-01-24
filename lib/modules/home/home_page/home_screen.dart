import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../home_controller/home_controller.dart';
import 'widgets/playlist_card.dart';
import '../../../../theme/theme.dart';
import '../../../../models/song.dart';
import '../../../../models/playlist.dart';
import '../../../../models/banner.dart';
import '../../../../app.dart';
import '../../../../screens/playlist/playlist_detail_screen.dart';
import '../../../../modules/player/player_controller/player_controller.dart';
import '../../../../screens/search/search_screen.dart';

/// Apple Music 风格首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // 搜索框
              _buildSearchBar(),
              // 内容区域
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return _buildLoading();
                  }
                  if (controller.error.value.isNotEmpty) {
                    return _buildError();
                  }
                  return RefreshIndicator(
                    onRefresh: controller.refreshData,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBanner(),
                          SizedBox(height: 32.h),
                          _buildHotPlaylists(),
                          SizedBox(height: 16.h),
                          _buildNewReleases(),
                          SizedBox(height: 16.h),
                          _buildTopCharts(),
                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 搜索框
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        // 跳转到搜索页面
        Get.to(() => const SearchScreen());
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        height: 44.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: AppColors.onSurfaceSecondary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.onSurfaceSecondary, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '搜索歌曲、歌手、专辑',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16.h),
          Text('加载失败: ${Get.find<HomeController>().error.value}'),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: Get.find<HomeController>().refreshData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Obx(() {
      final banners = Get.find<HomeController>().banners;
      if (banners.isEmpty) {
        return _buildDefaultBanner();
      }

      return SizedBox(
        height: 160.h,
        child: PageView.builder(
          itemCount: banners.length > 5 ? 5 : banners.length,
          itemBuilder: (context, index) {
            return _buildBannerItem(banners[index]);
          },
        ),
      );
    });
  }

  Widget _buildDefaultBanner() {
    // 为每个 Banner 使用不同的紫色渐变
    final bannerGradients = [
      AppColors.primaryGradient,
      AppColors.purplePinkGradient,
      AppColors.purpleOrangeGradient,
    ];

    return SizedBox(
      height: 180.h,
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bannerGradients[index % bannerGradients.length],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: bannerGradients[index % bannerGradients.length].first.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20.w,
                  bottom: -20.h,
                  child: Icon(
                    Icons.music_note,
                    size: 140.sp,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '推荐歌单',
                        style: AppTextStyles.footnote.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '热门精选 ${index + 1}',
                        style: AppTextStyles.title1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerItem(BannerItem banner) {
    return GestureDetector(
      onTap: () {
        if (banner.url.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(playlistId: banner.url),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          image: banner.imageUrl.isNotEmpty
              ? DecorationImage(
                  image: CachedNetworkImageProvider(banner.imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.1),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                banner.title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (banner.description.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  banner.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (banner.playCount > 0) ...[
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.play_arrow,
                      size: 12.sp,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _formatPlayCount(banner.playCount),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    } else if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  Widget _buildHotPlaylists() {
    return Obx(() {
      final playlists = Get.find<HomeController>().playlists.isEmpty ? _getSamplePlaylists() : Get.find<HomeController>().playlists;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              '热门歌单',
              style: AppTextStyles.title2,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 210.h,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: PlaylistCard(
                    playlist: playlists[index],
                    onTap: () {
                      final collectionId = playlists[index].globalCollectionId.isNotEmpty
                          ? playlists[index].globalCollectionId
                          : playlists[index].id;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(playlistId: collectionId),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildNewReleases() {
    return Obx(() {
      final songs = Get.find<HomeController>().newSongs.isEmpty ? _getSampleSongs() : Get.find<HomeController>().newSongs;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              '新歌速递',
              style: AppTextStyles.title2,
            ),
          ),
          SizedBox(height: 16.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return _buildSongListItem(context, songs[index], index + 1);
            },
          ),
        ],
      );
    });
  }

  /// Apple Music 风格歌曲列表项
  Widget _buildSongListItem(BuildContext context, Song song, int index) {
    return GestureDetector(
      onTap: () async {
        await _playSong(song, _getSampleSongs());
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Row(
          children: [
            // 序号
            SizedBox(
              width: 24.w,
              child: Text(
                '$index',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.onSurfaceTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 12.w),
            // 封面图
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                child: song.coverUrl != null && song.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.music_note, color: AppColors.onSurfaceTertiary, size: 20),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.music_note, color: AppColors.onSurfaceTertiary, size: 20),
                      ),
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
                    style: AppTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    song.artist,
                    style: AppTextStyles.footnote,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 更多按钮
            Icon(Icons.more_horiz, color: AppColors.onSurfaceTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCharts() {
    return Obx(() {
      final rankList = Get.find<HomeController>().rankList;

      // 使用紫色渐变色系
      final chartGradients = [
        AppColors.purpleTealGradient, // 紫-青-绿（热歌榜）
        AppColors.purplePinkGradient, // 紫-紫-粉（新歌榜）
        AppColors.purpleOrangeGradient, // 紫-紫-橙（原创榜）
      ];

      final charts = rankList.isEmpty
          ? [
              {'title': '热歌榜', 'gradient': AppColors.purpleTealGradient, 'id': '8888'},
              {'title': '新歌榜', 'gradient': AppColors.purplePinkGradient, 'id': '31312'},
              {'title': '原创榜', 'gradient': AppColors.purpleOrangeGradient, 'id': '2'},
            ]
          : List.generate(
              rankList.length > 3 ? 3 : rankList.length,
              (index) {
                final rank = rankList[index];
                return {
                  'title': rank.name,
                  'gradient': chartGradients[index % chartGradients.length],
                  'id': rank.id,
                };
              },
            );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              '排行榜',
              style: AppTextStyles.title2,
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: charts.map((chart) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // 跳转到排行榜详情页面
                      Get.toNamed(AppRoutes.rankDetail, arguments: chart['id']);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: chart['gradient'] as List<Color>,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: (chart['gradient'] as List<Color>).first.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 32.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            chart['title'] as String,
                            style: AppTextStyles.callout.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  List<Playlist> _getSamplePlaylists() {
    return [
      Playlist.online(
        id: '1',
        name: '华语热门',
        description: '最受欢迎的华语歌曲',
        coverUrl: 'https://picsum.photos/200',
        playCount: 10000000,
        trackCount: 50,
      ),
      Playlist.online(
        id: '2',
        name: '欧美经典',
        description: '回味无穷的经典欧美',
        coverUrl: 'https://picsum.photos/201',
        playCount: 8000000,
        trackCount: 100,
      ),
      Playlist.online(
        id: '3',
        name: '日语精选',
        description: '好听的日语歌曲',
        coverUrl: 'https://picsum.photos/202',
        playCount: 5000000,
        trackCount: 30,
      ),
      Playlist.online(
        id: '4',
        name: '韩流热歌',
        description: 'K-POP热门歌曲',
        coverUrl: 'https://picsum.photos/203',
        playCount: 12000000,
        trackCount: 80,
      ),
    ];
  }

  List<Song> _getSampleSongs() {
    // 使用真实的酷狗歌曲 hash 作为示例
    return [
      Song.fromOnline(
        id: '0C4178077B8DFC3DC0937E85547AFA6E', // 周深 - 太平年
        title: '太平年',
        artist: '周深',
        album: '影视原声带',
        coverUrl: 'https://imge.kugou.com/stdmusic/20250319/20250319232204316906.jpg',
        duration: const Duration(minutes: 3, seconds: 33),
      ),
      Song.fromOnline(
        id: '11FB913633611784F5042FB322CCB647', // Michael FK, Yal!X - The World Can Wait
        title: 'The World Can Wait',
        artist: 'Michael FK、Yal!X',
        album: 'Electronic Vibes',
        coverUrl: 'https://imge.kugou.com/stdmusic/20240311/20240311161214589894.jpg',
        duration: const Duration(minutes: 5, seconds: 42),
      ),
      Song.fromOnline(
        id: 'A21DA32DC56592D608F5586F9C1CAB49', // 示例歌曲3
        title: '示例歌曲',
        artist: '歌手C',
        album: '专辑C',
        coverUrl: 'https://imge.kugou.com/stdmusic/20241219/20241219164221229666.png',
        duration: const Duration(minutes: 3, seconds: 28),
      ),
    ];
  }

  /// 播放歌曲
  Future<void> _playSong(Song song, List<Song> playlist) async {
    try {
      final playerController = Get.find<PlayerController>();

      // 直接播放歌曲，PlayerController 会处理在线和本地歌曲
      await playerController.playSong(song, newPlaylist: playlist);

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
}
