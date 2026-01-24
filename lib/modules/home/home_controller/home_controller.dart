import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/api/kugou_api_service.dart';
import '../../../../models/playlist.dart';
import '../../../../models/song.dart';
import '../../../../models/banner.dart';
import '../../../../services/api/kugou_api_service.dart' show RankItem;

/// 首页控制器
class HomeController extends GetxController {
  // API 服务
  final KugouApiService _api = KugouApiService();

  // 响应式状态
  final RxList<Playlist> playlists = <Playlist>[].obs;
  final RxList<Song> newSongs = <Song>[].obs;
  final RxList<RankItem> rankList = <RankItem>[].obs;
  final RxList<BannerItem> banners = <BannerItem>[].obs;

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// 加载首页数据
  Future<void> loadData() async {
    isLoading.value = true;
    error.value = '';

    try {
      // 并行加载数据
      final results = await Future.wait([
        _api.getBanners(),
        _api.getRecommendPlaylists(pagesize: 10),
        _api.getNewSongs(pagesize: 10),
        _api.getRankList(),
      ]);

      banners.value = results[0] as List<BannerItem>;
      playlists.value = results[1] as List<Playlist>;
      newSongs.value = results[2] as List<Song>;
      rankList.value = results[3] as List<RankItem>;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        '加载失败',
        '请检查网络连接后重试',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await loadData();
  }

  /// 获取排行榜颜色
  Color getRankColor(int index) {
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
}
