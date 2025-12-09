import 'dart:ui';
import 'package:flutter/material.dart';
import '../pages/subscribe_page.dart';
import '../services/subscription_service.dart';

/// Wrapper widget that shows premium upgrade modal for non-premium users
/// Supports optional blur preview to show users what they're missing
class PremiumSectionWrapper extends StatelessWidget {
  /// The section title (e.g., "Adverse Reactions")
  final String sectionTitle;

  /// Whether the user has premium access
  final bool isPremium;

  /// Optional callback when upgrade button is tapped
  final VoidCallback? onUpgradeTap;

  /// Optional preview content to show blurred for non-premium users
  final Widget? previewContent;

  /// Which tier unlocks this feature (defaults to SmartFiltering)
  final SubscriptionTier requiredTier;

  /// Optional description of what's behind the paywall
  final String? featureDescription;

  const PremiumSectionWrapper({
    super.key,
    required this.sectionTitle,
    required this.isPremium,
    this.onUpgradeTap,
    this.previewContent,
    this.requiredTier = SubscriptionTier.smartFiltering,
    this.featureDescription,
  });

  String _getTierName() {
    switch (requiredTier) {
      case SubscriptionTier.recallMatch:
        return 'RecallMatch';
      case SubscriptionTier.smartFiltering:
        return 'SmartFiltering';
      case SubscriptionTier.free:
        return 'Free';
    }
  }

  String _getTierPrice() {
    switch (requiredTier) {
      case SubscriptionTier.recallMatch:
        return '\$4.99/month';
      case SubscriptionTier.smartFiltering:
        return '\$1.99/month';
      case SubscriptionTier.free:
        return 'Free';
    }
  }

  Color _getTierColor() {
    switch (requiredTier) {
      case SubscriptionTier.recallMatch:
        return const Color(0xFFFFD700); // Gold
      case SubscriptionTier.smartFiltering:
        return const Color(0xFF64B5F6); // Blue
      case SubscriptionTier.free:
        return const Color(0xFF4CAF50); // Green
    }
  }

  void _showUpgradeModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_open, color: _getTierColor(), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Unlock Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTierColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getTierColor(), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      requiredTier == SubscriptionTier.recallMatch
                          ? Icons.star
                          : Icons.filter_list,
                      color: _getTierColor(),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getTierName(),
                      style: TextStyle(
                        color: _getTierColor(),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                featureDescription ??
                    'Upgrade to ${_getTierName()} to view $sectionTitle and other premium details.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _getTierPrice(),
                style: TextStyle(
                  color: _getTierColor(),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Maybe Later',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onUpgradeTap != null) {
                  onUpgradeTap!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscribePage(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getTierColor(),
                foregroundColor: requiredTier == SubscriptionTier.recallMatch
                    ? Colors.black
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upgrade Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      // Premium user - return nothing (accordion will be built normally by parent)
      return const SizedBox.shrink();
    }

    // If preview content is provided, show blurred preview
    if (previewContent != null) {
      return _buildBlurredPreview(context);
    }

    // Default: show locked button with lock icon
    return _buildLockedButton(context);
  }

  /// Build a blurred preview of the content with a lock overlay
  Widget _buildBlurredPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // Blurred preview content
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.6,
                  child: previewContent,
                ),
              ),
            ),
          ),
          // Lock overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _showUpgradeModal(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getTierColor().withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Unlock with ${_getTierName()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the locked button (default locked state without preview)
  Widget _buildLockedButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C), // Darker background for locked state
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _getTierColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showUpgradeModal(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              // Lock icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTierColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock,
                  color: _getTierColor(),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_getTierName()} feature',
                      style: TextStyle(
                        color: _getTierColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Tier badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTierColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Upgrade',
                  style: TextStyle(
                    color: requiredTier == SubscriptionTier.recallMatch
                        ? Colors.black
                        : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alternative minimal lock badge for smaller sections
class PremiumLockBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final SubscriptionTier requiredTier;

  const PremiumLockBadge({
    super.key,
    this.onTap,
    this.requiredTier = SubscriptionTier.smartFiltering,
  });

  Color _getTierColor() {
    switch (requiredTier) {
      case SubscriptionTier.recallMatch:
        return const Color(0xFFFFD700);
      case SubscriptionTier.smartFiltering:
        return const Color(0xFF64B5F6);
      case SubscriptionTier.free:
        return const Color(0xFF4CAF50);
    }
  }

  String _getTierName() {
    switch (requiredTier) {
      case SubscriptionTier.recallMatch:
        return 'RecallMatch';
      case SubscriptionTier.smartFiltering:
        return 'Premium';
      case SubscriptionTier.free:
        return 'Free';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscribePage(),
              ),
            );
          },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getTierColor(),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _getTierColor().withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              color: requiredTier == SubscriptionTier.recallMatch
                  ? Colors.black
                  : Colors.white,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              _getTierName(),
              style: TextStyle(
                color: requiredTier == SubscriptionTier.recallMatch
                    ? Colors.black
                    : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline premium feature indicator - shows what tier is needed
class PremiumTierBadge extends StatelessWidget {
  final SubscriptionTier tier;
  final bool showIcon;

  const PremiumTierBadge({
    super.key,
    required this.tier,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = tier == SubscriptionTier.recallMatch
        ? const Color(0xFFFFD700)
        : const Color(0xFF64B5F6);

    final name = tier == SubscriptionTier.recallMatch
        ? 'RecallMatch'
        : 'SmartFiltering';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              tier == SubscriptionTier.recallMatch
                  ? Icons.star
                  : Icons.filter_list,
              color: color,
              size: 10,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
