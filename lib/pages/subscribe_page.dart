import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main_navigation.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../widgets/subscription_paywall.dart';
import '../widgets/recallmatch_paywall.dart';
import '../mixins/hide_on_scroll_mixin.dart';
import '../providers/data_providers.dart';
import '../services/subscription_service.dart';

class SubscribePage extends ConsumerStatefulWidget {
  const SubscribePage({super.key});

  @override
  ConsumerState<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends ConsumerState<SubscribePage> with HideOnScrollMixin {
  final int _currentIndex = 2; // Settings tab

  @override
  void initState() {
    super.initState();
    initHideOnScroll();
  }

  @override
  void dispose() {
    disposeHideOnScroll();
    super.dispose();
  }

  String _getTierDisplayName(SubscriptionTier? tier) {
    switch (tier) {
      case SubscriptionTier.smartFiltering:
        return 'SmartFilter';
      case SubscriptionTier.recallMatch:
        return 'RecallMatch';
      case SubscriptionTier.free:
      default:
        return 'Free';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch subscription info
    final subscriptionAsync = ref.watch(subscriptionInfoProvider);
    final subscriptionInfo = subscriptionAsync.maybeWhen(
      data: (info) => info,
      orElse: () => null,
    );

    final isFreePlan = subscriptionInfo?.tier == SubscriptionTier.free || subscriptionInfo == null;
    final isSmartFilterPlan = subscriptionInfo?.tier == SubscriptionTier.smartFiltering;
    final isRecallMatchPlan = subscriptionInfo?.tier == SubscriptionTier.recallMatch;

    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Dark blue background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with App Icon and Subscribe Text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // App Icon
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      'assets/images/shield_logo4.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Subscribe Text
                  const Text(
                    'Subscribe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Atlanta',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: hideOnScrollController,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Plan Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Plan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTierDisplayName(subscriptionInfo?.tier),
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Free Plan Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: isFreePlan ? Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 3,
                        ) : null,
                        boxShadow: [
                          BoxShadow(
                            color: isFreePlan
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.1),
                            blurRadius: isFreePlan ? 12 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B7DA9), // Blue header
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isFreePlan ? 13 : 16),
                                topRight: Radius.circular(isFreePlan ? 13 : 16),
                              ),
                            ),
                            child: Column(
                              children: [
                                if (isFreePlan)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'CURRENT PLAN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                const Text(
                                  'Free',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'All FDA and USDA recalls',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content section
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '\$',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Text(
                                      '0',
                                      style: TextStyle(
                                        fontSize: 60,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        height: 1.0,
                                      ),
                                    ),
                                    const Text(
                                      '00',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'Monthly',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Features List
                                _buildFeatureItem(
                                  'Real-time alerts from FDA & USDA',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Save up to 5 recalls',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Filter by 1 state',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Basic recall information',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Last 30 days of recall history',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // SmartFiltering Plan Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: isSmartFilterPlan ? Border.all(
                          color: const Color(0xFF4CAF50),
                          width: 3,
                        ) : null,
                        boxShadow: [
                          BoxShadow(
                            color: isSmartFilterPlan
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.1),
                            blurRadius: isSmartFilterPlan ? 12 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B7DA9), // Blue header
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isSmartFilterPlan ? 13 : 16),
                                topRight: Radius.circular(isSmartFilterPlan ? 13 : 16),
                              ),
                            ),
                            child: Column(
                              children: [
                                if (isSmartFilterPlan)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'CURRENT PLAN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                const Text(
                                  'SmartFilter',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Stay Organized',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content section
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '\$',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Text(
                                      '1',
                                      style: TextStyle(
                                        fontSize: 60,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        height: 1.0,
                                      ),
                                    ),
                                    const Text(
                                      '99',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'Monthly',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Features List
                                _buildFeatureItem(
                                  'Everything in Free, plus:',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'CPSC alerts (consumer products)',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Save up to 10 custom SmartFilters',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Save up to 15 recalls',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Filter by up to 3 states',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Premium recall details (adverse reactions, recommendations, distribution)',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Full recall history since January 1',
                                ),
                                const SizedBox(height: 24),

                                // Upgrade Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isSmartFilterPlan ? null : () async {
                                      // Show subscription paywall with IAP integration
                                      final result = await SubscriptionPaywall.show(context);
                                      if (result == true && context.mounted) {
                                        // Refresh subscription info after successful purchase
                                        ref.invalidate(subscriptionInfoProvider);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSmartFilterPlan
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFF2196F3),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(0xFF4CAF50),
                                      disabledForegroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      isSmartFilterPlan ? 'Current Plan' : 'Upgrade',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // RecallMatch Plan Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRecallMatchPlan ? const Color(0xFF4CAF50) : const Color(0xFFFFD700),
                          width: isRecallMatchPlan ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isRecallMatchPlan
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                : const Color(0xFFFFD700).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header section with gradient
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFD700),
                                  const Color(0xFFFFA500),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isRecallMatchPlan ? 13 : 14),
                                topRight: Radius.circular(isRecallMatchPlan ? 13 : 14),
                              ),
                            ),
                            child: Column(
                              children: [
                                if (isRecallMatchPlan)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'CURRENT PLAN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'RecallMatch',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Protect Your Home',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content section
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '\$',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Text(
                                      '4',
                                      style: TextStyle(
                                        fontSize: 60,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        height: 1.0,
                                      ),
                                    ),
                                    const Text(
                                      '99',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'Monthly',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Features List
                                _buildFeatureItem(
                                  'Everything in SmartFiltering, plus:',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  '📷 SmartScan: Camera & barcode scanning',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  '🏠 Household Inventory (up to 75 items)',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  '🤖 RecallMatch Engine: Automated daily matching of YOUR items',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  '✅ Recall Management Center (RMC): Step-by-step resolution',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  '🚗 NHTSA alerts (vehicle/auto recalls)',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Unlimited SmartFilters & state filtering',
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(
                                  'Save up to 50 recalls',
                                ),
                                const SizedBox(height: 24),

                                // Upgrade Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isRecallMatchPlan ? null : () async {
                                      // Show RecallMatch paywall (Coming Soon with waitlist)
                                      await RecallMatchPaywall.show(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isRecallMatchPlan
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFFFD700),
                                      foregroundColor: isRecallMatchPlan ? Colors.white : Colors.black,
                                      disabledBackgroundColor: const Color(0xFF4CAF50),
                                      disabledForegroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      isRecallMatchPlan ? 'Current Plan' : 'Upgrade to RecallMatch',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Quick Comparison Table
                    _buildComparisonTable(),

                    const SizedBox(height: 40),

                    // FAQ Section
                    _buildFaqSection(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedVisibilityWrapper(
        isVisible: isBottomNavVisible,
        direction: SlideDirection.down,
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF2C3E50),
          selectedItemColor: const Color(0xFF64B5F6),
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
          elevation: 8,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 0),
                  ),
                  (route) => false,
                );
                break;
              case 1:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 1),
                  ),
                  (route) => false,
                );
                break;
              case 2:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 2),
                  ),
                  (route) => false,
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: const Icon(
            Icons.check_circle,
            color: Color(0xFF4CAF50), // Green check
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// Build a quick comparison table for all tiers
  Widget _buildComparisonTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Quick Comparison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF1D3547)),
              dataRowColor: WidgetStateProperty.all(const Color(0xFF2A4A5C)),
              columnSpacing: 16,
              horizontalMargin: 16,
              columns: const [
                DataColumn(
                  label: Text('Feature', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Free', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('SmartFilter', style: TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('RecallMatch', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                ),
              ],
              rows: [
                _buildComparisonRow('Recall Sources', 'FDA, USDA', '+ CPSC', '+ NHTSA'),
                _buildComparisonRow('History', '30 days', 'YTD', 'YTD'),
                _buildComparisonRow('States', '1', '3', '3'),
                _buildComparisonRow('Saved Recalls', '5', '15', '50'),
                _buildComparisonRow('Saved Filters', '0', '10', 'Unlimited'),
                _buildComparisonRow('Inventory Items', '-', '-', '75'),
                _buildComparisonRow('RecallMatch Engine', '-', '-', '✓'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  DataRow _buildComparisonRow(String feature, String free, String smart, String match) {
    return DataRow(
      cells: [
        DataCell(Text(feature, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        DataCell(Text(free, style: const TextStyle(color: Colors.white, fontSize: 13))),
        DataCell(Text(smart, style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 13))),
        DataCell(Text(match, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13))),
      ],
    );
  }

  /// Build FAQ section with expandable questions
  Widget _buildFaqSection() {
    final faqs = [
      (
        'How do I cancel my subscription?',
        'You can cancel anytime through your device\'s app store settings. Go to Settings > [Your Name] > Subscriptions on iOS, or Google Play Store > Menu > Subscriptions on Android.'
      ),
      (
        'Will I lose my data if I downgrade?',
        'No, your saved recalls and filters remain stored. However, you may lose access to premium features and excess items beyond your new tier\'s limits.'
      ),
      (
        'What happens when RecallMatch launches?',
        'If you\'re on our waitlist, you\'ll be notified first. RecallMatch subscribers will get immediate access to household inventory management and automated recall matching.'
      ),
      (
        'Is there a free trial?',
        'We don\'t currently offer a free trial, but our Free tier gives you access to FDA and USDA recalls with basic filtering. You can upgrade anytime to unlock more features.'
      ),
      (
        'Do subscriptions auto-renew?',
        'Yes, subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. You can manage this in your device\'s app store settings.'
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...faqs.map((faq) => _buildFaqItem(faq.$1, faq.$2)),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white70,
          title: Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
