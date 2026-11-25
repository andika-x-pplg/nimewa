import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/anime_item.dart';
import '../../data/models/schedule_entry.dart';
import '../../data/services/schedule_service.dart';
import '../widgets/schedule_timeline_card.dart';
import '../widgets/schedule_week_bar.dart';

/// Responsive weekly anime release schedule screen backed by [ScheduleService].
class ScheduleScreen extends StatefulWidget {
  final ScheduleService? scheduleService;
  final void Function(AnimeItem anime)? onAnimeTap;
  final DateTime Function()? nowProvider;

  const ScheduleScreen({
    super.key,
    this.scheduleService,
    this.onAnimeTap,
    this.nowProvider,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver {
  static const double largeScreenMinWidth = 600.0;
  static const double _wideComfortPaddingMinWidth = 720.0;
  static const double _maxContentWidth = 960.0;

  late final ScheduleService _scheduleService;
  late DateTime Function() _nowProvider;
  late DateTime _selectedDate;

  WeeklyScheduleResult? _scheduleResult;
  bool _isLoading = true;
  String? _errorMessage;
  bool _onlyReminders = false;
  final Set<String> _remindedKeys = <String>{};
  int _loadRequestId = 0;
  String? _loadingWeekKey;
  String? _pendingRolloverWeekKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleService = widget.scheduleService ?? ScheduleService();
    _nowProvider = widget.nowProvider ?? DateTime.now;
    final initialNow = _currentNow();
    _selectedDate = _dateOnly(initialNow);
    _loadSchedule(updateStateBeforeFetch: false);
  }

  @override
  void didUpdateWidget(covariant ScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nowProvider != oldWidget.nowProvider) {
      _nowProvider = widget.nowProvider ?? DateTime.now;
    }
    _checkAndHandleWeekRollover(deferToPostFrame: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndHandleWeekRollover();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime _currentNow() => _nowProvider().toLocal();

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _weekKeyFor(DateTime dt) =>
      ScheduleDateHelper.dateKey(ScheduleDateHelper.weekStartSunday(dt));

  void _checkAndHandleWeekRollover({bool deferToPostFrame = false}) {
    final now = _currentNow();
    final currentWeekKey = _weekKeyFor(now);
    final result = _scheduleResult;

    if (result == null) {
      if (!deferToPostFrame && !_isLoading) {
        _selectedDate = _dateOnly(now);
        _loadSchedule();
      }
      return;
    }

    final loadedWeekKey = _weekKeyFor(result.weekStart);
    if (currentWeekKey == loadedWeekKey) {
      if (!_isLoading) {
        _pendingRolloverWeekKey = null;
      }
      return;
    }

    if (_isLoading && _loadingWeekKey == currentWeekKey) {
      return;
    }

    if (deferToPostFrame) {
      if (_pendingRolloverWeekKey == currentWeekKey) {
        return;
      }
      _pendingRolloverWeekKey = currentWeekKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final latestNow = _currentNow();
        final latestWeekKey = _weekKeyFor(latestNow);
        final latestResult = _scheduleResult;
        if (latestResult != null &&
            _weekKeyFor(latestResult.weekStart) == latestWeekKey) {
          _pendingRolloverWeekKey = null;
          return;
        }
        if (_isLoading && _loadingWeekKey == latestWeekKey) {
          return;
        }
        _selectedDate = _dateOnly(latestNow);
        _loadSchedule();
      });
      return;
    }

    _pendingRolloverWeekKey = currentWeekKey;
    _selectedDate = _dateOnly(now);
    _loadSchedule();
  }

  String _entryReminderKey(ScheduleEntry entry) =>
      '${entry.scheduleId}:${entry.mediaId}';

  bool _isReminded(ScheduleEntry entry) =>
      _remindedKeys.contains(_entryReminderKey(entry));

  DateTime _resolveSelectedDate(List<DateTime> weekDays, DateTime today) {
    final selectedKey = ScheduleDateHelper.dateKey(_selectedDate);
    for (final day in weekDays) {
      if (ScheduleDateHelper.dateKey(day) == selectedKey) {
        return _dateOnly(day);
      }
    }
    return today;
  }

  Set<String> _computeReminderDateKeys() {
    final result = _scheduleResult;
    if (result == null || _remindedKeys.isEmpty) {
      return const <String>{};
    }
    final keys = <String>{};
    for (final entry in result.entriesByDateKey.entries) {
      if (entry.value.any(_isReminded)) {
        keys.add(entry.key);
      }
    }
    return keys;
  }

  Future<void> _loadSchedule({
    bool forceRefresh = false,
    bool updateStateBeforeFetch = true,
  }) async {
    final fetchNow = _currentNow();
    final requestWeekKey = _weekKeyFor(fetchNow);
    final requestId = ++_loadRequestId;
    _loadingWeekKey = requestWeekKey;
    if (updateStateBeforeFetch && mounted) {
      setState(() {
        _isLoading = true;
        if (_scheduleResult == null) {
          _errorMessage = null;
        }
      });
    }

    try {
      final result = await _scheduleService.fetchWeeklySchedule(
        now: fetchNow,
        forceRefresh: forceRefresh,
      );
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _scheduleResult = result;
        _isLoading = false;
        _loadingWeekKey = null;
        _errorMessage = null;
        if (_weekKeyFor(result.weekStart) == _weekKeyFor(_currentNow())) {
          _pendingRolloverWeekKey = null;
        }
      });
    } catch (_) {
      if (!mounted || requestId != _loadRequestId) return;
      if (_scheduleResult == null) {
        setState(() {
          _isLoading = false;
          _loadingWeekKey = null;
          _errorMessage = 'Gagal memuat jadwal tayang anime.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _loadingWeekKey = null;
        });
        _showSnackBar('Gagal memperbarui jadwal. Periksa koneksi internet Anda.');
      }
    }
  }

  void _toggleReminder(ScheduleEntry entry) {
    final key = _entryReminderKey(entry);
    final added = !_remindedKeys.contains(key);
    setState(() {
      if (added) {
        _remindedKeys.add(key);
      } else {
        _remindedKeys.remove(key);
      }
    });

    final message = added
        ? 'Pengingat diaktifkan untuk ${entry.title} Ep. ${entry.episodeNumber}.'
        : 'Pengingat dihapus untuk ${entry.title} Ep. ${entry.episodeNumber}.';
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final now = _currentNow();
    _checkAndHandleWeekRollover(deferToPostFrame: true);
    final today = _dateOnly(now);
    final weekDays = ScheduleDateHelper.weekDays(now);
    final selectedDate = _resolveSelectedDate(weekDays, today);
    final bottomReserve = 32.0 + MediaQuery.paddingOf(context).bottom;

    return Container(
      color: AppColors.bgPrimary,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final isWide = maxWidth > largeScreenMinWidth;
            final contentPadding = isWide
                ? (maxWidth > _wideComfortPaddingMinWidth ? 24.0 : 16.0)
                : (maxWidth < 352.0 ? 12.0 : 16.0);
            final weekBarPadding = isWide
                ? contentPadding
                : ((maxWidth - 320.0) / 2.0).clamp(0.0, 16.0);

            return Center(
              child: ConstrainedBox(
                key: const Key('schedule_max_width_container'),
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: RefreshIndicator(
                  color: AppColors.accentBlue,
                  backgroundColor: AppColors.surfaceElevated,
                  onRefresh: () => _loadSchedule(forceRefresh: true),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          contentPadding,
                          12,
                          contentPadding,
                          14,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildHeader(),
                        ),
                      ),
                      ..._buildBodySlivers(
                        now: now,
                        today: today,
                        weekDays: weekDays,
                        selectedDate: selectedDate,
                        isWide: isWide,
                        contentPadding: contentPadding,
                        weekBarPadding: weekBarPadding,
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: bottomReserve),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Jangan lewatkan episode terbaru.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Jadwal Rilis',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildReminderFilterButton(),
      ],
    );
  }

  Widget _buildReminderFilterButton() {
    final hasReminders = _remindedKeys.isNotEmpty;
    return Semantics(
      button: true,
      toggled: _onlyReminders,
      label: _onlyReminders
          ? 'Tampilkan semua jadwal'
          : 'Filter hanya pengingat',
      child: Tooltip(
        message: 'Hanya Pengingat',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('schedule_reminder_filter_button'),
            onTap: () {
              setState(() {
                _onlyReminders = !_onlyReminders;
              });
            },
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _onlyReminders
                    ? AppColors.accentBlue.withValues(alpha: 0.16)
                    : AppColors.surfaceElevated,
                border: Border.all(
                  color: _onlyReminders
                      ? AppColors.accentBlue
                      : AppColors.borderSubtle,
                  width: 1.0,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _onlyReminders
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    size: 21,
                    color: _onlyReminders
                        ? AppColors.accentBlue
                        : AppColors.textPrimary,
                  ),
                  if (hasReminders && !_onlyReminders)
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.accentBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBodySlivers({
    required DateTime now,
    required DateTime today,
    required List<DateTime> weekDays,
    required DateTime selectedDate,
    required bool isWide,
    required double contentPadding,
    required double weekBarPadding,
  }) {
    if (_isLoading && _scheduleResult == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildLoadingState(),
        ),
      ];
    }

    if (_errorMessage != null && _scheduleResult == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildErrorState(contentPadding),
        ),
      ];
    }

    final result = _scheduleResult;
    if (result == null) {
      return const [];
    }

    final dayEntries = result.entriesForDate(selectedDate);
    final visibleEntries = _onlyReminders
        ? dayEntries.where(_isReminded).toList()
        : dayEntries;

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: weekBarPadding),
        sliver: SliverToBoxAdapter(
          child: ScheduleWeekBar(
            days: weekDays,
            selectedDate: selectedDate,
            today: today,
            reminderDateKeys: _computeReminderDateKeys(),
            onDaySelected: (day) {
              setState(() {
                _selectedDate = _dateOnly(day);
              });
            },
          ),
        ),
      ),
      if (result.isStaleCache)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(contentPadding, 14, contentPadding, 0),
          sliver: SliverToBoxAdapter(
            child: _buildOfflineBanner(),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(contentPadding, 18, contentPadding, 12),
        sliver: SliverToBoxAdapter(
          child: _buildSectionHeader(
            selectedDate: selectedDate,
            now: now,
            episodeCount: visibleEntries.length,
          ),
        ),
      ),
      if (visibleEntries.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: contentPadding),
            child: _buildEmptyState(
              selectedDate: selectedDate,
              today: today,
            ),
          ),
        )
      else if (isWide)
        _buildTwoColumnGridSliver(
          entries: visibleEntries,
          now: now,
          contentPadding: contentPadding,
        )
      else
        _buildSingleColumnTimelineSliver(
          entries: visibleEntries,
          now: now,
          contentPadding: contentPadding,
        ),
    ];
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentAmber.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: AppColors.accentAmber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mode offline. Menampilkan jadwal tersimpan.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed:
                _isLoading ? null : () => _loadSchedule(forceRefresh: true),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: AppColors.accentBlue,
              disabledBackgroundColor:
                  AppColors.accentBlue.withValues(alpha: 0.5),
              foregroundColor: AppColors.textPrimary,
              disabledForegroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Memuat...',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Segarkan',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required DateTime selectedDate,
    required DateTime now,
    required int episodeCount,
  }) {
    final title = ScheduleDateHelper.sectionHeaderTitle(selectedDate, now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$episodeCount episode',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (_onlyReminders) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 15,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Hanya Pengingat · ${_remindedKeys.length} aktif',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSingleColumnTimelineSliver({
    required List<ScheduleEntry> entries,
    required DateTime now,
    required double contentPadding,
  }) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: contentPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildScheduleCard(
            entry: entries[index],
            now: now,
            isLastInColumn: index == entries.length - 1,
            showTimelineRail: true,
          ),
          childCount: entries.length,
        ),
      ),
    );
  }

  Widget _buildTwoColumnGridSliver({
    required List<ScheduleEntry> entries,
    required DateTime now,
    required double contentPadding,
  }) {
    final rowCount = (entries.length + 1) ~/ 2;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: contentPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, rowIndex) {
            final leftIndex = rowIndex * 2;
            final rightIndex = leftIndex + 1;
            final leftEntry = entries[leftIndex];
            final rightEntry =
                rightIndex < entries.length ? entries[rightIndex] : null;
            final isLastRow = rowIndex == rowCount - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLastRow ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildScheduleCard(
                      entry: leftEntry,
                      now: now,
                      isLastInColumn: true,
                      showTimelineRail: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: rightEntry != null
                        ? _buildScheduleCard(
                            entry: rightEntry,
                            now: now,
                            isLastInColumn: true,
                            showTimelineRail: false,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
          childCount: rowCount,
        ),
      ),
    );
  }

  Widget _buildScheduleCard({
    required ScheduleEntry entry,
    required DateTime now,
    required bool isLastInColumn,
    required bool showTimelineRail,
  }) {
    return ScheduleTimelineCard(
      entry: entry,
      now: now,
      isReminded: _isReminded(entry),
      isLastInColumn: isLastInColumn,
      showTimelineRail: showTimelineRail,
      onTap: () => widget.onAnimeTap?.call(entry.toAnimeItem()),
      onReminderToggle: () => _toggleReminder(entry),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat jadwal anime...',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(double contentPadding) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 40,
          horizontal: contentPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat jadwal tayang anime.',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Periksa koneksi internet Anda lalu coba muat ulang.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadSchedule(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(132, 44),
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required DateTime selectedDate,
    required DateTime today,
  }) {
    final isReminderFilter = _onlyReminders;
    final isSelectedToday =
        ScheduleDateHelper.dateKey(selectedDate) ==
        ScheduleDateHelper.dateKey(today);

    final IconData icon;
    final String message;
    final String actionLabel;
    final VoidCallback onAction;

    if (isReminderFilter) {
      icon = Icons.notifications_off_outlined;
      message = _remindedKeys.isEmpty
          ? 'Belum ada anime yang diingatkan.'
          : 'Tidak ada pengingat pada hari ini.';
      actionLabel = 'Reset Filter';
      onAction = () {
        setState(() {
          _onlyReminders = false;
        });
      };
    } else {
      icon = Icons.calendar_today_rounded;
      message = 'Tidak ada jadwal tayang pada hari ini.';
      if (isSelectedToday) {
        actionLabel = 'Muat Ulang';
        onAction = () => _loadSchedule(forceRefresh: true);
      } else {
        actionLabel = 'Kembali ke Hari Ini';
        onAction = () {
          setState(() {
            _selectedDate = today;
          });
        };
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 44),
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                actionLabel,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
