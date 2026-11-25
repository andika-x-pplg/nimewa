import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/anime_item.dart';
import '../../data/models/my_list_entry.dart';
import '../../data/services/anime_stream_service.dart';
import '../../data/services/my_list_repository.dart';
import '../../data/services/user_profile_repository.dart';
import '../widgets/anime_image_placeholder.dart';
import 'anime_detail_screen.dart';

/// Displays all unique anime watched by the user (combining My List active/completed
/// entries and watch history).
class WatchedAnimeListScreen extends StatelessWidget {
  final MyListRepository? myListRepository;
  final UserProfileRepository? profileRepository;
  final AnimeStreamService? streamService;

  const WatchedAnimeListScreen({
    super.key,
    this.myListRepository,
    this.profileRepository,
    this.streamService,
  });

  List<_WatchedAnimeSummary> _collectWatched() {
    final myListRepo = myListRepository ?? MyListRepository.instance;
    final profileRepo = profileRepository ?? UserProfileRepository.instance;
    final map = <String, _WatchedAnimeSummary>{};

    for (final e in myListRepo.entriesByStatus(MyListStatus.watching)) {
      map[e.canonicalKey] = _WatchedAnimeSummary(
        animeId: e.animeId,
        title: e.title,
        posterUrl: e.posterUrl,
        subtitle: e.progressSummaryText,
        previewItem: e.toAnimeItem(),
      );
    }
    for (final e in myListRepo.entriesByStatus(MyListStatus.completed)) {
      map[e.canonicalKey] = _WatchedAnimeSummary(
        animeId: e.animeId,
        title: e.title,
        posterUrl: e.posterUrl,
        subtitle: '${e.progressSummaryText} · Tamat',
        previewItem: e.toAnimeItem(),
      );
    }
    for (final h in profileRepo.watchHistory) {
      map.putIfAbsent(
        h.canonicalKey,
        () => _WatchedAnimeSummary(
          animeId: h.animeId,
          title: h.title,
          posterUrl: h.posterUrl,
          subtitle: 'Episode ${h.episodeNumber} · ${h.formattedPosition}',
          previewItem: h.toAnimeItem(),
        ),
      );
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _collectWatched();
    final myListRepo = myListRepository ?? MyListRepository.instance;
    final service = streamService ?? const AnimeStreamService();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text('Anime Ditonton (${items.length})'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Belum ada anime yang ditonton.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Material(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AnimeDetailScreen(
                                animeId: item.animeId,
                                previewItem: item.previewItem,
                                service: service,
                                myListRepository: myListRepo,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 52,
                                  height: 72,
                                  child: item.posterUrl.trim().isEmpty
                                      ? AnimeImagePlaceholder(
                                          title: item.title,
                                          showTitle: false,
                                        )
                                      : Image.network(
                                          item.posterUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              AnimeImagePlaceholder(
                                            title: item.title,
                                            showTitle: false,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _WatchedAnimeSummary {
  final String animeId;
  final String title;
  final String posterUrl;
  final String subtitle;
  final AnimeItem previewItem;

  const _WatchedAnimeSummary({
    required this.animeId,
    required this.title,
    required this.posterUrl,
    required this.subtitle,
    required this.previewItem,
  });
}

