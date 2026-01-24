import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/theme.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../home/widgets/song_item.dart';

class ArtistDetailScreen extends StatelessWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 280.h,
              backgroundColor: AppColors.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
              ),
              leading: Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert, color: AppColors.onSurface),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            // Tab bar
            SliverPersistentHeader(
              delegate: _TabBarDelegate(
                TabBar(
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.onSurfaceSecondary,
                  labelStyle: AppTextStyles.labelLarge,
                  tabs: const [
                    Tab(text: '热门歌曲'),
                    Tab(text: '专辑'),
                    Tab(text: '简介'),
                  ],
                ),
              ),
              pinned: true,
            ),
            // Content
            SliverList(
              delegate: SliverChildListDelegate([
                _buildHotSongs(),
                _buildAlbums(),
                _buildDescription(),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surfaceVariant,
                AppColors.background,
              ],
            ),
          ),
        ),
        // Artist image
        Positioned(
          left: 0,
          right: 0,
          top: 60,
          child: Column(
            children: [
              Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20.r,
                      offset: Offset(0, 10.h),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: (artist.coverUrl != null && artist.coverUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: artist.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.person, color: AppColors.onSurfaceSecondary, size: 80),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.person, color: AppColors.onSurfaceSecondary, size: 80),
                        ),
                ),
              ),
              SizedBox(height: 16.h),
              // Artist name
              Text(
                artist.name,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              // Fan count
              Text(
                '粉丝 ${artist.formattedFanCount}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                    child: const Text(
                      '+ 关注',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.message, color: AppColors.onSurface),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHotSongs() {
    final songs = _getSampleSongs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              const Icon(Icons.play_circle_filled, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text('热门${songs.length}首', style: AppTextStyles.titleLarge),
            ],
          ),
        ),
        ...List.generate(songs.length, (index) {
          return SongItem(
            song: songs[index],
            index: index + 1,
            onTap: () {},
          );
        }),
      ],
    );
  }

  Widget _buildAlbums() {
    final albums = List.generate(6, (index) => index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Text('专辑', style: AppTextStyles.titleLarge),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8.r),
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.album, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '专辑名称 ${index + 1}',
                          style: AppTextStyles.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '2024',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurfaceSecondary,
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
      ],
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('艺人简介', style: AppTextStyles.titleLarge),
          SizedBox(height: 12.h),
          Text(
            artist.description ??
                '${artist.name}是一位优秀的音乐人，代表作品包括多首脍炙人口的歌曲。',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Song> _getSampleSongs() {
    return List.generate(10, (index) {
      return Song.fromOnline(
        id: '${artist.id}_song_$index',
        title: '热门歌曲 ${index + 1}',
        artist: artist.name,
        album: '专辑 ${index + 1}',
        coverUrl: 'https://picsum.photos/100',
        audioUrl: 'https://example.com/song$index.mp3',
        duration: Duration(minutes: 3 + index % 5, seconds: (index * 7) % 60),
      );
    });
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
