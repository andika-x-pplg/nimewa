import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/anime_item.dart';
import '../../data/models/my_list_entry.dart';
import '../../data/services/anime_api_client.dart';
import '../../data/services/anime_stream_service.dart';
import '../../data/services/my_list_repository.dart';
import '../../data/services/schedule_service.dart';
import '../widgets/continue_watching_strip.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/empty_continue_watching.dart';
import '../widgets/home_header.dart';
import '../widgets/spotlight_carousel.dart';
import 'anime_detail_screen.dart';
import 'anime_watch_screen.dart';
import 'explore_screen.dart';
import 'my_list_screen.dart';
import 'schedule_screen.dart';

/// Main Shell Screen for Nimeva.
/// Supports switching between Home, Explore, and other tabs via CustomBottomNavBar,
/// and navigating to AnimeDetailScreen when any anime is selected.
class HomeScreen extends StatefulWidget {
  final AnimeStreamService? streamService;
  final ScheduleService? scheduleService;
  final MyListRepository? myListRepository;

  const HomeScreen({
    super.key,
    this.streamService,
    this.scheduleService,
    this.myListRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final AnimeStreamService _streamService;
  late final ScheduleService _scheduleService;
  late final MyListRepository _myListRepo;
  List<AnimeItem> _spotlightItems = AnimeApiClient.cachedTrendingAnime;
  bool _isLoadingSpotlight = false;
  String? _spotlightError;

  @override
  void initState() {
    super.initState();
    _streamService = widget.streamService ?? const AnimeStreamService();
    _scheduleService = widget.scheduleService ?? ScheduleService();
    _myListRepo = widget.myListRepository ?? MyListRepository.instance;
    _myListRepo.addListener(_onMyListChanged);
    if (!_myListRepo.isInitialized && !_myListRepo.isLoading) {
      _myListRepo.init();
    }
    _loadSpotlight();
  }

  @override
  void dispose() {
    _myListRepo.removeListener(_onMyListChanged);
    super.dispose();
  }

  void _onMyListChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSpotlight() async {
    setState(() {
      _isLoadingSpotlight = true;
      _spotlightError = null;
    });

    try {
      final items = await _streamService.getSpotlightAnime();
      if (mounted) {
        setState(() {
          _spotlightItems = items;
          _isLoadingSpotlight = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _spotlightError = 'Gagal memuat anime unggulan.';
          _isLoadingSpotlight = false;
        });
      }
    }
  }

  void _openAnimeDetail(AnimeItem anime) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimeDetailScreen(
          animeId: anime.id,
          previewItem: anime,
          service: _streamService,
          myListRepository: _myListRepo,
        ),
      ),
    );
  }

  Future<void> _openWatchFromEntry(MyListEntry entry) async {
    if (!entry.hasVideoAvailable) {
      _openAnimeDetail(entry.toAnimeItem());
      return;
    }
    try {
      final detail = await _streamService.getAnimeDetail(entry.animeId);
      if (!mounted) return;
      if (detail.episodes.isEmpty) {
        _openAnimeDetail(entry.toAnimeItem());
        return;
      }
      final targetEpNum = entry.watchedEpisode > 0 ? entry.watchedEpisode : 1;
      final targetEpisode = detail.episodes.firstWhere(
        (ep) => ep.episodeNumber == targetEpNum,
        orElse: () => detail.episodes.first,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AnimeWatchScreen(
            anime: detail,
            initialEpisode: targetEpisode,
            myListRepository: _myListRepo,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _openAnimeDetail(entry.toAnimeItem());
      }
    }
  }

  Future<void> _handleToggleSpotlightSave(AnimeItem item) async {
    final existing = _myListRepo.findEntry(
      item.id,
      aniListId: item.aniListId,
      title: item.title,
    );
    if (existing != null) {
      final removed = await _myListRepo.removeEntry(existing.canonicalKey);
      if (!mounted || removed == null) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.clearSnackBars();
      messenger?.showSnackBar(
        SnackBar(
          content: Text('${removed.title} dihapus dari My List'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Urungkan',
            textColor: AppColors.accentBlue,
            onPressed: () {
              _myListRepo.restoreEntry(removed);
            },
          ),
        ),
      );
    } else {
      await _myListRepo.toggleSaveAnime(item);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.clearSnackBars();
      messenger?.showSnackBar(
        SnackBar(
          content: Text('${item.title} ditambahkan ke My List'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSpotlightSection() {
    if (_spotlightError != null) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.textMuted, size: 32),
              const SizedBox(height: 8),
              Text(
                _spotlightError!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadSpotlight,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accentBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Coba Lagi', style: AppTypography.labelMedium.copyWith(color: AppColors.accentBlue)),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingSpotlight && _spotlightItems.isEmpty) {
      return Container(
        height: 420,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentBlue,
          ),
        ),
      );
    }

    return SpotlightCarousel(
      items: _spotlightItems,
      sectionBadge: 'HOT SPOTLIGHT',
      sectionTitle: 'ANIME POPULER',
      onWatchNow: _openAnimeDetail,
      onAddList: _handleToggleSpotlightSave,
      isSaved: (item) => _myListRepo.contains(
        item.id,
        aniListId: item.aniListId,
        title: item.title,
      ),
    );
  }

  Widget _buildHomeTab() {
    final watchingEntries = _myListRepo.entriesByStatus(MyListStatus.watching);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const Key('home_screen_scroll_view'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeader(username: 'dikzzz'),
            const SizedBox(height: 8),
            _buildSpotlightSection(),
            const SizedBox(height: 20),
            if (watchingEntries.isNotEmpty)
              ContinueWatchingStrip(
                entries: watchingEntries,
                onSeeAllTap: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                },
                onEntryTap: (entry) => _openAnimeDetail(entry.toAnimeItem()),
                onPlayTap: _openWatchFromEntry,
              )
            else
              EmptyContinueWatching(
                onExploreTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Segera hadir di pembaruan berikutnya.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return ExploreScreen(
          streamService: _streamService,
          onAnimeTap: _openAnimeDetail,
        );
      case 2:
        return ScheduleScreen(
          scheduleService: _scheduleService,
          onAnimeTap: _openAnimeDetail,
        );
      case 3:
        return MyListScreen(
          repository: _myListRepo,
          streamService: _streamService,
          onExploreTap: () {
            setState(() {
              _currentIndex = 1;
            });
          },
        );
      case 4:
        return _buildPlaceholderTab('Profil Pengguna', Icons.person_rounded);
      case 0:
      default:
        return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
