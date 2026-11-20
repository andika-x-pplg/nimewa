import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/anime_item.dart';
import 'anime_image_placeholder.dart';

/// Cinematic Spotlight Carousel widget for popular anime highlights.
/// Features high-contrast dark vignette gradient, metadata chips,
/// Crimson "Tonton Sekarang" CTA button, "+" watchlist button, and pagination dots.
class SpotlightCarousel extends StatefulWidget {
  const SpotlightCarousel({
    super.key,
    required this.items,
    this.onWatchNow,
    this.onAddList,
    this.sectionBadge = 'HOT SPOTLIGHT',
    this.sectionTitle = 'ANIME POPULER',
  });

  final List<AnimeItem> items;
  final void Function(AnimeItem item)? onWatchNow;
  final void Function(AnimeItem item)? onAddList;
  final String sectionBadge;
  final String sectionTitle;

  @override
  State<SpotlightCarousel> createState() => _SpotlightCarouselState();
}

class _SpotlightCarouselState extends State<SpotlightCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant SpotlightCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty) {
      _currentPage = 0;
    } else if (_currentPage >= widget.items.length) {
      _currentPage = widget.items.length - 1;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 12),
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildCarouselCard(item);
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildPageIndicators(),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.accentBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.sectionBadge,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.sectionTitle,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(AnimeItem item) {
    final imageUrl = item.backdropUrl.isNotEmpty ? item.backdropUrl : item.posterUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Graceful Network Fallback
            _buildBackdropImage(imageUrl, item),

            // Vignette Gradient Overlay (ensuring high WCAG AA text contrast)
            _buildGradientOverlay(),

            // Card Bottom Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Metadata Row: Rating, Year, Genres
                  _buildMetadataRow(item),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    item.title,
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons
                  _buildActionButtons(item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdropImage(String imageUrl, AnimeItem item) {
    if (imageUrl.isEmpty) {
      return AnimeImagePlaceholder(
        title: item.title,
        showTitle: false,
        iconSize: 48,
        fontSize: 14,
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return AnimeImagePlaceholder(
          title: item.title,
          showTitle: false,
          iconSize: 48,
          fontSize: 14,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.surfaceCard,
          child: const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accentBlue,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.bgPrimary.withValues(alpha: 0.1),
              AppColors.bgPrimary.withValues(alpha: 0.75),
              AppColors.bgPrimary.withValues(alpha: 0.96),
            ],
            stops: const [0.0, 0.35, 0.70, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(AnimeItem item) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        // Star & Rating
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              color: AppColors.accentAmber,
              size: 18,
            ),
            const SizedBox(width: 3),
            Text(
              item.rating.toStringAsFixed(1),
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Text(
          '•',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Release Year
        Text(
          '${item.releaseYear}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Text(
          '•',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Genre Chips (take up to 3 to keep layout tidy)
        ...item.genres.take(3).map((genre) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 0.8,
              ),
            ),
            child: Text(
              genre,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons(AnimeItem item) {
    return Row(
      children: [
        // Primary CTA Button: "Tonton Sekarang"
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => widget.onWatchNow?.call(item),
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
            label: const Text(
              'Tonton Sekarang',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Secondary Button: "+" Add to Watchlist
        Semantics(
          button: true,
          label: 'Tambah ke Daftar Tonton',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onAddList?.call(item),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.items.length, (index) {
            final isActive = index == _currentPage;
            return GestureDetector(
              key: Key('carousel_dot_$index'),
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Semantics(
                button: true,
                label: 'Halaman ${index + 1}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  height: 6.0,
                  width: isActive ? 20.0 : 6.0,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accentBlue
                        : AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
