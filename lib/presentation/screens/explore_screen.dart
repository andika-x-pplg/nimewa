import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/mock_explore_data.dart';
import '../../data/models/anime_item.dart';
import '../../data/services/anime_stream_service.dart';
import '../widgets/anime_grid_card.dart';

/// Screen for exploring anime with filters and 2-column grid.
class ExploreScreen extends StatefulWidget {
  final AnimeStreamService? streamService;
  final void Function(AnimeItem anime)? onAnimeTap;

  const ExploreScreen({
    super.key,
    this.streamService,
    this.onAnimeTap,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final AnimeStreamService _streamService;
  String _selectedFilter = 'popular'; // 'popular', 'latest', 'top_rated'
  String _selectedGenre = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  List<AnimeItem> _animeList = [];
  bool _isLoading = false;
  String? _errorMessage;

  static const List<Map<String, String>> _filterTabs = [
    {'key': 'popular', 'label': 'Popular'},
    {'key': 'latest', 'label': 'Latest'},
    {'key': 'top_rated', 'label': 'Top rated'},
  ];

  static const List<String> _genres = [
    'Semua',
    'Action',
    'Fantasy',
    'Romance',
    'Sci-Fi',
    'Isekai',
  ];

  @override
  void initState() {
    super.initState();
    _streamService = widget.streamService ?? const AnimeStreamService();
    _animeList = getExploreAnime(filter: _selectedFilter, genre: _selectedGenre);
    _fetchCatalog(isInitial: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCatalog({bool isInitial = false}) async {
    if (!isInitial) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final list = await _streamService.getExploreAnimeList(
        filter: _selectedFilter,
        genre: _selectedGenre,
        query: _searchController.text,
      );
      if (mounted) {
        setState(() {
          _animeList = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat katalog anime.';
          _isLoading = false;
        });
      }
    }
  }

  String get _sectionTitle {
    if (_selectedGenre != 'Semua') {
      return 'Genre: $_selectedGenre';
    }
    switch (_selectedFilter) {
      case 'latest':
        return 'Anime Terbaru';
      case 'top_rated':
        return 'Rating Tertinggi';
      case 'popular':
      default:
        return 'Popular Saat Ini';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildFilterTabs(),
              const SizedBox(height: 20),
              _buildGenreChips(),
              const SizedBox(height: 20),
              _buildSectionHeader(_animeList.length),
              const SizedBox(height: 14),
              _buildContent(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temukan anime favoritmu',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Jelajah',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _fetchCatalog(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    cursorColor: AppColors.accentBlue,
                    decoration: InputDecoration(
                      hintText: 'Cari anime, genre, atau studio...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _fetchCatalog();
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Filter button
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.tune_rounded,
              color: AppColors.accentBlue,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filterTabs.map((tab) {
          final isSelected = _selectedFilter == tab['key'] && _selectedGenre == 'Semua';
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: tab['label'],
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilter = tab['key']!;
                    _selectedGenre = 'Semua';
                  });
                  _fetchCatalog();
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentBlue : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.accentBlue : AppColors.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    tab['label']!,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenreChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JELAJAH GENRE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _genres.map((genre) {
              final isSelected = _selectedGenre == genre;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: genre,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedGenre = genre;
                      });
                      _fetchCatalog();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentBlue.withValues(alpha: 0.15)
                            : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.accentBlue : AppColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        genre,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
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

  Widget _buildSectionHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _sectionTitle,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$count anime',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.textMuted,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _fetchCatalog(),
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

    if (_isLoading) {
      return _buildSkeletonGrid();
    }

    if (_animeList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: AppColors.textMuted,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada anime yang cocok.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _animeList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final item = _animeList[index];
        return AnimeGridCard(
          item: item,
          onTap: () => widget.onAnimeTap?.call(item),
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

