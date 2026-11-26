import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/mock_explore_data.dart';
import '../../data/models/anime_item.dart';
import '../../data/services/anilist_api_client.dart';
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
  late final ScrollController _scrollController;
  String _selectedFilter = 'popular'; // 'popular', 'latest', 'top_rated'
  String _selectedGenre = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  List<AnimeItem> _animeList = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  Timer? _debounceTimer;
  int _searchRequestId = 0;
  final List<AnimeItem> _cachedSearchResults = [];

  static const List<Map<String, String>> _filterTabs = [
    {'key': 'popular', 'label': 'Popular'},
    {'key': 'latest', 'label': 'Latest'},
    {'key': 'top_rated', 'label': 'Top rated'},
  ];

  static const List<String> _genres = [
    'Semua',
    'Action',
    'Romance',
    'Fantasy',
    'Comedy',
    'Isekai',
    'Sci-Fi',
    'Adventure',
    'Drama',
    'Horror',
    'Mecha',
    'Music',
    'Mystery',
    'Psychological',
    'Seinen',
    'Shounen',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
    'Movie',
    'Demons',
    'Harem',
    'Game',
    'Historical',
    'Josei',
    'Magic',
    'Martial Arts',
    'Military',
    'Parody',
    'Police',
    'Samurai',
    'School',
    'Shoujo',
    'Shoujo Ai',
    'Super Power',
    'Vampire',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _streamService = widget.streamService ?? const AnimeStreamService();
    _animeList = List.of(allCatalogAnime)..shuffle(Random());
    _fetchCatalog(isInitial: true);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AnimeItem> get _allKnownAnime {
    final pool = <String, AnimeItem>{};
    for (final a in allCatalogAnime) {
      pool[a.title.toLowerCase()] = a;
    }
    for (final a in AniListApiClient.cachedTrendingAnime) {
      pool[a.title.toLowerCase()] = a;
    }
    for (final a in _cachedSearchResults) {
      pool[a.title.toLowerCase()] = a;
    }
    return pool.values.toList();
  }

  void _onSearchChanged(String val) {
    final query = val.trim();
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      _fetchCatalog();
      return;
    }

    // 1. Instant local match across all in-memory anime (letters, words, initials)
    final localMatches = _allKnownAnime
        .where((item) => item.matchesSearch(query))
        .toList();

    setState(() {
      _animeList = localMatches;
      _isLoading = false;
      _errorMessage = null;
      _hasMore = true;
    });

    // 2. Debounce remote search (300ms) to query AniList's full global library
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performRemoteSearch(query);
    });
  }

  Future<void> _performRemoteSearch(String query) async {
    final currentRequestId = ++_searchRequestId;

    try {
      final remoteList = await _streamService.getExploreAnimeList(
        filter: _selectedFilter,
        genre: _selectedGenre,
        query: query,
        limit: 20,
        offset: 0,
      );

      if (!mounted ||
          _searchRequestId != currentRequestId ||
          _searchController.text.trim().toLowerCase() != query.toLowerCase()) {
        return;
      }

      // Cache discovered items
      _cachedSearchResults.addAll(remoteList);

      // Merge: preserve local matches at the top, append new remote items without duplicates
      final existingTitles = _animeList.map((a) => a.title.toLowerCase()).toSet();
      final existingIds = _animeList.map((a) => a.id).toSet();
      final newItems = remoteList
          .where((a) =>
              !existingTitles.contains(a.title.toLowerCase()) &&
              !existingIds.contains(a.id))
          .toList();

      setState(() {
        if (_animeList.isEmpty) {
          _animeList = remoteList;
        } else {
          _animeList.addAll(newItems);
        }
        _isLoading = false;
        _hasMore = remoteList.length >= 20;
      });
    } catch (_) {
      // If network fails (e.g. rate limit, offline), silently keep local matches
      if (mounted && _searchRequestId == currentRequestId) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCatalog({bool isInitial = false}) async {
    if (!isInitial) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _hasMore = true;
      });
    }

    try {
      final list = await _streamService.getExploreAnimeList(
        filter: _selectedFilter,
        genre: _selectedGenre,
        query: _searchController.text,
        limit: 20,
        offset: 0,
      );
      if (mounted) {
        final displayList = List<AnimeItem>.of(list);
        if (_searchController.text.trim().isEmpty) {
          displayList.shuffle(Random());
        }
        setState(() {
          _animeList = displayList;
          _isLoading = false;
          _hasMore = list.length >= 20;
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

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextBatch = await _streamService.getExploreAnimeList(
        filter: _selectedFilter,
        genre: _selectedGenre,
        query: _searchController.text,
        limit: 20,
        offset: _animeList.length,
      );

      if (mounted) {
        if (nextBatch.isEmpty) {
          setState(() {
            _hasMore = false;
            _isLoadingMore = false;
          });
        } else {
          final existingIds = _animeList.map((a) => a.id).toSet();
          final uniqueNew = nextBatch.where((a) => !existingIds.contains(a.id)).toList();
          setState(() {
            _animeList.addAll(uniqueNew);
            _isLoadingMore = false;
            _hasMore = nextBatch.length >= 20;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
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
          controller: _scrollController,
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
              _buildSectionHeader(),
              const SizedBox(height: 14),
              _buildContent(),
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ),
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
                    onChanged: _onSearchChanged,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    cursorColor: AppColors.accentBlue,
                    decoration: InputDecoration(
                      hintText: 'Cari nama anime',
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
                      _onSearchChanged('');
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

  Widget _buildSectionHeader() {
    return Text(
      _sectionTitle,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
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

