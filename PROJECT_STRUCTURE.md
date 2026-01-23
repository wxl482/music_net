# 音乐应用 - 项目结构规范

## 技术栈

- **状态管理**: GetX
- **屏幕适配**: flutter_screenutil
- **网络请求**: http
- **本地存储**: shared_preferences
- **图片缓存**: cached_network_image

## 目录结构规范

每个功能模块必须按照以下结构组织：

```
lib/
├── main.dart                 # 应用入口
├── app/                      # 应用级配置
│   ├── pages/               # 全局页面（启动页、引导页等）
│   ├── routes/              # 路由配置
│   └── bindings/            # 全局绑定
├── core/                    # 核心功能
│   ├── utils/               # 工具类
│   ├── constants/           # 常量
│   └── theme/               # 主题配置
├── models/                  # 全局数据模型（跨模块共用）
├── services/                # 服务层（API、存储等）
└── modules/                 # 功能模块
    ├── home/                # 首页模块
    │   ├── home_page/       # 页面
    │   ├── home_controller/ # 控制器
    │   └── models/          # 模型（如果特有）
    ├── search/              # 搜索模块
    │   ├── search_page/
    │   ├── search_controller/
    │   └── models/
    ├── player/              # 播放器模块
    │   ├── player_page/
    │   ├── player_controller/
    │   └── models/
    └── ...
```

## 模块结构详解

每个功能模块必须包含三个子文件夹：

### 1. xx_page/ (页面文件夹)
存放所有与该模块相关的 UI 组件

```
home_page/
├── home_screen.dart           # 主页面
├── widgets/                   # 页面专属组件
│   ├── section_header.dart
│   ├── playlist_card.dart
│   └── song_item.dart
└── bindings/                  # 依赖注入（如果需要）
    └── home_binding.dart
```

### 2. xx_controller/ (控制器文件夹)
存放业务逻辑和状态管理

```
home_controller/
├── home_controller.dart       # 主控制器
└── widgets/                   # 组件控制器（如果需要）
    └── playlist_card_controller.dart
```

### 3. models/ (数据模型文件夹)
存放该模块特有的数据模型

```
models/
├── playlist_model.dart        # 歌单模型
├── song_model.dart            # 歌曲模型
└── rank_model.dart            # 排行榜模型
```

## 命名规范

### 文件命名
- 页面文件: `{module}_screen.dart` 或 `{module}_page.dart`
- 控制器文件: `{module}_controller.dart`
- 模型文件: `{name}_model.dart`
- 组件文件: `{name}_widget.dart` 或 `{name}.dart`（在 widgets 文件夹内）

### 类命名
- 页面类: `{Name}Screen` 或 `{Name}Page`
- 控制器类: `{Name}Controller` extends `GetxController`
- 模型类: `{Name}` 或 `{Name}Model`

### 文件夹命名
- 使用小写+下划线: `home_page`, `search_controller`

## 代码规范

### 1. 使用 ScreenUtil 进行尺寸适配

```dart
// 初始化
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // 设计稿尺寸
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(...);
      },
    );
  }
}

// 使用示例
Container(
  width: 100.w,    // 宽度 100 逻辑像素
  height: 50.h,    // 高度 50 逻辑像素
  padding: EdgeInsets.all(10.r),
  child: Text(
    'Hello',
    style: TextStyle(fontSize: 14.sp), // 字体大小
  ),
)
```

### 2. 使用 GetX 进行状态管理

```dart
// 控制器
class HomeController extends GetxController {
  // 响应式变量
  final RxList<Playlist> playlists = <Playlist>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // 普通变量
  final KugouApiService _api = KugouApiService();

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    error.value = '';

    try {
      final result = await _api.getRecommendPlaylists();
      playlists.value = result;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}

// 页面中使用
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }
        return ListView.builder(
          itemCount: controller.playlists.length,
          itemBuilder: (context, index) {
            return PlaylistCard(playlist: controller.playlists[index]);
          },
        );
      }),
    );
  }
}
```

### 3. 路由管理

```dart
// 路由配置
class AppRoutes {
  static const HOME = '/';
  static const SEARCH = '/search';
  static const PLAYER = '/player';
  static const PLAYLIST_DETAIL = '/playlist/:id';
}

// 路由绑定
class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.SEARCH,
      page: () => const SearchScreen(),
      binding: SearchBinding(),
    ),
  ];
}

// 使用路由
Get.toNamed(AppRoutes.SEARCH);
Get.toNamed(AppRoutes.PLAYLIST_DETAIL, arguments: {'id': playlistId});
```

### 4. 依赖注入

```dart
// Binding 类
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}

// 或者在控制器中直接使用
class HomeController extends GetxController {
  static HomeController get to => Get.find();

  // 使用其他服务
  final KugouApiService _api = Get.find<KugouApiService>();
}
```

## 模块迁移检查清单

迁移现有代码到新结构时，确保：

- [ ] 创建三个文件夹: `xx_page/`, `xx_controller/`, `models/`
- [ ] 页面使用 `GetView<Controller>` 或 `GetWidget<Controller>`
- [ ] 状态使用 `.obs` 响应式变量
- [ ] UI 使用 `Obx()` 或 `GetBuilder()` 包裹
- [ ] 尺寸使用 `.w`, `.h`, `.sp`, `.r` 等扩展
- [ ] 创建对应的 Binding 类
- [ ] 在路由中注册页面和 Binding

## 注意事项

1. **全局服务**（如 API 服务）应该在 `main.dart` 中初始化并注入
2. **跨模块共用模型**放在 `lib/models/`，模块特有模型放在模块内 `models/`
3. **避免在控制器中直接操作 UI**，所有 UI 相关代码应该在页面中
4. **使用 GetX 的生命周期方法**: `onInit()`, `onReady()`, `onClose()`
