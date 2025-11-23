# CPSC (Consumer Product Safety Commission) Implementation Plan

**Status:** READY TO IMPLEMENT
**Estimated Time:** 2-3 days (Backend) + 1 day (Flutter)
**Priority:** High

---

## Executive Summary

Adding CPSC as a new regulatory source is **straightforward** because:
1. Your `RecallData` model is already **agency-agnostic** (same fields work for all agencies)
2. **Subscription tier gating is already implemented** (CPSC is in SmartFiltering tier)
3. The architecture mirrors FDA/USDA exactly - just add parallel endpoints

---

## What's Already Done (No Changes Needed)

### Flutter App
- [x] `SubscriptionInfo.getAllowedAgencies()` - Already returns CPSC for SmartFiltering tier
- [x] `article_service.dart` - Already has `getCpscArticles()` method
- [x] Marketing copy mentions CPSC in intro_page1.dart and subscribe_page.dart
- [x] `RecallData` model - Agency-agnostic, handles any agency string

### Architecture
- [x] Tier-based filtering in `filteredRecallsProvider` - Works for any agency
- [x] Category counts provider - Works for any agency

---

## Implementation Steps

### PHASE 1: Backend (Django) - 2-3 Days

#### Step 1.1: Add CPSC Endpoint to Django REST API
**File:** `api/views.py` (or create `api/views/cpsc_views.py`)

```python
# Add alongside existing FDA/USDA views
class CPSCRecallViewSet(viewsets.ModelViewSet):
    """CPSC Recalls endpoint"""
    queryset = Recall.objects.filter(agency='CPSC').order_by('-date_issued')
    serializer_class = RecallSerializer
    permission_classes = [AllowAny]  # Or your existing permissions
```

#### Step 1.2: Add URL Route
**File:** `api/urls.py`

```python
# Add to router
router.register(r'recalls/cpsc', CPSCRecallViewSet, basename='cpsc-recalls')
```

**Result:** `GET /api/recalls/cpsc/` returns CPSC recalls

#### Step 1.3: CPSC Data Import (Choose One)

**Option A: Manual Import via Admin**
- Add CPSC recalls manually through Django admin
- Set `agency = 'CPSC'` on each recall

**Option B: Automated Scraper**
```python
# api/management/commands/import_cpsc.py
from django.core.management.base import BaseCommand
import requests

class Command(BaseCommand):
    def handle(self, *args, **options):
        # CPSC has a public API: https://www.cpsc.gov/Recalls/CPSC-Recalls-Application-Program-Interface-API
        # OR scrape from: https://www.cpsc.gov/Recalls
        pass
```

**CPSC API Reference:**
- Official API: `https://www.saferproducts.gov/RestWebServices/Recall`
- Documentation: https://www.cpsc.gov/Recalls/CPSC-Recalls-Application-Program-Interface-API

#### Step 1.4: Verify Backend Works
```bash
# Test the endpoint
curl https://api.centerforrecallsafety.com/api/recalls/cpsc/
```

---

### PHASE 2: Flutter App - 1 Day

#### Step 2.1: Add CPSC Endpoint to AppConfig
**File:** `lib/config/app_config.dart`

```dart
// Add after apiUsdaEndpoint
static const String apiCpscEndpoint = '/recalls/cpsc/';
```

#### Step 2.2: Add CPSC Fetch Method to RecallDataService
**File:** `lib/services/recall_data_service.dart`

