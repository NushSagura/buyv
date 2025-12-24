import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../domain/models/cj_product_model.dart';
import '../../../services/post_service.dart';

class AddPostScreen extends StatefulWidget {
  final CJProduct? selectedProduct;
  final bool forceReelType;

  const AddPostScreen({
    super.key,
    this.selectedProduct,
    this.forceReelType = false,
  });

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  XFile? _selectedMedia;
  String _selectedPostType = 'reel'; // reel, photo
  List<String> _taggedFriends = [];
  List<String> _hashtags = [];
  String? _selectedMusic;

  @override
  void initState() {
    super.initState();

    // If a product is selected for promotion, force reel type
    if (widget.selectedProduct != null || widget.forceReelType) {
      _selectedPostType = 'reel';
    }

    // Pre-fill caption with product info if available
    if (widget.selectedProduct != null) {
      _captionController.text =
          'Check out this amazing product: ${widget.selectedProduct!.productName}';
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectMedia() async {
    try {
      // Show dialog to choose between camera and gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Choose Media Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source != null) {
        XFile? pickedFile;

        // Choose between image and video based on post type
        if (_selectedPostType == 'reel') {
          pickedFile = await _picker.pickVideo(source: source);
        } else {
          pickedFile = await _picker.pickImage(source: source);
        }

        if (pickedFile != null) {
          setState(() {
            _selectedMedia = pickedFile;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${_selectedPostType == 'reel' ? 'Video' : 'Image'} selected successfully',
                ),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting media: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _publishPost() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a description for the post'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image or video for the post'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Prepare optional metadata
      Map<String, dynamic> additionalData = {
        'userName': currentUser.displayName,
        'userImage': currentUser.profileImageUrl ?? '',
        'location': _locationController.text.trim(),
        'isActive': true,
        'tags': _hashtags,
      };

      // Add CJ product info if this is a promotional reel
      if (widget.selectedProduct != null) {
        additionalData.addAll({
          'isPromotional': true,
          'cjProductId': widget.selectedProduct!.pid,
          'cjProductName': widget.selectedProduct!.productName,
          'cjProductPrice': widget.selectedProduct!.sellPrice,
          'cjProductImage': widget.selectedProduct!.productImage,
          'commissionRate': 0.01, // 1%
          'expectedCommission': widget.selectedProduct!.commission,
        });
      }

      // Save via PostService (handles upload)
      final post = await PostService().createPost(
        type: _selectedPostType,
        file: _selectedMedia!,
        caption: _captionController.text.trim(),
        additionalData: additionalData,
      );

      if (post == null) {
        throw Exception('Failed to publish ${_selectedPostType}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedPostType == 'reel' ? 'Reel' : 'Post'} published successfully',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error publishing post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error occurred: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
        ),
        title: const Text(
          'Add New Post',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Type Selection Section
            if (widget.selectedProduct == null && !widget.forceReelType)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Post Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D3D67),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPostTypeOption(
                            type: 'reel',
                            icon: Icons.video_library,
                            label: 'Reel',
                            isSelected: _selectedPostType == 'reel',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPostTypeOption(
                            type: 'photo',
                            icon: Icons.photo_camera,
                            label: 'Photo',
                            isSelected: _selectedPostType == 'photo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Product promotion info
            if (widget.selectedProduct != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.campaign, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Promotional Reel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.selectedProduct!.productImage,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedProduct!.productName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Commission: \$${widget.selectedProduct!.commission.toStringAsFixed(2)} per sale',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Media Upload Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPostType == 'reel'
                        ? 'Upload Video'
                        : 'Upload Image',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D3D67),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _selectMedia,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedMedia != null
                              ? const Color(0xFF176DBA)
                              : const Color(0xFFDEE2E6),
                          width: 2,
                        ),
                      ),
                      child: _selectedMedia != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _selectedPostType == 'reel'
                                  ? Container(
                                      color: Colors.black,
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.play_circle_filled,
                                              size: 60,
                                              color: Color(0xFFFF6F00),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Video Selected',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : kIsWeb
                                  ? Image.network(
                                      _selectedMedia!.path,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.error),
                                            );
                                          },
                                    )
                                  : Image.file(
                                      File(_selectedMedia!.path),
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF6F00),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _selectedPostType == 'reel'
                                        ? Icons.videocam
                                        : Icons.camera_alt,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedPostType == 'reel'
                                      ? 'Tap to add video'
                                      : 'Tap to add image',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6C757D),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Supported formats: JPG, PNG, MP4',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Post Details Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Post Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D3D67),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  CustomTextField(
                    controller: _captionController,
                    labelText: 'Description',
                    hintText: 'Write a description for your post...',
                    maxLines: 3,
                    prefixIcon: Icons.description,
                  ),

                  const SizedBox(height: 16),

                  // Location Field
                  CustomTextField(
                    controller: _locationController,
                    labelText: 'Location (Optional)',
                    hintText: 'Add location',
                    prefixIcon: Icons.location_on,
                  ),

                  // Product-specific fields
                  if (_selectedPostType == 'product') ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _priceController,
                      labelText: 'Price',
                      hintText: 'Enter product price',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.attach_money,
                    ),

                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _quantityController,
                      labelText: 'Quantity',
                      hintText: 'Available quantity',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.inventory,
                    ),

                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _categoryController,
                      labelText: 'Category',
                      hintText: 'Product category',
                      prefixIcon: Icons.category,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Additional Options Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Additional Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D3D67),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildOptionTile(
                    icon: Icons.people,
                    title: 'Tag Friends',
                    subtitle: 'Tag people in your post',
                    onTap: () {
                      _showTagFriendsDialog(context);
                    },
                  ),

