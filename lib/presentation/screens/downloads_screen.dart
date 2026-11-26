import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/download_item.dart';
import '../../data/services/download_repository.dart';
import '../widgets/anime_image_placeholder.dart';

/// Displays all downloaded, downloading, and paused anime episodes with
/// pause/resume controls and long-press deletion.
class DownloadsScreen extends StatefulWidget {
  final DownloadRepository? repository;

  const DownloadsScreen({super.key, this.repository});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  DownloadRepository get _repo =>
      widget.repository ?? DownloadRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onChanged);
    if (!_repo.isInitialized) {
      _repo.init();
    }
  }

  @override
  void dispose() {
    _repo.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  String _statusLabel(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.downloading:
        return 'Mengunduh · ${item.progressPercent}% (${item.formattedSize})';
      case DownloadStatus.paused:
        return 'Dijeda · ${item.progressPercent}% (${item.formattedSize})';
      case DownloadStatus.completed:
        return 'Selesai · ${item.formattedSize}';
      case DownloadStatus.failed:
        return 'Gagal · Ketuk lanjutkan untuk coba lagi';
    }
  }

  Future<void> _showDeleteSheet(DownloadItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF5A5F),
                ),
                title: Text(
                  'Hapus Download',
                  style: AppTypography.titleSmall.copyWith(
                    color: const Color(0xFFFF5A5F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${item.title} · Episode ${item.episodeNumber}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  await _repo.removeDownload(item.id);
                  if (!mounted) return;
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: Text(
                        '${item.title} Ep ${item.episodeNumber} dihapus',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _repo.items;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text('Download (${items.length})'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.download_for_offline_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada anime yang diunduh',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Unduh episode dari pemutar video agar bisa dilihat di sini.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
                        onLongPress: () => _showDeleteSheet(item),
                        borderRadius: BorderRadius.circular(14),
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
                                  width: 54,
                                  height: 74,
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
                                      '${item.title} · Ep ${item.episodeNumber}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleSmall.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _statusLabel(item),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: item.status ==
                                                DownloadStatus.completed
                                            ? const Color(0xFF00E676)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: item.progress,
                                        minHeight: 5,
                                        backgroundColor: AppColors.borderSubtle,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          AppColors.accentBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.status != DownloadStatus.completed) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: IconButton(
                                    key: Key('download_toggle_${item.id}'),
                                    tooltip: item.status ==
                                            DownloadStatus.downloading
                                        ? 'Jeda'
                                        : 'Lanjutkan',
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.accentBlue
                                          .withValues(alpha: 0.16),
                                      foregroundColor: AppColors.accentBlue,
                                    ),
                                    icon: Icon(
                                      item.status == DownloadStatus.downloading
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                    onPressed: () {
                                      if (item.status ==
                                          DownloadStatus.downloading) {
                                        _repo.pauseDownload(item.id);
                                      } else {
                                        _repo.resumeDownload(item.id);
                                      }
                                    },
                                  ),
                                ),
                              ],
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

