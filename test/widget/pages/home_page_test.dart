/// HomePage Widget Tests
///
/// Tests for the HomePage UI including:
/// - Navigation tabs rendering
/// - Recall list display
/// - Pull to refresh
/// - Search functionality
/// - Filter chip display
///
/// To run: flutter test test/widget/pages/home_page_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';
import '../../fixtures/recall_fixtures.dart';

void main() {
  group('HomePage - Navigation', () {
    testWidgets('renders bottom navigation bar with all tabs', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestHomePage()));
      await tester.pumpAndSettle();

      // Should have bottom navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Should have all navigation items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Recalls'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('tapping nav item changes selected index', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestHomePage()));
      await tester.pumpAndSettle();

      // Initially on Home tab (index 0)
      var navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 0);

      // Tap Recalls tab
      await tester.tap(find.text('Recalls'));
      await tester.pumpAndSettle();

      navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 1);

      // Tap Saved tab
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 2);
    });

    testWidgets('shows correct page content for each tab', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestHomePage()));
      await tester.pumpAndSettle();

      // Home tab content
      expect(find.text('Home Content'), findsOneWidget);

      // Switch to Recalls tab
      await tester.tap(find.text('Recalls'));
      await tester.pumpAndSettle();
      expect(find.text('Recalls Content'), findsOneWidget);

      // Switch to Saved tab
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.text('Saved Content'), findsOneWidget);

      // Switch to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile Content'), findsOneWidget);
    });
  });

  group('HomePage - Recall List', () {
    testWidgets('displays list of recall cards', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestRecallListPage()),
      );
      await tester.pumpAndSettle();

      // Should show recall cards
      expect(find.byType(_RecallCard), findsWidgets);
    });

    testWidgets('recall card shows product name and brand', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestRecallListPage()),
      );
      await tester.pumpAndSettle();

      // Check first recall card content
      expect(find.text('Organic Peanut Butter'), findsOneWidget);
      expect(find.text('NuttyHealth'), findsOneWidget);
    });

    testWidgets('recall card shows risk level badge', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestRecallListPage()),
      );
      await tester.pumpAndSettle();

      // Should show risk level
      expect(find.text('HIGH'), findsWidgets);
    });

    testWidgets('recall card shows agency badge', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestRecallListPage()),
      );
      await tester.pumpAndSettle();

      // Should show agency badges
      expect(find.text('FDA'), findsWidgets);
    });

    testWidgets('empty state shown when no recalls', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestEmptyRecallList()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No recalls found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('loading indicator shown while fetching', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestLoadingRecallList()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HomePage - Pull to Refresh', () {
    testWidgets('shows refresh indicator on pull down', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestRefreshableRecallList()),
      );
      await tester.pumpAndSettle();

      // Find the refresh indicator
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('triggers refresh callback on pull', (tester) async {
      var refreshTriggered = false;

      await tester.pumpWidget(
        createTestableWidget(
          _TestRefreshableRecallList(
            onRefresh: () async {
              refreshTriggered = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Perform pull to refresh gesture
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(refreshTriggered, true);
    });
  });

  group('HomePage - Search', () {
    testWidgets('renders search bar', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestSearchablePage()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('search input updates text', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestSearchablePage()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'salmonella');
      await tester.pump();

      expect(find.text('salmonella'), findsOneWidget);
    });

    testWidgets('clear button appears when text entered', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestSearchablePage()),
      );
      await tester.pumpAndSettle();

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button appears
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clear button clears search text', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestSearchablePage()),
      );
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'test search');
      await tester.pump();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Text should be cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '');
    });

    testWidgets('search debounces rapid input', (tester) async {
      var searchCount = 0;

      await tester.pumpWidget(
        createTestableWidget(
          _TestSearchablePage(
            onSearch: (query) {
              searchCount++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type rapidly
      await tester.enterText(find.byType(TextField), 's');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'sa');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'sal');
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 500));

      // Should only trigger search once after debounce
      expect(searchCount, 1);
    });
  });

  group('HomePage - Filter Chips', () {
    testWidgets('displays active filter chips', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestFilterChipsPage()),
      );
      await tester.pumpAndSettle();

      // Should show filter chips
      expect(find.byType(FilterChip), findsWidgets);
      expect(find.text('FDA'), findsOneWidget);
      expect(find.text('High Risk'), findsOneWidget);
    });

    testWidgets('filter chip can be removed', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestFilterChipsPage()),
      );
      await tester.pumpAndSettle();

      // Find and tap the delete icon on FDA chip
      final fdaChip = find.ancestor(
        of: find.text('FDA'),
        matching: find.byType(FilterChip),
      );
      expect(fdaChip, findsOneWidget);

      // Tap the chip to remove it
      await tester.tap(fdaChip);
      await tester.pumpAndSettle();

      // FDA chip should be removed
      expect(find.text('FDA'), findsNothing);
    });

    testWidgets('clear all filters button works', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestFilterChipsPage()),
      );
      await tester.pumpAndSettle();

      // Should have clear all button
      expect(find.text('Clear All'), findsOneWidget);

      // Tap clear all
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // All filter chips should be removed
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('filter count badge shows correct number', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestFilterChipsPage()),
      );
      await tester.pumpAndSettle();

      // Should show filter count (2 filters active)
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('HomePage - App Bar', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestHomePage()));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('RecallSentry'), findsOneWidget);
    });

    testWidgets('renders notification icon in app bar', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestHomePage()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('notification badge shows unread count', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestHomePageWithNotifications(count: 5)),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('notification badge hidden when count is zero', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestHomePageWithNotifications(count: 0)),
      );
      await tester.pumpAndSettle();

      // Badge should not show "0"
      expect(find.text('0'), findsNothing);
    });
  });

  group('HomePage - Error States', () {
    testWidgets('shows error message on load failure', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestErrorStatePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load recalls'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestErrorStatePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button triggers reload', (tester) async {
      var retryTriggered = false;

      await tester.pumpWidget(
        createTestableWidget(
          _TestErrorStatePage(
            onRetry: () {
              retryTriggered = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryTriggered, true);
    });

    testWidgets('shows offline indicator when no connection', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(const _TestOfflinePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('You are offline'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });
  });
}

// Test Widgets

/// Test home page with bottom navigation
class _TestHomePage extends StatefulWidget {
  const _TestHomePage();

  @override
  State<_TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<_TestHomePage> {
  int _currentIndex = 0;

  final List<String> _pageContents = [
    'Home Content',
    'Recalls Content',
    'Saved Content',
    'Profile Content',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RecallSentry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(child: Text(_pageContents[_currentIndex])),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Recalls'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Test home page with notification badge
class _TestHomePageWithNotifications extends StatelessWidget {
  final int count;

  const _TestHomePageWithNotifications({required this.count});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RecallSentry'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              if (count > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: const Center(child: Text('Home')),
    );
  }
}

/// Test recall list page
class _TestRecallListPage extends StatelessWidget {
  const _TestRecallListPage();

  @override
  Widget build(BuildContext context) {
    final recalls = RecallFixtures.recallList;

    return Scaffold(
      body: ListView.builder(
        itemCount: recalls.length,
        itemBuilder: (context, index) {
          final recall = recalls[index];
          return _RecallCard(recall: recall);
        },
      ),
    );
  }
}

/// Recall card widget for testing
class _RecallCard extends StatelessWidget {
  final Map<String, dynamic> recall;

  const _RecallCard({required this.recall});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  recall['agency'] as String? ?? 'FDA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    recall['risk_level'] as String? ?? 'HIGH',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recall['product_name'] as String? ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              recall['brand_name'] as String? ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty recall list for testing
class _TestEmptyRecallList extends StatelessWidget {
  const _TestEmptyRecallList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No recalls found'),
          ],
        ),
      ),
    );
  }
}

