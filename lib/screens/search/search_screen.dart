import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchHistory = ['周杰伦', '林俊杰', '陈奕迅', '张学友'];
  final List<String> _hotKeywords = [
    '热门搜索1',
    '热门搜索2',
    '热门搜索3',
    '热门搜索4',
    '热门搜索5',
    '热门搜索6',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          height: 44.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.bodyLarge,
            decoration: const InputDecoration(
              hintText: '搜索歌曲、歌手、专辑',
              hintStyle: TextStyle(color: AppColors.onSurfaceSecondary),
              border: InputBorder.none,
              icon: Icon(Icons.search, color: AppColors.onSurfaceSecondary),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none, color: AppColors.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceSecondary,
              labelStyle: AppTextStyles.labelLarge,
              tabs: const [
                Tab(text: '综合'),
                Tab(text: '歌曲'),
                Tab(text: '歌手'),
                Tab(text: '专辑'),
              ],
            ),
          ),
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
    );
  }

  Widget _buildComprehensiveTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_searchHistory.isNotEmpty)
            _buildSectionHeader('搜索历史', onClear: () {
              setState(() {
                _searchHistory.clear();
              });
            }),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: _searchHistory.map((keyword) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history,
                          size: 16, color: AppColors.onSurfaceSecondary),
                      SizedBox(width: 6.w),
                      Text(keyword, style: AppTextStyles.labelMedium),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 24.h),
          _buildSectionHeader('热搜榜'),
          Column(
            children: _hotKeywords.asMap().entries.map((entry) {
              final index = entry.key;
              final keyword = entry.value;
              return _buildHotItem(index + 1, keyword);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onClear}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          const Spacer(),
          if (onClear != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.onSurfaceSecondary),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }

  Widget _buildHotItem(int rank, String keyword) {
    final isTop3 = rank <= 3;
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              rank.toString(),
              style: AppTextStyles.titleLarge.copyWith(
                color: isTop3 ? AppColors.primary : AppColors.onSurfaceSecondary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    keyword,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (isTop3)
              const Icon(Icons.trending_up, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 4.h),
          leading: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
          title: Text('搜索结果歌曲 ${index + 1}', style: AppTextStyles.titleMedium),
          subtitle: Text('歌手 - 专辑', style: AppTextStyles.bodySmall),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceSecondary),
            onPressed: () {},
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40.r,
                backgroundColor: AppColors.surfaceVariant,
                child: const Icon(Icons.person, color: Colors.white, size: 40),
              ),
              SizedBox(height: 8.h),
              Text('歌手 $index', style: AppTextStyles.titleMedium),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12.r),
                    ),
                  ),
                  child: const Center(child: Icon(Icons.album, color: Colors.white)),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.w),
                child: Text('专辑 $index', style: AppTextStyles.labelLarge),
              ),
            ],
          ),
        );
      },
    );
  }
}
