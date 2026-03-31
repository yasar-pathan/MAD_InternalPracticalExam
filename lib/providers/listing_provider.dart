import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listing_model.dart';
import '../services/listing_service.dart';

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) {
    state = category;
  }
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

final listingsProvider = StreamProvider.autoDispose<List<ListingModel>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  return ref.watch(listingServiceProvider).getListings(category: category);
});

final listingByIdProvider = FutureProvider.family<ListingModel, String>((ref, id) {
  return ref.watch(listingServiceProvider).getListingById(id);
});
