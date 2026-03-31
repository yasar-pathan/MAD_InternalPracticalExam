import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../services/listing_service.dart';
import '../../services/storage_service.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Electronics';
  
  final List<String> categories = ['Electronics', 'Clothing', 'Vehicles', 'Furniture', 'Books', 'Sports', 'Other'];
  final List<File> _images = [];
  bool _isLoading = false;

  Future<void> _pickImage() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 5 images allowed')));
      return;
    }
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _images.add(File(pickedFile.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least 1 image')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('Must be logged in');

      final storage = ref.read(storageServiceProvider);
      final downloadUrls = await storage.uploadListingImages(_images);

      final listing = ListingModel(
        id: '',
        title: _titleController.text.trim(),
        lowercaseTitle: _titleController.text.trim().toLowerCase(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        images: downloadUrls,
        category: _selectedCategory,
        sellerId: user.uid,
        status: 'active',
        createdAt: DateTime.now(),
        location: _locationController.text.trim(),
      );

      await ref.read(listingServiceProvider).createListing(listing);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing created successfully!'), backgroundColor: Colors.green));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Listing')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _images.length) {
                            return GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Icon(Icons.add_a_photo, color: Colors.grey),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(image: FileImage(_images[index]), fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                      maxLength: 100,
                      validator: (v) => v!.isEmpty ? 'Enter title' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder(), prefixText: '\$ '),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v!.isEmpty) return 'Enter price';
                        final p = double.tryParse(v);
                        if (p == null || p <= 0) return 'Must be valid positive number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Enter location' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 4,
                      validator: (v) => v!.isEmpty ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Post Listing', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
