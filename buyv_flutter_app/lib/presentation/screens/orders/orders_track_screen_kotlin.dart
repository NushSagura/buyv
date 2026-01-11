import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Orders Track Screen - Design Kotlin
/// Avec timeline horizontal et système de rating
class OrdersTrackScreenKotlin extends StatefulWidget {
  const OrdersTrackScreenKotlin({super.key});

  @override
  State<OrdersTrackScreenKotlin> createState() => _OrdersTrackScreenKotlinState();
}

class _OrdersTrackScreenKotlinState extends State<OrdersTrackScreenKotlin> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  File? _selectedImage;
  bool _isDelivered = true;
  int _currentStep = 2; // 0 = Order Placed, 1 = On the Way, 2 = Delivered

  // Mock product data
  final String _productName = "Hanger Shirt";
  final String _productDesc = "Slim Fit, Men's Fashion";
  final String _productPrice = "\$100.00";

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Orders Track',
          style: TextStyle(
            color: Color(0xFF0066CC),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0066CC)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header Card
            _buildProductHeader(),
            
            const SizedBox(height: 24),
            
            // Truck Icon
            Center(
              child: Icon(
                Icons.local_shipping,
                size: 54,
                color: const Color(0xFF2196F3),
              ),
            ),
            
            const SizedBox(height: 18),
            
            // Title
            const Center(
              child: Text(
                'Track Your Order',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 29,
                  color: Color(0xFF172D3F),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Horizontal Progress Timeline
            _buildHorizontalTimeline(),
            
            const SizedBox(height: 48),
            
            // Confirm Delivery Button
            _buildConfirmDeliveryButton(),
            
            // Review Section (if delivered)
            if (_isDelivered) ...[
              const SizedBox(height: 32),
              _buildReviewSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Product Image (placeholder)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.checkroom,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF172D3F),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _productDesc,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Price
          Text(
            _productPrice,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6F00),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTimeline() {
    final steps = [
      {'label': 'Order\nPlaced', 'icon': Icons.shopping_bag},
      {'label': 'On the\nWay', 'icon': Icons.local_shipping},
      {'label': 'Delivery', 'icon': Icons.home},
    ];

    return Column(
      children: [
        // Timeline with dots and lines
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isEven) {
              // Dot
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex <= _currentStep;
              final isActive = stepIndex == _currentStep;
              
              return _buildTimelineDot(isCompleted, isActive);
            } else {
              // Line
              final lineIndex = index ~/ 2;
              final isCompleted = lineIndex < _currentStep;
              
              return Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted 
                          ? [const Color(0xFFFF9800), const Color(0xFF2196F3)]
                          : [Colors.grey[300]!, Colors.grey[300]!],
                    ),
                  ),
                ),
              );
            }
          }),
        ),
        
        const SizedBox(height: 12),
        
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = index <= _currentStep;
            
            return SizedBox(
              width: 80,
              child: Text(
                step['label'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? Colors.black : Colors.grey,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimelineDot(bool isCompleted, bool isActive) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted 
            ? (isActive ? const Color(0xFF2196F3) : const Color(0xFFFF9800))
            : Colors.grey[300],
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : [],
      ),
    );
  }

  Widget _buildConfirmDeliveryButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6F00).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isDelivered = true;
          });
        },
        icon: const Icon(Icons.check_circle, color: Colors.white),
        label: const Text(
          'Confirm Delivery',
          style: TextStyle(
            fontSize: 19,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6F00),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How was your experience?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 21,
            color: Color(0xFF172D3F),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Star Rating
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = index + 1;
                });
              },
              child: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: const Color(0xFFFF6F00),
                size: 34,
              ),
            );
          }),
        ),
        
        const SizedBox(height: 15),
        
        // Image preview if selected
        if (_selectedImage != null) ...[
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey, width: 1),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: IconButton(
                  onPressed: _removeImage,
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.7),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        
        // Review input and image picker
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBCC3C7), width: 1),
                ),
                child: TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write a review',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            
            const SizedBox(width: 10),
            
            // Image picker button
            IconButton(
              onPressed: _pickImage,
              icon: const Icon(
                Icons.image,
                color: Color(0xFF176DBA),
                size: 30,
              ),
              iconSize: 42,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 28),
        
        // Submit Review Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6F00).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              if (_rating == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a rating'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (_reviewController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please write a review'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Submit review logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Review submitted successfully!'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
              
              // Clear form
              setState(() {
                _rating = 0;
                _reviewController.clear();
                _selectedImage = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F00),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text(
              'Submit Review',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
