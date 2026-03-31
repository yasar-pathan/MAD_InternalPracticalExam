import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/listing_model.dart';

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

class CacheService {
  static const String _cacheBoxName = 'cache_box';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _cachedListingsKey = 'cached_listings';

  Box _box() => Hive.box(_cacheBoxName);

  Future<void> cacheListings(List<ListingModel> listings) async {
    final data = listings.map((e) => e.toMap()..['id'] = e.id).toList();
    await _box().put(_cachedListingsKey, data);
  }

  List<ListingModel> getCachedListings() {
    final raw = _box().get(_cachedListingsKey);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map((map) => ListingModel.fromMap(map, map['id']?.toString() ?? ''))
        .toList();
  }

  Future<void> saveSearchQuery(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final recent = getRecentSearches();
    recent.removeWhere((q) => q.toLowerCase() == normalized.toLowerCase());
    recent.insert(0, normalized);

    if (recent.length > 10) {
      recent.removeRange(10, recent.length);
    }

    await _box().put(_recentSearchesKey, recent);
  }

  List<String> getRecentSearches() {
    final raw = _box().get(_recentSearchesKey);
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }
}
