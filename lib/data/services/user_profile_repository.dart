import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/anime_detail.dart';
import '../models/watch_history_entry.dart';
import 'my_list_repository.dart';

/// Persistent repository managing the user's profile (username, joinedAt, EXP)
/// and episode-level watch history with exact playback positions.
class UserProfileRepository extends ChangeNotifier {
  static final UserProfileRepository instance =
      UserProfileRepository._internal();

  UserProfileRepository._internal()
      : _storageFile = null,
        _disablePersistence = false,
        _clock = DateTime.now;

  UserProfileRepository({
    File? storageFile,
    bool disablePersistence = false,
    DateTime Function()? clock,
  })  : _storageFile = storageFile,
        _disablePersistence = disablePersistence,
        _clock = clock ?? DateTime.now;

  final File? _storageFile;
  final bool _disablePersistence;
  final DateTime Function() _clock;

  String _username = 'dikzzz';
  DateTime? _joinedAt;
  final int _exp = 0;
  final Map<String, WatchHistoryEntry> _history = {};
  bool _initialized = false;
  Future<void> _persistChain = Future<void>.value();

  bool get isInitialized => _initialized;
  String get username => _username;
  String get initial =>
      _username.trim().isNotEmpty ? _username.trim()[0].toUpperCase() : 'N';
  DateTime get joinedAt => _joinedAt ?? _clock();
  int get exp => _exp;

  /// Total months the user has been on Nimeva (minimum 1).
  int get monthsActive {
    final start = joinedAt;
    final now = _clock();
    final diffMonths =
        (now.year - start.year) * 12 + (now.month - start.month);
    return diffMonths < 1 ? 1 : diffMonths;
  }

  /// Watch history sorted by most recently watched first.
  List<WatchHistoryEntry> get watchHistory {
    final list = _history.values.toList();
    list.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return List.unmodifiable(list);
  }

  File _resolveStorageFile() {
    final custom = _storageFile;
    if (custom != null) return custom;
    if (Platform.isAndroid) {
      final androidDir = Directory('/data/user/0/com.example.nimeva/files');
      if (androidDir.existsSync()) {
        return File('${androidDir.path}/nimeva_profile.json');
      }
    }
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty && home != '/') {
      return File('$home/.nimeva/nimeva_profile.json');
    }
    return File('${Directory.systemTemp.path}/nimeva_profile.json');
  }

  Future<void> init({bool forceReload = false}) async {
    if (_initialized && !forceReload) return;
    _joinedAt ??= _clock();
    if (_disablePersistence) {
      _initialized = true;
      return;
    }

    try {
      final file = _resolveStorageFile();
      if (file.existsSync()) {
        final raw = file.readAsStringSync();
        if (raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            final name = decoded['username']?.toString().trim();
            if (name != null && name.isNotEmpty) {
              _username = name;
            }
            final parsedJoin = DateTime.tryParse(
              (decoded['joinedAt'] ?? '').toString(),
            );
            if (parsedJoin != null) {
              _joinedAt = parsedJoin;
            }
            final histList = decoded['history'];
            if (histList is List) {
              _history.clear();
              for (final item in histList) {
                if (item is Map<String, dynamic>) {
                  final entry = WatchHistoryEntry.fromJson(item);
                  if (entry.canonicalKey.isNotEmpty) {
                    _history[entry.canonicalKey] = entry;
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {
      // Keep in-memory defaults on storage read errors.
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> _persist() {
    if (_disablePersistence) return Future<void>.value();
    _persistChain = _persistChain.then((_) async {
      try {
        final file = _resolveStorageFile();
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        final payload = jsonEncode({
          'username': _username,
          'joinedAt': joinedAt.toIso8601String(),
          'exp': _exp,
          'history': watchHistory.map((e) => e.toJson()).toList(),
        });
        await file.writeAsString(payload);
      } catch (_) {
        // Non-fatal in sandboxed environments.
      }
    });
    return _persistChain;
  }

  Future<void> updateUsername(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    _username = trimmed;
    notifyListeners();
    await _persist();
  }

  Future<void> recordWatchHistory({
    required AnimeDetail detail,
    required int episodeNumber,
    required String episodeTitle,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final key = MyListRepository.canonicalKeyFor(
      detail.id,
      aniListId: detail.aniListId,
      title: detail.title,
    );
    _history[key] = WatchHistoryEntry(
      canonicalKey: key,
      animeId: detail.id,
      aniListId: detail.aniListId,
      title: detail.title,
      posterUrl: detail.posterUrl,
      episodeNumber: episodeNumber,
      episodeTitle: episodeTitle,
      positionSeconds: positionSeconds < 0 ? 0 : positionSeconds,
      durationSeconds: durationSeconds < 0 ? 0 : durationSeconds,
      watchedAt: _clock(),
    );
    notifyListeners();
    await _persist();
  }

  Duration? getSavedPosition(
    String animeId,
    int episodeNumber, {
    int aniListId = 0,
    String title = '',
  }) {
    final key = MyListRepository.canonicalKeyFor(
      animeId,
      aniListId: aniListId,
      title: title,
    );
    final entry = _history[key];
    if (entry == null || entry.episodeNumber != episodeNumber) return null;
    if (entry.positionSeconds <= 0) return null;
    return Duration(seconds: entry.positionSeconds);
  }

  Future<void> removeHistoryEntry(String canonicalKey) async {
    if (_history.remove(canonicalKey) != null) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> clearHistory() async {
    if (_history.isEmpty) return;
    _history.clear();
    notifyListeners();
    await _persist();
  }
}

