import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ar', 'SA'),
    Locale('fr', 'FR'),
  ];

  // Common
  String get appName => _localizedValues[locale.languageCode]!['app_name']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get search => _localizedValues[locale.languageCode]!['search']!;

  // Navigation
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get shop => _localizedValues[locale.languageCode]!['shop']!;
  String get cart => _localizedValues[locale.languageCode]!['cart']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get reels => _localizedValues[locale.languageCode]!['reels']!;
  String get products => _localizedValues[locale.languageCode]!['products']!;

  // Cart
  String get addToCart => _localizedValues[locale.languageCode]!['add_to_cart']!;
  String get removeFromCart => _localizedValues[locale.languageCode]!['remove_from_cart']!;
  String get cartEmpty => _localizedValues[locale.languageCode]!['cart_empty']!;
  String get cartEmptyMessage => _localizedValues[locale.languageCode]!['cart_empty_message']!;
  String get continueShopping => _localizedValues[locale.languageCode]!['continue_shopping']!;
  String get subtotal => _localizedValues[locale.languageCode]!['subtotal']!;
  String get shipping => _localizedValues[locale.languageCode]!['shipping']!;
  String get tax => _localizedValues[locale.languageCode]!['tax']!;
  String get total => _localizedValues[locale.languageCode]!['total']!;
  String get buy => _localizedValues[locale.languageCode]!['buy']!;
  String get checkout => _localizedValues[locale.languageCode]!['checkout']!;

  // Product
  String get price => _localizedValues[locale.languageCode]!['price']!;
  String get discount => _localizedValues[locale.languageCode]!['discount']!;
  String get inStock => _localizedValues[locale.languageCode]!['in_stock']!;
  String get outOfStock => _localizedValues[locale.languageCode]!['out_of_stock']!;

  // Auth
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'BuyV',
      'loading': 'Loading...',
      'error': 'Error',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'home': 'Home',
      'shop': 'Shop',
      'cart': 'Cart',
      'profile': 'Profile',
      'reels': 'Reels',
      'products': 'Products',
      'add_to_cart': 'Add to Cart',
      'remove_from_cart': 'Remove from Cart',
      'cart_empty': 'Your cart is empty',
      'cart_empty_message': 'Add some products to get started',
      'continue_shopping': 'Continue Shopping',
      'subtotal': 'Subtotal',
      'shipping': 'Shipping',
      'tax': 'Tax',
      'total': 'Total',
      'buy': 'Buy',
      'checkout': 'Checkout',
      'price': 'Price',
      'discount': 'Discount',
      'in_stock': 'In Stock',
      'out_of_stock': 'Out of Stock',
      'login': 'Login',
      'logout': 'Logout',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
    },
    'ar': {
      'app_name': 'BuyV',
      'loading': 'Loading...',
      'error': 'Error',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'home': 'Home',
      'shop': 'Shop',
      'cart': 'Cart',
      'profile': 'Profile',
      'reels': 'Reels',
      'products': 'Products',
      'add_to_cart': 'Add to Cart',
      'remove_from_cart': 'Remove from Cart',
      'cart_empty': 'Your cart is empty',
      'cart_empty_message': 'Add some products to get started',
      'continue_shopping': 'Continue Shopping',
      'subtotal': 'Subtotal',
      'shipping': 'Shipping',
      'tax': 'Tax',
      'total': 'Total',
      'buy': 'Buy',
      'checkout': 'Checkout',
      'price': 'Price',
      'discount': 'Discount',
      'in_stock': 'In Stock',
      'out_of_stock': 'Out of Stock',
      'login': 'Login',
      'logout': 'Logout',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
    },
    'fr': {
      'app_name': 'BuyV',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'ok': 'OK',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'search': 'Rechercher',
      'home': 'Accueil',
      'shop': 'Boutique',
      'cart': 'Panier',
      'profile': 'Profil',
      'reels': 'Reels',
      'products': 'Produits',
      'add_to_cart': 'Ajouter au panier',
      'remove_from_cart': 'Retirer du panier',
      'cart_empty': 'Votre panier est vide',
      'cart_empty_message': 'Ajoutez des produits pour commencer',
      'continue_shopping': 'Continuer les achats',
      'subtotal': 'Sous-total',
      'shipping': 'Livraison',
      'tax': 'Taxe',
      'total': 'Total',
      'buy': 'Acheter',
      'checkout': 'Commander',
      'price': 'Prix',
      'discount': 'Remise',
      'in_stock': 'En stock',
      'out_of_stock': 'Rupture de stock',
      'login': 'Connexion',
      'logout': 'Déconnexion',
      'register': 'S\'inscrire',
      'email': 'Email',
      'password': 'Mot de passe',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}