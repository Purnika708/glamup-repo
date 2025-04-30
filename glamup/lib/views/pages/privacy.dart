import 'package:flutter/material.dart';
import 'package:glamup/views/components/shared_header.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  Future<void> _sharePolicy() async {
    // await Share.share(
    //   'Check out GlamUp\'s Privacy Policy: https://glamup.com/privacy-policy',
    //   subject: 'GlamUp Privacy Policy',
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SharedHeader(
            title: 'Privacy Policy',
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _sharePolicy,
                tooltip: 'Share Policy',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildPolicyContent(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.pink.shade50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.privacy_tip_outlined,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last Updated: March 1, 2025',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPolicySection(
            context,
            title: 'Introduction',
            content: 'GlamUp ("we", "our", or "us") respects your privacy and is committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data when you visit our website or use our mobile application (collectively, "Services") and tell you about your privacy rights and how the law protects you.\n\nThis privacy policy aims to give you information on how we collect and process your personal data through your use of our Services, including any data you may provide when you sign up for an account, purchase a product, or take part in a promotion.',
          ),
          
          _buildPolicySection(
            context,
            title: 'Information We Collect',
            content: 'We may collect, use, store and transfer different kinds of personal data about you, including:\n\n'
                '• Identity Data: First name, last name, username, gender\n'
                '• Contact Data: Billing address, delivery address, email address, phone numbers\n'
                '• Financial Data: Payment card details (processed securely through our payment processors)\n'
                '• Transaction Data: Details about payments and products you have purchased\n'
                '• Technical Data: IP address, browser type, device information\n'
                '• Profile Data: Your purchases, preferences, feedback and survey responses\n'
                '• Usage Data: Information about how you use our website and app\n'
                '• Marketing Data: Your preferences in receiving marketing from us',
          ),
          
          _buildPolicySection(
            context,
            title: 'How We Use Your Information',
            content: 'We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:\n\n'
                '• To process and deliver your order\n'
                '• To manage your relationship with us\n'
                '• To enable you to participate in features of our Services\n'
                '• To administer and protect our business and Services\n'
                '• To deliver relevant content and advertisements to you\n'
                '• To use data analytics to improve our Services\n'
                '• To make suggestions and recommendations to you about goods or services',
          ),
          
          _buildPolicySection(
            context,
            title: 'Disclosure of Your Information',
            content: 'We may share your personal data with the parties set out below for the purposes set out in this privacy policy:\n\n'
                '• Service providers who provide IT and system administration services\n'
                '• Professional advisers including lawyers, bankers, auditors and insurers\n'
                '• Tax authorities, regulators and other authorities who require reporting of processing activities\n'
                '• Third parties to whom we may choose to sell, transfer, or merge parts of our business\n\n'
                'We require all third parties to respect the security of your personal data and to treat it in accordance with the law.',
          ),
          
          _buildPolicySection(
            context,
            title: 'Data Security',
            content: 'We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way, altered or disclosed. In addition, we limit access to your personal data to those employees, agents, contractors and other third parties who have a business need to know.\n\n'
                'We have put in place procedures to deal with any suspected personal data breach and will notify you and any applicable regulator of a breach where we are legally required to do so.',
          ),
          
          _buildPolicySection(
            context,
            title: 'Data Retention',
            content: 'We will only retain your personal data for as long as necessary to fulfill the purposes we collected it for, including for the purposes of satisfying any legal, accounting, or reporting requirements.\n\n'
                'To determine the appropriate retention period for personal data, we consider the amount, nature, and sensitivity of the data, the potential risk of harm from unauthorized use or disclosure, the purposes for which we process your data and whether we can achieve those purposes through other means, and the applicable legal requirements.',
          ),
          
          _buildPolicySection(
            context,
            title: 'Your Legal Rights',
            content: 'Under certain circumstances, you have rights under data protection laws in relation to your personal data, including the right to:\n\n'
                '• Request access to your personal data\n'
                '• Request correction of your personal data\n'
                '• Request erasure of your personal data\n'
                '• Object to processing of your personal data\n'
                '• Request restriction of processing your personal data\n'
                '• Request transfer of your personal data\n'
                '• Right to withdraw consent\n\n'
                'If you wish to exercise any of these rights, please contact us.',
          ),
          
          _buildPolicySection(
            context,
            title: 'Changes to This Privacy Policy',
            content: 'We may update our privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page and updating the "Last Updated" date at the top of this policy.\n\n'
                'You are advised to review this privacy policy periodically for any changes. Changes to this privacy policy are effective when they are posted on this page.',
          ),
          
          _buildPolicySection(
            context,
            title: 'Contact Us',
            content: 'If you have any questions about this privacy policy or our privacy practices, please contact us at:\n\n'
                'Email: privacy@glamup.com\n'
                'Phone: +977 92892928928929\n'
                'Address: GlamUp Headquarters, 123 Beauty Street, Fashion District, Pokhara Nepal',
            isLast: true,
          ),
          
          const SizedBox(height: 40),
          
          Center(
            child: OutlinedButton.icon(
              onPressed: _sharePolicy,
              icon: const Icon(Icons.share),
              label: const Text('Share Privacy Policy'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPolicySection(
    BuildContext context, {
    required String title,
    required String content,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        if (!isLast) const Divider(height: 32, thickness: 1),
      ],
    );
  }
}