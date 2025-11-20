# Providers Documentation

This directory contains Riverpod providers for state management throughout the RecallSentry application.

## Overview

We use **Riverpod 2.5+** for state management to solve several critical issues:

- **Service Duplication**: Previously, every page created its own instance of services
- **Data Refetching**: Same data was fetched multiple times across different pages
- **No Shared State**: No way to share data between pages without prop drilling
- **Performance Issues**: Excessive rebuilds and memory overhead

## Architecture

### Service Providers (`service_providers.dart`)

**Singleton providers** for all service classes. These ensure only one instance of each service exists throughout the app lifecycle.

```dart
// Example usage:
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recallService = ref.watch(recallDataServiceProvider);
    // Use the service...
  }
}
```

**Available Service Providers:**
- `recallDataServiceProvider` - FDA/USDA recall data
- `subscriptionServiceProvider` - User subscription tier
- `apiServiceProvider` - Backend API calls
- `savedRecallsServiceProvider` - Local saved recalls
- `savedFilterServiceProvider` - Cloud SmartFilters
- `gamificationServiceProvider` - SafetyScore & badges
- `authServiceProvider` - Authentication
- `userProfileServiceProvider` - User profile data
- `articleServiceProvider` - Safety articles

### Data Providers (`data_providers.dart`)

**Higher-level providers** that use service providers to fetch and cache data.

#### Subscription Providers

```dart
// Get full subscription info
final subscriptionInfoProvider = FutureProvider<SubscriptionInfo>

// Quick access to just the tier
final subscriptionTierProvider = Provider<SubscriptionTier>

// Boolean checks for features
final hasPremiumAccessProvider = Provider<bool>
final hasRMCAccessProvider = Provider<bool>
final isLoggedInProvider = Provider<bool>
```

#### Recall Data Providers

```dart
// All FDA recalls (cached)
final fdaRecallsProvider = FutureProvider<List<RecallData>>

// All USDA recalls (cached)
final usdaRecallsProvider = FutureProvider<List<RecallData>>

// Combined FDA + USDA
final allRecallsProvider = FutureProvider<List<RecallData>>

// Filtered by tier (Free: 30 days, Premium: YTD)
final filteredRecallsProvider = FutureProvider<List<RecallData>>

// User's saved recalls
final savedRecallsProvider = FutureProvider<List<RecallData>>
```

#### Filter & Gamification Providers

```dart
// All saved filters
final savedFiltersProvider = FutureProvider<List<SavedFilter>>

// Only active filters with criteria
final activeFiltersProvider = FutureProvider<List<SavedFilter>>

// User's SafetyScore (gamification)
final safetyScoreProvider = FutureProvider<SafetyScore?>
```

## Usage Patterns

### ConsumerWidget (Recommended for most cases)

```dart
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch a provider - rebuilds when data changes
    final tier = ref.watch(subscriptionTierProvider);

    // Read a provider - doesn't rebuild
    final service = ref.read(recallDataServiceProvider);

    return Text('Tier: $tier');
  }
}
```

### ConsumerStatefulWidget (When you need lifecycle methods)

```dart
class ComplexPage extends ConsumerStatefulWidget {
  const ComplexPage({super.key});

  @override
  ConsumerState<ComplexPage> createState() => _ComplexPageState();
}

class _ComplexPageState extends ConsumerState<ComplexPage> {
  @override
  void initState() {
    super.initState();
    // Can use ref in lifecycle methods
  }

  @override
  Widget build(BuildContext context) {
    final recalls = ref.watch(filteredRecallsProvider);

    return recalls.when(
      data: (data) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### FutureProvider Handling

```dart
// Pattern 1: Using .when()
final recallsAsync = ref.watch(fdaRecallsProvider);
return recallsAsync.when(
  data: (recalls) => Text('Count: ${recalls.length}'),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);

// Pattern 2: Using .maybeWhen()
final hasPremium = ref.watch(hasPremiumAccessProvider);
if (!hasPremium) {
  return UpgradePrompt();
}

