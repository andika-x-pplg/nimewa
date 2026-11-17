import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/anime_detail.dart';
import '../../data/models/anime_item.dart';
import '../../data/models/episode_item.dart';
import '../../data/services/anime_stream_service.dart';

/// Screen displaying anime information, synopsis, and episode streaming list.
class AnimeDetailScreen extends StatefulWidget {
  final String animeId;
  final AnimeItem? previewItem;
  final void Function(EpisodeItem episode)? onEpisodeTap;

  const AnimeDetailScreen({
    super.key,
    required this.animeId,
    this.previewItem,
    this.onEpisodeTap,
  });

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  final AnimeStreamService _service = AnimeStreamService();
  late Future<AnimeDetail> _detailFuture;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _service.getAnimeDetail(widget.animeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: FutureBuilder<AnimeDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && widget.previewItem == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue),
            );
          }

          if (snapshot.hasError && widget.previewItem == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat detail anime.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final detail = snapshot.data;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(detail),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetadataSection(detail),
                      const SizedBox(height: 16),
                      _buildActionButtons(detail),
                      const SizedBox(height: 20),
                      _buildSynopsisSection(detail),
                      const SizedBox(height: 24),
                      _buildEpisodeSection(detail),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(AnimeDetail? detail) {
    final backdrop = detail?.backdropUrl ?? widget.previewItem?.backdropUrl ?? '';

    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.6),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.6),
            child: IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                color: _isBookmarked ? AppColors.accentBlue : Colors.white,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isBookmarked = !_isBookmarked;
                });
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (backdrop.isNotEmpty)
              Image.network(
                backdrop,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceCard,
                  child: const Center(
                    child: Icon(Icons.movie_rounded, color: AppColors.textMuted, size: 48),
                  ),
                ),
              )
            else
              Container(color: AppColors.surfaceCard),

            // Gradient scrim fading into pure OLED black
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.6),
                    AppColors.bgPrimary,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(AnimeDetail? detail) {
    final title = detail?.title ?? widget.previewItem?.title ?? 'Anime Title';
    final rating = detail?.rating ?? widget.previewItem?.rating ?? 8.0;
    final year = detail?.releaseYear ?? widget.previewItem?.releaseYear ?? 2025;
    final status = detail?.status ?? widget.previewItem?.statusLabel ?? 'Ongoing';
    final studio = detail?.studio ?? 'Anime Studio';
    final genres = detail?.genres ?? widget.previewItem?.genres ?? const ['Action'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        if (detail?.japaneseTitle.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            detail!.japaneseTitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Info badges row
        Row(
          children: [
            // Rating
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.accentAmber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Year
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                '$year',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
              ),
              child: Text(
                status,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Studio
            Flexible(
              child: Text(
                studio,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Genre Chips
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: genres.map((genre) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                genre,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AnimeDetail? detail) {
    final firstEpisode = detail?.episodes.isNotEmpty ?? false ? detail!.episodes.first : null;

    return Row(
      children: [
        // Primary Watch Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (firstEpisode != null) {
                widget.onEpisodeTap?.call(firstEpisode);
              }
            },
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            label: const Text(
              'Mulai Nonton',
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

        // Bookmark button
        InkWell(
          onTap: () {
            setState(() {
              _isBookmarked = !_isBookmarked;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(
                  _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: _isBookmarked ? AppColors.accentBlue : AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  _isBookmarked ? 'Tersimpan' : 'Daftar Tonton',
                  style: AppTypography.labelMedium.copyWith(
                    color: _isBookmarked ? AppColors.accentBlue : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSynopsisSection(AnimeDetail? detail) {
    final synopsis = detail?.synopsis ??
        'Sinopsis anime ini menceritakan kisah petualangan luar biasa dengan visual yang memukau dan aksi seru yang menegangkan.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sinopsis',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          synopsis,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeSection(AnimeDetail? detail) {
    final episodes = detail?.episodes ?? [];

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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Center(
              child: Text(
                'Belum ada episode yang tersedia.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: episodes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return InkWell(
                onTap: () => widget.onEpisodeTap?.call(episode),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      // Episode number pill
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Center(
                          child: Text(
                            '${episode.episodeNumber}',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              episode.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rilis: ${episode.releaseDate}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Play icon button
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.accentBlue,
                            size: 18,
                          ),
                        ),
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

