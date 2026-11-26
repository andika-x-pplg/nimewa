import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/my_list_entry.dart';
import '../../data/models/rank_tier.dart';
import '../../data/models/watch_history_entry.dart';
import '../../data/services/anime_stream_service.dart';
import '../../data/services/my_list_repository.dart';
import '../../data/services/user_profile_repository.dart';
import '../widgets/animated_rank_badge.dart';
import '../widgets/anime_image_placeholder.dart';
import 'anime_detail_screen.dart';
import 'anime_watch_screen.dart';
import 'rank_list_screen.dart';
import 'watched_anime_list_screen.dart';

/// User Profile screen displaying dynamic initial avatar, editable username,
/// account stats (EXP, months active, total anime watched), watch history
/// with exact timestamp resume, and quick navigation options.
class ProfileScreen extends StatefulWidget {
  final UserProfileRepository? profileRepository;
  final MyListRepository? myListRepository;
  final AnimeStreamService? streamService;
  final ValueChanged<int>? onNavigateTab;

  const ProfileScreen({
    super.key,
    this.profileRepository,
    this.myListRepository,
    this.streamService,
    this.onNavigateTab,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isOpeningPlayer = false;

  UserProfileRepository get _profileRepo =>
      widget.profileRepository ?? UserProfileRepository.instance;
  MyListRepository get _myListRepo =>
      widget.myListRepository ?? MyListRepository.instance;
  AnimeStreamService get _service =>
      widget.streamService ?? const AnimeStreamService();

  @override
  void initState() {
    super.initState();
    _profileRepo.addListener(_onChanged);
    _myListRepo.addListener(_onChanged);
    if (!_profileRepo.isInitialized) {
      _profileRepo.init();
    }
    if (!_myListRepo.isInitialized && !_myListRepo.isLoading) {
      _myListRepo.init();
    }
  }

  @override
  void dispose() {
    _profileRepo.removeListener(_onChanged);
    _myListRepo.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int _totalWatchedAnime() {
    final keys = <String>{};
    for (final e in _myListRepo.entriesByStatus(MyListStatus.watching)) {
      keys.add(e.canonicalKey);
    }
    for (final e in _myListRepo.entriesByStatus(MyListStatus.completed)) {
      keys.add(e.canonicalKey);
    }
    for (final h in _profileRepo.watchHistory) {
      keys.add(h.canonicalKey);
    }
    return keys.length;
  }

  Future<void> _showEditNameDialog() async {
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _EditUsernameDialog(initialName: _profileRepo.username),
    );
    if (updated != null && updated.trim().isNotEmpty) {
      await _profileRepo.updateUsername(updated);
    }
  }

  Future<void> _resumeHistoryEntry(WatchHistoryEntry entry) async {
    if (_isOpeningPlayer) return;
    setState(() => _isOpeningPlayer = true);
    try {
      final detail = await _service.getAnimeDetail(entry.animeId);
      if (!mounted) return;
      if (detail.episodes.isEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnimeDetailScreen(
              animeId: entry.animeId,
              previewItem: entry.toAnimeItem(),
              service: _service,
              myListRepository: _myListRepo,
            ),
          ),
        );
        return;
      }

      final targetEp = detail.episodes.firstWhere(
        (ep) => ep.episodeNumber == entry.episodeNumber,
        orElse: () => detail.episodes.first,
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AnimeWatchScreen(
            anime: detail,
            initialEpisode: targetEp,
            myListRepository: _myListRepo,
            profileRepository: _profileRepo,
            initialPosition: entry.positionSeconds > 0
                ? Duration(seconds: entry.positionSeconds)
                : null,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Gagal membuka pemutar video.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningPlayer = false);
      }
    }
  }

