import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../theme/theme.dart';
import '../../../../models/song.dart';
import '../../../../utils/image_utils.dart';

/// 播放器专辑封面组件 - 黑胶唱片风格
class AlbumArtWidget extends StatefulWidget {
  final Song song;
  final bool isPlaying;
  final Animation<double> rotationAnimation;
  final bool isChangingTrack;
  final bool isNextTrack;

  const AlbumArtWidget({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.rotationAnimation,
    this.isChangingTrack = false,
    this.isNextTrack = true,
  });

  @override
  State<AlbumArtWidget> createState() => _AlbumArtWidgetState();
}

class _AlbumArtWidgetState extends State<AlbumArtWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late AnimationController _newRotationController;
  late Animation<double> _newRotationAnimation;
  Song? _oldSong;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    // 新黑胶的旋转动画 - 从0开始
    _newRotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _newRotationAnimation = _newRotationController;

    _wasPlaying = widget.isPlaying;
    if (_wasPlaying) {
      _newRotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(AlbumArtWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 检测到切歌，触发动画
    if (widget.song.id != oldWidget.song.id) {
      _oldSong = oldWidget.song;
      _slideController.reset();
      _slideController.forward();

      // 重置新黑胶的旋转动画，让它从0开始
      _newRotationController.reset();
      if (widget.isPlaying) {
        _newRotationController.repeat();
      }
    }

    // 检测播放状态变化
    if (widget.isPlaying != _wasPlaying) {
      _wasPlaying = widget.isPlaying;
      if (_wasPlaying) {
        _newRotationController.repeat();
      } else {
        _newRotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _newRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320.w,
      height: 320.w,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 黑胶唱片 - 带切换动画
          _buildAnimatedVinylRecord(),
          // 唱片臂（放在上层）
          _buildToneArm(),
        ],
      ),
    );
  }

  /// 唱片臂
  Widget _buildToneArm() {
    // 切歌时保持抬起状态
    final armPosition = widget.isChangingTrack ? -0.12 : (widget.isPlaying ? -0.06 : -0.12);

    return Positioned(
      top: -45.w,
      child: AnimatedRotation(
        // 播放时唱针在黑色盘面，暂停时移出唱片
        turns: armPosition,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Container(
          width: 100.w,
          height: 180.w,
          alignment: Alignment.topCenter,
          child: CustomPaint(
            size: Size(100.w, 180.w),
            painter: _ToneArmPainter(),
          ),
        ),
      ),
    );
  }

  /// 带切换动画的黑胶唱片 - 替换效果
  Widget _buildAnimatedVinylRecord() {
    return Positioned(
      top: 20.h,
      child: SizedBox(
        width: 320.w,
        height: 320.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 静止的外围毛玻璃圈（不动）
            _buildStaticOuterRing(),
            // 滑动的黑胶唱片
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                // 下一曲：旧唱片从0滑到-350.w（左出），新唱片从350.w滑到0（右入）
                // 上一曲：旧唱片从0滑到350.w（右出），新唱片从-350.w滑到0（左入）
                final double spacing = 50.w; // 间距
                final double distance = 300.w + spacing;

                final double outgoingOffset = widget.isNextTrack
                    ? -distance * _slideAnimation.value  // 向左滑出
                    : distance * _slideAnimation.value;   // 向右滑出
                final double incomingOffset = widget.isNextTrack
                    ? distance * (1 - _slideAnimation.value)  // 从右边滑入
                    : -distance * (1 - _slideAnimation.value); // 从左边滑入

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // 旧唱片（滑出屏幕）- 保持旋转
                    if (_slideAnimation.value < 1.0 && _oldSong != null)
                      Transform.translate(
                        offset: Offset(outgoingOffset, 0),
                        child: _buildVinylRecord(_oldSong, isNewTrack: false),
                      ),
                    // 新唱片（从屏幕外滑入）- 保持静止
                    Transform.translate(
                      offset: Offset(incomingOffset, 0),
                      child: _buildVinylRecord(widget.song, isNewTrack: true),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 静止的外围毛玻璃圈（环形，中间镂空）
  Widget _buildStaticOuterRing() {
    return CustomPaint(
      size: Size(320.w, 320.w),
      painter: _OuterRingPainter(),
    );
  }

  /// 构建黑胶唱片组件（不含外圈）
  Widget _buildVinylRecord(Song? song, {bool isNewTrack = false}) {
    if (song == null) return const SizedBox.shrink();

    // 新黑胶使用独立的旋转动画（从0开始），旧黑胶使用全局旋转动画
    final rotationAnimation = isNewTrack ? _newRotationAnimation : widget.rotationAnimation;
    // 新黑胶在切歌动画完成前保持静止
    final shouldRotate = !isNewTrack || _slideAnimation.value == 1.0;

    return Container(
      width: 300.w,
      height: 300.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40.r,
            spreadRadius: 8.r,
            offset: Offset(0, 15.w),
          ),
        ],
      ),
      child: ClipOval(
        child: RotationTransition(
          turns: shouldRotate ? rotationAnimation : const AlwaysStoppedAnimation(0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 黑胶纹理
              _buildVinylTexture(),
              // 封面图片（唱片标签）
              _buildRecordLabelForSong(song),
            ],
          ),
        ),
      ),
    );
  }

  /// 黑胶纹理
  Widget _buildVinylTexture() {
    return Container(
      width: 300.w,
      height: 300.w,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: const [
            Color(0xFF1a1a1a),
            Color(0xFF0d0d0d),
            Color(0xFF000000),
            Color(0xFF2a2a2a),
            Color(0xFF000000),
            Color(0xFF222222),
            Color(0xFF000000),
          ],
          stops: const [0.0, 0.25, 0.42, 0.47, 0.52, 0.62, 1.0],
        ),
      ),
      child: CustomPaint(
        size: Size(300.w, 300.w),
        painter: _VinylGroovesPainter(),
      ),
    );
  }

  /// 唱片标签（封面图片）
  Widget _buildRecordLabel() {
    return _buildRecordLabelForSong(widget.song);
  }

  /// 唱片标签（封面图片）- 接受 Song 参数
  Widget _buildRecordLabelForSong(Song song) {
    return Container(
      width: 220.w,
      height: 220.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.3),
          width: 3.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15.r,
            spreadRadius: 3.r,
          ),
        ],
      ),
      child: ClipOval(
        child: _buildCoverImageForSong(song),
      ),
    );
  }

  Widget _buildCoverImage() {
    return _buildCoverImageForSong(widget.song);
  }

  Widget _buildCoverImageForSong(Song song) {
    // 检查是否有有效的封面 URL
    final hasValidCover = song.coverUrl != null && song.coverUrl!.isNotEmpty;

    if (!hasValidCover) {
      return _buildDefaultCover();
    }

    // 本地图片
    if (song.isLocal) {
      return Image.file(
        File(song.coverUrl!),
        width: 200.w,
        height: 200.w,
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
      coverUrl = ImageUtils.replaceImageSize(coverUrl, 500);
    }

    return CachedNetworkImage(
      imageUrl: coverUrl,
      width: 200.w,
      height: 200.w,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildDefaultCover(),
      errorWidget: (context, url, error) => _buildDefaultCover(),
      memCacheWidth: 500,
      memCacheHeight: 500,
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 800,
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      width: 200.w,
      height: 200.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceVariant,
            AppColors.surface,
          ],
        ),
      ),
      child: Icon(
        Icons.music_note,
        color: Colors.white.withValues(alpha: 0.5),
        size: 50.sp,
      ),
    );
  }
}

