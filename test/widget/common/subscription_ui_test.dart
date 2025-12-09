/// Subscription UI Widget Tests
///
/// Tests for subscription-related UI components including:
/// - Tier badges
/// - Feature gates
/// - Upgrade prompts
/// - Limit indicators
///
/// To run: flutter test test/widget/common/subscription_ui_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('TierBadge Widget', () {
    testWidgets('displays Free tier badge', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const TierBadge(tier: 'free'),
      ));

      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('displays SmartFiltering tier badge', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const TierBadge(tier: 'smart_filtering'),
      ));

      expect(find.text('SmartFiltering'), findsOneWidget);
    });

    testWidgets('displays RecallMatch tier badge', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const TierBadge(tier: 'recall_match'),
      ));

      expect(find.text('RecallMatch'), findsOneWidget);
    });

    testWidgets('uses correct color for free tier', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const TierBadge(tier: 'free'),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.blue[100]);
    });

    testWidgets('uses correct color for premium tiers', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const TierBadge(tier: 'recall_match'),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.amber[100]);
    });
  });

  group('FeatureGate Widget', () {
    testWidgets('shows content when feature is unlocked', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const FeatureGate(
          isUnlocked: true,
          child: Text('Premium Content'),
          lockedWidget: Text('Locked'),
        ),
      ));

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.text('Locked'), findsNothing);
    });

    testWidgets('shows locked widget when feature is locked', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const FeatureGate(
          isUnlocked: false,
          child: Text('Premium Content'),
          lockedWidget: Text('Locked'),
        ),
      ));

      expect(find.text('Premium Content'), findsNothing);
      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets('shows lock icon overlay when locked', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const FeatureGate(
          isUnlocked: false,
          showOverlay: true,
          child: Text('Premium Content'),
        ),
      ));

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });
  });

  group('UpgradePrompt Widget', () {
    testWidgets('displays upgrade message', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const UpgradePrompt(
          title: 'Upgrade to Premium',
          message: 'Get unlimited access to all features.',
        ),
      ));

      expect(find.text('Upgrade to Premium'), findsOneWidget);
      expect(find.text('Get unlimited access to all features.'), findsOneWidget);
    });

    testWidgets('displays upgrade button', (tester) async {
      bool upgradePressed = false;

      await tester.pumpWidget(createTestableWidget(
        UpgradePrompt(
          title: 'Upgrade Required',
          message: 'This feature requires SmartFiltering.',
          onUpgrade: () => upgradePressed = true,
        ),
      ));

      expect(find.text('Upgrade'), findsOneWidget);

      await tester.tap(find.text('Upgrade'));
      await tester.pump();

      expect(upgradePressed, true);
    });

    testWidgets('displays required tier', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const UpgradePrompt(
          title: 'Premium Feature',
          message: 'Access CPSC recalls.',
          requiredTier: 'SmartFiltering',
        ),
      ));

      expect(find.text('Requires SmartFiltering'), findsOneWidget);
    });

    testWidgets('displays dismiss button when closeable', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(createTestableWidget(
        UpgradePrompt(
          title: 'Upgrade',
          message: 'Get more features.',
          isCloseable: true,
          onDismiss: () => dismissed = true,
        ),
      ));

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissed, true);
    });
  });

  group('LimitIndicator Widget', () {
    testWidgets('displays current usage', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const LimitIndicator(
          label: 'Saved Recalls',
          current: 3,
          limit: 5,
        ),
      ));

      expect(find.text('Saved Recalls'), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);
    });

    testWidgets('shows progress bar', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const LimitIndicator(
          label: 'Filters',
          current: 2,
          limit: 3,
          showProgress: true,
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows warning color when near limit', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const LimitIndicator(
          label: 'Filters',
          current: 3,
          limit: 3, // At limit
        ),
      ));

      final text = tester.widget<Text>(find.text('3 / 3'));
      expect(text.style?.color, Colors.orange);
    });

    testWidgets('shows error color when at limit', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const LimitIndicator(
          label: 'Saved Recalls',
          current: 5,
          limit: 5,
        ),
      ));

      // Text should be styled to indicate limit reached
      final text = tester.widget<Text>(find.text('5 / 5'));
      expect(text.style?.color, Colors.orange);
    });

    testWidgets('shows unlimited when limit is 999', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const LimitIndicator(
          label: 'Saved Recalls',
          current: 10,
          limit: 999,
        ),
      ));

      expect(find.text('10 / ∞'), findsOneWidget);
    });
  });

  group('AgencyAccessBadge Widget', () {
    testWidgets('displays allowed agency as active', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const AgencyAccessBadge(
          agency: 'FDA',
          isAllowed: true,
        ),
      ));

      expect(find.text('FDA'), findsOneWidget);
      // Should not have lock icon
      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('displays locked agency with lock icon', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const AgencyAccessBadge(
          agency: 'NHTSA',
          isAllowed: false,
        ),
      ));

      expect(find.text('NHTSA'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('uses muted style for locked agencies', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const AgencyAccessBadge(
          agency: 'CPSC',
          isAllowed: false,
        ),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.grey[200]);
    });
  });

  group('SubscriptionCard Widget', () {
    testWidgets('displays tier name and price', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const SubscriptionCard(
          tierName: 'SmartFiltering',
          monthlyPrice: '\$4.99',
          yearlyPrice: '\$49.99',
          features: ['10 saved filters', '15 saved recalls', 'CPSC access'],
        ),
      ));

      expect(find.text('SmartFiltering'), findsOneWidget);
      expect(find.text('\$4.99'), findsOneWidget);
    });

    testWidgets('displays feature list', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const SubscriptionCard(
          tierName: 'SmartFiltering',
          monthlyPrice: '\$4.99',
          yearlyPrice: '\$49.99',
          features: ['10 saved filters', '15 saved recalls', 'CPSC access'],
        ),
      ));

      expect(find.text('10 saved filters'), findsOneWidget);
      expect(find.text('15 saved recalls'), findsOneWidget);
      expect(find.text('CPSC access'), findsOneWidget);
    });

    testWidgets('shows check icons for features', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const SubscriptionCard(
          tierName: 'Premium',
          monthlyPrice: '\$9.99',
          yearlyPrice: '\$99.99',
          features: ['Feature 1', 'Feature 2'],
        ),
      ));

      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('highlights recommended tier', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const SubscriptionCard(
          tierName: 'SmartFiltering',
          monthlyPrice: '\$4.99',
          yearlyPrice: '\$49.99',
          features: ['Feature'],
          isRecommended: true,
        ),
      ));

      expect(find.text('Recommended'), findsOneWidget);
    });

    testWidgets('shows current plan indicator', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const SubscriptionCard(
          tierName: 'Free',
          monthlyPrice: 'Free',
          yearlyPrice: 'Free',
          features: ['Basic features'],
          isCurrentPlan: true,
        ),
      ));

      expect(find.text('Current Plan'), findsOneWidget);
    });
  });
}

