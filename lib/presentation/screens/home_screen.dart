import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/anime_item.dart';
import '../../data/services/anime_api_client.dart';
import '../../data/services/anime_stream_service.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/empty_continue_watching.dart';
import '../widgets/home_header.dart';
import '../widgets/spotlight_carousel.dart';
import 'anime_detail_screen.dart';
import 'explore_screen.dart';

/// Main Shell Screen for Nimeva.
/// Supports switching between Home, Explore, and other tabs via CustomBottomNavBar,
/// and navigating to AnimeDetailScreen when any anime is selected.
class HomeScreen extends StatefulWidget {
  final AnimeStreamService? streamService;

  const HomeScreen({
    super.key,
    this.streamService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final AnimeStreamService _streamService;
  List<AnimeItem> _spotlightItems = AnimeApiClient.cachedTrendingAnime;
  bool _isLoadingSpotlight = false;
  String? _spotlightError;

  @override
  void initState() {
    super.initState();
    _streamService = widget.streamService ?? const AnimeStreamService();
    _loadSpotlight();
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
        ),
      ),
    );
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
      sectionBadge: 'HOT SPOTLIGHT 2026',
      sectionTitle: 'ANIME POPULER 2026',
      onWatchNow: _openAnimeDetail,
    );
  }

  Widget _buildHomeTab() {
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
        return _buildPlaceholderTab('Jadwal Tayang Anime', Icons.calendar_month_rounded);
      case 3:
        return _buildPlaceholderTab('Daftar Tonton Saya', Icons.bookmark_rounded);
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
