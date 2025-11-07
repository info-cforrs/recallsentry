import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/recall_data.dart';
import '../../models/recommended_product.dart';
import '../premium_section_wrapper.dart';
import '../../services/subscription_service.dart';

class SharedRecommendedProductsAccordion extends StatelessWidget {
  final RecallData recall;
  final bool? isPremiumUser; // Optional override for premium status

  const SharedRecommendedProductsAccordion({
    required this.recall,
    this.isPremiumUser,
    super.key,
  });

  Future<bool> _checkPremiumAccess() async {
    if (isPremiumUser != null) {
      return isPremiumUser!;
    }
    final subscription = await SubscriptionService().getSubscriptionInfo();
    return subscription.hasPremiumAccess;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkPremiumAccess(),
      builder: (context, snapshot) {
        // While loading, show grey locked button by default
        if (snapshot.connectionState == ConnectionState.waiting) {
          return PremiumSectionWrapper(
            sectionTitle: 'Recommended Replacement Items',
            isPremium: false,
          );
        }

        final hasPremium = snapshot.data ?? false;

        // If not premium, show grey locked button
        if (!hasPremium) {
          return PremiumSectionWrapper(
            sectionTitle: 'Recommended Replacement Items',
            isPremium: false,
          );
        }

        // If premium, show normal section
        return _buildSectionContent();
      },
    );
  }

  Widget _buildSectionContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            const Text(
              'Recommended Replacement Items',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            // Content (always shown)
            _buildProductsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    final recommendations = recall.recommendations;

    if (recommendations.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: const Text(
          'No recommended replacement items available for this recall.',
          style: TextStyle(color: Colors.white, fontSize: 15),
          textAlign: TextAlign.left,
        ),
      );
    }

    // Find the most recent verification date
    DateTime mostRecentDate = recommendations.first.lastVerified;
    for (var product in recommendations) {
      if (product.lastVerified.isAfter(mostRecentDate)) {
        mostRecentDate = product.lastVerified;
      }
    }

    // Format date as "Month DD, YYYY"
    final formattedDate = '${_getMonthName(mostRecentDate.month)} ${mostRecentDate.day}, ${mostRecentDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...recommendations.map((product) => _buildProductCard(product)),
        const SizedBox(height: 12),
        Text(
          'These recommended products were verified safe as of $formattedDate.',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _cleanProductTitle(String title) {
    // Remove HTML entities and special characters
    return title
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'[^\x00-\x7F]+'), '') // Remove non-ASCII characters
        .trim();
  }

  Widget _buildProductCard(RecommendedProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B7DA9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final uri = Uri.parse(product.amazonUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Product Image (Left)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.productPhoto,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Product Details (Middle & Right)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Title
                    Text(
                      _cleanProductTitle(product.productTitle),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Bottom Row: Amazon | Rating | Price
                    Row(
                      children: [
                        // Amazon Label
                        const Text(
                          'Amazon',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),

                        // Rating
                        if (product.productRating.isNotEmpty) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            product.productRating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],

                        // Price
                        Text(
                          product.productPrice,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
