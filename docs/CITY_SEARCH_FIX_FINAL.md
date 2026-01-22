# City-Based Search Fix - Final Solution

## Problem Identified

When typing "Екатеринбург Ленина 33":
1. ✅ Suggest API correctly receives full query with city name
2. ✅ Returns suggestions from Ekaterinburg 
3. ❌ **BUT**: When user selects suggestion, only "проспект Ленина, 33" is passed to `startSearch()` - **city name is lost!**

### Root Cause

The flow was:
```
User types: "Екатеринбург Ленина 33"
  ↓
MapSearchManager.setQueryText("Екатеринбург Ленина 33") → suggest API
  ↓
Suggest returns: item.title = "проспект Ленина, 33"
  ↓
User selects suggestion
  ↓
AddressAutocompleteField formats address → "проспект Ленина, 33"
  ↓
main_screen.dart calls: _mapManager.startSearch("проспект Ленина, 33") ❌
  ↓
startSearch() doesn't see city → searches locally in Perm
```

## Solution Implemented

### 1. Store Full Query with City
In `map_search_manager.dart`, added field:
```dart
String? _lastFullQuery;
```

Modified `setQueryText()` to save queries containing cities:
```dart
void setQueryText(String query) {
  _searchQuery.add(query);
  
  // Save full query if it contains a city
  if (_queryContainsCity(query)) {
    _lastFullQuery = query;
    print('💾 Saved full query with city: "$query"');
  }
}
```

### 2. Use Saved Query in startSearch()
Modified `startSearch()` to restore the full query:
```dart
void startSearch([String? query]) {
  var searchQuery = query ?? _searchQuery.value;
  
  // If query has no city but we have a saved full query,
  // use the saved query (because suggest loses city name)
  if (!_queryContainsCity(searchQuery) && _lastFullQuery != null) {
    print('🔄 Using saved full query: "$_lastFullQuery"');
    searchQuery = _lastFullQuery!;
  }
  
  // Continue with city detection logic...
}
```

## Expected Behavior

Now when typing "Екатеринбург Ленина 33":

1. User types → `setQueryText("Екатеринбург Ленина 33")`
2. Saved as `_lastFullQuery = "Екатеринбург Ленина 33"` ✅
3. Suggest returns "проспект Ленина, 33"
4. User selects → `startSearch("проспект Ленина, 33")`
5. **NEW**: Detects no city + has saved query → uses `"Екатеринбург Ленина 33"` ✅
6. City detection finds "Екатеринбург" → uses wide search area ✅
7. Finds address in Ekaterinburg! ✅

## Files Modified

1. `/lib/features/search/managers/map_search_manager.dart`
2. `/taxi_route_calculator/lib/features/search/managers/map_search_manager.dart`

## Testing

Test with:
- ✅ "Екатеринбург Ленина 33" → should find in Ekaterinburg
- ✅ "Москва Кутузовский 43" → should find in Moscow
- ✅ "Ленина 1" (no city) → should search locally in Perm

## Logs to Watch

```
💾 Saved full query with city: "Екатеринбург Ленина 33"
🔄 Query has no city, but we have saved full query: "Екатеринбург Ленина 33"
   Using saved full query for search
🌐 Query contains city "Екатеринбург Ленина 33" → using wide search area
```
