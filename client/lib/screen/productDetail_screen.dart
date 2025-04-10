import 'package:flutter/material.dart';
import 'package:myproject/models/products.dart';

class ProductDetail extends StatelessWidget {
  final Products product;
  final String userId;

  const ProductDetail({
    Key? key,
    required this.product,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              product.imageUrl,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price}đ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ) ??
                        TextStyle(
                          // Fallback style nếu headline5 là null
                          fontSize: 24,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  // Thêm các widget khác tùy theo nhu cầu
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // Xử lý thêm vào giỏ hàng
          },
          child: const Text('Thêm vào giỏ hàng'),
        ),
      ),
    );
  }
}
