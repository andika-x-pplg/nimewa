import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _controllers = {};
  Duration _position = Duration.zero;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int textureId) async {
    _controllers[textureId]?.close();
    _controllers.remove(textureId);
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _controllers.length + 1;
    _controllers[id] = StreamController<VideoEvent>.broadcast();
    scheduleMicrotask(() {
      _controllers[id]?.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(minutes: 24),
          size: const Size(1920, 1080),
        ),
      );
    });
    return id;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> play(int textureId) async {
    _controllers[textureId]?.add(VideoEvent(eventType: VideoEventType.isPlayingStateUpdate, isPlaying: true));
  }

  @override
  Future<void> pause(int textureId) async {
    _controllers[textureId]?.add(VideoEvent(eventType: VideoEventType.isPlayingStateUpdate, isPlaying: false));
  }

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<void> seekTo(int textureId, Duration position) async {
    _position = position;
  }

  @override
  Future<Duration> getPosition(int textureId) async => _position;

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return _controllers[textureId]?.stream ??
        Stream<VideoEvent>.value(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(minutes: 24),
            size: const Size(1920, 1080),
          ),
        );
  }

  @override
  Widget buildView(int textureId) {
    return const SizedBox(
      key: Key('fake_video_surface'),
    );
  }
}
