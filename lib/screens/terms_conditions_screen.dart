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
                'Last Updated: January 16, 2026',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(
                'Welcome to FuelBhai! These Terms and Conditions ("Terms") govern your use of the FuelBhai mobile application. By downloading, installing, or using this app, you agree to be bound by these Terms. Please read them carefully.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('1. Acceptance of Terms'),
              _buildSection(
                'By accessing or using FuelBhai, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy. If you do not agree to these Terms, please do not use the app.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('2. Description of Service'),
              _buildSection(
                'FuelBhai is a fuel tracking and vehicle management application that allows you to:\n\n• Track fuel consumption and costs\n• Monitor vehicle mileage and fuel efficiency\n• Record service and maintenance activities\n• Track trips and associated expenses\n• Access statistics and analytics about your vehicle usage\n• Sync data across multiple devices\n\nThe app is provided free of charge with optional premium features that may be added in the future.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('3. User Accounts and Registration'),
              _buildSection(
                'Account Creation: You may create an account using Google Sign-In or use the app as a guest with limited features.\n\nAccount Security: You are responsible for maintaining the confidentiality of your account credentials. Notify us immediately of any unauthorized access.\n\nAccurate Information: You agree to provide accurate and current information when creating your account.\n\nAge Requirement: You must be at least 13 years old to use this app. Users under 18 should have parental consent.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('4. Acceptable Use'),
              _buildSection(
                'You agree to use FuelBhai only for lawful purposes. You must not:\n\n• Use the app in any way that violates applicable laws or regulations\n• Attempt to gain unauthorized access to our systems or other users\' accounts\n• Interfere with or disrupt the app\'s functionality\n• Reverse engineer, decompile, or attempt to extract source code\n• Use automated systems to access the app without permission\n• Upload malicious code, viruses, or harmful content\n• Misrepresent yourself or impersonate others\n• Use the app for commercial purposes without authorization',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('5. User Content and Data'),
              _buildSection(
                'Ownership: You retain ownership of all data you enter into the app, including fuel records, trip data, and service information.\n\nLicense: By using the app, you grant us a limited license to store, process, and display your data solely for providing the service.\n\nAccuracy: You are responsible for the accuracy of the data you enter. We are not liable for errors in calculations based on incorrect input.\n\nBackup: While we provide cloud backup, you are encouraged to maintain your own backups of important data.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('6. Intellectual Property'),
              _buildSection(
                'All content, features, and functionality of FuelBhai, including but not limited to design, graphics, text, code, and trademarks, are owned by FuelBhai and protected by copyright and intellectual property laws. You may not copy, modify, distribute, or create derivative works without explicit permission.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('7. Third-Party Services'),
              _buildSection(
                'FuelBhai integrates with third-party services including:\n\n• Google Firebase for authentication and data storage\n• Google Sign-In for user authentication\n• Analytics services for app improvement\n\nYour use of these services is subject to their respective terms and privacy policies. We are not responsible for third-party services or their practices.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('8. Disclaimers and Limitations'),
              _buildSection(
                'No Warranty: The app is provided "as is" and "as available" without warranties of any kind, express or implied. We do not guarantee uninterrupted, error-free, or secure operation.\n\nCalculation Accuracy: While we strive for accuracy, fuel efficiency calculations are estimates based on your input data. Actual results may vary.\n\nNo Professional Advice: FuelBhai does not provide professional mechanical, financial, or vehicle maintenance advice.\n\nData Loss: While we implement backup measures, we are not liable for any data loss. Users should maintain their own backups.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('9. Limitation of Liability'),
              _buildSection(
                'To the maximum extent permitted by law, FuelBhai and its developers shall not be liable for:\n\n• Indirect, incidental, special, or consequential damages\n• Loss of profits, data, or business opportunities\n• Damages arising from use or inability to use the app\n• Errors, interruptions, or security breaches\n• Third-party actions or content\n\nOur total liability shall not exceed the amount you paid for the app (currently zero for free version).',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('10. Subscription and Payments'),
              _buildSection(
                'Currently, FuelBhai is free to use. If we introduce premium features or subscriptions in the future:\n\n• Pricing and payment terms will be clearly communicated\n• Subscriptions may auto-renew unless cancelled\n• Refunds will be subject to our refund policy and app store guidelines\n• Free trial terms will be specified at the time of offer',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('11. Termination'),
              _buildSection(
                'You may terminate your account at any time by deleting it through the app settings. We reserve the right to suspend or terminate accounts that:\n\n• Violate these Terms\n• Engage in fraudulent or abusive behavior\n• Compromise security or other users\' experience\n\nUpon termination, your data will be deleted according to our Privacy Policy, and your right to use the app will cease immediately.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('12. Updates and Modifications'),
              _buildSection(
                'We may update the app periodically to add features, fix bugs, or improve performance. We reserve the right to modify or discontinue any feature at any time. We will make reasonable efforts to notify users of significant changes.\n\nThese Terms may be updated from time to time. Continued use after changes constitutes acceptance of revised Terms.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('13. Governing Law'),
              _buildSection(
                'These Terms are governed by and construed in accordance with applicable laws. Any disputes shall be resolved through good faith negotiation or, if necessary, in appropriate courts.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('14. Severability'),
              _buildSection(
                'If any provision of these Terms is found to be invalid or unenforceable, the remaining provisions shall remain in full force and effect.',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('15. Contact Information'),
              _buildSection(
                'For questions, concerns, or support regarding these Terms or the app, please contact us at:\n\nEmail: contact.azizulislam@gmail.com\n\nWe value your feedback and will respond to inquiries promptly.',
              ),
              const SizedBox(height: 20),
              _buildSection(
                'By using FuelBhai, you acknowledge that you have read and understood these Terms and Conditions and agree to be bound by them. Thank you for choosing FuelBhai!',
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
