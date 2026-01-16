import 'package:flutter/material.dart';
import 'package:mileage_calculator/utils/theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Terms and Conditions',
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last Updated: August 2025',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(
                'This Privacy Policy describes how TankiBhai ("we," "our, or "us") collects, uses, and protects your information when you use our mobile application.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Data Collection'),
              _buildSection(
                'FuelBhai collects fuel tracking data you manually enter (fuel amount, cost, mileage) and basic account information (name, email) when you create an account. We use Google Sign-In for secure authentication.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Data Storage'),
              _buildSection(
                'Your fuel tracking data is stored both locally on your device and securely in Google Firebase Cloud Firestore. This enables data sync across devices and backup protection.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Data Security'),
              _buildSection(
                'All data is encrypted and stored securely using Google Firebase services. Each user can only access their own data. We implement industry-standard security measures to protect your information.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Data Sharing'),
              _buildSection(
                'We do not share, sell, or distribute your personal data to any third parties. Your fuel tracking information remains private and is only accessible by you through your authenticated account.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Authentication'),
              _buildSection(
                'The app uses Google Sign-In and Firebase Authentication for secure account management. You can also use the app as a guest with local-only data storage.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Permissions'),
              _buildSection(
                'The app requires internet permission for data synchronization and Google Sign-In. Local storage permission is used for offline functionality and data caching.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Data Retention'),
              _buildSection(
                'Your data is retained as long as your account is active. You can delete your account and all associated data at any time through the app settings.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Changes to Privacy Policy'),
              _buildSection(
                'We may update this Privacy Policy from time to time. We will notify users of any changes by posting the new Privacy Policy in the app.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Contact Information'),
              _buildSection(
                'For questions about this Privacy Policy, please contact us at: contact.azizulislam@gmail.com',
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSection(String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
        height: 1.5,
      ),
    );
  }
}
