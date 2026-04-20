import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripeService {
  static const Map<String, String> _testTokens = {
    '0124597636544145': 'tok_visa',
    '9451230456789512': 'tok_visa_debit',
    '1032654789542536': 'tok_mastercard',
    '1254630148754556': 'tok_visa_mastercard_debit',
    '9548762015555545': 'tok_visa_chargeDeclined',
    '3245619854763102': 'tok_chargeDeclinedInsufficientFunds'
  };

  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll(' ', '');
    final token = _testTokens[cleanCard];

    if (token == null) {
      return {
        'success': false,
        'error': 'Unknown test card. Use 0124597636544145 or 1032654789542536',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amountInCentavos,
          'currency': 'php',
          'payment_method_types[]': 'card',
          'payment_method_data[type]': 'card',
          'payment_method_data[card][token]': token,
          'confirm': 'true',
          'return_url': 'https://example.com/return',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == 'succeeded') {
          return {
            'success': true,
            'data': data,
          };
        } else {
          return {
            'success': false,
            'error': 'Payment status: ${data['status']}',
            'data': data,
          };
        }
      } else {
        return {
          'success': false,
          'error': data['error']?['message'] ?? 'Payment failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': {e.toString()},
      };
    }
  }
}
