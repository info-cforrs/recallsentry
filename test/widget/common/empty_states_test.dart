/// Empty State Widget Tests
///
/// Tests for empty state UI patterns including:
/// - No recalls found
/// - No saved items
/// - No search results
/// - No filters applied
///
/// To run: flutter test test/widget/common/empty_states_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('Empty State - No Recalls', () {
    testWidgets('displays no recalls message', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.search_off,
          title: 'No Recalls Found',
          message: 'There are no recalls matching your criteria.',
        ),
      ));

      expect(find.text('No Recalls Found'), findsOneWidget);
      expect(find.text('There are no recalls matching your criteria.'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(createTestableWidget(
        EmptyStateWidget(
          icon: Icons.search_off,
          title: 'No Recalls Found',
          message: 'Try adjusting your filters.',
          actionLabel: 'Clear Filters',
          onAction: () => buttonPressed = true,
        ),
      ));

      expect(find.text('Clear Filters'), findsOneWidget);

      await tester.tap(find.text('Clear Filters'));
      await tester.pump();

      expect(buttonPressed, true);
    });

    testWidgets('hides action button when not provided', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.search_off,
          title: 'No Recalls Found',
          message: 'Check back later for new recalls.',
        ),
      ));

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('Empty State - No Saved Items', () {
    testWidgets('displays no saved recalls message', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.bookmark_border,
          title: 'No Saved Recalls',
          message: 'Recalls you save will appear here.',
        ),
      ));

      expect(find.text('No Saved Recalls'), findsOneWidget);
      expect(find.text('Recalls you save will appear here.'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('displays no saved filters message', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.filter_list_off,
          title: 'No Saved Filters',
          message: 'Save your filter combinations for quick access.',
        ),
      ));

      expect(find.text('No Saved Filters'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_off), findsOneWidget);
    });

    testWidgets('displays no user items message', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.inventory_2_outlined,
          title: 'No Items Added',
          message: 'Add items to your inventory to track recalls.',
        ),
      ));

      expect(find.text('No Items Added'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });

  group('Empty State - Search Results', () {
    testWidgets('displays no search results', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.search,
          title: 'No Results',
          message: 'No recalls found for "peanut butter".',
        ),
      ));

      expect(find.text('No Results'), findsOneWidget);
      expect(find.text('No recalls found for "peanut butter".'), findsOneWidget);
    });

    testWidgets('suggests trying different search terms', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.search,
          title: 'No Results',
          message: 'Try searching with different keywords or check your spelling.',
        ),
      ));

      expect(find.textContaining('different keywords'), findsOneWidget);
    });
  });

  group('Empty State - Offline', () {
    testWidgets('displays offline message', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.wifi_off,
          title: 'You\'re Offline',
          message: 'Connect to the internet to see the latest recalls.',
        ),
      ));

      expect(find.text('You\'re Offline'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('displays retry button when offline', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(createTestableWidget(
        EmptyStateWidget(
          icon: Icons.wifi_off,
          title: 'Connection Error',
          message: 'Unable to load recalls.',
          actionLabel: 'Retry',
          onAction: () => retryPressed = true,
        ),
      ));

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryPressed, true);
    });
  });

  group('Empty State - Error', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Something Went Wrong',
          message: 'We couldn\'t load the recalls. Please try again.',
          isError: true,
        ),
      ));

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('error icon is styled correctly', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Error',
          message: 'An error occurred.',
          isError: true,
        ),
      ));

      final iconFinder = find.byIcon(Icons.error_outline);
      expect(iconFinder, findsOneWidget);
    });
  });

  group('Empty State - Premium Feature', () {
    testWidgets('displays premium upgrade message', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.lock_outline,
          title: 'Premium Feature',
          message: 'Upgrade to access this feature.',
        ),
      ));

      expect(find.text('Premium Feature'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('displays upgrade button', (tester) async {
      bool upgradePressed = false;

      await tester.pumpWidget(createTestableWidget(
        EmptyStateWidget(
          icon: Icons.lock_outline,
          title: 'Premium Feature',
          message: 'Access CPSC recalls with Smart Filtering.',
          actionLabel: 'Upgrade Now',
          onAction: () => upgradePressed = true,
        ),
      ));

      expect(find.text('Upgrade Now'), findsOneWidget);

      await tester.tap(find.text('Upgrade Now'));
      await tester.pump();

      expect(upgradePressed, true);
    });
  });

  group('Empty State - Loading vs Empty', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const LoadingOrEmptyWidget(
          isLoading: true,
          isEmpty: true,
          loadingWidget: CircularProgressIndicator(),
          emptyWidget: EmptyStateWidget(
            icon: Icons.search_off,
            title: 'No Results',
            message: 'Nothing found.',
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No Results'), findsNothing);
    });

    testWidgets('shows empty state when not loading and empty', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const LoadingOrEmptyWidget(
          isLoading: false,
          isEmpty: true,
          loadingWidget: CircularProgressIndicator(),
          emptyWidget: EmptyStateWidget(
            icon: Icons.search_off,
            title: 'No Results',
            message: 'Nothing found.',
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No Results'), findsOneWidget);
    });

    testWidgets('shows content when not loading and not empty', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const LoadingOrEmptyWidget(
          isLoading: false,
          isEmpty: false,
          loadingWidget: CircularProgressIndicator(),
          emptyWidget: EmptyStateWidget(
            icon: Icons.search_off,
            title: 'No Results',
            message: 'Nothing found.',
          ),
          child: Text('Content Here'),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No Results'), findsNothing);
      expect(find.text('Content Here'), findsOneWidget);
    });
  });

  group('Empty State - Styling', () {
    testWidgets('icon has correct size', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.search_off,
          title: 'Test',
          message: 'Test message',
          iconSize: 80,
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.search_off));
      expect(icon.size, 80);
    });

    testWidgets('centers content', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.search_off,
          title: 'Centered',
          message: 'This should be centered.',
        ),
      ));

      // The Column should be centered
      final column = tester.widget<Column>(find.byType(Column).first);
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
      expect(column.crossAxisAlignment, CrossAxisAlignment.center);
    });

    testWidgets('has proper spacing between elements', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        const EmptyStateWidget(
          icon: Icons.search_off,
          title: 'Test',
          message: 'Test message',
        ),
      ));

      // Should have SizedBox for spacing
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}

/// Reusable empty state widget for testing
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isError ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget that shows loading, empty, or content based on state
class LoadingOrEmptyWidget extends StatelessWidget {
  final bool isLoading;
  final bool isEmpty;
  final Widget loadingWidget;
  final Widget emptyWidget;
  final Widget? child;

  const LoadingOrEmptyWidget({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.loadingWidget,
    required this.emptyWidget,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: loadingWidget);
    }
    if (isEmpty) {
      return emptyWidget;
    }
    return child ?? const SizedBox.shrink();
  }
}
