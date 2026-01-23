import 'package:get/get.dart';
import '../../player_controller/player_controller.dart';

/// 播放器绑定
class PlayerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlayerController>(() => PlayerController());
  }
}
