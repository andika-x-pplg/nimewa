import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/anime_detail.dart';
import '../../data/models/episode_item.dart';
import '../../data/services/anime_stream_resolver.dart';
import '../../data/services/my_list_repository.dart';
import '../../data/services/user_profile_repository.dart';

/// Screen for watching anime video streams with interactive video controls,
/// server selection, episode navigation, and quick playback actions.
class AnimeWatchScreen extends StatefulWidget {
  final AnimeDetail anime;
  final EpisodeItem initialEpisode;
  final MyListRepository? myListRepository;
  final UserProfileRepository? profileRepository;
  final Duration? initialPosition;

  const AnimeWatchScreen({
    super.key,
    required this.anime,
    required this.initialEpisode,
    this.myListRepository,
    this.profileRepository,
    this.initialPosition,
  });

  @override
  State<AnimeWatchScreen> createState() => _AnimeWatchScreenState();
}

class _AnimeWatchScreenState extends State<AnimeWatchScreen> {
  static const List<String> availableServers = [
    'Server 1 (Fast HD)',
    'Server 2 (Backup)',
    'Server 3 (Otaku)',
    'Server 4 (Consumet Cloud)',
  ];

  late EpisodeItem _currentEpisode;
  bool _isPlaying = true;
  Duration _currentPosition = Duration.zero;
  final Duration _totalDuration = const Duration(minutes: 24); // 1440 seconds default
  late String _selectedServer;
  bool _isControlsVisible = true;
  bool _isFullscreen = false;
  String? _serverErrorMessage;

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoBuffering = false;
  int _lastExpPositionSeconds = 0;

