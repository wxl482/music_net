import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/online_music_controller.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../theme/theme.dart';
import '../../services/api/kugou_api_service.dart';
import '../../utils/image_utils.dart';
import '../../app.dart';
import '../playlist/playlist_detail_screen.dart';
import '../search/search_screen.dart';
import '../../modules/player/player_controller/player_controller.dart';

/// 发现/在线音乐页面
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final OnlineMusicController _onlineController;

  @override
  void initState() {
    super.initState();
    _onlineController = Get.find<OnlineMusicController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onlineController.fetchRecommendPlaylists();
      _onlineController.fetchRankList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '发现音乐',
          style: AppTextStyles.headlineLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.onSurface),
            onPressed: () {
              Get.to(() => const SearchScreen());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            SizedBox(height: 24.h),
            _buildRecommendPlaylists(),
            SizedBox(height: 24.h),
            _buildRankList(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      height: 150.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1ED760)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 48.sp, color: Colors.white),
            SizedBox(height: 8.h),
            Text(
              '酷狗音乐',
              style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
            ),
            SizedBox(height: 4.h),
            Text(
              '发现好音乐',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendPlaylists() {
    return Obx(() {
      if (_onlineController.isLoadingPlaylists.value) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: const CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final playlists = _onlineController.recommendPlaylists;
      if (playlists.isEmpty) {
        return _buildEmptyView('推荐歌单');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  const Icon(Icons.recommend, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Text(
                    '推荐歌单',
                    style: AppTextStyles.titleLarge,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 210.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  return _buildPlaylistCard(playlists[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistCard(Playlist playlist) {
    return GestureDetector(
      onTap: () {
        final collectionId = playlist.globalCollectionId.isNotEmpty
            ? playlist.globalCollectionId
            : playlist.id;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailScreen(playlistId: collectionId),
          ),
        );
      },
      child: Container(
        width: 140.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CachedNetworkImage(
                imageUrl: ImageUtils.replaceImageSize(playlist.coverUrl ?? '', 140.w),
                width: 140.w,
                height: 140.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              playlist.name,
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (playlist.creatorName != null && playlist.creatorName!.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                playlist.creatorName!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRankList() {
    return Obx(() {
      if (_onlineController.isLoadingRank.value) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: const CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final ranks = _onlineController.rankList;
      if (ranks.isEmpty) {
        return _buildEmptyView('排行榜');
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.orange),
                SizedBox(width: 8.w),
                Text(
                  '排行榜',
                  style: AppTextStyles.titleLarge,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: ranks.length,
            itemBuilder: (context, index) {
              return _buildRankCard(ranks[index], index + 1);
            },
          ),
        ],
      );
    });
  }

  Widget _buildRankCard(RankItem rank, int index) {
    return GestureDetector(
      onTap: () {
        // 跳转到排行榜详情页面
        Get.toNamed(AppRoutes.rankDetail, arguments: rank.id);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getRankColor(index).withValues(alpha: 0.6),
              _getRankColor(index).withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getRankColor(index),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '$index',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    rank.updateText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      default:
        return AppColors.primary;
    }
  }

  void _showRankSongsDialog(String title, List<Song> songs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTextStyles.titleLarge),
        content: SizedBox(
          width: double.maxFinite,
          height: 400.h,
          child: ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Text('${index + 1}'),
                title: Text(songs[index].title),
                subtitle: Text(songs[index].artist),
                onTap: () async {
                  final playerController = Get.find<PlayerController>();
                  await playerController.playSong(songs[index]);
                  Navigator.pop(context);
                  // 跳转到播放页面
                  Get.toNamed(AppRoutes.player);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 60.sp,
            color: AppColors.onSurfaceSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            '无法加载$title',
            style: AppTextStyles.titleLarge,
          ),
          SizedBox(height: 8.h),
          Text(
            '请检查网络连接',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 音乐搜索Delegate
class MusicSearchDelegate extends SearchDelegate {
  final OnlineMusicController onlineController;

  MusicSearchDelegate({required this.onlineController});

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
    if (query.isEmpty) {
      return _buildHistoryView(context);
    }

    return Obx(() {
      if (onlineController.isSearching.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      final results = onlineController.searchResults;
      if (results.isEmpty && query.isNotEmpty && !onlineController.isSearching.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_off,
                size: 60.sp,
                color: AppColors.onSurfaceSecondary,
              ),
              SizedBox(height: 16.h),
              Text(
                '未找到相关音乐',
                style: AppTextStyles.titleLarge,
              ),
              SizedBox(height: 8.h),
              Text(
                '请尝试其他关键词',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
            ],
          ),
        );
      }

      if (results.isEmpty) {
        return _buildHistoryView(context);
      }

      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: results.length,
        itemBuilder: (context, index) {
          return _buildSearchResultItem(results[index], index, context);
        },
      );
    });
  }

  Widget _buildSearchResultItem(Song song, int index, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          final playerController = Get.find<PlayerController>();
          await playerController.playSong(song);
          close(context, null);
          // 跳转到播放页面
          Get.toNamed(AppRoutes.player);
        } catch (e) {
          if (context.mounted) {
            Get.snackbar(
              '错误',
              '播放失败: $e',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.withValues(alpha: 0.8),
              colorText: Colors.white,
            );
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            SizedBox(
              width: 32.w,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: AppColors.onSurfaceSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: (song.coverUrl != null && song.coverUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: ImageUtils.replaceImageSize(song.coverUrl!, 48.w),
                      width: 48.w,
                      height: 48.h,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 48.w,
                        height: 48.h,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
                    )
                  : Container(
                      width: 48.w,
                      height: 48.h,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
            ),
            SizedBox(width: 12.w),
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
                    '${song.artist} - ${song.album}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceSecondary),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 60.sp,
            color: AppColors.onSurfaceSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            '搜索音乐',
            style: AppTextStyles.titleLarge,
          ),
          SizedBox(height: 8.h),
          Text(
            '输入歌手名、歌曲名',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