```dart
// Add member variables
List<RecallData> _cachedCpscRecalls = [];
DateTime? _lastCpscFetch;

// Add method (copy getFdaRecalls structure)
Future<List<RecallData>> getCpscRecalls({
  bool forceRefresh = false,
  int? limit,
  int? offset,
}) async {
  if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {
    try {
      print('🔵 Starting CPSC recalls fetch from REST API...');

      if (limit != null || offset != null) {
        final cpscRecalls = await _apiService.fetchCpscRecalls(
          limit: limit,
          offset: offset,
        );
        return cpscRecalls;
      }

      if (!forceRefresh &&
          _lastCpscFetch != null &&
          DateTime.now().difference(_lastCpscFetch!).inMinutes < 30) {
        return _cachedCpscRecalls;
      }

      final cpscRecalls = await _apiService.fetchCpscRecalls();
      print('✅ CPSC recalls fetched successfully: ${cpscRecalls.length} items');

      _cachedCpscRecalls = cpscRecalls;
      _lastCpscFetch = DateTime.now();
      await _saveToPersistentCache('cpsc_recalls', cpscRecalls);
      return _cachedCpscRecalls;
    } catch (e, stackTrace) {
      print('❌ ERROR fetching CPSC recalls from API: $e');

      final cachedData = await _loadFromPersistentCache('cpsc_recalls');
      if (cachedData != null && cachedData.isNotEmpty) {
        return cachedData;
      }
      return [];
    }
  }

  return []; // No Google Sheets fallback for CPSC
}
```

#### Step 2.3: Add CPSC Fetch Method to ApiService
**File:** `lib/services/api_service.dart`

```dart
/// Fetch CPSC recalls only
Future<List<RecallData>> fetchCpscRecalls({
  int? limit,
  int? offset,
}) async {
  try {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();

    final uri = Uri.parse('$baseUrl${AppConfig.apiCpscEndpoint}')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await _httpClient.get(uri);
    ApiUtils.checkResponse(response, context: 'Fetch CPSC recalls');

    final results = ApiUtils.parseJsonList(response.body);
    return results
        .map((json) => _convertFromApi(json as Map<String, dynamic>))
        .toList();
  } on ApiException {
    rethrow;
  } catch (e, stack) {
    throw ApiException(
      'Failed to fetch CPSC recalls',
      originalException: e,
      stackTrace: stack,
    );
  }
}
```

#### Step 2.4: Add CPSC Provider to data_providers.dart
**File:** `lib/providers/data_providers.dart`

```dart
/// CPSC Recalls Provider - Fetches all CPSC recalls
final cpscRecallsProvider = FutureProvider<List<RecallData>>((ref) async {
  final recallService = ref.watch(recallDataServiceProvider);
  return recallService.getCpscRecalls();
});
```

#### Step 2.5: Update allRecallsProvider to Include CPSC
**File:** `lib/providers/data_providers.dart`

```dart
/// All Recalls Provider - Combines FDA, USDA, and CPSC recalls
final allRecallsProvider = FutureProvider<List<RecallData>>((ref) async {
  final fdaRecallsAsync = ref.watch(fdaRecallsProvider);
  final usdaRecallsAsync = ref.watch(usdaRecallsProvider);
  final cpscRecallsAsync = ref.watch(cpscRecallsProvider);

  // Wait for all to complete
  final fdaRecalls = await fdaRecallsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<RecallData>[]),
    error: (_, __) => Future.value(<RecallData>[]),
  );

  final usdaRecalls = await usdaRecallsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<RecallData>[]),
    error: (_, __) => Future.value(<RecallData>[]),
  );

  final cpscRecalls = await cpscRecallsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<RecallData>[]),
    error: (_, __) => Future.value(<RecallData>[]),
  );

  return [...fdaRecalls, ...usdaRecalls, ...cpscRecalls];
});
```

#### Step 2.6: Update Home Page Category Counts (Optional)
**File:** `lib/providers/data_providers.dart` - `categoryCountsProvider`

The existing category mapping should work, but you may want to add CPSC-specific categories:

```dart
// CPSC typically covers these categories:
'childProducts': ['cribs', 'strollers', 'car seats', 'toys'],
'homeGoods': ['furniture', 'appliances', 'bedding'],
'sports': ['bicycles', 'sports equipment', 'exercise equipment'],
```

---

### PHASE 3: Testing

