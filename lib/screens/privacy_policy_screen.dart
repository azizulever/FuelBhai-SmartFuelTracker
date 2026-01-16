import 'package:flutter/material.dart';
import 'package:mileage_calculator/utils/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Privacy and Policy',
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
                'Last Updated: January 16, 2026',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(
                'Welcome to FuelBhai! This Privacy Policy explains how we collect, use, store, and protect your personal information when you use our fuel tracking mobile application. By using FuelBhai, you agree to the practices described in this policy.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('1. Information We Collect'),
              _buildSection(
                'We collect the following types of information:\n\n• Personal Information: When you create an account, we collect your name and email address through Google Sign-In authentication.\n\n• Fuel Tracking Data: Information you manually enter including fuel amount, fuel cost, mileage readings, odometer readings, and refueling dates.\n\n• Vehicle Information: Data about your vehicles including vehicle type (bike or car) and service records.\n\n• Trip Data: Trip duration, distance, and associated costs when you use trip tracking features.\n\n• Device Information: Device type, operating system version, and app usage analytics for improving app performance.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('2. How We Use Your Information'),
              _buildSection(
                'Your information is used to:\n\n• Provide and maintain the fuel tracking service\n• Calculate mileage, fuel efficiency, and cost analytics\n• Sync your data across multiple devices\n• Send notifications about trips and service reminders\n• Authenticate your account and ensure security\n• Improve app functionality and user experience\n• Provide customer support when requested\n\nWe never use your personal data for advertising or marketing purposes.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('3. Data Storage and Security'),
              _buildSection(
                'Your data is stored both locally on your device and securely in Google Firebase Cloud Firestore. We implement industry-standard security measures including:\n\n• End-to-end encryption for data transmission\n• Secure authentication via Google Sign-In and Firebase Authentication\n• Regular security audits and updates\n• Access controls ensuring you alone can access your data\n• Automatic backups for data recovery\n\nLocal storage enables offline functionality, while cloud storage ensures your data is backed up and accessible across devices.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('4. Data Sharing and Third Parties'),
              _buildSection(
                'We respect your privacy and do not sell, rent, or share your personal information with third parties for their marketing purposes. We only share data with:\n\n• Google Firebase: For secure cloud storage and authentication (governed by Google\'s privacy policy)\n• Service providers who help us operate the app, bound by confidentiality agreements\n\nWe may disclose information if required by law or to protect our rights and user safety.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('5. Your Rights and Choices'),
              _buildSection(
                'You have the right to:\n\n• Access your personal data at any time\n• Update or correct your information through the app\n• Delete your account and all associated data\n• Export your fuel tracking data\n• Use the app as a guest with local-only storage\n• Opt out of notifications in app settings\n\nTo exercise these rights, access the settings menu in the app or contact us directly.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('6. Permissions'),
              _buildSection(
                'The app requests the following permissions:\n\n• Internet Access: For data synchronization, Google Sign-In, and cloud backup\n• Storage: For local data caching and offline functionality\n• Location (optional): For trip tracking features and nearby fuel station search\n• Notifications: For trip reminders and service alerts\n\nYou can manage these permissions in your device settings.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('7. Data Retention'),
              _buildSection(
                'We retain your data as long as your account remains active. If you delete your account, all personal information and fuel tracking data will be permanently removed from our servers within 30 days. Local data on your device can be cleared by uninstalling the app.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('8. Children\'s Privacy'),
              _buildSection(
                'FuelBhai is not intended for users under 13 years of age. We do not knowingly collect personal information from children. If you believe we have collected data from a child, please contact us immediately.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('9. Cookies and Tracking'),
              _buildSection(
                'We use minimal tracking technologies to improve app performance and user experience. Firebase Analytics may collect anonymized usage data. You can disable analytics in the app settings.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('10. Changes to This Policy'),
              _buildSection(
                'We may update this Privacy Policy periodically to reflect changes in our practices or legal requirements. We will notify you of significant changes through in-app notifications or email. The "Last Updated" date indicates when changes were made. Continued use of the app after updates constitutes acceptance of the revised policy.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('11. Contact Us'),
              _buildSection(
                'If you have questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact us at:\n\nEmail: contact.azizulislam@gmail.com\n\nWe aim to respond to all inquiries within 48 hours.',
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
