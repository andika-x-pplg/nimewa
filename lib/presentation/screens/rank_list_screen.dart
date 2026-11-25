import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/rank_tier.dart';
import '../../data/services/user_profile_repository.dart';
import '../widgets/animated_rank_badge.dart';

/// Screen displaying the user's current level, resetting level EXP bar,
/// cumulative EXP earned, and all 16 rank tiers.
class RankListScreen extends StatefulWidget {
  final UserProfileRepository? profileRepository;

  const RankListScreen({super.key, this.profileRepository});

  @override
  State<RankListScreen> createState() => _RankListScreenState();
}

class _RankListScreenState extends State<RankListScreen> {
  UserProfileRepository get _repo =>
      widget.profileRepository ?? UserProfileRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentRank = _repo.currentRank;
    final currentLevel = _repo.level;
    final barExp = _repo.currentLevelExp;
    final maxBarExp = _repo.expPerLevel;
    final fraction = (barExp / maxBarExp).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: const Text('Rank & Level'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedRankBadge(
                      tier: currentRank,
                      currentLevel: currentLevel,
                      isActive: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progres Level ${RankCatalog.formatNumber(currentLevel)}',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$barExp / $maxBarExp EXP',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: AppColors.borderSubtle,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total EXP terkumpul: ${RankCatalog.formatNumber(_repo.exp)} EXP · +${RankCatalog.formatNumber(currentRank.expPerSecond)} EXP/detik tonton nyata',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Daftar 16 Rank Nimeva',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...RankCatalog.tiers.map(
                (tier) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimatedRankBadge(
                    tier: tier,
                    isActive: tier.tier == currentRank.tier,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