  MyListRepository get _myListRepo =>
      widget.myListRepository ?? MyListRepository.instance;
  UserProfileRepository get _profileRepo =>
      widget.profileRepository ?? UserProfileRepository.instance;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.initialEpisode;
    _currentPosition = widget.initialPosition ?? Duration.zero;
    _lastExpPositionSeconds = _currentPosition.inSeconds;
    _selectedServer = availableServers.first;
    _initializePlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recordWatchProgress(_currentEpisode);
      }
    });
  }

  void _recordWatchProgress(EpisodeItem episode) {
    if (!widget.anime.hasVideoAvailable) return;
    _myListRepo.recordWatchProgress(
      detail: widget.anime,
      episodeNumber: episode.episodeNumber,
      episodeTitle: episode.title,
    );
    _saveWatchHistory(episode: episode);
  }

  void _saveWatchHistory({EpisodeItem? episode}) {
    if (!widget.anime.hasVideoAvailable) return;
    final ep = episode ?? _currentEpisode;
    final dur = (_videoController != null && _videoController!.value.isInitialized)
        ? _videoController!.value.duration.inSeconds
        : _totalDuration.inSeconds;
    _profileRepo.recordWatchHistory(
      detail: widget.anime,
      episodeNumber: ep.episodeNumber,
      episodeTitle: ep.title,
      positionSeconds: _currentPosition.inSeconds,
      durationSeconds: dur,
    );
  }

  @override
  void dispose() {
    _saveWatchHistory();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  String _getStreamUrlForServer(String server, EpisodeItem episode) {
    return AnimeStreamResolver.resolveStreamUrl(
      animeId: widget.anime.id,
      animeTitle: widget.anime.title,
      server: server,
      episodeNumber: episode.episodeNumber,
      existingStreamUrl: episode.streamUrl,
    );
  }

  Future<void> _initializePlayer() async {
    if (!_isServerAvailable(_selectedServer)) return;

    if (_serverErrorMessage != null && mounted) {
      setState(() {
        _serverErrorMessage = null;
      });
    }

    final savedPosition = _currentPosition;
    String url = _getStreamUrlForServer(_selectedServer, _currentEpisode);
    if (_selectedServer.contains('Consumet') && url.isEmpty) {
      try {
        final asyncUrl = await AnimeStreamResolver.resolveStreamUrlAsync(
          animeId: widget.anime.id,
          animeTitle: widget.anime.title,
          server: _selectedServer,
          episodeNumber: _currentEpisode.episodeNumber,
          existingStreamUrl: _currentEpisode.streamUrl,
        ).timeout(const Duration(seconds: 2));
        if (asyncUrl.isNotEmpty) {
          url = asyncUrl;
        }
      } catch (_) {
        // Retain fallback url
      }
    }

    if (url.isEmpty) {
      url = _getStreamUrlForServer('Server 1 (Fast HD)', _currentEpisode);
    }

    _videoController?.removeListener(_videoListener);
    await _videoController?.dispose();

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _videoController = controller;

    try {
      await controller.initialize();
      if (savedPosition > Duration.zero && savedPosition < controller.value.duration) {
        await controller.seekTo(savedPosition);
      }
      controller.addListener(_videoListener);
      await controller.play();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isVideoBuffering = false;
          _isPlaying = true;
          _serverErrorMessage = null;
        });
      }
    } catch (_) {
      // Auto-failover across active servers if primary encountered an issue
      final candidateServers = availableServers
          .where((s) => s != _selectedServer && _isServerAvailable(s))
          .toList();

      for (final fallbackServer in candidateServers) {
        final fallbackUrl = _getStreamUrlForServer(fallbackServer, _currentEpisode);
        if (fallbackUrl.isNotEmpty && fallbackUrl != url) {
          try {
            final fallbackController = VideoPlayerController.networkUrl(
              Uri.parse(fallbackUrl),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            );
            _videoController = fallbackController;
            await fallbackController.initialize();
            if (savedPosition > Duration.zero && savedPosition < fallbackController.value.duration) {
              await fallbackController.seekTo(savedPosition);
            }
            fallbackController.addListener(_videoListener);
            await fallbackController.play();
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
                _isVideoBuffering = false;
                _isPlaying = true;
                _selectedServer = fallbackServer;
                _serverErrorMessage = null;
              });
              return;
            }
          } catch (_) {
            continue;
          }
        }
      }

      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
          _isVideoBuffering = false;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    final value = _videoController!.value;
    final posSeconds = value.position.inSeconds;
    if (value.isPlaying && posSeconds > _lastExpPositionSeconds) {
      final delta = posSeconds - _lastExpPositionSeconds;
      _lastExpPositionSeconds = posSeconds;
      // Anti-skip: only natural continuous playback (1..5s) awards EXP.
      if (delta >= 1 && delta <= 5 && widget.anime.hasVideoAvailable) {
        _profileRepo.addWatchExp(watchedSeconds: delta);
      }
    } else if (posSeconds < _lastExpPositionSeconds) {
      _lastExpPositionSeconds = posSeconds;
    }
    setState(() {
      if (value.position > Duration.zero) {
        _currentPosition = value.position;
      }
      _isPlaying = value.isPlaying;
      _isVideoBuffering = value.isBuffering;
    });
  }

  bool _isServerAvailable(String server) {
    return server != 'Server 2 (Backup)';
  }

  void _onServerSelected(String server) {
    setState(() {
      _selectedServer = server;
      if (!_isServerAvailable(server)) {
        _isPlaying = false;
        _serverErrorMessage =
            'Server 2 sedang gangguan / maintenance. Silakan beralih ke Server 1 atau Server 3 yang aktif.';
        _videoController?.pause();
      } else {
        _serverErrorMessage = null;
        _isPlaying = true;
        _initializePlayer();
      }
    });
  }

  int get _currentEpisodeIndex {
    final idx = widget.anime.episodes.indexWhere((ep) => ep.id == _currentEpisode.id);
    return idx != -1 ? idx : 0;
  }

  bool get _hasPreviousEpisode => _currentEpisodeIndex > 0;
  bool get _hasNextEpisode =>
      widget.anime.episodes.isNotEmpty && _currentEpisodeIndex < widget.anime.episodes.length - 1;

  void _selectEpisode(EpisodeItem episode) {
    _saveWatchHistory();
    setState(() {
      _currentEpisode = episode;
      _currentPosition = Duration.zero;
      _lastExpPositionSeconds = 0;
      _isPlaying = true;
    });
    _initializePlayer();
    _recordWatchProgress(episode);
  }

  void _goToPreviousEpisode() {
    if (_hasPreviousEpisode) {
      _selectEpisode(widget.anime.episodes[_currentEpisodeIndex - 1]);
    }
  }

  void _goToNextEpisode() {
    if (_hasNextEpisode) {
      _selectEpisode(widget.anime.episodes[_currentEpisodeIndex + 1]);
    }
  }

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    } else {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  Duration get _effectiveDuration {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        _videoController!.value.duration > Duration.zero) {
      return _videoController!.value.duration;
    }
    final isMovie = widget.anime.totalEpisodes == 1 &&
        (widget.anime.status == 'Tayang' ||
            widget.anime.title.toLowerCase().contains('movie') ||
            widget.initialEpisode.title.toLowerCase().contains('movie'));
    return isMovie ? const Duration(minutes: 105) : _totalDuration;
  }

  void _seekRelative(int seconds) {
    final current = _currentPosition;
    final duration = _effectiveDuration;
    final target = current + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > duration ? duration : target);
    setState(() {
      _currentPosition = clamped;
    });
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.seekTo(clamped);
    }
  }

  void _toggleControlsVisibility() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: !_isFullscreen,
        bottom: !_isFullscreen,
        child: _isFullscreen
            ? _buildVideoPlayerContainer(isExpanded: true)
            : Column(
                children: [
                  _buildVideoPlayerContainer(isExpanded: false),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEpisodeInfo(),
                          const SizedBox(height: 16),
                          _buildServerSelector(),
                          const SizedBox(height: 16),
                          _buildQuickActions(),
                          const SizedBox(height: 22),
                          _buildEpisodeListSection(),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVideoPlayerContainer({required bool isExpanded}) {
    final videoWidget = GestureDetector(
      key: const Key('video_player_gesture_detector'),
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControlsVisibility,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video layer (real video or fallback thumbnail while loading)
          if (_isVideoInitialized && _videoController != null)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio > 0
                    ? _videoController!.value.aspectRatio
                    : 16 / 9,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            _buildVideoBackdrop(),

          // Buffering indicator
          if (_isVideoBuffering)
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentBlue,
              ),
            ),

          // Center pause indicator visual
          if (_serverErrorMessage == null && !_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pause_rounded, color: AppColors.accentBlue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Dijeda',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Controls overlay
          if (_serverErrorMessage == null)
            AnimatedOpacity(
              opacity: _isControlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_isControlsVisible,
                child: _buildControlsOverlay(),
              ),
            ),

          // In-player error banner overlay (on top of everything)
          if (_serverErrorMessage != null)
            Center(
              child: Container(
                key: const Key('in_player_server_error_banner'),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF181206).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB800)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB800), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serverErrorMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      key: const Key('btn_switch_to_active_server'),
                      onPressed: () => _onServerSelected('Server 1 (Fast HD)'),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text('Ganti ke Server 1 (Aktif)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (isExpanded) {
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: videoWidget,
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: videoWidget,
      ),
    );
  }

  Widget _buildVideoBackdrop() {
    final backdropUrl = widget.anime.backdropUrl.isNotEmpty
        ? widget.anime.backdropUrl
        : widget.anime.posterUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (backdropUrl.isNotEmpty)
          Image.network(
            backdropUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildVideoFallbackCanvas(),
          )
        else
          _buildVideoFallbackCanvas(),

        // Subtle dark cinematic tint
        Container(
          color: Colors.black.withValues(alpha: _isPlaying ? 0.35 : 0.6),
        ),
      ],
    );
  }

  Widget _buildVideoFallbackCanvas() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0F12),
            Color(0xFF1B1B22),
            Color(0xFF08080A),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_rounded,
          color: AppColors.textMuted.withValues(alpha: 0.4),
          size: 54,
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.black.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopBar(),
          _buildCenterControls(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('video_back_button'),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.anime.title} · Ep ${_currentEpisode.episodeNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentEpisode.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '1080p',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Replay 10s
        IconButton(
          key: const Key('video_replay_10'),
          iconSize: 32,
          icon: const Icon(
            Icons.replay_10_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => _seekRelative(-10),
        ),
        const SizedBox(width: 24),

        // Play / Pause Toggle Button
        GestureDetector(
          key: const Key('video_play_pause_button'),
          onTap: _togglePlayPause,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accentBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentBlue.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 24),

        // Forward 10s
        IconButton(
          key: const Key('video_forward_10'),
          iconSize: 32,
          icon: const Icon(
            Icons.forward_10_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => _seekRelative(10),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final maxSeconds = _effectiveDuration.inSeconds.toDouble();
    final positionSeconds = _currentPosition.inSeconds.toDouble().clamp(0.0, maxSeconds);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${_formatDuration(_currentPosition)} / ${_formatDuration(_effectiveDuration)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              IconButton(
                key: const Key('video_fullscreen_button'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                onPressed: _toggleFullscreen,
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.accentBlue,
              inactiveTrackColor: Colors.white24,
              thumbColor: AppColors.accentBlue,
              overlayColor: AppColors.accentBlue.withValues(alpha: 0.25),
            ),
            child: Slider(
              key: const Key('video_progress_slider'),
              value: positionSeconds,
              min: 0.0,
              max: maxSeconds > 0 ? maxSeconds : 1.0,
              onChanged: (value) {
                final target = Duration(seconds: value.round());
                if (_videoController != null && _videoController!.value.isInitialized) {
                  _videoController!.seekTo(target);
                }
                setState(() {
                  _currentPosition = target;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.anime.title,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Episode ${_currentEpisode.episodeNumber}: ${_currentEpisode.title}',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.amberRating, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    widget.anime.rating.toStringAsFixed(1),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Rilis: ${_currentEpisode.releaseDate}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Server',
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: availableServers.map((server) {
              final isSelected = server == _selectedServer;
              final isAvailable = _isServerAvailable(server);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => _onServerSelected(server),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentBlue : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.accentBlue : AppColors.border,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAvailable ? const Color(0xFF00E676) : const Color(0xFFFFB800),
                          ),
                        ),
                        Icon(
                          Icons.dns_rounded,
                          size: 14,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          server,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
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

  Widget _buildQuickActions() {
    return Row(
      children: [
        // Episode Sebelumnya
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('btn_prev_episode'),
            onPressed: _hasPreviousEpisode ? _goToPreviousEpisode : null,
            icon: const Icon(Icons.skip_previous_rounded, size: 18),
            label: const Text('Sebelumnya', maxLines: 1, overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              disabledForegroundColor: AppColors.textMuted,
              side: BorderSide(
                color: _hasPreviousEpisode ? AppColors.border : AppColors.border.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Episode Selanjutnya
        Expanded(
          child: ElevatedButton.icon(
            key: const Key('btn_next_episode'),
            onPressed: _hasNextEpisode ? _goToNextEpisode : null,
            icon: const Icon(Icons.skip_next_rounded, size: 18),
            label: const Text('Selanjutnya', maxLines: 1, overflow: TextOverflow.ellipsis),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasNextEpisode ? AppColors.surfaceElevated : AppColors.surface,
              foregroundColor: _hasNextEpisode ? AppColors.accentBlue : AppColors.textMuted,
              disabledBackgroundColor: AppColors.surface,
              disabledForegroundColor: AppColors.textMuted,
              side: BorderSide(
                color: _hasNextEpisode ? AppColors.accentBlue.withValues(alpha: 0.4) : AppColors.border,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Download Action
        IconButton(
          key: const Key('btn_download_episode'),
          tooltip: 'Download',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceElevated,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.download_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mengunduh Episode ${_currentEpisode.episodeNumber}...'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.surfaceElevated,
              ),
            );
          },
        ),
        const SizedBox(width: 6),

        // Beri Nilai Action
        IconButton(
          key: const Key('btn_rate_episode'),
          tooltip: 'Beri Nilai',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceElevated,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.star_outline_rounded, color: AppColors.amberRating, size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Terima kasih atas penilaian Anda!'),
                duration: Duration(seconds: 2),
                backgroundColor: AppColors.surfaceElevated,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEpisodeListSection() {
    final episodes = widget.anime.episodes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Episode',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${episodes.length} Episode',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (episodes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'Tidak ada episode tersedia.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ep = episodes[index];
              final isCurrent = ep.id == _currentEpisode.id;

              return InkWell(
                key: Key('episode_item_${ep.episodeNumber}'),
                onTap: () => _selectEpisode(ep),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.surfaceElevated : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent ? AppColors.accentBlue : AppColors.border,
                      width: isCurrent ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Episode number container
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.accentBlue.withValues(alpha: 0.15)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent ? AppColors.accentBlue : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${ep.episodeNumber}',
                            style: AppTypography.labelMedium.copyWith(
                              color: isCurrent ? AppColors.accentBlue : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Episode details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ep.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall.copyWith(
                                color: isCurrent ? AppColors.accentBlue : AppColors.textPrimary,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rilis: ${ep.releaseDate}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Playing or Play indicator
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.accentBlue.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.volume_up_rounded,
                                color: AppColors.accentBlue,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Diputar',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Icon(
                          Icons.play_circle_outline_rounded,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
