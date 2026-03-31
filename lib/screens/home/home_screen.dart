import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/listing_model.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/listing_provider.dart';
import '../../services/cache_service.dart';
import '../../services/review_service.dart';
import 'widgets/listing_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const List<String> categories = [
    'All',
    'Electronics',
    'Clothing',
    'Vehicles',
    'Furniture',
    'Books',
    'Sports',
    'Other',
  ];

  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
      final isNowOffline = results.contains(ConnectivityResult.none);
      if (isNowOffline != isOffline) {
        if (mounted) setState(() => isOffline = isNowOffline);
      }
    });
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) setState(() => isOffline = result.contains(ConnectivityResult.none));
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final listingsAsync = ref.watch(listingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (isOffline)
              Container(
                width: double.infinity,
                color: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Text('Offline mode - viewing cached data', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text('Search marketplace...', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.tune),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      onSelected: (selected) {
                        ref.read(selectedCategoryProvider.notifier).setCategory(category);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(listingsProvider);
                },
                child: isOffline
                    ? _buildOfflineGrid(ref)
                    : listingsAsync.when(
                      data: (listings) {
                        ref.read(cacheServiceProvider).cacheListings(listings);
                        return _buildGrid(listings);
                      },
                      loading: () => _buildShimmerGrid(),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-listing'),
        label: const Text('Sell Something'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildOfflineGrid(WidgetRef ref) {
    final cacheService = ref.read(cacheServiceProvider);
    final cached = cacheService.getCachedListings();
    if (cached.isEmpty) return const Center(child: Text('No offline data available'));
    return _buildGrid(cached);
  }

  Widget _buildGrid(List<ListingModel> listings) {
    if (listings.isEmpty) {
      return const Center(child: Text('No listings found'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final item = listings[index];
        return FutureBuilder(
          future: ref.read(reviewServiceProvider).getUser(item.sellerId),
          builder: (context, snapshot) {
            final seller = snapshot.data;
            return ListingCard(
              listing: item,
              sellerName: seller?.name ?? 'Seller',
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
