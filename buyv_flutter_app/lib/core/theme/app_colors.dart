import 'package:flutter/material.dart';

/// Couleurs exactes extraites de Colors.kt (Kotlin)
class AppColors {
  // Couleurs Primaires
  static const Color primary = Color(0xFFF4A032);         // Orange Kotlin
  static const Color primaryText = Color(0xFF114B7F);     // PrimaryColorText
  static const Color primary80 = Color(0xCCF4A032);
  static const Color primary60 = Color(0x99F4A032);
  static const Color primary37 = Color(0x5EF4A032);
  
  // Couleurs Secondaires (Bleu)
  static const Color secondary = Color(0xFF0B649B);       // SecondaryColor Kotlin
  static const Color secondary80 = Color(0xCC0B649B);
  static const Color secondary60 = Color(0x990B649B);
  static const Color secondary37 = Color(0x5E0B649B);
  
  // Couleurs de texte
  static const Color titleText = Color(0xFF00210E);       // TitleTextColor
  static const Color titleText80 = Color(0xCC00210E);
  static const Color titleText60 = Color(0x9900210E);
  
  // Noir
  static const Color black = Color(0xFF121212);           // BlackColor
  static const Color black80 = Color(0xCC121212);
  static const Color black60 = Color(0x99121212);
  static const Color black37 = Color(0x5E121212);
  
  // Gris
  static const Color grayDeep = Color(0xFF444444);        // GrayDeep
  static const Color gray = Color(0xFFD5D6DB);            // GrayColor
  static const Color primaryGray = Color(0xFF7A7E91);     // PrimaryGray (nav inactive)
  
  // Couleurs spéciales
  static const Color chips = Color(0xFF34BE9D);           // ChipsColor (succès)
  static const Color error = Color(0xFFE46962);           // ErrorPrimaryColor
  static const Color errorSecondary = Color(0xFFEC928E);
  static const Color errorThird = Color(0xFFFFDAD6);
  
  // Alias pratiques
  static const Color success = chips;
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color textPrimary = black;
  static const Color textSecondary = primaryGray;
  static const Color border = gray;
  
  // Gradient Kotlin
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
  
  // Gradient inversé
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, primary],
  );
}
