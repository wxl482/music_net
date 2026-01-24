import 'package:flutter/material.dart';

/// 紫色 + 黑色主题颜色系统
class AppColors {
  // ========== Primary Colors - 主色调（紫色系）==========
  static const Color primary = Color(0xFFBB86FC); // 紫色主色
  static const Color primaryLight = Color(0xFFE1BEE7);
  static const Color primaryDark = Color(0xFF9955E8);
  static const Color secondary = Color(0xFFCF6679); // 粉色辅助色

  // ========== Accents - 强调色 ==========
  static const Color accentPink = Color(0xFFFF4081);
  static const Color accentOrange = Color(0xFFFFAB40);
  static const Color accentGreen = Color(0xFF69F0AE);
  static const Color accentTeal = Color(0xFF18FFFF);
  static const Color accentIndigo = Color(0xFF7C4DFF);

  // ========== Dark Theme Colors - 深色模式 ==========
  static const Color background = Color(0xFF000000); // 纯黑背景
  static const Color surface = Color(0xFF121212); // 深灰表面
  static const Color surfaceVariant = Color(0xFF1E1E1E); // 浅灰变体
  static const Color surfaceElevated = Color(0xFF2C2C2C); // 提升表面
  static const Color surfaceGrouped = Color(0xFF000000); // 分组背景

  // ========== Separator Colors - 分隔线颜色 ==========
  static const Color separator = Color(0xFF2C2C2C); // 深色分隔线
  static const Color separatorOpaque = Color(0xFF3D3D3D); // 不透明分隔线

  // ========== Text Colors - 文字色（深色主题）==========
  static const Color onPrimary = Colors.black;
  static const Color onSurface = Color(0xFFFFFFFF); // 纯白文字
  static const Color onSurfaceSecondary = Color(0xB3FFFFFF); // 次要文字 (70% 白)
  static const Color onSurfaceTertiary = Color(0x80FFFFFF); // 三级文字 (50% 白)
  static const Color onBackground = Color(0xFFFFFFFF);

  // ========== Status Colors - 状态色 ==========
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF03DAC6);
  static const Color warning = Color(0xFFFFAB40);

  // ========== 紫色系特殊颜色 ==========
  static const Color purpleLight = Color(0xFFE1BEE7);
  static const Color purple = Color(0xFFBB86FC);
  static const Color purpleDark = Color(0xFF9955E8);
  static const Color purpleDeep = Color(0xFF7C4DFF);
  static const Color purpleDarker = Color(0xFF6200EA);
  static const Color systemGray = Color(0xFFB0B0B0);
  static const Color systemGray2 = Color(0xFF808080);
  static const Color systemGray3 = Color(0xFF606060);
  static const Color systemGray4 = Color(0xFF404040);
  static const Color systemGray5 = Color(0xFF303030);
  static const Color systemGray6 = Color(0xFF202020);

  // ========== Gradients - 渐变色库 ==========
  // 紫色主渐变
  static const List<Color> primaryGradient = [
    Color(0xFFBB86FC),
    Color(0xFFE1BEE7),
    Color(0xFF7C4DFF),
  ];

  // 紫粉渐变（热门/推荐）
  static const List<Color> purplePinkGradient = [
    Color(0xFF7C4DFF),
    Color(0xFFBB86FC),
    Color(0xFFFF4081),
  ];

  // 紫橙渐变（活力/运动）
  static const List<Color> purpleOrangeGradient = [
    Color(0xFFBB86FC),
    Color(0xFF9955E8),
    Color(0xFFFFAB40),
  ];

  // 紫青渐变（排行榜）
  static const List<Color> purpleTealGradient = [
    Color(0xFFBB86FC),
    Color(0xFF18FFFF),
    Color(0xFF69F0AE),
  ];

  // 深邃渐变（用于卡片阴影等）
  static const List<Color> deepGradient = [
    Color(0xFF121212),
    Color(0xFF1E1E1E),
    Color(0xFF2C2C2C),
  ];

  // 玻璃渐变（半透明）- 深色主题
  static const List<Color> glassGradient = [
    Color(0xCC121212),
    Color(0x661E1E1E),
    Color(0x332C2C2C),
  ];

  // 卡片渐变
  static const List<Color> cardGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF222222),
    Color(0xFF2C2C2C),
  ];

  // 浅色渐变（用于装饰）
  static const List<Color> lightGradient = [
    Color(0xFF2C2C2C),
    Color(0xFF3C3C3C),
    Color(0xFF4C4C4C),
  ];

  // 紫色光晕渐变
  static const List<Color> purpleGlow = [
    Color(0xFFBB86FC),
    Color(0x80BB86FC),
    Color(0x33BB86FC),
    Color(0x00BB86FC),
  ];
}

/// iOS 17+ 风格文本样式
class AppTextStyles {
  // Large Title (34pt, Bold) - iOS 大标题
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
    letterSpacing: -0.5,
  );

  // Title 1 (28pt, Bold)
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
    letterSpacing: -0.3,
  );

  // Title 2 (22pt, Bold)
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
    letterSpacing: -0.2,
  );

  // Title 3 (20pt, Semibold)
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  // Headline (17pt, Semibold)
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  // Body (17pt, Regular)
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurface,
  );

  // Callout (16pt, Semibold)
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  // Subheadline (15pt, Regular)
  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurfaceSecondary,
  );

  // Footnote (13pt, Regular)
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurfaceSecondary,
  );

  // Caption 1 (12pt, Regular)
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurfaceTertiary,
  );

  // Caption 2 (11pt, Regular)
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurfaceTertiary,
  );

  // 兼容旧样式
  static const TextStyle displayLarge = largeTitle;
  static const TextStyle displayMedium = title1;
  static const TextStyle headlineLarge = title2;
  static const TextStyle headlineMedium = title3;
  static const TextStyle titleLarge = headline;
  static const TextStyle titleMedium = callout;
  static const TextStyle bodyLarge = body;
  static const TextStyle bodyMedium = subheadline;
  static const TextStyle bodySmall = footnote;
  static const TextStyle labelLarge = callout;
  static const TextStyle labelMedium = caption1;
}

/// iOS 17+ 风格尺寸常量
class AppDimensions {
  // 圆角半径
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;

  // 卡片圆角 (iOS 17+ 风格)
  static const double cardRadius = 20.0;
  static const double modalRadius = 24.0;

  // 间距
  static const double paddingTiny = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;
  static const double paddingXXLarge = 24.0;

  // 列表项高度
  static const double listItemHeight = 56.0;
  static const double listItemHeightCompact = 44.0;

  // 导航栏高度
  static const double navBarHeight = 44.0;
  static const double tabBarHeight = 49.0;

  // 阴影
  static const double shadowSmall = 2.0;
  static const double shadowMedium = 4.0;
  static const double shadowLarge = 8.0;
  static const double shadowXLarge = 16.0;
}

/// Apple Music 风格主题
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onPrimary,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceSecondary,
        error: AppColors.error,
        outline: AppColors.separator,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      dividerColor: AppColors.separator,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title3,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        color: AppColors.surface,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLarge,
          vertical: AppDimensions.paddingSmall,
        ),
        titleTextStyle: AppTextStyles.body,
        subtitleTextStyle: AppTextStyles.subheadline,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
      ),
    );
  }
}