/// 唱片臂绘制器
class _ToneArmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.12;

    // 唱臂参数
    final armWidth = size.width * 0.07;

    // 阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // 绘制唱臂主体 - 明显的折角设计
    final armPath = Path();

    // 定义关键点
    // 支点
    final pivot = Offset(centerX, centerY);
    // 折角点 - 约160度折角
    final elbow = Offset(centerX + size.width * 0.32, centerY + size.height * 0.15);
    // 唱针点
    final needle = Offset(elbow.dx, elbow.dy + size.height * 0.55);

    // 右侧路径
    armPath.moveTo(centerX + armWidth / 2, pivot.dy);
    // 第一段：从支点到折角点（水平）
    armPath.lineTo(elbow.dx + armWidth / 2, elbow.dy);
    // 折角：从折角点向下（垂直，160度左右）
    armPath.lineTo(needle.dx + armWidth / 2, needle.dy);

    // 唱针头
    final headWidth = armWidth * 2.2;
    final headHeight = size.height * 0.08;
    armPath.lineTo(needle.dx + headWidth / 2, needle.dy + headHeight * 0.2);
    armPath.lineTo(needle.dx + headWidth / 2, needle.dy + headHeight);

    // 左侧路径 - 对称返回
    armPath.lineTo(needle.dx - headWidth / 2, needle.dy + headHeight);
    armPath.lineTo(needle.dx - headWidth / 2, needle.dy + headHeight * 0.2);
    armPath.lineTo(needle.dx - armWidth / 2, needle.dy);
    // 向上返回折角点
    armPath.lineTo(elbow.dx - armWidth / 2, elbow.dy);
    // 返回支点
    armPath.lineTo(centerX - armWidth / 2, pivot.dy);
    armPath.close();

    // 绘制阴影
    canvas.drawPath(armPath, shadowPaint);

    // 金属渐变
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFF0F0F0),
        const Color(0xFFD8D8D8),
        const Color(0xFFA8A8A8),
        const Color(0xFFC8C8C8),
      ],
      stops: const [0.0, 0.25, 0.6, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset(centerX, centerY + size.height * 0.35),
      radius: size.height * 0.4,
    ));

    // 绘制唱臂
    final armPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(armPath, armPaint);

    // 细微边框
    final strokePaint = Paint()
      ..color = const Color(0xFFAAAAAA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(armPath, strokePaint);

    // 绘制唱针
    final needlePaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(needle.dx, needle.dy + headHeight + size.height * 0.035),
        width: 1.3,
        height: size.height * 0.045,
      ),
      needlePaint,
    );

    // 唱针尖端
    canvas.drawCircle(
      Offset(needle.dx, needle.dy + headHeight + size.height * 0.075),
      1.0,
      needlePaint,
    );

    // 绘制支点
    _drawPivot(canvas, centerX, centerY, size.width * 0.14);
  }

  void _drawPivot(Canvas canvas, double x, double y, double radius) {
    // 外圈阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(x, y), radius + 2, shadowPaint);

    // 金属外圈渐变
    final outerGradient = RadialGradient(
      colors: [
        const Color(0xFFE5E5E5),
        const Color(0xFF959595),
        const Color(0xFFC5C5C5),
      ],
      stops: const [0.0, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));

    canvas.drawCircle(Offset(x, y), radius, Paint()..shader = outerGradient);

    // 中圈
    canvas.drawCircle(
      Offset(x, y),
      radius * 0.62,
      Paint()..color = const Color(0xFFE8E8E8),
    );

    // 内圈
    canvas.drawCircle(
      Offset(x, y),
      radius * 0.38,
      Paint()..color = const Color(0xFF4A4A4A),
    );

    // 中心点
    canvas.drawCircle(
      Offset(x, y),
      radius * 0.12,
      Paint()..color = const Color(0xFF2A2A2A),
    );

    // 高光
    canvas.drawCircle(
      Offset(x - radius * 0.25, y - radius * 0.25),
      radius * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 黑胶纹理绘制器 - 空实现（无纹路）
class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 不绘制任何纹路，只保留渐变背景
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 外围毛玻璃圈绘制器（环形，中间镂空带淡淡毛玻璃效果）
class _OuterRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = 145.w; // 300.w / 2 - 10.w 间隙

    // 绘制外圈环形
    final ringPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerRadius))
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius))
      ..fillType = PathFillType.evenOdd;

    // 外圈半透明背景
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(ringPath, ringPaint);

    // 绘制边框
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, outerRadius, borderPaint);
    canvas.drawCircle(center, innerRadius, borderPaint);

    // 中间镂空部分的淡淡毛玻璃效果
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, innerRadius - 1, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
