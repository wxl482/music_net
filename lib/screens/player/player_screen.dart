import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/player_provider.dart';
import '../../theme/theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final currentSong = playerProvider.currentSong;

    if (currentSong == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text('暂无播放', style: AppTextStyles.bodyLarge),
        ),
      );
    }

    // Start rotation animation when playing
    if (playerProvider.isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Album art
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.all(40.w),
              child: RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(_rotationController),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 30.r,
                        spreadRadius: 10.r,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: currentSong.coverUrl != null
                        ? (currentSong.isLocal
                            ? Image.file(
                                File(currentSong.coverUrl!),
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                imageUrl: currentSong.coverUrl!,
                                fit: BoxFit.cover,
                              ))
                        : Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.music_note,
                                color: Colors.white, size: 80),
                          ),
                  ),
                ),
              ),
            ),
          ),
          // Song info and lyrics
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Song title and artist
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    children: [
                      Text(
                        currentSong.title,
                        style: AppTextStyles.headlineMedium,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        currentSong.artist,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.onSurfaceSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Progress bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4.h,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surfaceVariant,
                          thumbColor: AppColors.primary,
                        ),
                        child: Slider(
                          value: playerProvider.position.inMilliseconds
                              .toDouble(),
                          min: 0,
                          max: playerProvider.duration.inMilliseconds
                              .toDouble(),
                          onChanged: (value) {
                            playerProvider.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                      // Time labels
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Row(
                          children: [
                            Text(
                              _formatTime(playerProvider.position),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onSurfaceSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTime(playerProvider.duration),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onSurfaceSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
          // Control buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Column(
              children: [
                // Playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: const Icon(Icons.shuffle, color: AppColors.onSurfaceSecondary),
                      onPressed: () {},
                    ),
                    // Previous
                    IconButton(
                      icon: const Icon(Icons.skip_previous,
                          color: AppColors.onSurface, size: 36),
                      onPressed: playerProvider.seekToPrevious,
                    ),
                    // Play/Pause
                    Container(
                      width: 64.w,
                      height: 64.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 16.r,
                            spreadRadius: 4.r,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          playerProvider.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: AppColors.onPrimary,
                          size: 36,
                        ),
                        onPressed: playerProvider.togglePlay,
                      ),
                    ),
                    // Next
                    IconButton(
                      icon:
                          const Icon(Icons.skip_next, color: AppColors.onSurface, size: 36),
                      onPressed: playerProvider.seekToNext,
                    ),
                    // Loop mode
                    IconButton(
                      icon: Icon(
                        playerProvider.playMode == PlayMode.loop
                            ? Icons.repeat
                            : Icons.repeat_one,
                        color: playerProvider.playMode != PlayMode.sequential
                            ? AppColors.primary
                            : AppColors.onSurfaceSecondary,
                      ),
                      onPressed: () {
                        final modes = PlayMode.values;
                        final currentIndex = modes.indexOf(playerProvider.playMode);
                        final nextIndex = (currentIndex + 1) % modes.length;
                        playerProvider.setPlayMode(modes[nextIndex]);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                // Extra actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.comment, '评论'),
                    _buildActionButton(Icons.share, '分享'),
                    _buildActionButton(Icons.playlist_play, '播放列表'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.onSurfaceSecondary, size: 24.sp),
        SizedBox(height: 4.h),
        Text(label, style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.onSurfaceSecondary,
        )),
      ],
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
