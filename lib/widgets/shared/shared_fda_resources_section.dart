import 'package:flutter/material.dart';
import '../../pages/resource_card_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedFdaResourcesSection extends StatelessWidget {
  const SharedFdaResourcesSection({super.key});

  @override
  Widget build(BuildContext context) {
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
              'FDA Resources',
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
            subtitle: 'https://www.safetyreporting.hhs.gov/SRP2/',
            onTap: () async {
              final url = Uri.parse(
                'https://www.safetyreporting.hhs.gov/SRP2/',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
