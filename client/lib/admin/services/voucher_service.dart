import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart';
import './../models/voucher_model.dart';

class VoucherService {
  // Api Danh sách voucher
  Future<List<Voucher>> getAllVouchers() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.getApiUrl('/voucher/getAllVoucher')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((json) => Voucher.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vouchers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load vouchers: $e');
    }
  }

  // API xóa voucher
  Future<bool> deleteVoucher(String voucherId) async {
    try {
      final response = await http.delete(
        Uri.parse(AppConfig.getApiUrl('/voucher/deleteVoucher/$voucherId')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['message'] == 'Voucher DELETED SUCCESSFULLY';
      } else {
        throw Exception('Failed to delete voucher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete voucher: $e');
    }
  }
}
