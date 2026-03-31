import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/listing_model.dart';
import '../../services/cache_service.dart';
import '../../services/listing_service.dart';
import '../../services/review_service.dart';
import '../home/widgets/listing_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool _loading = false;
  List<ListingModel> _results = [];

  String? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 100000);
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String text) async {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(cacheServiceProvider).saveSearchQuery(query);
      final items = await ref.read(listingServiceProvider).searchListings(
            query: query,
            category: _selectedCategory,
            minPrice: _priceRange.start,
            maxPrice: _priceRange.end,
            sortBy: _sortBy,
          );

      if (mounted) {
        setState(() {
          _results = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    }
  }

  void _onChange(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _openFilters() async {
    final categories = ['All', 'Electronics', 'Clothing', 'Vehicles', 'Furniture', 'Books', 'Sports', 'Other'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: categories
                        .map(
                          (c) => ChoiceChip(
                            label: Text(c),
                            selected: (_selectedCategory ?? 'All') == c,
                            onSelected: (_) => setLocal(() {
                              _selectedCategory = c == 'All' ? null : c;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Text('Price Range: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}'),
                  RangeSlider(
                    min: 0,
                    max: 100000,
                    divisions: 100,
                    values: _priceRange,
                    labels: RangeLabels('\$${_priceRange.start.round()}', '\$${_priceRange.end.round()}'),
                    onChanged: (value) => setLocal(() => _priceRange = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: const InputDecoration(labelText: 'Sort By'),
                    items: const ['Newest', 'Price Low-High', 'Price High-Low']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setLocal(() => _sortBy = v ?? 'Newest'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _search(_searchController.text);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentSearches = ref.read(cacheServiceProvider).getRecentSearches();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: RefreshIndicator(
        onRefresh: () => _search(_searchController.text),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onChange,
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.tune), onPressed: _openFilters),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_searchController.text.trim().isEmpty && recentSearches.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: recentSearches
                    .map(
                      (item) => ActionChip(
                        label: Text(item),
                        onPressed: () {
                          _searchController.text = item;
                          _search(item);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_searchController.text.trim().isNotEmpty && _results.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: Text('No listings found for your search')), 
              )
            else ..._results.map(
              (listing) => FutureBuilder(
                future: ref.read(reviewServiceProvider).getUser(listing.sellerId),
                builder: (context, snapshot) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 260,
                      child: ListingCard(
                        listing: listing,
                        sellerName: snapshot.data?.name ?? 'Seller',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
