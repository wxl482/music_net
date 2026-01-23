import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/theme.dart';
import 'local_music_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            '我的音乐',
            style: AppTextStyles.headlineLarge,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.onSurface),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.sort, color: AppColors.onSurface),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Tab bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.onSurfaceSecondary,
                labelStyle: AppTextStyles.labelLarge,
                tabs: const [
                  Tab(text: '本地'),
                  Tab(text: '收藏'),
                  Tab(text: '歌单'),
                  Tab(text: '最近'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                children: [
                  const LocalMusicScreen(),
                  _buildFavoritesTab(),
                  _buildPlaylistsTab(),
                  _buildRecentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final favoriteSongs = List.generate(5, (index) => index);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Statistics card
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 32),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我喜欢的音乐',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${favoriteSongs.length}首歌曲',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Play all button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                const Icon(Icons.play_circle_filled, color: AppColors.primary, size: 28),
                SizedBox(width: 8.w),
                Text('播放全部', style: AppTextStyles.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.onSurface),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceVariant),
          // Song list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: favoriteSongs.length,
            itemBuilder: (context, index) {
              return _buildFavoriteSongItem(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteSongItem(int index) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4.h),
      leading: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: const Icon(Icons.music_note, color: Colors.white),
      ),
      title: Text('喜欢的歌曲 ${index + 1}', style: AppTextStyles.titleMedium),
      subtitle: Text('歌手', style: AppTextStyles.bodySmall),
      trailing: IconButton(
        icon: const Icon(Icons.favorite, color: AppColors.primary),
        onPressed: () {},
      ),
    );
  }

  Widget _buildPlaylistsTab() {
    final playlists = List.generate(6, (index) => index);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create playlist button
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: AppColors.primary),
                  ),
                  SizedBox(width: 12.w),
                  Text('创建新歌单', style: AppTextStyles.titleLarge),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text('我的歌单 (${playlists.length})', style: AppTextStyles.titleMedium),
            SizedBox(height: 12.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                return _buildPlaylistItem(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistItem(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('歌单名称 $index', style: AppTextStyles.titleMedium),
                SizedBox(height: 4.h),
                Text(
                  '${index * 10}首歌曲',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
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
    );
  }

  Widget _buildRecentTab() {
    final recentItems = List.generate(10, (index) => index);

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: recentItems.length,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 4.h),
          leading: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.history, color: Colors.white),
          ),
          title: Text('最近播放 $index', style: AppTextStyles.titleMedium),
          subtitle: Text('歌手', style: AppTextStyles.bodySmall),
          trailing: Text(
            '${index + 1}小时前',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceSecondary,
            ),
          ),
        );
      },
    );
  }
}
