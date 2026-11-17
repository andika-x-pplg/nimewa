import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock/mock_anime_data.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/empty_continue_watching.dart';
import '../widgets/home_header.dart';
import '../widgets/spotlight_carousel.dart';
import 'explore_screen.dart';

/// Main Shell Screen for Nimeva.
/// Supports switching between Home, Explore, and other tabs via CustomBottomNavBar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildHomeTab() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            HomeHeader(username: 'dikzzz'),
            SizedBox(height: 8),
            SpotlightCarousel(items: mockPopularAnime),
            SizedBox(height: 20),
            EmptyContinueWatching(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Segera hadir di pembaruan berikutnya.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return const ExploreScreen();
      case 2:
        return _buildPlaceholderTab('Jadwal Tayang Anime', Icons.calendar_month_rounded);
      case 3:
        return _buildPlaceholderTab('Daftar Tonton Saya', Icons.bookmark_rounded);
      case 4:
        return _buildPlaceholderTab('Profil Pengguna', Icons.person_rounded);
      case 0:
      default:
        return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
