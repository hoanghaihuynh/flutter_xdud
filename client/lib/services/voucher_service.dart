// services/voucher_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart'; 
import 'package:myproject/utils/getUserId.dart'; // Assuming getUserId is here

class VoucherService {
  Future<Map<String, dynamic>> applyVoucher(String voucherCode) async {
    final userId = await getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('User not logged in');
    }

    final response = await http.post(
      Uri.parse(AppConfig.getApiUrl('/cart/apply-voucher')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'voucher_code': voucherCode}),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      return responseData; // Hoặc chỉ trả về phần data cần thiết
    } else {
      throw Exception(responseData['message'] ?? 'Failed to apply voucher');
    }
  }
}