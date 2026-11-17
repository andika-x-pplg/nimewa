import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/mock_anime_data.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/empty_continue_watching.dart';
import '../widgets/home_header.dart';
import '../widgets/spotlight_carousel.dart';

/// Main Home Screen for Nimeva.
/// Assembles the HomeHeader, SpotlightCarousel, EmptyContinueWatching,
/// and floating/anchored CustomBottomNavBar with Obsidian & Crimson styling.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
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
      ),
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