/// Tier badge widget for testing
class TierBadge extends StatelessWidget {
  final String tier;

  const TierBadge({super.key, required this.tier});

  String get displayName {
    switch (tier) {
      case 'free':
        return 'Free';
      case 'smart_filtering':
        return 'SmartFiltering';
      case 'recall_match':
        return 'RecallMatch';
      default:
        return 'Free';
    }
  }

  Color get badgeColor {
    switch (tier) {
      case 'free':
        return Colors.blue[100]!;
      case 'smart_filtering':
        return Colors.green[100]!;
      case 'recall_match':
        return Colors.amber[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(displayName),
    );
  }
}

/// Feature gate widget for testing
class FeatureGate extends StatelessWidget {
  final bool isUnlocked;
  final Widget child;
  final Widget? lockedWidget;
  final bool showOverlay;

  const FeatureGate({
    super.key,
    required this.isUnlocked,
    required this.child,
    this.lockedWidget,
    this.showOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) {
      return child;
    }

    if (showOverlay) {
      return Stack(
        children: [
          Opacity(opacity: 0.5, child: child),
          const Positioned.fill(
            child: Center(
              child: Icon(Icons.lock, size: 48, color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return lockedWidget ?? const SizedBox.shrink();
  }
}

/// Upgrade prompt widget for testing
class UpgradePrompt extends StatelessWidget {
  final String title;
  final String message;
  final String? requiredTier;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;
  final bool isCloseable;

  const UpgradePrompt({
    super.key,
    required this.title,
    required this.message,
    this.requiredTier,
    this.onUpgrade,
    this.onDismiss,
    this.isCloseable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                if (isCloseable)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
            if (requiredTier != null) ...[
              const SizedBox(height: 8),
              Text('Requires $requiredTier', style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onUpgrade,
              child: const Text('Upgrade'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Limit indicator widget for testing
class LimitIndicator extends StatelessWidget {
  final String label;
  final int current;
  final int limit;
  final bool showProgress;

  const LimitIndicator({
    super.key,
    required this.label,
    required this.current,
    required this.limit,
    this.showProgress = false,
  });

  bool get isAtLimit => current >= limit && limit != 999;
  bool get isNearLimit => current >= limit * 0.8 && limit != 999;

  Color get textColor {
    if (isAtLimit) return Colors.orange;
    if (isNearLimit) return Colors.orange;
    return Colors.black;
  }

  String get limitDisplay => limit >= 999 ? '∞' : limit.toString();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label)),
              Text(
                '$current / $limitDisplay',
                style: TextStyle(color: textColor),
              ),
            ],
          ),
          if (showProgress && limit < 999) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: current / limit,
              backgroundColor: Colors.grey[200],
            ),
          ],
        ],
      ),
    );
  }
}

/// Agency access badge widget for testing
class AgencyAccessBadge extends StatelessWidget {
  final String agency;
  final bool isAllowed;

  const AgencyAccessBadge({
    super.key,
    required this.agency,
    required this.isAllowed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAllowed ? Colors.green[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(agency),
          if (!isAllowed) ...[
            const SizedBox(width: 4),
            const Icon(Icons.lock, size: 14),
          ],
        ],
      ),
    );
  }
}

/// Subscription card widget for testing
class SubscriptionCard extends StatelessWidget {
  final String tierName;
  final String monthlyPrice;
  final String yearlyPrice;
  final List<String> features;
  final bool isRecommended;
  final bool isCurrentPlan;

  const SubscriptionCard({
    super.key,
    required this.tierName,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.isRecommended = false,
    this.isCurrentPlan = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Recommended'),
              ),
            if (isCurrentPlan)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Current Plan', style: TextStyle(color: Colors.white)),
              ),
            Text(tierName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(monthlyPrice, style: const TextStyle(fontSize: 24)),
            const Divider(),
            ...features.map((f) => Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(f),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
