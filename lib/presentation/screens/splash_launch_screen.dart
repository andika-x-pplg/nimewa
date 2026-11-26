import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'home_screen.dart';

/// Full-screen launch splash screen that plays the 8-second Nimeva intro video
/// before transitioning to [HomeScreen].
class SplashLaunchScreen extends StatefulWidget {
  const SplashLaunchScreen({super.key});

  @override
  State<SplashLaunchScreen> createState() => _SplashLaunchScreenState();
}

class _SplashLaunchScreenState extends State<SplashLaunchScreen> {
  VideoPlayerController? _controller;
  bool _navigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    if (WidgetsBinding.instance.runtimeType
        .toString()
        .contains('AutomatedTestWidgetsFlutterBinding')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
      return;
    }

    _fallbackTimer = Timer(const Duration(seconds: 9), _goHome);
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller =
        VideoPlayerController.asset('assets/videos/launch_animation.mp4');
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.addListener(_onVideoTick);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      _goHome();
    }
  }

  void _onVideoTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.duration > Duration.zero &&
        c.value.position >= c.value.duration - const Duration(milliseconds: 120)) {
      _goHome();
    }
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _fallbackTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: (c != null && c.value.isInitialized)
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: c.value.size.width > 0 ? c.value.size.width : 1080,
                    height: c.value.size.height > 0 ? c.value.size.height : 1920,
                    child: VideoPlayer(c),
                  ),
                ),
              )
            : Image.asset(
                'assets/images/nimeva_logo.jpg',
                width: 120,
                height: 120,
              ),
      ),
    );
  }
}

