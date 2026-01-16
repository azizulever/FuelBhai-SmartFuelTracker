import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mileage_calculator/screens/about_screen.dart';
import 'package:mileage_calculator/screens/onboarding_screen.dart';
import 'package:mileage_calculator/screens/privacy_policy_screen.dart';
import 'package:mileage_calculator/screens/terms_conditions_screen.dart';
import 'package:mileage_calculator/screens/contact_support_screen.dart';
import 'package:mileage_calculator/screens/edit_name_screen.dart';
import 'package:mileage_calculator/services/auth_service.dart';
import 'package:mileage_calculator/utils/theme.dart';
import 'package:mileage_calculator/widgets/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
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
          _userName = currentUser.displayName ?? 'Guest User';
          _userEmail = currentUser.email ?? 'guest@fuelbhai.com';
        });
      } else {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _userName = prefs.getString('user_name') ?? 'Guest User';
          _userEmail = prefs.getString('user_email') ?? 'guest@fuelbhai.com';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _userName = 'Guest User';
        _userEmail = 'guest@fuelbhai.com';
      });
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 3),
              ),
              child: ClipOval(
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: primaryColor,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User Name
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // User Email
            Text(
              _userEmail,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
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
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    onTap: _showLogoutDialog,
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
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 22,
                ),
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