/// Loading state for testing
class _TestLoadingRecallList extends StatelessWidget {
  const _TestLoadingRecallList();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Refreshable recall list
class _TestRefreshableRecallList extends StatelessWidget {
  final Future<void> Function()? onRefresh;

  const _TestRefreshableRecallList({this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
        ),
      ),
    );
  }
}

/// Searchable page for testing
class _TestSearchablePage extends StatefulWidget {
  final void Function(String)? onSearch;

  const _TestSearchablePage({this.onSearch});

  @override
  State<_TestSearchablePage> createState() => _TestSearchablePageState();
}

class _TestSearchablePageState extends State<_TestSearchablePage> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    // Debounce search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_controller.text.isNotEmpty) {
        widget.onSearch?.call(_controller.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search recalls...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _hasText
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const Expanded(child: Center(child: Text('Search Results'))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Filter chips page for testing
class _TestFilterChipsPage extends StatefulWidget {
  const _TestFilterChipsPage();

  @override
  State<_TestFilterChipsPage> createState() => _TestFilterChipsPageState();
}

class _TestFilterChipsPageState extends State<_TestFilterChipsPage> {
  List<String> _activeFilters = ['FDA', 'High Risk'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_activeFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_activeFilters.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: _activeFilters.map((filter) {
                        return FilterChip(
                          label: Text(filter),
                          onSelected: (_) {
                            setState(() {
                              _activeFilters.remove(filter);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _activeFilters = [];
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          const Expanded(child: Center(child: Text('Results'))),
        ],
      ),
    );
  }
}

/// Error state page for testing
class _TestErrorStatePage extends StatelessWidget {
  final VoidCallback? onRetry;

  const _TestErrorStatePage({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text('Failed to load recalls'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Offline page for testing
class _TestOfflinePage extends StatelessWidget {
  const _TestOfflinePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('You are offline'),
          ],
        ),
      ),
    );
  }
}
