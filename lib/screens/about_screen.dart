import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mileage_calculator/utils/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About & Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Creator Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Azizul Islam',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    'Mobile App Developer & Content Creator',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'YouTube: Azizul & Ever',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Features Section
            _buildSectionCard(
              title: 'App Features',
              icon: Icons.star_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(
                    icon: Icons.cloud_sync,
                    title: 'Cloud Synchronization',
                    description:
                        'Automatic data sync across all your devices using Firebase',
                  ),
                  _buildFeatureItem(
                    icon: Icons.offline_bolt,
                    title: 'Offline Support',
                    description: 'Works seamlessly without internet connection',
                  ),
                  _buildFeatureItem(
                    icon: Icons.account_circle,
                    title: 'Google Sign-In',
                    description:
                        'Secure authentication with your Google account',
                  ),
                  _buildFeatureItem(
                    icon: Icons.calculate,
                    title: 'Smart Analytics',
                    description:
                        'Automatic mileage calculation and fuel cost analysis',
                  ),
                  _buildFeatureItem(
                    icon: Icons.history,
                    title: 'Detailed History',
                    description:
                        'Complete fuel tracking history with search and filter',
                  ),
                  _buildFeatureItem(
                    icon: Icons.person_outline,
                    title: 'Guest Mode',
                    description: 'Use the app without creating an account',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Privacy Policy Section
            _buildSectionCard(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPolicyItem(
                    'Data Collection',
                    'FuelBhai collects fuel tracking data you manually enter (fuel amount, cost, mileage) and basic account information (name, email) when you create an account. We use Google Sign-In for secure authentication.',
                  ),
                  _buildPolicyItem(
                    'Data Storage',
                    'Your fuel tracking data is stored both locally on your device and securely in Google Firebase Cloud Firestore. This enables data sync across devices and backup protection.',
                  ),
                  _buildPolicyItem(
                    'Data Security',
                    'All data is encrypted and stored securely using Google Firebase services. Each user can only access their own data. We implement industry-standard security measures to protect your information.',
                  ),
                  _buildPolicyItem(
                    'Data Sharing',
                    'We do not share, sell, or distribute your personal data to any third parties. Your fuel tracking information remains private and is only accessible by you through your authenticated account.',
                  ),
                  _buildPolicyItem(
                    'Authentication',
                    'The app uses Google Sign-In and Firebase Authentication for secure account management. You can also use the app as a guest with local-only data storage.',
                  ),
                  _buildPolicyItem(
                    'Permissions',
                    'The app requires internet permission for data synchronization and Google Sign-In. Local storage permission is used for offline functionality and data caching.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Terms of Use Section
            _buildSectionCard(
              title: 'Terms of Use',
              icon: Icons.description_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPolicyItem(
                    'App Features',
                    'FuelBhai provides fuel consumption tracking, mileage calculation, cost analysis, and data synchronization across devices. The app supports both authenticated users and guest mode.',
                  ),
                  _buildPolicyItem(
                    'Account Management',
                    'Users can create accounts using Google Sign-In for cloud data sync, or use the app as a guest with local-only storage. Account data can be updated through the profile section.',
                  ),
                  _buildPolicyItem(
                    'Data Accuracy',
                    'The app calculates mileage and cost analysis based on the data you provide. Please ensure accurate fuel and mileage entries for reliable calculations.',
                  ),
                  _buildPolicyItem(
                    'Copyright Notice',
                    'FuelBhai app is developed by Azizul Islam. All rights reserved. Unauthorized copying, modification, or distribution of this app is strictly prohibited.',
                  ),
                  _buildPolicyItem(
                    'Disclaimer',
                    'This app is provided "as is" without warranty. The developer is not responsible for any data loss, calculation errors, or device issues. Use at your own risk.',
                  ),
                  _buildPolicyItem(
                    'Updates',
                    'The developer reserves the right to update the app, features, and these terms at any time. Continued use constitutes acceptance of any changes.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact & Support Section
            _buildSectionCard(
              title: 'Contact & Support',
              icon: Icons.support_agent_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For any app-related issues, suggestions, or support:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.email, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => _copyEmailToClipboard(
                                context,
                                'contact.azizulislam@gmail.com',
                              ),
                          child: const Text(
                            'contact.azizulislam@gmail.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap email address to copy to clipboard.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Version & Copyright
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text(
                    'FuelBhai - Smart Fuel Tracker',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version: 1.0.0 (Production Ready)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Features: Cloud Sync • Google Sign-In • Offline Support',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Copyright ©️2025, Azizul & Ever',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All rights reserved.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyEmailToClipboard(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.copy, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Email copied: $email',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
