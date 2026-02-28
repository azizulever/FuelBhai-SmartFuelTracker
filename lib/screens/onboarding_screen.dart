import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/screens/auth/login_screen.dart';
import 'package:mileage_calculator/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.to.logScreenView('OnboardingScreen');
  }

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      svgAsset: 'assets/svgs/welcome-screen-1.svg',
      title: 'Save Fuel, Save Money',
      description:
          'Analyze your driving habits, optimize fuel consumption, and reduce fuel expenses effortlessly.',
    ),
    OnboardingPage(
      svgAsset: 'assets/svgs/welcome-screen-2.svg',
      title: 'Track Your Fuel Usage',
      description:
          'Monitor every liter you fill. Stay in control of your vehicle\'s fuel usage for both bikes and cars.',
    ),
    OnboardingPage(
      svgAsset: 'assets/svgs/welcome-screen-3.svg',
      title: 'Calculate Mileage & Efficiency',
      description:
          'Get accurate mileage reports with distance covered, fuel used, and cost per liter — all in one place.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Get.off(() => const LoginScreen());
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 12),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPageContent(_pages[index]);
                },
              ),
            ),

            // Page indicator and next button - with more spacing
            Padding(
              padding: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Next/Get Started button
                  _buildNextButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.01),

          // SVG Illustration - more space for the image
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SvgPicture.asset(
                  page.svgAsset,
                  fit: BoxFit.contain,
                  placeholderBuilder:
                      (context) =>
                          const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.04),

          // Title - cleaner typography
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1F1F),
              height: 1.3,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 18),

          // Description - lighter and more readable
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              page.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.6,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: screenHeight * 0.025),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: isActive ? 36 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildNextButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth * 0.19;
    final innerButtonSize = screenWidth * 0.16;

    // Calculate progress based on current page (0.33, 0.66, 1.0)
    final double progress = (_currentPage + 1) / _pages.length;

    return GestureDetector(
      onTap: _nextPage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer progress ring
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              tween: Tween<double>(begin: 0, end: progress),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 3,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2563EB),
                  ),
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
          // Inner button
          Container(
            width: innerButtonSize,
            height: innerButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2563EB),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String svgAsset;
  final String title;
  final String description;

  OnboardingPage({
    required this.svgAsset,
    required this.title,
    required this.description,
  });
}
