import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/download_item.dart';

/// Persistent repository managing episode downloads with pause, HTTP Range
/// resume, and long-press deletion.
class DownloadRepository extends ChangeNotifier {
  static final DownloadRepository instance = DownloadRepository._internal();

  DownloadRepository._internal()
      : _storageFile = null,
        _disablePersistence = false;

  DownloadRepository({
    File? storageFile,
    bool disablePersistence = false,
  })  : _storageFile = storageFile,
        _disablePersistence = disablePersistence;

  final File? _storageFile;
  final bool _disablePersistence;

  final Map<String, DownloadItem> _items = {};
  final Map<String, HttpClient> _activeClients = {};
  final Set<String> _pausedIds = {};
  bool _initialized = false;
  Future<void> _persistChain = Future<void>.value();

  bool get isInitialized => _initialized;

  List<DownloadItem> get items {
    final list = _items.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  File _resolveStorageFile() {
    final custom = _storageFile;
    if (custom != null) return custom;
    if (Platform.isAndroid) {
      final androidDir = Directory('/data/user/0/com.example.nimeva/files');
      if (androidDir.existsSync()) {
        return File('${androidDir.path}/nimeva_downloads.json');
      }
    }
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty && home != '/') {
      return File('$home/.nimeva/nimeva_downloads.json');
    }
    return File('${Directory.systemTemp.path}/nimeva_downloads.json');
  }

  Directory _resolveDownloadDir() {
    if (Platform.isAndroid) {
      final dlDir = Directory('/storage/emulated/0/Download/Nimeva');
      try {
        if (!dlDir.existsSync()) dlDir.createSync(recursive: true);
        return dlDir;
      } catch (_) {}
    }
    return Directory.systemTemp;
  }

  Future<void> init({bool forceReload = false}) async {
    if (_initialized && !forceReload) return;
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
          if (decoded is List) {
            _items.clear();
            for (final rawItem in decoded) {
              if (rawItem is Map<String, dynamic>) {
                final item = DownloadItem.fromJson(rawItem);
                if (item.id.isNotEmpty) {
                  _items[item.id] = item;
                }
              }
            }
          }
        }
      }
    } catch (_) {
      // Keep in-memory state on read error.
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
        final payload = jsonEncode(items.map((e) => e.toJson()).toList());
        await file.writeAsString(payload);
      } catch (_) {}
    });
    return _persistChain;
  }

  Future<void> startDownload({
    required String animeId,
    required String title,
    String posterUrl = '',
    required int episodeNumber,
    String episodeTitle = '',
    required String streamUrl,
  }) async {
    final id = '${animeId}_ep_$episodeNumber';
    final safeTitle = title
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final fileName = '${safeTitle}_Ep_$episodeNumber.mp4';
    final outFile = File('${_resolveDownloadDir().path}/$fileName');

    _pausedIds.remove(id);
    _items[id] = DownloadItem(
      id: id,
      animeId: animeId,
      title: title,
      posterUrl: posterUrl,
      episodeNumber: episodeNumber,
      episodeTitle: episodeTitle,
      streamUrl: streamUrl,
      filePath: outFile.path,
      receivedBytes: 0,
      totalBytes: 0,
      status: DownloadStatus.downloading,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
    unawaited(_runDownload(id));
  }

  Future<void> pauseDownload(String id) async {
    final existing = _items[id];
    if (existing == null || existing.status != DownloadStatus.downloading) {
      return;
    }
    _pausedIds.add(id);
    _activeClients[id]?.close(force: true);
    _activeClients.remove(id);
    _items[id] = existing.copyWith(
      status: DownloadStatus.paused,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> resumeDownload(String id) async {
    final existing = _items[id];
    if (existing == null || existing.status == DownloadStatus.completed) {
      return;
    }
    _pausedIds.remove(id);
    _items[id] = existing.copyWith(
      status: DownloadStatus.downloading,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
    unawaited(_runDownload(id));
  }

  Future<void> removeDownload(String id) async {
    _pausedIds.add(id);
    _activeClients[id]?.close(force: true);
    _activeClients.remove(id);
    final removed = _items.remove(id);
    if (removed != null) {
      try {
        final f = File(removed.filePath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
      notifyListeners();
      await _persist();
    }
  }

  /// Inserts a pre-built item (useful for tests).
  Future<void> restoreItem(DownloadItem item) async {
    _items[item.id] = item;
    notifyListeners();
    await _persist();
  }

  Future<void> _runDownload(String id) async {
    final item = _items[id];
    if (item == null) return;
    final uri = Uri.tryParse(item.streamUrl);
    if (uri == null || !uri.hasScheme) {
      _items[id] = item.copyWith(
        status: DownloadStatus.failed,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      await _persist();
      return;
    }

    final client = HttpClient();
    _activeClients[id] = client;
    try {
      final outFile = File(item.filePath);
      final existingBytes = outFile.existsSync() ? outFile.lengthSync() : 0;

      final request = await client.getUrl(uri);
      if (existingBytes > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
      }
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final isPartial = response.statusCode == 206;
      final baseOffset = isPartial ? existingBytes : 0;
      final total = response.contentLength > 0
          ? baseOffset + response.contentLength
          : item.totalBytes;

      final sink = outFile.openWrite(
        mode: isPartial ? FileMode.append : FileMode.write,
      );
      int received = baseOffset;
      int lastNotifiedBytes = received;

      await for (final chunk in response) {
        if (_pausedIds.contains(id) || !_items.containsKey(id)) {
          await sink.flush();
          await sink.close();
          return;
        }
        sink.add(chunk);
        received += chunk.length;
        if (received - lastNotifiedBytes >= 64 * 1024) {
          lastNotifiedBytes = received;
          final current = _items[id];
          if (current != null) {
            _items[id] = current.copyWith(
              receivedBytes: received,
              totalBytes: total > 0 ? total : current.totalBytes,
              updatedAt: DateTime.now(),
            );
            notifyListeners();
          }
        }
      }
      await sink.flush();
      await sink.close();

      if (_pausedIds.contains(id) || !_items.containsKey(id)) return;
      final current = _items[id];
      if (current != null) {
        _items[id] = current.copyWith(
          receivedBytes: received,
          totalBytes: total > 0 ? total : received,
          status: DownloadStatus.completed,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
        await _persist();
      }
    } catch (_) {
      if (_pausedIds.contains(id) || !_items.containsKey(id)) return;
      final current = _items[id];
      if (current != null) {
        _items[id] = current.copyWith(
          status: DownloadStatus.failed,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
        await _persist();
      }
    } finally {
      _activeClients.remove(id);
      client.close(force: true);
    }
  }
}