#### Backend Tests
```bash
# Test CPSC endpoint
curl https://api.centerforrecallsafety.com/api/recalls/cpsc/
curl https://api.centerforrecallsafety.com/api/recalls/cpsc/?limit=10

# Verify response format matches FDA/USDA
```

#### Flutter Tests
1. Run app as FREE user - should NOT see CPSC recalls
2. Run app as SmartFiltering user - should see CPSC recalls
3. Check console for `✅ CPSC recalls fetched successfully`
4. Verify CPSC recalls appear in recall lists

---

## CPSC-Specific Fields (If Different from FDA/USDA)

Based on CPSC's public data, common fields include:

| CPSC Field | Maps To RecallData Field |
|------------|-------------------------|
| RecallID | id / recall_id |
| RecallNumber | fieldRecallNumber |
| RecallDate | dateIssued |
| Description | description |
| ProductName | productName |
| Hazard | recallReason |
| Remedy | (remedyReturn/Repair/Replace/Dispose) |
| LastPublishDate | updated_at |
| Images | imageUrl, imageUrl2, etc. |
| Injuries | negativeOutcomes |
| Deaths | negativeOutcomes |
| ConsumerContact | firmContactForm |
| ManufacturerCountries | distributor |

**Most fields map directly!** Your existing `RecallData` model can handle CPSC without modification.

---

## Files to Modify (Summary)

### Backend (Django)
```
api/views.py (or api/views/cpsc_views.py) - Add CPSCRecallViewSet
api/urls.py - Add CPSC route
api/management/commands/import_cpsc.py - (Optional) Import script
```

### Flutter
```
lib/config/app_config.dart - Add apiCpscEndpoint
lib/services/api_service.dart - Add fetchCpscRecalls()
lib/services/recall_data_service.dart - Add getCpscRecalls()
lib/providers/data_providers.dart - Add cpscRecallsProvider, update allRecallsProvider
```

---

## Timeline

| Task | Duration | Dependencies |
|------|----------|--------------|
| Backend: Add CPSC endpoint | 2 hours | None |
| Backend: Create data import | 4-8 hours | Endpoint done |
| Backend: Import initial data | 2-4 hours | Import script done |
| Flutter: Add config + service | 1 hour | Backend deployed |
| Flutter: Add provider | 30 mins | Service done |
| Testing | 2-4 hours | All above done |
| **TOTAL** | **2-3 days** | |

---

## Recommended Order of Implementation

1. **Backend First:**
   - Create CPSC endpoint
   - Import sample CPSC data (even 5-10 recalls)
   - Deploy to staging

2. **Flutter Second:**
   - Add endpoint config
   - Add API service method
   - Add data service method
   - Add provider + update allRecallsProvider

3. **Test:**
   - Verify free tier doesn't see CPSC
   - Verify SmartFiltering tier sees CPSC
   - Check all UI displays work

---

## Notes

### Subscription Tier Enforcement
Already implemented! The `filteredRecallsProvider` filters by `allowedAgencies`, which already includes CPSC for SmartFiltering and RecallMatch tiers.

### No Model Changes Needed
Your `RecallData` model is agency-agnostic. The `agency` field is a string that can be 'FDA', 'USDA', 'CPSC', or 'NHTSA'.

### Error Handling
Copy the pattern from FDA/USDA - catch errors, fall back to cache, return empty list if no data.

---

## Future: Adding NHTSA

The same process applies for NHTSA (vehicles/auto recalls):
1. Add `/api/recalls/nhtsa/` backend endpoint
2. Add `apiNhtsaEndpoint` to AppConfig
3. Add `fetchNhtsaRecalls()` to ApiService
4. Add `getNhtsaRecalls()` to RecallDataService
5. Add `nhtsaRecallsProvider` to data_providers
6. Update `allRecallsProvider` to include NHTSA

NHTSA is already gated to RecallMatch tier in `getAllowedAgencies()`.

---

**Ready to start implementation? Begin with the backend CPSC endpoint!**
