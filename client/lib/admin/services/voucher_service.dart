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

  // API thêm voucher
  Future<Voucher?> createVoucher({
    required String code,
    required String discountType,
    required double discountValue,
    required double maxDiscount,
    required DateTime startDate,
    required DateTime expiryDate,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/voucher/createVoucher')),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'code': code,
          'discount_type': discountType,
          'discount_value': discountValue,
          'max_discount': maxDiscount,
          'start_date': startDate.toIso8601String(),
          'expiry_date': expiryDate.toIso8601String(),
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return Voucher.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to create voucher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create voucher: $e');
    }
  }

  /// API chỉnh sửa voucher
  ///
  /// [voucherId] là ID của voucher cần cập nhật.
  /// [updateData] là một Map chứa các trường cần cập nhật.
  /// Ví dụ: {'code': 'NEWCODE', 'discount_value': 20}
  Future<Voucher?> updateVoucher(
      String voucherId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse(AppConfig.getApiUrl('/voucher/updateVoucher/$voucherId')),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return Voucher.fromJson(jsonResponse);
      } else {
        // Thêm log để xem chi tiết lỗi từ server
        print(
            'Failed to update voucher. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to update voucher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update voucher: $e');
    }
  }
}
