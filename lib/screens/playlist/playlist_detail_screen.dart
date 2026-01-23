import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/theme.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../home/widgets/song_item.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with cover
          SliverAppBar(
            expandedHeight: 320.h,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
            leading: Container(
              margin: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          // Content
          SliverList(
            delegate: SliverChildListDelegate([
              _buildActionBar(),
              _buildSongList(),
            ]),
          ),
        ],
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
        // Cover image
        Positioned(
          left: 24.w,
          top: 80.h,
          child: Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: playlist.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: playlist.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.music_note, color: Colors.white, size: 60),
                    ),
            ),
          ),
        ),
        // Playlist info
        Positioned(
          left: 24.w,
          top: 240.h,
          right: 24.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playlist.name,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
              if (playlist.description != null)
                Text(
                  playlist.description!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          // Play all button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text(
                '播放全部',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Favorite button
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                playlist.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: playlist.isFavorite ? AppColors.primary : AppColors.onSurface,
              ),
              onPressed: () {},
            ),
          ),
          SizedBox(width: 8.w),
          // More options
          Container(
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
    final songs = playlist.songs.isNotEmpty
        ? playlist.songs
        : _getSampleSongs();

    return Column(
      children: List.generate(songs.length, (index) {
        return SongItem(
          song: songs[index],
          index: index + 1,
          onTap: () {},
        );
      }),
    );
  }

  List<Song> _getSampleSongs() {
    return List.generate(10, (index) {
      return Song.fromOnline(
        id: '${playlist.id}_$index',
        title: '歌曲 ${index + 1}',
        artist: '歌手 ${index + 1}',
        album: '专辑 ${index + 1}',
        coverUrl: 'https://picsum.photos/100',
        audioUrl: 'https://example.com/song$index.mp3',
        duration: Duration(minutes: 3 + index % 5, seconds: (index * 7) % 60),
      );
    });
  }
}
