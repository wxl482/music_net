import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/song.dart';
import '../../../../theme/theme.dart';
import '../../../../utils/image_utils.dart';
import '../../player_controller/player_controller.dart';

/// 播放列表底部弹窗
class PlaylistBottomSheet extends StatelessWidget {
  final PlayerController controller;

  const PlaylistBottomSheet({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final playlist = controller.playlist;
      final currentSong = controller.currentSong.value;

      if (playlist.isEmpty) {
        return _buildEmptyState();
      }

      return Container(
        height: 0.6.sh,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // 顶部标题栏
            _buildHeader(context, playlist.length),
            // 播放列表
            Expanded(
              child: ListView.builder(
                itemCount: playlist.length,
                itemBuilder: (context, index) {
                  final song = playlist[index];
                  // 直接用歌曲 ID 匹配判断当前播放
                  final isCurrent = currentSong != null && song.id == currentSong.id;
                  return _buildSongItem(
                    context,
                    song,
                    isCurrent,
                    index,
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Container(
      height: 0.4.sh,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_play,
              size: 48.sp,
              color: AppColors.onSurfaceSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              '播放列表为空',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '播放列表 ($count)',
            style: AppTextStyles.titleMedium,
          ),
          // 清空列表按钮
          if (count > 0)
            TextButton.icon(
              onPressed: () => _showClearDialog(context),
              icon: Icon(
                Icons.delete_outline,
                size: 18.sp,
                color: AppColors.onSurfaceSecondary,
              ),
              label: Text(
                '清空',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSongItem(
    BuildContext context,
    Song song,
    bool isCurrent,
    int index,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.surfaceVariant : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: _buildLeading(song, isCurrent, index),
        title: Text(
          song.title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isCurrent ? AppColors.primary : AppColors.onSurface,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isCurrent
            ? Icon(
                Icons.bar_chart,
                color: AppColors.primary,
                size: 20.sp,
              )
            : IconButton(
                icon: Icon(
                  Icons.close,
                  color: AppColors.onSurfaceSecondary,
                  size: 20.sp,
                ),
                onPressed: () => _removeSong(index),
              ),
        onTap: () => _playSong(index),
      ),
    );
  }

  Widget _buildLeading(Song song, bool isCurrent, int index) {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: isCurrent
            ? Border.all(
                color: AppColors.primary,
                width: 2,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: song.coverUrl != null && song.coverUrl!.isNotEmpty
            ? (song.isLocal
                ? Image.network(
                    song.coverUrl!,
                    width: 40.w,
                    height: 40.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultCover();
                    },
                  )
                : CachedNetworkImage(
                    imageUrl: ImageUtils.replaceImageSize(song.coverUrl!, 40.w),
                    width: 40.w,
                    height: 40.w,
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
                    errorWidget: (context, url, error) => _buildDefaultCover(),
                  ))
            : _buildDefaultCover(),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        Icons.music_note,
        color: AppColors.onSurfaceSecondary,
        size: 20.sp,
      ),
    );
  }

  void _playSong(int index) {
    final song = controller.playlist[index];
    // 传入完整的播放列表，确保 currentIndex 正确更新
    controller.playSong(song, newPlaylist: controller.playlist.toList());
    Get.back();
  }

  void _removeSong(int index) {
    // 从播放列表中移除歌曲（仅移除 UI 展示，不影响 just_audio 序列）
    final songs = controller.playlist.toList();
    if (index < songs.length) {
      songs.removeAt(index);
      controller.playlist.value = songs;
    }
  }

  void _showClearDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('清空播放列表', style: AppTextStyles.titleMedium),
        content: Text(
          '确定要清空播放列表吗？',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: AppTextStyles.labelMedium),
          ),
          TextButton(
            onPressed: () {
              controller.clearPlaylist();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              '清空',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示播放列表弹窗
  static void show(BuildContext context, PlayerController controller) {
    Get.bottomSheet(
      PlaylistBottomSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }
}
