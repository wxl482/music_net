import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/theme.dart';
import '../modules/home/home_page/home_screen.dart';
import '../modules/home/home_controller/home_controller.dart';
import 'discover/discover_screen.dart';
import 'search/search_screen.dart';
import 'library/library_screen.dart';
import '../widgets/mini_player.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DiscoverScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 初始化首页控制器
    Get.put(HomeController());
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
      icon: Icon(Icons.search_outlined),
      activeIcon: Icon(Icons.search),
      label: '搜索',
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
    final playerProvider = Provider.of<PlayerProvider>(context);
    final hasMiniPlayer = playerProvider.currentSong != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildCurrentPage(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomBar(hasMiniPlayer),
            ),
          ],
        ),
      ),
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
      case 3:
        return _pages[2];
      default:
        return const HomeScreen();
    }
  }

  Widget _buildBottomBar(bool hasMiniPlayer) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasMiniPlayer) const MiniPlayer(),
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