// Pattern 3: Await the future directly
final recalls = await ref.watch(fdaRecallsProvider.future);
```

### Refreshing Data

```dart
// Force refresh a provider
ref.invalidate(fdaRecallsProvider);

// Or use refresh
ref.refresh(subscriptionInfoProvider);
```

## Migration Guide

### Before (StatefulWidget + setState)

```dart
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RecallDataService _recallService = RecallDataService();
  List<RecallData> _recalls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecalls();
  }

  Future<void> _loadRecalls() async {
    setState(() => _isLoading = true);
    final recalls = await _recallService.getFdaRecalls();
    setState(() {
      _recalls = recalls;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return CircularProgressIndicator();
    return ListView.builder(
      itemCount: _recalls.length,
      itemBuilder: (ctx, i) => RecallCard(recall: _recalls[i]),
    );
  }
}
```

### After (ConsumerWidget + Providers)

```dart
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recallsAsync = ref.watch(fdaRecallsProvider);

    return recallsAsync.when(
      data: (recalls) => ListView.builder(
        itemCount: recalls.length,
        itemBuilder: (ctx, i) => RecallCard(recall: recalls[i]),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

**Benefits:**
- ✅ No manual loading state management
- ✅ Automatic caching - data shared across pages
- ✅ No service instantiation overhead
- ✅ Cleaner, more testable code
- ✅ Automatic disposal

## Best Practices

1. **Use `ref.watch()` in build methods** - Rebuilds when data changes
2. **Use `ref.read()` in callbacks/events** - Doesn't create dependency
3. **Use `ref.listen()` for side effects** - Show snackbars, navigate, etc.
4. **Invalidate providers when data changes** - Keep data fresh
5. **Combine providers intelligently** - Avoid unnecessary watchers
6. **Keep providers small and focused** - Single responsibility

## Performance Tips

- ✅ Use `const` constructors whenever possible
- ✅ Use `select()` to watch only part of provider data
- ✅ Avoid watching providers in loops
- ✅ Extract widgets to prevent unnecessary rebuilds
- ✅ Use `AsyncValue.guard()` for error handling

## Testing

```dart
// Testing with Riverpod
testWidgets('HomePage shows recalls', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fdaRecallsProvider.overrideWith((ref) => Future.value([
          // Mock data
        ])),
      ],
      child: MaterialApp(home: HomePage()),
    ),
  );

  await tester.pump();
  expect(find.byType(RecallCard), findsWidgets);
});
```

## Common Patterns

### Loading Multiple Providers

```dart
// Bad - Multiple watchers
final fda = ref.watch(fdaRecallsProvider);
final usda = ref.watch(usdaRecallsProvider);

// Good - Single combined provider
final allRecalls = ref.watch(allRecallsProvider);
```

### Conditional Provider Watching

```dart
final hasPremium = ref.watch(hasPremiumAccessProvider);

// Only watch expensive provider if needed
if (hasPremium) {
  final rmcRecalls = ref.watch(rmcRecallsProvider);
  // Show RMC data
}
```

### Provider Composition

```dart
// Build on top of existing providers
final newRecallsProvider = Provider<List<RecallData>>((ref) {
  final allRecalls = ref.watch(filteredRecallsProvider);
  final now = DateTime.now();
  final yesterday = now.subtract(Duration(days: 1));

  return allRecalls.when(
    data: (recalls) => recalls.where((r) =>
      r.dateIssued.isAfter(yesterday)
    ).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
```

## Troubleshooting

**Problem:** "ProviderNotFoundException"
**Solution:** Ensure `ProviderScope` wraps your app in `main.dart`

**Problem:** Provider not updating
**Solution:** Use `ref.watch()` not `ref.read()` in build method

**Problem:** Too many rebuilds
**Solution:** Extract widgets, use `select()`, or `const` constructors

**Problem:** Stale data
**Solution:** Call `ref.invalidate(provider)` or `ref.refresh(provider)`

## Resources

- [Riverpod Documentation](https://riverpod.dev)
- [Migration Guide](https://riverpod.dev/docs/from_provider/motivation)
- [Best Practices](https://riverpod.dev/docs/essentials/combining_requests)
