import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/anime_detail.dart';
import '../../data/models/anime_external_link.dart';
import '../../data/models/anime_item.dart';
import '../../data/models/episode_item.dart';
import '../../data/services/anime_stream_service.dart';
import '../widgets/anime_image_placeholder.dart';
import 'anime_watch_screen.dart';

/// Screen displaying anime information, synopsis, and episode streaming list.
class AnimeDetailScreen extends StatefulWidget {
  final String animeId;
  final AnimeItem? previewItem;
  final void Function(EpisodeItem episode)? onEpisodeTap;
  final AnimeStreamService? service;

  const AnimeDetailScreen({
    super.key,
    required this.animeId,
    this.previewItem,
    this.onEpisodeTap,
    this.service,
  });

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  late final AnimeStreamService _service;
  late Future<AnimeDetail> _detailFuture;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? const AnimeStreamService();
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
                      if (detail?.relations.isNotEmpty ?? false) ...[
                        _buildFranchiseRelationsSection(detail!),
                        const SizedBox(height: 24),
                      ],
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
                errorBuilder: (context, error, stackTrace) => AnimeImagePlaceholder(
                  title: detail?.title ?? widget.previewItem?.title ?? '',
                  showTitle: false,
                  iconSize: 48,
                ),
              )
            else
              AnimeImagePlaceholder(
                title: detail?.title ?? widget.previewItem?.title ?? '',
                showTitle: false,
                iconSize: 48,
              ),

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

        // Info badges
        Wrap(
          spacing: 8.0,
          runSpacing: 6.0,
          crossAxisAlignment: WrapCrossAlignment.center,
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
                mainAxisSize: MainAxisSize.min,
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

            // Availability badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (detail?.hasVideoAvailable ?? widget.previewItem?.hasVideoAvailable ?? true)
                    ? AppColors.accentBlue.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (detail?.hasVideoAvailable ?? widget.previewItem?.hasVideoAvailable ?? true)
                      ? AppColors.accentBlue.withValues(alpha: 0.3)
                      : AppColors.borderSubtle,
                ),
              ),
              child: Text(
                (detail?.hasVideoAvailable ?? widget.previewItem?.hasVideoAvailable ?? true)
                    ? 'Video tersedia'
                    : 'Belum tersedia',
                style: AppTypography.labelSmall.copyWith(
                  color: (detail?.hasVideoAvailable ?? widget.previewItem?.hasVideoAvailable ?? true)
                      ? AppColors.accentBlue
                      : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Studio
            Text(
              studio,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
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

  void _openWatchScreen(AnimeDetail detail, EpisodeItem episode) {
    widget.onEpisodeTap?.call(episode);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimeWatchScreen(
          anime: detail,
          initialEpisode: episode,
        ),
      ),
    );
  }

  Widget _buildActionButtons(AnimeDetail? detail) {
    final hasVideo = detail?.hasVideoAvailable ?? widget.previewItem?.hasVideoAvailable ?? false;
    final firstEpisode = detail?.episodes.isNotEmpty ?? false ? detail!.episodes.first : null;
    final isPlayable = detail != null && hasVideo && firstEpisode != null && firstEpisode.streamUrl.isNotEmpty;
    final streamingLinks = detail?.streamingLinks ?? const [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Primary Watch Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isPlayable
                    ? () {
                        _openWatchScreen(detail, firstEpisode);
                      }
                    : null,
                icon: Icon(
                  hasVideo ? Icons.play_arrow_rounded : Icons.videocam_off_outlined,
                  color: isPlayable ? Colors.white : AppColors.textMuted,
                  size: 20,
                ),
                label: Text(
                  hasVideo ? 'Mulai Nonton' : 'Video Belum Tersedia',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: isPlayable ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPlayable ? AppColors.accentBlue : AppColors.surfaceCard,
                  disabledBackgroundColor: AppColors.surfaceCard,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isPlayable ? Colors.transparent : AppColors.borderSubtle,
                    ),
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
        ),

        // Official platform streaming button (Crunchyroll, Netflix, Bilibili, etc.)
        if (streamingLinks.isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openOfficialStreaming(streamingLinks),
            icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.accentBlue),
            label: Text(
              streamingLinks.length == 1
                  ? 'Tonton di platform resmi (${streamingLinks.first.site})'
                  : 'Tonton di platform resmi',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accentBlue, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: AppColors.accentBlue.withValues(alpha: 0.08),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openOfficialStreaming(List<AnimeExternalLink> links) async {
    if (links.isEmpty) return;
    if (links.length == 1) {
      final uri = Uri.tryParse(links.first.url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Platform Streaming Resmi',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...links.map((link) => ListTile(
                      leading: const Icon(Icons.ondemand_video_rounded, color: AppColors.accentBlue),
                      title: Text(
                        link.site.isNotEmpty ? link.site : 'Platform Resmi',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        final uri = Uri.tryParse(link.url);
                        if (uri != null) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    )),
              ],
            ),
          ),
        );
      },
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

  Widget _buildFranchiseRelationsSection(AnimeDetail detail) {
    final relations = detail.relations;
    if (relations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Relasi Franchise',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Prequel / Sequel',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: relations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rel = relations[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AnimeDetailScreen(
                        animeId: rel.id.toString(),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        aspectRatio: 0.75,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: rel.posterUrl.trim().isEmpty
                                  ? AnimeImagePlaceholder(
                                      title: rel.title,
                                      iconSize: 24,
                                      fontSize: 9,
                                    )
                                  : Image.network(
                                      rel.posterUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          AnimeImagePlaceholder(
                                        title: rel.title,
                                        iconSize: 24,
                                        fontSize: 9,
                                      ),
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  rel.relationType,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rel.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeSection(AnimeDetail? detail) {
    final hasVideo = detail?.hasVideoAvailable ?? true;
    final episodes = detail?.episodes ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Daftar Episode',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              detail != null
                  ? (hasVideo ? '${episodes.length} Episode' : 'Tidak Tersedia')
                  : (widget.previewItem?.episodeInfo ?? 'Memuat...'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (detail == null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: AppColors.accentBlue, strokeWidth: 2),
              ),
            ),
          )
        else if (!hasVideo || episodes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.videocam_off_outlined,
                  color: AppColors.textMuted,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  'Episode video belum tersedia untuk judul ini.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Anda dapat melihat franchise relation (prequel/sequel) atau katalog judul lainnya.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
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
                onTap: () {
                  _openWatchScreen(detail, episode);
                },
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

