import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/data_models.dart';

/// Manages local caching and filter state persistence
class CacheService {
  /// Loads cached stylists and reports from local storage
  Future<CachedPayload?> loadCachedPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final stylistsRaw = prefs.getString(cacheStylistsKey);
    final reportsRaw = prefs.getString(cacheReportsKey);
    if (stylistsRaw == null || reportsRaw == null) {
      return null;
    }

    try {
      final stylistsJson = jsonDecode(stylistsRaw) as List<dynamic>;
      final reportsJson = jsonDecode(reportsRaw) as List<dynamic>;
      final stylists = stylistsJson
          .map((item) => Stylist.fromJson(item as Map<String, dynamic>))
          .toList();
      final reports = reportsJson
          .map((item) => Report.fromJson(item as Map<String, dynamic>))
          .toList();
      final lastSyncRaw = prefs.getString(cacheLastSyncKey);
      final lastSync =
          lastSyncRaw == null ? null : DateTime.tryParse(lastSyncRaw);
      return CachedPayload(
        stylists: stylists,
        reports: reports,
        lastSync: lastSync,
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves stylists and reports to local cache with timestamp
  Future<void> saveCache({
    required List<Stylist> stylists,
    required List<Report> reports,
    required DateTime lastSync,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      cacheStylistsKey,
      jsonEncode(stylists.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(
      cacheReportsKey,
      jsonEncode(reports.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(cacheLastSyncKey, lastSync.toIso8601String());
  }

  /// Loads persisted filter state from local storage
  Future<FilterState> loadFilterState(List<String> availableMonths) async {
    final prefs = await SharedPreferences.getInstance();
    var selectedMonth = prefs.getString(filterMonthKey);
    final startDate = parseStoredDate(prefs.getString(filterStartKey));
    final endDate = parseStoredDate(prefs.getString(filterEndKey));
    final searchQuery = prefs.getString(filterSearchKey) ?? '';
    final sortColumnIndex = prefs.getInt(filterSortIndexKey) ?? 0;
    final sortAscending = prefs.getBool(filterSortAscKey) ?? true;

    // Validate month selection
    if (selectedMonth != null && !availableMonths.contains(selectedMonth)) {
      selectedMonth = null;
    }

    return FilterState(
      selectedMonth: selectedMonth,
      startDate: startDate,
      endDate: endDate,
      searchQuery: searchQuery,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
    );
  }

  /// Persists current filter state to local storage
  Future<void> persistFilterState(FilterState state) async {
    final prefs = await SharedPreferences.getInstance();

    if (state.selectedMonth == null) {
      await prefs.remove(filterMonthKey);
    } else {
      await prefs.setString(filterMonthKey, state.selectedMonth!);
    }

    if (state.startDate == null) {
      await prefs.remove(filterStartKey);
    } else {
      await prefs.setString(filterStartKey, state.startDate!.toIso8601String());
    }

    if (state.endDate == null) {
      await prefs.remove(filterEndKey);
    } else {
      await prefs.setString(filterEndKey, state.endDate!.toIso8601String());
    }

    await prefs.setString(filterSearchKey, state.searchQuery);
    await prefs.setInt(filterSortIndexKey, state.sortColumnIndex);
    await prefs.setBool(filterSortAscKey, state.sortAscending);
  }
}

/// Represents the current filter and sort state
class FilterState {
  FilterState({
    this.selectedMonth,
    this.startDate,
    this.endDate,
    this.searchQuery = '',
    this.sortColumnIndex = 0,
    this.sortAscending = true,
  });

  final String? selectedMonth;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;
  final int sortColumnIndex;
  final bool sortAscending;
}

/// Parses ISO date string to DateTime
DateTime? parseStoredDate(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}
