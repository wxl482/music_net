import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme/theme.dart';
import 'providers/player_provider.dart';
import 'providers/local/local_music_provider.dart';
import 'providers/online_music_provider.dart';
import 'screens/main_screen.dart';
import 'modules/player/player_page/player_screen.dart';
import 'modules/player/player_page/bindings/player_binding.dart';

/// 全局路由名称
class AppRoutes {
  static const HOME = '/home';
  static const DISCOVER = '/discover';
  static const SEARCH = '/search';
  static const LIBRARY = '/library';
  static const PLAYER = '/player';
  static const PLAYLIST_DETAIL = '/playlist/:id';
  static const ARTIST_DETAIL = '/artist/:id';
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PlayerProvider()),
            ChangeNotifierProvider(create: (_) => LocalMusicProvider()),
            ChangeNotifierProvider(create: (_) => OnlineMusicProvider()),
          ],
          child: GetMaterialApp(
            title: 'Music App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme.copyWith(
              textTheme: GoogleFonts.notoSansTextTheme(
                AppTheme.darkTheme.textTheme,
              ),
            ),
            home: const MainScreen(),
            // 初始化全局控制器
            initialBinding: _InitialBinding(),
            getPages: [
              GetPage(
                name: AppRoutes.PLAYER,
                page: () => const PlayerScreen(),
                binding: PlayerBinding(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 初始化绑定 - 注册全局单例服务
class _InitialBinding extends Bindings {
  @override
  void dependencies() {
    // PlayerController 会被 PlayerBinding 懒加载
    // 这里可以注册其他全局服务
  }
}
