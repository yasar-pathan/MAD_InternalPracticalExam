import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/listing_model.dart';
import '../../providers/listing_provider.dart';
import '../../services/listing_service.dart';
import '../../services/storage_service.dart';

class EditListingScreen extends ConsumerStatefulWidget {
  const EditListingScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  List<String> _existingImages = [];
  final List<File> _newImages = [];
  bool _isSaving = false;
  bool _sold = false;
  String _category = 'Electronics';

  static const categories = ['Electronics', 'Clothing', 'Vehicles', 'Furniture', 'Books', 'Sports', 'Other'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    if (_existingImages.length + _newImages.length >= 5) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _newImages.add(File(picked.path)));
  }

  Future<void> _save(ListingModel listing) async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least 1 image is required')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uploaded = _newImages.isEmpty ? <String>[] : await ref.read(storageServiceProvider).uploadListingImages(_newImages);
      final updated = listing.copyWith(
        title: _titleController.text.trim(),
        lowercaseTitle: _titleController.text.trim().toLowerCase(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _category,
        location: _locationController.text.trim(),
        images: [..._existingImages, ...uploaded],
        status: _sold ? 'sold' : 'active',
      );

      await ref.read(listingServiceProvider).updateListing(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update listing: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _prefill(ListingModel listing) {
    if (_titleController.text.isNotEmpty) return;
    _titleController.text = listing.title;
    _descController.text = listing.description;
    _priceController.text = listing.price.toStringAsFixed(0);
    _locationController.text = listing.location;
    _existingImages = List<String>.from(listing.images);
    _category = listing.category;
    _sold = listing.status == 'sold';
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingByIdProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Listing')),
      body: listingAsync.when(
        data: (listing) {
          _prefill(listing);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Text('Mark as Sold'),
                    Switch(value: _sold, onChanged: (v) => setState(() => _sold = v)),
                  ],
                ),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._existingImages.map(
                        (url) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Image.network(url, width: 90, height: 90, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.white),
                                  onPressed: () => setState(() => _existingImages.remove(url)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ..._newImages.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Image.file(entry.value, width: 90, height: 90, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.white),
                                  onPressed: () => setState(() => _newImages.removeAt(entry.key)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    if (value == null || value <= 0) return 'Enter a positive price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _category = v ?? categories.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _save(listing),
                  child: _isSaving ? const CircularProgressIndicator() : const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load listing: $e')),
      ),
    );
  }
}
