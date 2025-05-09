import 'package:http/http.dart' as http;
import 'dart:convert';
import './../config/config.dart';
import 'package:flutter/foundation.dart';

class ToppingService {
  static final ToppingService _instance = ToppingService._internal();
  factory ToppingService() => _instance;
  ToppingService._internal();

  final Map<String, String> _toppingCache = {};

  Future<String> getToppingName(String toppingId) async {
    if (_toppingCache.containsKey(toppingId)) {
      return _toppingCache[toppingId]!;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.getApiUrl('/topping/getToppingById')}/$toppingId'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final toppingName =
            responseData['name'] as String? ?? 'Topping $toppingId';

        _toppingCache[toppingId] = toppingName;
        return toppingName;
      } else {
        debugPrint('Failed to load topping: ${response.statusCode}');
        return 'Topping $toppingId';
      }
    } catch (e) {
      debugPrint('Error fetching topping name: $e');
      return 'Topping $toppingId';
    }
  }

  Future<Map<String, String>> getBatchToppings(List<String> toppingIds) async {
    final Map<String, String> result = {};
    final List<String> uncachedIds = [];

    // Kiểm tra cache trước
    for (var id in toppingIds) {
      if (_toppingCache.containsKey(id)) {
        result[id] = _toppingCache[id]!;
      } else {
        uncachedIds.add(id);
      }
    }

    // Nếu tất cả đã có trong cache thì return luôn
    if (uncachedIds.isEmpty) return result;

    try {
      // Gọi API cho các topping chưa có trong cache
      for (var id in uncachedIds) {
        final response = await http.get(
          Uri.parse('${AppConfig.getApiUrl('/topping/getToppingById')}/$id'),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final name = responseData['name'] as String? ?? 'Topping $id';
          result[id] = name;
          _toppingCache[id] = name;
        } else {
          result[id] = 'Topping $id';
          debugPrint('Failed to load topping $id: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error batch loading toppings: $e');
      // Đặt giá trị mặc định cho các topping bị lỗi
      for (var id in uncachedIds) {
        result[id] = 'Topping $id';
      }
    }

    return result;
  }
}
