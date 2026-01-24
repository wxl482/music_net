import 'dart:ui';

/// 图片工具类
class ImageUtils {
  /// 根据显示尺寸计算合适的图片大小
  ///
  /// [url] - 图片 URL，可能包含 {size} 占位符
  /// [displaySize] - 实际显示的像素值
  ///
  /// 返回替换 {size} 后的 URL
  ///
  /// 注意：
  /// - 对于高 DPI 屏幕（如 Retina），图片尺寸应该是显示尺寸的 2-3 倍
  /// - 使用 MediaQuery.devicePixelRatio 获取设备像素比可以更精确
  static String replaceImageSize(String? url, double displaySize) {
    if (url == null || url.isEmpty) {
      return '';
    }
    if (!url.contains('{size}')) {
      return url;
    }

    // 获取设备像素比，默认为 2.0（Retina 屏幕）
    final pixelRatio = PlatformDispatcher.instance.views.first.devicePixelRatio;
    // 至少使用 2 倍尺寸以保证清晰度
    final scale = pixelRatio.clamp(2.0, 3.0);
    final imageSize = (displaySize * scale).round();

    return url.replaceAll('{size}', imageSize.toString());
  }

  /// 根据显示尺寸计算合适的图片大小（带自定义缩放比例）
  ///
  /// [url] - 图片 URL，可能包含 {size} 占位符
  /// [displaySize] - 实际显示的像素值
  /// [scale] - 缩放比例，默认为 2.0
  static String replaceImageSizeWithScale(
    String? url,
    double displaySize, {
    double scale = 2.0,
  }) {
    if (url == null || url.isEmpty) {
      return '';
    }
    if (!url.contains('{size}')) {
      return url;
    }

    final imageSize = (displaySize * scale).round();
    return url.replaceAll('{size}', imageSize.toString());
  }
}
