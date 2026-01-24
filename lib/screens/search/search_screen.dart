import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/online_music_controller.dart';
import '../../modules/player/player_controller/player_controller.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../../theme/theme.dart';
import '../../utils/image_utils.dart';
import '../../utils/gradient_utils.dart';
import '../../app.dart';

/// 搜索页面
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  late final OnlineMusicController _onlineController;
  late final PlayerController _playerController;
  int _lastSearchTabIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _onlineController = Get.find<OnlineMusicController>();
    _playerController = Get.find<PlayerController>();

    // Tab 切换时触发搜索
    _tabController.addListener(() {
      // 只有当 index 真正变化且与上次搜索的 index 不同时才触发搜索
      if (_tabController.index != _lastSearchTabIndex) {
        _lastSearchTabIndex = _tabController.index;
        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    switch (_tabController.index) {
      case 0: // 综合 - 搜索歌曲
        _onlineController.searchMusic(query);
        break;
      case 1: // 歌曲
        _onlineController.searchMusic(query);
        break;
      case 2: // 歌手
        _onlineController.searchArtists(query);
        break;
      case 3: // 专辑
        _onlineController.searchAlbums(query);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            _buildSearchBar(),
            // Tab 栏
            _buildTabBar(),
            // 内容区域
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildComprehensiveTab(),
                  _buildSongsTab(),
                  _buildArtistsTab(),
                  _buildAlbumsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.onSurface, size: 20.sp),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 40.w),
            onPressed: () => Navigator.pop(context),
          ),
          // 搜索框
          Expanded(
            child: Container(
              height: 44.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: AppColors.onSurfaceSecondary.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.onSurfaceSecondary, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.bodyMedium,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => _performSearch(value),
                      decoration: InputDecoration(
                        hintText: '搜索歌曲、歌手、专辑',
                        hintStyle: TextStyle(
                          color: AppColors.onSurfaceSecondary,
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          Icons.cancel,
                          color: AppColors.onSurfaceSecondary,
                          size: 18.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // 语音搜索按钮 - 使用渐变工具类
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.mic, color: Colors.white, size: 20.sp),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 栏
  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.onSurfaceSecondary.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
          insets: EdgeInsets.zero,
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceSecondary,
        labelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelLarge,
        tabs: const [
                Tab(text: '综合'),
                Tab(text: '歌曲'),
                Tab(text: '歌手'),
                Tab(text: '专辑'),
              ],
      ),
    );
  }

  Widget _buildComprehensiveTab() {
    return Obx(() {
      if (_onlineController.isSearching.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      final results = _onlineController.searchResults;
      if (_searchController.text.isEmpty) {
        return _buildInitialView();
      }

      if (results.isEmpty) {
        return _buildEmptyView();
      }

      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: results.length,
        itemBuilder: (context, index) => _buildSongItem(results[index], index),
      );
    });
  }

  Widget _buildSongsTab() {
    return Obx(() {
      if (_onlineController.isSearching.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      final results = _onlineController.searchResults;
      if (_searchController.text.isEmpty) {
        return _buildInitialView();
      }

      if (results.isEmpty) {
        return _buildEmptyView();
      }

      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: results.length,
        itemBuilder: (context, index) => _buildSongItem(results[index], index),
      );
    });
  }

  Widget _buildArtistsTab() {
    return Obx(() {
      if (_onlineController.isSearching.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      final results = _onlineController.searchArtistResults;
      if (_searchController.text.isEmpty) {
        return _buildInitialView();
      }

      if (results.isEmpty) {
        return _buildEmptyView();
      }

      return GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) => _buildArtistItem(results[index]),
      );
    });
  }

  Widget _buildAlbumsTab() {
    return Obx(() {
      if (_onlineController.isSearching.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      final results = _onlineController.searchAlbumResults;
      if (_searchController.text.isEmpty) {
        return _buildInitialView();
      }

      if (results.isEmpty) {
        return _buildEmptyView();
      }

      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: results.length,
        itemBuilder: (context, index) => _buildAlbumItem(results[index]),
      );
    });
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40.h),
          // 搜索图标和渐变背景
          Center(
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.search,
                size: 50.sp,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          // 标题
          Center(
            child: Text(
              '搜索音乐',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // 副标题
          Center(
            child: Text(
              '发现你喜欢的音乐、歌手和专辑',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
            ),
          ),
          SizedBox(height: 48.h),
          // 热门搜索标签
          Text(
            '热门搜索',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _buildHotSearchTag('周杰伦'),
              _buildHotSearchTag('邓紫棋'),
              _buildHotSearchTag('林俊杰'),
              _buildHotSearchTag('陈奕迅'),
              _buildHotSearchTag('薛之谦'),
              _buildHotSearchTag('海阔天空'),
              _buildHotSearchTag('流行歌曲'),
              _buildHotSearchTag('经典老歌'),
            ],
          ),
        ],
      ),
    );
  }

  /// 热门搜索标签 - 使用紫粉渐变
  Widget _buildHotSearchTag(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        setState(() {});
        _performSearch(text);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.purplePinkGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 空状态插图
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.onSurfaceSecondary.withValues(alpha: 0.2),
                    AppColors.onSurfaceSecondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.search_off,
                size: 50.sp,
                color: AppColors.onSurfaceSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              '未找到相关内容',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '试试调整关键词或搜索其他内容',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            // 搜索建议
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '搜索建议',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.onSurfaceSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '• 检查输入是否正确\n• 尝试使用更通用的关键词\n• 搜索歌手名或歌曲名',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(Song song, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _playerController.playSong(song);
            Get.toNamed(AppRoutes.player);
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                // 排名
                SizedBox(
                  width: 32.w,
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: index < 3
                          ? AppColors.primary
                          : AppColors.onSurfaceSecondary,
                      fontWeight: index < 3 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 8.w),
                // 封面
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: song.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: ImageUtils.replaceImageSize(song.coverUrl!, 48.w),
                            width: 48.w,
                            height: 48.w,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              width: 48.w,
                              height: 48.w,
                              color: AppColors.surfaceVariant,
                              child: Icon(Icons.music_note, color: AppColors.onSurfaceSecondary, size: 20.sp),
                            ),
                          )
                        : Container(
                            width: 48.w,
                            height: 48.w,
                            color: AppColors.surfaceVariant,
                            child: Icon(Icons.music_note, color: AppColors.onSurfaceSecondary, size: 20.sp),
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                // 歌曲信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${song.artist} · ${song.album}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // 播放按钮
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.play_arrow,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      await _playerController.playSong(song);
                      Get.toNamed(AppRoutes.player);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistItem(Artist artist) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 跳转到歌手详情页
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                // 歌手头像
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.3),
                            AppColors.primary.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: ClipOval(
                          child: artist.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: ImageUtils.replaceImageSize(artist.coverUrl!, 100),
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(
                                    color: AppColors.surfaceVariant,
                                    child: Icon(Icons.person, color: AppColors.onSurfaceSecondary, size: 30.sp),
                                  ),
                                )
                              : Container(
                                  color: AppColors.surfaceVariant,
                                  child: Icon(Icons.person, color: AppColors.onSurfaceSecondary, size: 30.sp),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                // 歌手名称
                Text(
                  artist.name,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumItem(Album album) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 跳转到专辑详情页
            if (album.id.isNotEmpty) {
              Get.toNamed(AppRoutes.albumDetail, arguments: album.id);
            } else {
              // 如果没有 ID，显示提示
              Get.snackbar(
                '提示',
                '该专辑暂无详情',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange.withValues(alpha: 0.8),
                colorText: Colors.white,
              );
            }
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Row(
              children: [
                // 专辑封面
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: album.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: ImageUtils.replaceImageSize(album.coverUrl!, 60.w),
                            width: 60.w,
                            height: 60.w,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              width: 60.w,
                              height: 60.w,
                              color: AppColors.surfaceVariant,
                              child: Icon(Icons.album, color: AppColors.onSurfaceSecondary, size: 24.sp),
                            ),
                          )
                        : Container(
                            width: 60.w,
                            height: 60.w,
                            color: AppColors.surfaceVariant,
                            child: Icon(Icons.album, color: AppColors.onSurfaceSecondary, size: 24.sp),
                          ),
                  ),
                ),
                SizedBox(width: 14.w),
                // 专辑信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'LP',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              '${album.artist}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onSurfaceSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${album.songCount} 首歌曲',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // 箭头
                Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceSecondary,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
