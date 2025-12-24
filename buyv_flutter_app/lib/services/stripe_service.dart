import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'security/secure_token_manager.dart';

class StripeService {
  static final StripeService instance = StripeService._internal();
  factory StripeService() => instance;
  StripeService._internal();

  /// Initialize Stripe with Publishable Key (Configured in main.dart ideally, or here lazily)
  void init() {
    // Ideally STRIPE_PUBLISHABLE_KEY should be handled via env,
    // but flutter_dotenv must be loaded before this.
    // Assuming keys are set in main.dart
  }

  Future<void> makePayment({
    required BuildContext context,
    required double amount,
    required String currency,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // 1. Create Payment Intent on Backend
      final paymentData = await _createPaymentIntent(amount, currency);

      if (paymentData == null) {
        onError('Failed to create payment intent');
        return;
      }

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentData['clientSecret'],
          merchantDisplayName: 'BuyV Store',
          customerId: paymentData['customer'],
          customerEphemeralKeySecret: paymentData['ephemeralKey'],
          // style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: Color(0xFFE94057)),
          ),
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Success
      onSuccess();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // User canceled, do nothing or show toast
        return;
      }
      onError('Payment Request Failed: ${e.error.localizedMessage}');
    } catch (e) {
      onError('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(
    double amount,
    String currency,
  ) async {
    try {
      final token = await SecureTokenManager.getAccessToken();
      final url = Uri.parse(
        '${AppConstants.fastApiBaseUrl}/payments/create-payment-intent',
      );

      // Amount must be integer cents
      final int amountCents = (amount * 100).toInt();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amountCents, 'currency': currency}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Backend payment intent error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Create payment intent exception: $e');
      return null;
    }
  }
}
