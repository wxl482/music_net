import 'package:get/get.dart';

/// 播放器绑定
/// PlayerController 已在 GlobalBinding 中全局注册，这里不需要重复注册
class PlayerBinding extends Bindings {
  @override
  void dependencies() {
    // PlayerController 通过 GlobalBinding 全局管理
    // 这里可以添加播放页面特有的依赖（如果有的话）
  }
}
