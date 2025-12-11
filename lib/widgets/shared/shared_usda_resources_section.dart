import 'package:flutter/material.dart';
import '../../pages/resource_card_button.dart';
import 'package:url_launcher/url_launcher.dart';

/// USDA contact information - hardcoded standard values
class UsdaContactInfo {
  static const String hotlineDescription =
      'USDA Meat and Poultry Hotline: 1-888-MPHotline (1-888-674-6854)';
  static const String hotlinePhone = '1-888-674-6854';
  static const String hotlineEmail = 'MPHotline@usda.gov';
  static const String complaintPortalUrl =
      'https://foodcomplaint.fsis.usda.gov/eCCF';
}

class SharedUsdaResourcesSection extends StatelessWidget {
  const SharedUsdaResourcesSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Use hardcoded USDA contact values
    const reportProblemUrl = UsdaContactInfo.complaintPortalUrl;
    const hotlinePhone = UsdaContactInfo.hotlinePhone;
    const hotlineEmail = UsdaContactInfo.hotlineEmail;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'USDA Resources',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ResourceCardButton(
            icon: Icons.language,
            title: 'File Complaint',
            subtitle: reportProblemUrl,
            onTap: () async {
              final url = Uri.parse(reportProblemUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 8),
          ResourceCardButton(
            icon: Icons.phone,
            title: 'Call Hotline',
            subtitle: hotlinePhone,
            onTap: () async {
              // Remove any non-digit characters from phone number for tel: URL
              final cleanPhone = hotlinePhone.replaceAll(RegExp(r'[^0-9]'), '');
              final url = Uri.parse('tel:$cleanPhone');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
          const SizedBox(height: 8),
          ResourceCardButton(
            icon: Icons.email,
            title: 'Email Hotline',
            subtitle: hotlineEmail,
            onTap: () async {
              final url = Uri.parse('mailto:$hotlineEmail');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
        ],
      ),
    );
  }
}
