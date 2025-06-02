import 'package:flutter/material.dart';
import 'package:myproject/models/products.dart';
import 'package:myproject/utils/constants.dart';
import 'package:myproject/utils/formatCurrency.dart';
import 'package:myproject/config/config.dart';

class CoffeeCard extends StatelessWidget {
  final Product product;
  final String userId;

  const CoffeeCard({
    Key? key,
    required this.product,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Kích thước cố định cho hình ảnh
    const double imageHeight = 120.0;
    const double imageWidth = double.infinity;

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
            height: imageHeight,
            width: imageWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: _buildProductImage(),
            ),
          ),

          // Phần thông tin sản phẩm
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
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
                    product.description,
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
                        '${formatCurrency(product.price)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextColor1,
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

  Widget _buildProductImage() {
    String fullImageUrl = '';
    if (product.imageUrl.isNotEmpty) {
      if (product.imageUrl.startsWith('http')) {
        // Nếu imageUrl đã là một URL đầy đủ
        fullImageUrl = product.imageUrl;
      } else {
        // Nếu imageUrl là đường dẫn tương đối từ server của bạn
        fullImageUrl = AppConfig.getBaseUrlForFiles() +
            (product.imageUrl.startsWith('/')
                ? product.imageUrl
                : '/${product.imageUrl}');
      }
    } else {
      // Ảnh placeholder nếu không có imageUrl hoặc imageUrl rỗng
      fullImageUrl = 'https://via.placeholder.com/150?text=No+Image';
    }
    // print('CoffeeCard - Displaying Image: $fullImageUrl for ${product.name}');
    return Image.network(
      fullImageUrl,
      fit: BoxFit.cover,
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
