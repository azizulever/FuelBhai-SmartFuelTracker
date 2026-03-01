import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/screens/onboarding_screen.dart';
import 'package:mileage_calculator/screens/privacy_policy_screen.dart';
import 'package:mileage_calculator/screens/terms_conditions_screen.dart';
import 'package:mileage_calculator/screens/contact_support_screen.dart';
import 'package:mileage_calculator/screens/edit_name_screen.dart';
import 'package:mileage_calculator/controllers/mileage_controller.dart';
import 'package:mileage_calculator/services/auth_service.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/widgets/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mileage_calculator/services/analytics_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  final bool showBottomNav;

  const UserProfileScreen({Key? key, this.showBottomNav = true})
    : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _userName = 'Guest User';
  String _userEmail = 'guest@fuelbhai.com';
  late final AuthService _authService;
  bool _isGuest = false;
  bool _isLinkingGoogle = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.to.logScreenView('UserProfileScreen');
    try {
      _authService = Get.find<AuthService>();
    } catch (e) {
      _authService = Get.put(AuthService());
    }
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await currentUser.reload();
        setState(() {
          _isGuest = false;
          _userName = currentUser.displayName ?? 'Guest User';
          _userEmail = currentUser.email ?? 'guest@fuelbhai.com';
        });
      } else {
        final prefs = await SharedPreferences.getInstance();
        final isSkipped = prefs.getBool('skipped_login') ?? false;
        setState(() {
          _isGuest = isSkipped;
          _userName = prefs.getString('user_name') ?? 'Guest User';
          _userEmail =
              isSkipped
                  ? 'Not signed in'
                  : (prefs.getString('user_email') ?? 'guest@fuelbhai.com');
        });
      }
    } catch (e) {
      setState(() {
        _userName = 'Guest User';
        _userEmail = 'guest@fuelbhai.com';
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLinkingGoogle = true);

    try {
      final result = await _authService.signInWithGoogle();
      if (result == 'Success') {
        // Allow sync to complete
        await Future.delayed(const Duration(milliseconds: 1000));

        // Refresh controllers so data is visible immediately
        try {
          MileageGetxController mileageController;
          try {
            mileageController = Get.find<MileageGetxController>();
          } catch (e) {
            mileageController = Get.put(MileageGetxController());
          }
          await mileageController.refreshFromFuelingService();
        } catch (_) {}

        // Reload profile data
        _loadUserData();
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => _isLinkingGoogle = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Get.offAll(() => const MainNavigation(initialIndex: 0));
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Profile Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isGuest ? Colors.orange : primaryColor,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: Icon(
                      _isGuest ? Icons.person_outline : Icons.person,
                      size: 60,
                      color: _isGuest ? Colors.orange : primaryColor,
                    ),
                  ),
                ),
                if (_isGuest)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // User Name
            Text(
              _isGuest ? 'Guest User' : _userName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _isGuest ? Colors.grey[700] : primaryColor,
              ),
            ),

            const SizedBox(height: 6),

            // User Email
            Text(
              _userEmail,
              style: TextStyle(
                fontSize: 14,
                color: _isGuest ? Colors.orange[700] : Colors.grey[600],
              ),
            ),

            // Guest Mode Banner
            if (_isGuest) ...[const SizedBox(height: 24), _buildGuestBanner()],

            const SizedBox(height: 28),

            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Edit Name — only for signed-in users
                  if (!_isGuest) ...[
                    _buildMenuItem(
                      icon: Icons.edit_outlined,
                      title: 'Edit Name',
                      onTap: () async {
                        final result = await Get.to(
                          () => EditNameScreen(currentName: _userName),
                        );
                        if (result != null) {
                          _loadUserData();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Privacy and Policy',
                    onTap: () => Get.to(() => const PrivacyPolicyScreen()),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Terms and Conditions',
                    onTap: () => Get.to(() => const TermsConditionsScreen()),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.support_agent_outlined,
                    title: 'Contact and Support',
                    onTap: () => Get.to(() => const ContactSupportScreen()),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon:
                        _isGuest ? Icons.logout_rounded : Icons.logout_rounded,
                    title: _isGuest ? 'Back to Login' : 'Logout',
                    onTap: _isGuest ? _backToLogin : _showLogoutDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Guest mode banner with sign-in prompt
  Widget _buildGuestBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.05),
              primaryColor.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            // Warning icon & text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Colors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your data is not backed up',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to sync your data to the cloud. Your existing records will be preserved.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sign in with Google button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLinkingGoogle ? null : _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                  ),
                ),
                child:
                    _isLinkingGoogle
                        ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.grey[500],
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/google-icon.svg',
                              height: 22,
                              width: 22,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate back to login/onboarding for guest users
  void _backToLogin() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Go to Login'),
            content: const Text(
              'Your local data will be cleared. Are you sure you want to go back to login?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _authService.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('skipped_login');
                  await prefs.remove('onboarding_completed');
                  Get.offAll(() => const OnboardingScreen());
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _authService.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('skipped_login');
                  await prefs.remove('onboarding_completed');
                  Get.offAll(() => const OnboardingScreen());
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