  Future<void> _confirmClearHistory() async {
    if (_profileRepo.watchHistory.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: Text(
          'Hapus Histori Tonton?',
          style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Semua riwayat episode dan posisi detik tontonan akan dihapus.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A5F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _profileRepo.clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _profileRepo.watchHistory;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Histori Tonton'),
                  const SizedBox(height: 12),
                  if (history.isEmpty)
                    _buildEmptyHistory()
                  else
                    Column(
                      children: history
                          .map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildHistoryCard(entry),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Menu & Pengaturan'),
                  const SizedBox(height: 12),
                  _buildMenuOptions(history.isNotEmpty),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.accentBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _profileRepo.initial,
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _profileRepo.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  key: const Key('profile_edit_name_button'),
                  onPressed: _showEditNameDialog,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit Nama'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentBlue,
                    side: const BorderSide(color: AppColors.accentBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedRankBadge(
            tier: _profileRepo.currentRank,
            currentLevel: _profileRepo.level,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildStatItem(
            RankCatalog.formatNumber(_profileRepo.exp),
            'EXP',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RankListScreen(
                    profileRepository: _profileRepo,
                  ),
                ),
              );
            },
          ),
          _buildVerticalDivider(),
          _buildStatItem('${_profileRepo.monthsActive}', 'Bulan'),
          _buildVerticalDivider(),
          _buildStatItem(
            '${_totalWatchedAnime()}',
            'Total Anime',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WatchedAnimeListScreen(
                    myListRepository: _myListRepo,
                    profileRepository: _profileRepo,
                    streamService: _service,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.borderSubtle,
    );
  }

  Widget _buildStatItem(String value, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  color: onTap != null
                      ? AppColors.accentBlue
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_rounded,
            size: 36,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada histori tontonan',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Video anime yang kamu putar akan tersimpan di sini beserta posisi terakhirnya.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showHistoryActionsSheet(WatchHistoryEntry entry) async {
    final isInMyList = _myListRepo.contains(
      entry.animeId,
      aniListId: entry.aniListId,
      title: entry.title,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    isInMyList
                        ? Icons.bookmark_remove_rounded
                        : Icons.bookmark_add_rounded,
                    color: AppColors.accentBlue,
                  ),
                  title: Text(
                    isInMyList ? 'Buang dari My List' : 'Simpan ke My List',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    if (isInMyList) {
                      final removed =
                          await _myListRepo.removeEntry(entry.canonicalKey);
                      if (!mounted || removed == null) return;
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      messenger?.clearSnackBars();
                      messenger?.showSnackBar(
                        SnackBar(
                          content: Text(
                            '${removed.title} dibuang dari My List',
                          ),
                          action: SnackBarAction(
                            label: 'Urungkan',
                            onPressed: () => _myListRepo.restoreEntry(removed),
                          ),
                        ),
                      );
                    } else {
                      await _myListRepo.toggleSaveAnime(entry.toAnimeItem());
                      if (!mounted) return;
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      messenger?.clearSnackBars();
                      messenger?.showSnackBar(
                        SnackBar(
                          content: Text('${entry.title} disimpan ke My List'),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF5A5F),
                  ),
                  title: Text(
                    'Hapus dari Histori',
                    style: AppTypography.titleSmall.copyWith(
                      color: const Color(0xFFFF5A5F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    await _profileRepo.removeHistoryEntry(entry.canonicalKey);
                    if (!mounted) return;
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    messenger?.clearSnackBars();
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text('${entry.title} dihapus dari histori'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryCard(WatchHistoryEntry entry) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _resumeHistoryEntry(entry),
        onLongPress: () => _showHistoryActionsSheet(entry),
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
                  width: 56,
                  height: 76,
                  child: entry.posterUrl.trim().isEmpty
                      ? AnimeImagePlaceholder(title: entry.title, showTitle: false)
                      : Image.network(
                          entry.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => AnimeImagePlaceholder(
                            title: entry.title,
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
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Episode ${entry.episodeNumber} · Lanjut di ${entry.formattedPosition}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.progressFraction,
                        minHeight: 5,
                        backgroundColor: AppColors.borderSubtle,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: () => _resumeHistoryEntry(entry),
                  tooltip: 'Lanjutkan menonton',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accentBlue.withValues(alpha: 0.16),
                    foregroundColor: AppColors.accentBlue,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOptions(bool hasHistory) {
    return Material(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.bookmark_rounded,
            title: 'Daftar Saya',
            subtitle: 'Lihat anime Watching, Saved, dan Completed',
            onTap: () => widget.onNavigateTab?.call(3),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          _buildMenuTile(
            icon: Icons.calendar_today_rounded,
            title: 'Jadwal Rilis Anime',
            subtitle: 'Pantau jadwal tayang mingguan',
            onTap: () => widget.onNavigateTab?.call(2),
          ),
          if (hasHistory) ...[
            const Divider(height: 1, color: AppColors.borderSubtle),
            _buildMenuTile(
              icon: Icons.delete_outline_rounded,
              title: 'Hapus Histori Tonton',
              subtitle: 'Bersihkan semua riwayat pemutaran video',
              iconColor: const Color(0xFFFF5A5F),
              onTap: _confirmClearHistory,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      minVerticalPadding: 12,
      leading: Icon(icon, color: iconColor ?? AppColors.accentBlue),
      title: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}

class _EditUsernameDialog extends StatefulWidget {
  final String initialName;

  const _EditUsernameDialog({required this.initialName});

  @override
  State<_EditUsernameDialog> createState() => _EditUsernameDialogState();
}

class _EditUsernameDialogState extends State<_EditUsernameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Nama tidak boleh kosong.');
      return;
    }
    Navigator.of(context).pop(text);
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
        'Edit Nama Profil',
        style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        decoration: InputDecoration(
          labelText: 'Nama pengguna',
          errorText: _errorText,
          labelStyle:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surfaceCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
        ),
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

