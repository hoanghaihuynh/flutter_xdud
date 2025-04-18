import 'package:flutter/material.dart';
import 'package:myproject/models/products.dart';
import 'package:myproject/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CoffeeCard extends StatelessWidget {
  final Products coffee;
  final String userId; // Thêm userId để sử dụng trong API

  const CoffeeCard({
    Key? key,
    required this.coffee,
    required this.userId, // Thêm userId vào constructor
  }) : super(key: key);

  // Hàm call API thêm sản phẩm vào giỏ hàng
  Future<void> addToCart(BuildContext context) async {
    const String apiUrl =
        'http://172.20.12.120:3000/cart/insertCart'; // Thay bằng endpoint thực tế của bạn

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userId": userId,
          "productId": coffee.id, // Giả sử Products model có trường id
          "quantity": 1 // Mặc định thêm 1 sản phẩm
        }),
      );

      if (response.statusCode == 201) {
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ĐÃ THÊM VÀO GIỎ HÀNG'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Xử lý khi API trả về lỗi
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Xử lý lỗi kết nối
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kích thước cố định cho tất cả hình ảnh
    const double imageHeight = 120.0; // Chỉnh theo nhu cầu
    const double imageWidth = double.infinity; // Chiều rộng bằng thẻ

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần hình ảnh với kích thước cố định
          Container(
            height: imageHeight, // Chiều cao cố định
            width: imageWidth, // Chiều rộng bằng thẻ
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: _buildProductImage(),
            ),
          ),

          // Phần thông tin sản phẩm (giữ nguyên)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coffee.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextColor1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    coffee.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(coffee.price)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextColor1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => addToCart(context),
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kTextColor1,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị hình ảnh (tách riêng để dễ quản lý)
  Widget _buildProductImage() {
    return Image.network(
      coffee.imageUrl,
      fit: BoxFit.cover, // Đảm bảo hình cover toàn bộ khung
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: 50,
            ),
          ),
        );
      },
    );
  }
}
