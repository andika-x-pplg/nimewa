import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/my_list_entry.dart';
import '../../data/services/anime_stream_service.dart';
import '../../data/services/my_list_repository.dart';
import '../widgets/my_list_anime_card.dart';
import 'anime_detail_screen.dart';
import 'anime_watch_screen.dart';

/// Screen displaying the user's saved, watching, and completed anime list
/// with episode progress, percentage tracking, quick-play, and management actions.
class MyListScreen extends StatefulWidget {
  final MyListRepository? repository;
  final AnimeStreamService? streamService;
  final VoidCallback? onExploreTap;

  const MyListScreen({
    super.key,
    this.repository,
    this.streamService,
    this.onExploreTap,
  });

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  MyListStatus _selectedStatus = MyListStatus.watching;
  bool _isOpeningPlayer = false;

  MyListRepository get _repo => widget.repository ?? MyListRepository.instance;
  AnimeStreamService get _service =>
      widget.streamService ?? const AnimeStreamService();

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepositoryChanged);
    if (!_repo.isInitialized && !_repo.isLoading) {
      _repo.init();
    }
  }

  @override
  void didUpdateWidget(covariant MyListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRepo = oldWidget.repository ?? MyListRepository.instance;
    if (oldRepo != _repo) {
      oldRepo.removeListener(_onRepositoryChanged);
      _repo.addListener(_onRepositoryChanged);
    }
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _tabLabel(MyListStatus status) {
    final count = _repo.countByStatus(status);
    switch (status) {
      case MyListStatus.watching:
        return 'Watching · $count';
      case MyListStatus.saved:
        return 'Saved · $count';
      case MyListStatus.completed:
        return 'Completed · $count';
    }
  }

  String _calloutEyebrow(MyListStatus status) {
    switch (status) {
      case MyListStatus.watching:
        return 'LANJUTKAN TONTONAN';
      case MyListStatus.saved:
        return 'SIAP DITONTON';
      case MyListStatus.completed:
        return 'SUDAH TAMAT';
    }
  }

  String _calloutHeadline(MyListStatus status, int count) {
    if (count == 0) {
      switch (status) {
        case MyListStatus.watching:
          return 'Belum ada anime yang sedang ditonton';
        case MyListStatus.saved:
          return 'Belum ada anime yang tersimpan';
        case MyListStatus.completed:
          return 'Belum ada anime yang selesai ditonton';
      }
    }
    switch (status) {
      case MyListStatus.watching:
        return '$count anime menunggu untuk dilanjutkan';
      case MyListStatus.saved:
        return '$count anime tersimpan untuk nanti';
      case MyListStatus.completed:
        return '$count anime selesai ditonton';
    }
  }

  String _sectionTitle(MyListStatus status) {
    switch (status) {
      case MyListStatus.watching:
        return 'Lanjutkan dari terakhir kali';
      case MyListStatus.saved:
        return 'Daftar anime tersimpan';
      case MyListStatus.completed:
        return 'Anime yang sudah tamat';
    }
  }

  void _openDetail(MyListEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimeDetailScreen(
          animeId: entry.animeId,
          previewItem: entry.toAnimeItem(),
          service: _service,
          myListRepository: _repo,
        ),
      ),
    );
  }

  Future<void> _handlePlay(MyListEntry entry) async {
    if (_isOpeningPlayer) return;
    if (!entry.hasVideoAvailable) {
      _openDetail(entry);
      return;
    }

    setState(() => _isOpeningPlayer = true);
    try {
      final detail = await _service.getAnimeDetail(entry.animeId);
      if (!mounted) return;
      if (detail.episodes.isEmpty) {
        _openDetail(entry);
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
            myListRepository: _repo,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _openDetail(entry);
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningPlayer = false);
      }
    }
  }

  Future<void> _showEditEpisodeDialog(MyListEntry entry) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _EditEpisodeDialog(entry: entry),
    );

    if (result != null && result >= 0) {
      await _repo.updateEpisodeProgress(entry.canonicalKey, result);
    }
  }

  Future<void> _handleDelete(MyListEntry entry) async {
    final removed = await _repo.removeEntry(entry.canonicalKey);
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
            _repo.restoreEntry(removed);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _repo.entriesByStatus(_selectedStatus);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Koleksi anime pilihanmu.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'My list',
                          style: AppTypography.headlineLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFilterTabs(),
                        const SizedBox(height: 16),
                        _buildCalloutBanner(entries),
                        const SizedBox(height: 20),
                        Text(
                          _sectionTitle(_selectedStatus),
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_repo.isLoading && !_repo.isInitialized)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentBlue,
                      ),
                    ),
                  )
                else if (_repo.loadError != null && _repo.allEntries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildErrorState(),
                  )
                else if (entries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.crossAxisExtent > 600;
                        if (!isWide) {
                          return SliverList.separated(
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _buildCard(entries[index]),
                          );
                        }

                        final rowCount = (entries.length + 1) ~/ 2;
                        return SliverList.separated(
                          itemCount: rowCount,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, rowIndex) {
                            final leftIndex = rowIndex * 2;
                            final rightIndex = leftIndex + 1;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildCard(entries[leftIndex]),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: rightIndex < entries.length
                                      ? _buildCard(entries[rightIndex])
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: MyListStatus.values.map((status) {
          final isSelected = _selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: ChoiceChip(
                label: Text(_tabLabel(status)),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
                backgroundColor: AppColors.surfaceCard,
                selectedColor: AppColors.accentBlue,
                side: BorderSide(
                  color:
                      isSelected ? AppColors.accentBlue : AppColors.borderSubtle,
                ),
                labelStyle: AppTypography.labelLarge.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }

  Widget _buildCalloutBanner(List<MyListEntry> entries) {
    final firstEntry = entries.isNotEmpty ? entries.first : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _calloutEyebrow(_selectedStatus),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _calloutHeadline(_selectedStatus, entries.length),
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (firstEntry != null) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: () => _handlePlay(firstEntry),
                tooltip: firstEntry.hasVideoAvailable
                    ? 'Putar anime terbaru'
                    : 'Buka detail anime',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accentBlue.withValues(alpha: 0.16),
                  foregroundColor: AppColors.accentBlue,
                ),
                icon: Icon(
                  firstEntry.hasVideoAvailable
                      ? Icons.play_arrow_rounded
                      : Icons.open_in_new_rounded,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(MyListEntry entry) {
    return MyListAnimeCard(
      entry: entry,
      onTap: () => _openDetail(entry),
      onPlayTap: () => _handlePlay(entry),
      onStatusChanged: (status) =>
          _repo.updateStatus(entry.canonicalKey, status),
      onEditProgress: () => _showEditEpisodeDialog(entry),
      onDelete: () => _handleDelete(entry),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    switch (_selectedStatus) {
      case MyListStatus.watching:
        title = 'Belum ada anime ditonton';
        subtitle =
            'Mulai tonton anime atau simpan dari Beranda untuk memantau progres episodenya di sini.';
      case MyListStatus.saved:
        title = 'Daftar simpanan masih kosong';
        subtitle =
            'Ketuk tombol + di Beranda atau Simpan Anime di halaman detail untuk menyimpannya.';
      case MyListStatus.completed:
        title = 'Belum ada anime tamat';
        subtitle =
            'Anime yang selesai kamu tonton akan otomatis masuk ke tab Completed.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onExploreTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Jelajahi Anime'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppColors.accentAmber,
            ),
            const SizedBox(height: 12),
            Text(
              _repo.loadError ?? 'Gagal memuat daftar anime.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _repo.init(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(140, 44),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditEpisodeDialog extends StatefulWidget {
  final MyListEntry entry;

  const _EditEpisodeDialog({required this.entry});

  @override
  State<_EditEpisodeDialog> createState() => _EditEpisodeDialogState();
}

class _EditEpisodeDialogState extends State<_EditEpisodeDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: '${widget.entry.watchedEpisode}',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _stepEpisode(int delta) {
    final current =
        int.tryParse(_controller.text.trim()) ?? widget.entry.watchedEpisode;
    var next = current + delta;
    if (next < 0) next = 0;
    final maxEp = widget.entry.totalEpisodes;
    if (maxEp > 0 && next > maxEp) next = maxEp;
    setState(() {
      _errorText = null;
      _controller.text = '$next';
    });
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 0) {
      setState(() => _errorText = 'Masukkan angka episode yang valid.');
      return;
    }
    final maxEp = widget.entry.totalEpisodes;
    final clamped = (maxEp > 0 && parsed > maxEp) ? maxEp : parsed;
    Navigator.of(context).pop(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      title: Text(
        'Atur Progres Episode',
        style: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.entry.totalEpisodes > 0
                ? '${widget.entry.title} (maks ${widget.entry.totalEpisodes} episode)'
                : widget.entry.title,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: () => _stepEpisode(-1),
                  tooltip: 'Kurangi episode',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceCard,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.remove_rounded),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Episode',
                    errorText: _errorText,
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: () => _stepEpisode(1),
                  tooltip: 'Tambah episode',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceCard,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
