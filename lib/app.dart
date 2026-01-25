import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_service/audio_service.dart';
import 'theme/theme.dart';
import 'screens/main_screen.dart';
import 'screens/rank/rank_detail_screen.dart';
import 'screens/history/playback_history_screen.dart';
import 'modules/player/player_page/player_screen.dart';
import 'modules/player/player_page/bindings/player_binding.dart';
import 'bindings/global_binding.dart';

/// Drawer 状态 - 全局追踪 Drawer 是否打开
class DrawerState extends GetxController {
  final RxBool isOpen = false.obs;
}

/// 全局 Drawer 状态实例
final drawerState = DrawerState();

/// 全局路由名称
class AppRoutes {
  static const String home = '/home';
  static const String discover = '/discover';
  static const String search = '/search';
  static const String library = '/library';
  static const String player = '/player';
  static const String playlistDetail = '/playlist/:id';
  static const String artistDetail = '/artist/:id';
  static const String albumDetail = '/album/detail';
  static const String rankDetail = '/rank/:id';
  static const String history = '/history';
}

class App extends StatelessWidget {
  final BaseAudioHandler audioHandler;

  const App({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Music App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme.copyWith(
            textTheme: GoogleFonts.notoSansTextTheme(
              AppTheme.darkTheme.textTheme,
            ),
          ),
          home: const MainScreen(),
          // 初始化全局控制器
          initialBinding: GlobalBinding(),
          getPages: [
            GetPage(
              name: AppRoutes.player,
              page: () => const PlayerScreen(),
              binding: PlayerBinding(),
              transition: Transition.downToUp,
              transitionDuration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            ),
            GetPage(
              name: AppRoutes.rankDetail,
              page: () => RankDetailScreen(
                rankId: Get.arguments as String? ?? '',
              ),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 350),
            ),
            GetPage(
              name: AppRoutes.history,
              page: () => const PlaybackHistoryScreen(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 350),
            ),
          ],
        );
      },
    );
  }
}
