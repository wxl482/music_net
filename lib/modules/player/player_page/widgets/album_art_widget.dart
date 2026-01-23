import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../theme/theme.dart';
import '../../../../models/song.dart';

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
    if (song.coverUrl != null) {
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
      } else {
        return CachedNetworkImage(
          imageUrl: song.coverUrl!,
          width: 280.w,
          height: 280.w,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.surfaceVariant,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          errorWidget: (context, url, error) => _buildDefaultCover(),
        );
      }
    }
    return _buildDefaultCover();
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
