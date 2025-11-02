import 'package:flutter/material.dart';
import '../../pages/resource_card_button.dart';
import '../../models/recall_data.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedUsdaResourcesSection extends StatelessWidget {
  final RecallData? recall;

  const SharedUsdaResourcesSection({super.key, this.recall});

  @override
  Widget build(BuildContext context) {
    // Use recall data if available, otherwise use default hardcoded values
    final reportProblemUrl = recall?.usdaToReportAProblem.isNotEmpty == true
        ? recall!.usdaToReportAProblem
        : 'https://foodcomplaint.fsis.usda.gov/eCCF';
    final hotlinePhone = recall?.usdaFoodSafetyQuestionsPhone.isNotEmpty == true
        ? recall!.usdaFoodSafetyQuestionsPhone
        : '1-888-674-6854';
    final hotlineEmail = recall?.usdaFoodSafetyQuestionsEmail.isNotEmpty == true
        ? recall!.usdaFoodSafetyQuestionsEmail
        : 'MPHotline@usda.gov';
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
