import 'package:get/get.dart';
import '../controllers/local_music_controller.dart';
import '../controllers/online_music_controller.dart';
import '../modules/player/player_controller/player_controller.dart';

/// 全局依赖注入绑定
class GlobalBinding extends Bindings {
  @override
  void dependencies() {
    // 播放控制器（全局单例）
    Get.lazyPut<PlayerController>(() => PlayerController(), fenix: true);

    // 本地音乐控制器
    Get.lazyPut<LocalMusicController>(() => LocalMusicController(), fenix: true);

    // 在线音乐控制器
    Get.lazyPut<OnlineMusicController>(() => OnlineMusicController(), fenix: true);
  }
}
