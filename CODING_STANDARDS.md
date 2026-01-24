# 音乐 APP 编码规范

## 核心规范

### 🚫 禁止：直接使用 Map 来解析 API 返回的数据

```dart
// ❌ 错误示例
final data = response.data['data'];
final name = data['name'];
final songs = data['songs'];
```

### ✅ 正确：使用实体类（Model）来解构数据

```dart
// ✅ 正确示例
final response = PlaylistDetailResponse.fromJson(response.data);
final name = response.info.name;
final songs = response.songs;
```

### 🖼️ 图片显示规范

使用 `CachedNetworkImage` 显示网络图片，必须包含 `placeholder` 和 `errorWidget`：

```dart
// ✅ 标准图片显示方式
CachedNetworkImage(
  imageUrl: imageUrl,
  fit: BoxFit.cover,
  placeholder: (context, url) => Container(
    color: AppColors.surfaceVariant,
    child: const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2,
      ),
    ),
  ),
  errorWidget: (context, url, error) => Container(
    color: AppColors.surfaceVariant,
    child: const Icon(Icons.music_note, color: Colors.white, size: 40),
  ),
)
```

**完整示例（带 ClipRRect 和默认占位）**：

```dart
// ✅ 封面图片完整示例
ClipRRect(
  borderRadius: BorderRadius.circular(12.r),
  child: coverUrl != null
      ? CachedNetworkImage(
          imageUrl: coverUrl,
          width: 120.w,
          height: 120.w,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 120.w,
            height: 120.w,
            color: AppColors.surfaceVariant,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 120.w,
            height: 120.w,
            color: AppColors.surfaceVariant,
            child: const Icon(Icons.music_note, color: Colors.white, size: 40),
          ),
        )
      : Container(
          width: 120.w,
          height: 120.w,
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.music_note, color: Colors.white, size: 40),
        ),
)
```

**注意事项**：
1. 必须使用 `CachedNetworkImage` 而不是 `Image.network`（支持缓存）
2. 必须提供 `placeholder`（加载中显示）
3. 必须提供 `errorWidget`（加载失败显示）
4. 图片 URL 可能为 null，需要处理空值情况
5. 本地图片使用 `Image.file(File(url))`

---

## 原因说明

1. **类型安全**：实体类提供编译时类型检查，减少运行时错误
2. **代码可维护性**：字段修改时 IDE 可以自动重构
3. **代码可读性**：通过类型就知道有哪些字段，不需要猜测
4. **易于测试**：可以轻松创建测试数据

---

## 项目结构规范

### Model 类位置

```
lib/models/
├── song.dart              # 歌曲实体
├── playlist.dart          # 歌单实体
├── playlist_detail.dart   # 歌单详情实体（待创建）
├── playlist_songs.dart    # 歌单歌曲响应实体（待创建）
├── artist.dart            # 歌手实体
└── ...
```

### API Response 类命名规范

```dart
// 原始响应数据封装
class XxxResponse {
  final int? status;
  final String? error;
  final XxxData? data;
  // ...
}

// 数据实体
class XxxData {
  final String id;
  final String name;
  // ...
}
```

---

## 当前需要重构的地方

### 1. ~~歌单详情页面~~ ✅ 已完成

**文件**: `lib/screens/playlist/playlist_detail_screen.dart`

**状态**: 已完成重构

**已创建的实体类**:
- ✅ `lib/models/playlist_detail.dart` - 歌单详情实体（包含 PlaylistDetailData、PlaylistSongsData、PlaylistSongItem、SingerInfo）

**已更新的 API 方法**:
- ✅ `KugouApiService.getPlaylistDetailWithSongs()` - 返回 PlaylistDetailData 实体
- ✅ `KugouApiService.getPlaylistDetailRaw()` - 标记为 @deprecated
- ✅ `KugouApiService.getPlaylistSongs()` - 标记为 @deprecated

