import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../theme/theme.dart';
import '../../../../models/song.dart';
import '../../../../utils/image_utils.dart';

/// 播放器专辑封面组件
class AlbumArtWidget extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final Animation<double> rotationAnimation;

  const AlbumArtWidget({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.rotationAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280.w,
      height: 280.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 40.r,
            spreadRadius: 10.r,
          ),
        ],
      ),
      child: ClipOval(
        child: RotationTransition(
          turns: rotationAnimation,
          child: _buildCoverImage(),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    // 检查是否有有效的封面 URL
    final hasValidCover = song.coverUrl != null && song.coverUrl!.isNotEmpty;

    if (!hasValidCover) {
      return _buildDefaultCover();
    }

    // 本地图片
    if (song.isLocal) {
      return Image.file(
        File(song.coverUrl!),
        width: 280.w,
        height: 280.w,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCover();
        },
      );
    }

    // 在线图片 - 使用高分辨率保证清晰度
    String coverUrl = song.coverUrl!;

    // 如果 URL 包含 {size} 占位符，替换为大尺寸
    if (coverUrl.contains('{size}')) {
      coverUrl = ImageUtils.replaceImageSize(coverUrl, 1000);
    }

    return CachedNetworkImage(
      imageUrl: coverUrl,
      width: 280.w,
      height: 280.w,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildDefaultCover(),
      errorWidget: (context, url, error) => _buildDefaultCover(),
      memCacheWidth: 1000,
      memCacheHeight: 1000,
      maxWidthDiskCache: 1500,
      maxHeightDiskCache: 1500,
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      width: 280.w,
      height: 280.w,
      color: AppColors.surfaceVariant,
      child: Icon(
        Icons.music_note,
        color: Colors.white.withValues(alpha: 0.5),
        size: 80.sp,
      ),
    );
  }
}
