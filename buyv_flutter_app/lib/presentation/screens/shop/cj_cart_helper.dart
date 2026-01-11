import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/cj_product_model.dart';
import '../../../domain/models/product_model.dart';
import '../../providers/cart_provider.dart';

void addCJProductToCart(BuildContext context, CJProduct cjProduct) {
  final cartProvider = Provider.of<CartProvider>(context, listen: false);
  
  // Construire la liste des images (inclure l'image principale si productImages est vide)
  List<String> imageUrls = cjProduct.productImages.isNotEmpty 
      ? cjProduct.productImages 
      : (cjProduct.productImage.isNotEmpty ? [cjProduct.productImage] : []);
  
  // Convertir CJProduct en ProductModel pour le panier
  final productModel = ProductModel(
    id: cjProduct.pid,
    name: cjProduct.productName,
    description: cjProduct.description,
    price: cjProduct.sellPrice,
    discountPrice: cjProduct.originalPrice > cjProduct.sellPrice ? cjProduct.sellPrice : null,
    category: cjProduct.categoryName,
    imageUrls: imageUrls,
    videoUrl: null,
    stockQuantity: 100,
    isAvailable: true,
    rating: cjProduct.rating,
    reviewsCount: cjProduct.reviewCount,
    sellerId: 'cj_dropshipping',
    sellerName: 'CJ Dropshipping',
    tags: [],
    specifications: cjProduct.specifications,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    viewsCount: 0,
    likesCount: 0,
    isFeatured: false,
  );
  
  cartProvider.addToCart(productModel, quantity: 1);
  
  // Fermer tout snackbar existant avant d'en afficher un nouveau
  ScaffoldMessenger.of(context).clearSnackBars();
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${cjProduct.productName} added to cart!'),
      backgroundColor: const Color(0xFF4CAF50),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