                  const Divider(height: 24),

                  _buildOptionTile(
                    icon: Icons.tag,
                    title: 'Add Hashtags',
                    subtitle: 'Make your post discoverable',
                    onTap: () {
                      _showHashtagsDialog(context);
                    },
                  ),

                  if (_selectedPostType == 'reel') ...[
                    const Divider(height: 24),
                    _buildOptionTile(
                      icon: Icons.music_note,
                      title: 'Add Music',
                      subtitle: 'Add background music for reel',
                      onTap: () {
                        _showMusicDialog(context);
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post saved as draft')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C757D),
                      side: const BorderSide(color: Color(0xFFDEE2E6)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Draft',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _publishPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Publish Post',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTypeOption({
    required String type,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPostType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF176DBA) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF176DBA)
                : const Color(0xFFDEE2E6),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : const Color(0xFF6C757D),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6C757D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6F00).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFFF6F00), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0D3D67),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF9CA3AF),
      ),
      onTap: onTap,
    );
  }

  void _showTagFriendsDialog(BuildContext context) {
    final TextEditingController friendController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tag Friends'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: friendController,
              decoration: const InputDecoration(
                hintText: 'Enter friend\'s username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            if (_taggedFriends.isNotEmpty) ...[
              const Text('Tagged Friends:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _taggedFriends
                    .map(
                      (friend) => Chip(
                        label: Text('@$friend'),
                        onDeleted: () {
                          setState(() {
                            _taggedFriends.remove(friend);
                          });
                          Navigator.pop(context);
                          _showTagFriendsDialog(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (friendController.text.isNotEmpty) {
                setState(() {
                  _taggedFriends.add(friendController.text);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showHashtagsDialog(BuildContext context) {
    final TextEditingController hashtagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Hashtags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hashtagController,
              decoration: const InputDecoration(
                hintText: 'Enter hashtag (without #)',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),
            if (_hashtags.isNotEmpty) ...[
              const Text('Added Hashtags:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _hashtags
                    .map(
                      (hashtag) => Chip(
                        label: Text('#$hashtag'),
                        onDeleted: () {
                          setState(() {
                            _hashtags.remove(hashtag);
                          });
                          Navigator.pop(context);
                          _showHashtagsDialog(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (hashtagController.text.isNotEmpty) {
                setState(() {
                  _hashtags.add(hashtagController.text);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showMusicDialog(BuildContext context) {
    final List<String> musicOptions = [
      'No Music',
      'Trending Song 1',
      'Trending Song 2',
      'Trending Song 3',
      'Popular Beat 1',
      'Popular Beat 2',
      'Chill Vibes',
      'Upbeat Track',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Music'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: musicOptions.length,
            itemBuilder: (context, index) {
              final music = musicOptions[index];
              return ListTile(
                leading: Icon(
                  music == 'No Music' ? Icons.music_off : Icons.music_note,
                ),
                title: Text(music),
                trailing: _selectedMusic == music
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedMusic = music == 'No Music' ? null : music;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
