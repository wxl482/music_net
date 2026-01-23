import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/theme.dart';
import 'widgets/section_header.dart';
import 'widgets/playlist_card.dart';
import 'widgets/song_item.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../services/api/kugou_api_service.dart';
import '../../services/api/kugou_api_service.dart' show RankItem;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final _api = KugouApiService();

  List<Playlist> _playlists = [];
  List<Song> _newSongs = [];
  List<RankItem> _rankList = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // 并行加载数据
      final results = await Future.wait([
        _api.getRecommendPlaylists(pagesize: 10),
        _api.getNewSongs(pagesize: 10),
        _api.getRankList(),
      ]);

      if (mounted) {
        setState(() {
          _playlists = results[0] as List<Playlist>;
          _newSongs = results[1] as List<Song>;
          _rankList = (results[2] as List<dynamic>).cast<RankItem>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '欢迎回来',
          style: AppTextStyles.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.onSurface),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBanner(),
                        const SizedBox(height: 24),
                        _buildQuickAccess(),
                        const SizedBox(height: 24),
                        _buildHotPlaylists(),
                        const SizedBox(height: 24),
                        _buildNewReleases(),
                        const SizedBox(height: 24),
                        _buildTopCharts(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16.h),
          Text('加载失败: $_error'),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    if (_playlists.isEmpty) {
      return _buildDefaultBanner();
    }

    return SizedBox(
      height: 160.h,
      child: PageView.builder(
        itemCount: _playlists.length > 5 ? 5 : _playlists.length,
        itemBuilder: (context, index) {
          return _buildBannerItem(_playlists[index]);
        },
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return SizedBox(
      height: 160.h,
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.primaryLight.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20.w,
                  bottom: -20.w,
                  child: Icon(
                    Icons.music_note,
                    size: 120.sp,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '推荐歌单',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '热门精选 ${index + 1}',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerItem(Playlist playlist) {
    return GestureDetector(
      onTap: () {
        // TODO: 跳转到歌单详情
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          image: playlist.coverUrl != null
              ? DecorationImage(
                  image: NetworkImage(playlist.coverUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.4),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                playlist.name,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (playlist.description != null && playlist.description!.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  playlist.description!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccess() {
    final quickActions = [
      {'icon': Icons.favorite, 'label': '我喜欢的', 'color': Colors.pink},
      {'icon': Icons.history, 'label': '最近播放', 'color': Colors.blue},
      {'icon': Icons.download, 'label': '下载管理', 'color': Colors.green},
      {'icon': Icons.radio, 'label': '电台', 'color': Colors.orange},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: quickActions.map((action) {
        return Column(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: (action['color'] as Color).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                action['icon'] as IconData,
                color: action['color'] as Color,
                size: 28.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              action['label'] as String,
              style: AppTextStyles.labelMedium,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHotPlaylists() {
    final playlists = _playlists.isEmpty ? _getSamplePlaylists() : _playlists;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '热门歌单', onSeeAll: null),
        SizedBox(
          height: 200.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              return PlaylistCard(
                playlist: playlists[index],
                onTap: () {
                  // TODO: 跳转到歌单详情
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewReleases() {
    final songs = _newSongs.isEmpty ? _getSampleSongs() : _newSongs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '新歌速递', onSeeAll: null),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return SongItem(
              song: songs[index],
              index: index + 1,
              onTap: () {
                // TODO: 播放歌曲
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopCharts() {
    final charts = _rankList.isEmpty
        ? [
            {'title': '热歌榜', 'color': Colors.red, 'id': '8888'},
            {'title': '新歌榜', 'color': Colors.blue, 'id': '31312'},
            {'title': '原创榜', 'color': Colors.green, 'id': '2'},
          ]
        : List.generate(
            _rankList.length > 3 ? 3 : _rankList.length,
            (index) {
              final rank = _rankList[index];
              return {
                'title': rank.name,
                'color': _getRankColor(index),
                'id': rank.id,
              };
            },
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '排行榜', onSeeAll: null),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: charts.map((chart) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    // TODO: 跳转到排行榜详情
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (chart['color'] as Color).withValues(alpha: 0.6),
                          (chart['color'] as Color).withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: chart['color'] as Color,
                          size: 32.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          chart['title'] as String,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  List<Playlist> _getSamplePlaylists() {
    return [
      Playlist.online(
        id: '1',
        name: '华语热门',
        description: '最受欢迎的华语歌曲',
        coverUrl: 'https://picsum.photos/200',
        playCount: 10000000,
        trackCount: 50,
      ),
      Playlist.online(
        id: '2',
        name: '欧美经典',
        description: '回味无穷的经典欧美',
        coverUrl: 'https://picsum.photos/201',
        playCount: 8000000,
        trackCount: 100,
      ),
      Playlist.online(
        id: '3',
        name: '日语精选',
        description: '好听的日语歌曲',
        coverUrl: 'https://picsum.photos/202',
        playCount: 5000000,
        trackCount: 30,
      ),
      Playlist.online(
        id: '4',
        name: '韩流热歌',
        description: 'K-POP热门歌曲',
        coverUrl: 'https://picsum.photos/203',
        playCount: 12000000,
        trackCount: 80,
      ),
    ];
  }

  List<Song> _getSampleSongs() {
    return [
      Song.fromOnline(
        id: '1',
        title: '歌曲名称',
        artist: '歌手名',
        album: '专辑名',
        coverUrl: 'https://picsum.photos/100',
        audioUrl: 'https://example.com/song1.mp3',
        duration: const Duration(minutes: 3, seconds: 45),
      ),
      Song.fromOnline(
        id: '2',
        title: '第二首歌',
        artist: '另一位歌手',
        album: '另一张专辑',
        coverUrl: 'https://picsum.photos/101',
        audioUrl: 'https://example.com/song2.mp3',
        duration: const Duration(minutes: 4, seconds: 12),
      ),
      Song.fromOnline(
        id: '3',
        title: '第三首歌',
        artist: '歌手C',
        album: '专辑C',
        coverUrl: 'https://picsum.photos/102',
        audioUrl: 'https://example.com/song3.mp3',
        duration: const Duration(minutes: 3, seconds: 28),
      ),
    ];
  }
}
