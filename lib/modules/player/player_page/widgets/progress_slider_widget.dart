import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../theme/theme.dart';

/// 播放进度条组件
class ProgressSliderWidget extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<double>? onChanged;

  const ProgressSliderWidget({
    super.key,
    required this.position,
    required this.duration,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentPosition = position.inMilliseconds.toDouble();
    final totalDuration = duration.inMilliseconds.toDouble();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4.h,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 6.r,
              ),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceVariant,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: currentPosition.clamp(0.0, totalDuration),
              min: 0,
              max: totalDuration > 0 ? totalDuration : 1.0,
              onChanged: onChanged,
            ),
          ),
          // 时间标签
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              children: [
                Text(
                  _formatTime(position),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(duration),
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
  }

  String _formatTime(Duration time) {
    final minutes = time.inMinutes;
    final seconds = time.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
