import 'package:flutter/material.dart';
import '../../pages/resource_card_button.dart';
import '../../models/recall_data.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedCpscResourcesSection extends StatelessWidget {
  final RecallData? recall;

  const SharedCpscResourcesSection({super.key, this.recall});

  @override
  Widget build(BuildContext context) {
    // CPSC resource URLs
    const reportProblemUrl = 'https://www.saferproducts.gov/CPSCUnsafeProductReport';
    const cpscWebsiteUrl = 'https://www.cpsc.gov';
    const hotlinePhone = '1-800-638-2772';

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
              'CPSC Resources',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ResourceCardButton(
            icon: Icons.report_problem,
            title: 'Report Product Safety Problem',
            subtitle: 'SaferProducts.gov',
            onTap: () async {
              final url = Uri.parse(reportProblemUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 8),
          ResourceCardButton(
            icon: Icons.language,
            title: 'CPSC Website',
            subtitle: cpscWebsiteUrl,
            onTap: () async {
              final url = Uri.parse(cpscWebsiteUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 8),
          ResourceCardButton(
            icon: Icons.phone,
            title: 'CPSC Hotline',
            subtitle: '$hotlinePhone (TTY 301-595-7054)',
            onTap: () async {
              // Remove any non-digit characters from phone number for tel: URL
              final cleanPhone = hotlinePhone.replaceAll(RegExp(r'[^0-9]'), '');
              final url = Uri.parse('tel:$cleanPhone');
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
