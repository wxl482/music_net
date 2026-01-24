import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../theme/theme.dart';
import '../modules/home/home_page/home_screen.dart';
import '../modules/home/home_controller/home_controller.dart';
import '../modules/player/player_controller/player_controller.dart';
import 'discover/discover_screen.dart';
import 'library/library_screen.dart';
import '../widgets/mini_player.dart';
import '../app.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _disposed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const DiscoverScreen(),
    const LibraryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 初始化首页控制器
    Get.put(HomeController());

    // 监听 Scaffold 的 Drawer 状态变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDrawerState();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // 定期检查 Drawer 状态
  void _checkDrawerState() {
    if (_disposed) return;
    final scaffoldState = _scaffoldKey.currentState;
    if (scaffoldState != null) {
      final isDrawerOpen = scaffoldState.isDrawerOpen;
      if (drawerState.isOpen.value != isDrawerOpen) {
        drawerState.isOpen.value = isDrawerOpen;
      }
    }
    // 继续检查
    Future.delayed(const Duration(milliseconds: 100), () {
      _checkDrawerState();
    });
  }

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: '首页',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.explore_outlined),
      activeIcon: Icon(Icons.explore),
      label: '发现',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.library_music_outlined),
      activeIcon: Icon(Icons.library_music),
      label: '我的',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context),
      drawerEnableOpenDragGesture: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildCurrentPage(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 280.w,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // 头部
            _buildDrawerHeader(),
            // 菜单列表
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                children: [
                  _buildMenuItem(
                    icon: Icons.home_outlined,
                    title: '首页',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 0);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.explore_outlined,
                    title: '发现',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 1);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.library_music_outlined,
                    title: '我的',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 2);
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Divider(
                      color: AppColors.onSurfaceSecondary.withValues(alpha: 0.2),
                      thickness: 0.5,
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.favorite_outline,
                    title: '我喜欢的',
                    onTap: () {
                      Navigator.pop(context);
                      Get.snackbar('提示', '即将上线');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: '最近播放',
                    onTap: () {
                      Navigator.pop(context);
                      Get.snackbar('提示', '即将上线');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.music_note,
              size: 32.sp,
              color: const Color(0xFF6366F1),
            ),
          ),
          SizedBox(width: 16.w),
          // 应用名称
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Music App',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '享受音乐的美好',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.onSurface,
        size: 24.sp,
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14.sp),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return _pages[0];
      case 2:
        return _pages[1];
      default:
        return const HomeScreen();
    }
  }

  Widget _buildBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 使用 Obx 监听 drawerState 和 PlayerController
        Obx(() {
          final playerController = Get.find<PlayerController>();
          final hasSong = playerController.currentSong.value != null;
          if (hasSong && !drawerState.isOpen.value) {
            return const MiniPlayer();
          }
          return const SizedBox.shrink();
        }),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.onSurfaceSecondary,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: _navItems,
              selectedFontSize: 10.sp,
              unselectedFontSize: 10.sp,
              iconSize: 24.sp,
            ),
          ),
        ),
      ],
    );
  }
}
