import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Favorite songs
  Future<void> addFavorite(Song song) async {
    final favorites = getFavoriteSongs();
    if (!favorites.any((s) => s.id == song.id)) {
      favorites.add(song);
      await _prefs?.setStringList(
        'favorites',
        favorites.map((s) => jsonEncode(s.toJson())).toList(),
      );
    }
  }

  Future<void> removeFavorite(String songId) async {
    final favorites = getFavoriteSongs();
    favorites.removeWhere((s) => s.id == songId);
    await _prefs?.setStringList(
      'favorites',
      favorites.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  List<Song> getFavoriteSongs() {
    final strings = _prefs?.getStringList('favorites') ?? [];
    return strings.map((s) => Song.fromJson(_parseJson(s))).toList();
  }

  bool isFavorite(String songId) {
    return getFavoriteSongs().any((s) => s.id == songId);
  }

  // Recent plays
  Future<void> addRecentPlay(Song song) async {
    final recent = getRecentPlays();
    recent.removeWhere((s) => s.id == song.id);
    recent.insert(0, song);
    if (recent.length > 50) recent.removeLast();

    await _prefs?.setStringList(
      'recent_plays',
      recent.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  List<Song> getRecentPlays() {
    final strings = _prefs?.getStringList('recent_plays') ?? [];
    return strings.map((s) => Song.fromJson(_parseJson(s))).toList();
  }

  // Local playlists
  Future<void> saveLocalPlaylist(Playlist playlist) async {
    final playlists = getLocalPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index >= 0) {
      playlists[index] = playlist;
    } else {
      playlists.add(playlist);
    }
    await _prefs?.setStringList(
      'local_playlists',
      playlists.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  List<Playlist> getLocalPlaylists() {
    final strings = _prefs?.getStringList('local_playlists') ?? [];
    return strings.map((p) => Playlist.fromJson(_parseJson(p))).toList();
  }

  Future<void> deleteLocalPlaylist(String playlistId) async {
    final playlists = getLocalPlaylists();
    playlists.removeWhere((p) => p.id == playlistId);
    await _prefs?.setStringList(
      'local_playlists',
      playlists.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  // Play history
  Future<void> addToHistory(Playlist playlist) async {
    final history = getPlayHistory();
    history.removeWhere((p) => p.id == playlist.id);
    history.insert(0, playlist.copyWith(songs: []));
    if (history.length > 20) history.removeLast();

    await _prefs?.setStringList(
      'play_history',
      history.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  List<Playlist> getPlayHistory() {
    final strings = _prefs?.getStringList('play_history') ?? [];
    return strings.map((p) => Playlist.fromJson(_parseJson(p))).toList();
  }

  // Settings
  bool getAutoPlay() => _prefs?.getBool('auto_play') ?? true;
  Future<void> setAutoPlay(bool value) async {
    await _prefs?.setBool('auto_play', value);
  }

  bool getShowLyrics() => _prefs?.getBool('show_lyrics') ?? true;
  Future<void> setShowLyrics(bool value) async {
    await _prefs?.setBool('show_lyrics', value);
  }

  String? getLastPlayerId() => _prefs?.getString('last_player_id');
  Future<void> setLastPlayerId(String id) async {
    await _prefs?.setString('last_player_id', id);
  }

  // Helper
  Map<String, dynamic> _parseJson(String jsonStr) {
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
