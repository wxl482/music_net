import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/rank.dart';
import '../../modules/player/player_controller/player_controller.dart';
import '../../theme/theme.dart';
import '../../services/api/kugou_api_service.dart';
import '../../utils/image_utils.dart';

/// 排行榜详情页面
class RankDetailScreen extends StatefulWidget {
  final String rankId;
  final String? rankName;

  const RankDetailScreen({
    super.key,
    required this.rankId,
    this.rankName,
  });

  @override
  State<RankDetailScreen> createState() => _RankDetailScreenState();
}

class _RankDetailScreenState extends State<RankDetailScreen> {
  final KugouApiService _api = KugouApiService();
  final PlayerController _playerController = Get.find<PlayerController>();

  // 排行榜信息
  Rank? _rank;

  // 歌曲列表
  List<RankSong> _songs = [];
  bool _isLoadingSongs = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 50;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreSongs();
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadRankInfo(),
      _loadSongs(),
    ]);
  }

  Future<void> _loadRankInfo() async {
    final rank = await _api.getRankInfo(widget.rankId);
    if (mounted) {
      setState(() {
        _rank = rank;
      });
    }
  }

  Future<void> _loadSongs() async {
    if (!_hasMore) return;

    setState(() => _isLoadingSongs = true);
    final response = await _api.getRankSongs(
      widget.rankId,
      rankCid: _rank?.rankCid,
      page: _currentPage,
      pageSize: _pageSize,
    );

    if (mounted && response != null) {
      setState(() {
        if (_currentPage == 1) {
          _songs = response.songs;
        } else {
          _songs.addAll(response.songs);
        }
        _hasMore = _songs.length < response.total;
        _isLoadingSongs = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingSongs = false);
    }
  }

  Future<void> _loadMoreSongs() async {
    if (_isLoadingSongs || !_hasMore) return;
    _currentPage++;
    await _loadSongs();
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadData();
  }

  void _playSong(RankSong song, int index) {
    final songs = _songs.map((s) => s.toSong()).toList();
    _playerController.playSong(song.toSong(), newPlaylist: songs);
    Get.toNamed('/player');
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _rank?.imgUrl ?? _rank?.bannerUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: Stack(
          children: [
            // 背景封面（毛玻璃模糊效果）
            if (coverUrl != null)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: ImageUtils.replaceImageSize(coverUrl, 600),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            // 模糊层
            if (coverUrl != null)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.background.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 内容区域
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 顶部空白（给返回按钮留空间）
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + 60.h,
                  ),
                ),

                // 标题和信息
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 排行榜名称
                        Text(
                          _rank?.rankName ?? widget.rankName ?? '排行榜',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 32.sp,
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // 更新信息
                        if (_rank?.intro != null)
                          Text(
                            _rank!.intro!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),

                        SizedBox(height: 16.h),

                        // 统计信息
                        Wrap(
                          spacing: 8.w,
                          children: [
                            if (_rank?.allTotal != null)
                              _buildStatChip('共${_rank!.allTotal}首'),
                            if (_rank?.newTotal != null && _rank!.newTotal! > 0)
                              _buildStatChip('${_rank!.newTotal}首新歌'),
                          ],
                        ),

                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),

                // 播放全部按钮
                if (_songs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildPlayAllButton(),
                  ),

                // 歌曲列表
                _buildSongList(),

                // 加载更多指示器
                if (_isLoadingSongs && _songs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildLoadingIndicator(),
                  ),

                // 底部空白
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),

            // 返回按钮（固定在顶部）
            Positioned(
              top: MediaQuery.of(context).padding.top + 8.h,
              left: 8.w,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption1.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPlayAllButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          // 播放全部按钮
          GestureDetector(
            onTap: () => _playAll(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                  SizedBox(width: 4.w),
                  Text(
                    '播放全部',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 选择按钮
          IconButton(
            icon: const Icon(Icons.check_circle_outline,
                color: AppColors.onSurfaceSecondary),
            onPressed: () {
              // TODO: 实现选择功能
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    if (_isLoadingSongs && _songs.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 400.h,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 400.h,
          child: Center(
            child: Text(
              '暂无歌曲',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = _songs[index];
          return _buildSongItem(song, index);
        },
        childCount: _songs.length,
      ),
    );
  }

  Widget _buildSongItem(RankSong song, int index) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      leading: _buildRankNumber(index + 1),
      title: Text(
        song.songName,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.authorName,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.onSurfaceSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _buildMoreButton(song),
      onTap: () => _playSong(song, index),
    );
  }

  Widget _buildRankNumber(int number) {
    Color color;
    if (number == 1) {
      color = const Color(0xFFFFD700); // 金色
    } else if (number == 2) {
      color = const Color(0xFFC0C0C0); // 银色
    } else if (number == 3) {
      color = const Color(0xFFCD7F32); // 铜色
    } else {
      color = AppColors.onSurfaceSecondary;
    }

    return SizedBox(
      width: 40.w,
      child: Text(
        number.toString(),
        style: AppTextStyles.titleLarge.copyWith(
          color: color,
          fontWeight: number <= 3 ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMoreButton(RankSong song) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert,
          color: AppColors.onSurfaceSecondary, size: 20),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      onSelected: (value) {
        switch (value) {
          case 'next':
            // 添加到下一首播放
            break;
          case 'playlist':
            // 添加到歌单
            break;
          case 'artist':
            // 查看歌手
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'next',
          child: Text('下一首播放'),
        ),
        const PopupMenuItem(
          value: 'playlist',
          child: Text('添加到歌单'),
        ),
        const PopupMenuItem(
          value: 'artist',
          child: Text('查看歌手'),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(20.w),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2,
      ),
    );
  }

  void _playAll() {
    if (_songs.isEmpty) return;
    final songs = _songs.map((s) => s.toSong()).toList();
    _playerController.playSong(_songs.first.toSong(), newPlaylist: songs);
    Get.toNamed('/player');
  }
}