**重构效果**:
- 不再使用 `Map<String, dynamic>? _playlistData`
- 改用 `PlaylistDetailData? _playlistDetail`
- 代码更简洁，类型更安全

### 2. ~~API 服务层（歌单相关）~~ ✅ 已完成

**文件**: `lib/services/api/kugou_api_service.dart`

**状态**: 已完成重构

**已添加**:
- ✅ `getPlaylistDetailWithSongs()` - 返回 `PlaylistDetailData?` 实体

**已标记为废弃**:
- ✅ `getPlaylistDetailRaw()` - @deprecated
- ✅ `getPlaylistSongs()` - @deprecated

### 3. 其他需要检查的地方

- [ ] `lib/screens/discover/discover_screen.dart` - 排行榜数据
- [ ] `lib/providers/online_music_provider.dart` - 各种数据解析
- [ ] 所有使用 `Map<String, dynamic>` 的地方

---

## 创建新实体类的步骤

### 1. 先查看 API 返回的实际数据格式

```dart
// 在 API 调用处打印数据
print('API 响应: $response');
```

### 2. 根据数据结构创建实体类

```dart
class XxxEntity {
  final String field1;
  final int? field2;
  final List<ChildEntity> children;

  XxxEntity({
    required this.field1,
    this.field2,
    required this.children,
  });

  factory XxxEntity.fromJson(Map<String, dynamic> json) {
    return XxxEntity(
      field1: json['field1'] ?? '默认值',
      field2: json['field2'],
      children: (json['children'] as List?)
          ?.map((e) => ChildEntity.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field1': field1,
      'field2': field2,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }

  XxxEntity copyWith({
    String? field1,
    int? field2,
    List<ChildEntity>? children,
  }) {
    return XxxEntity(
      field1: field1 ?? this.field1,
      field2: field2 ?? this.field2,
      children: children ?? this.children,
    );
  }
}
```

### 3. 更新 API 服务返回类型

```dart
// 修改 API 方法
Future<XxxEntity?> getXxxData() async {
  final response = await _dio.get('/xxx');
  if (response.statusCode == 200) {
    return XxxEntity.fromJson(response.data['data']);
  }
  return null;
}
```

### 4. 更新使用方代码

```dart
// 修改前
final data = await api.getXxxData();
final name = data?['name'];

// 修改后
final entity = await api.getXxxData();
final name = entity?.name;
```

---

## 待办事项清单

### 高优先级（当前正在使用的功能）

- [ ] 创建 `PlaylistDetailData` 实体类
- [ ] 创建 `PlaylistSongsData` 实体类
- [ ] 重构 `getPlaylistDetailRaw` 方法
- [ ] 重构 `getPlaylistSongs` 方法
- [ ] 更新 `PlaylistDetailScreen` 使用实体类

### 中优先级（常用功能）

- [ ] 创建 `RankDetailResponse` 实体类
- [ ] 创建 `SearchResultResponse` 实体类
- [ ] 重构排行榜相关代码
- [ ] 重构搜索相关代码

### 低优先级（不常用功能）

- [ ] 审查所有 Provider 中的 Map 使用
- [ ] 统一所有 API 响应格式

---

## 快速检查清单

每次新增 API 调用时，检查：

- [ ] 是否创建了对应的实体类？
- [ ] 实体类是否包含 `fromJson` 方法？
- [ ] 实体类是否包含 `toJson` 方法？
- [ ] 实体类是否包含 `copyWith` 方法？
- [ ] 是否处理了所有可能的 null 值？
- [ ] 是否处理了字段类型不确定的情况（如 String vs List）？
- [ ] 是否添加了默认值？

---

## 记录：Claude 注意事项

> 每次修改或新增功能时，首先检查是否有对应的实体类。
> 如果没有，先创建实体类，再实现功能。
> 严禁在业务代码中直接使用 `Map<String, dynamic>` 来解析 API 数据。
>
> **特别警惕**: `lib/screens/playlist/playlist_detail_screen.dart` 中有大量 Map 解析代码，这是紧急需要重构的！
