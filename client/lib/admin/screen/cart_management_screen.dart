import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../admin/models/cart_model.dart';
import '../../admin/services/cart_service.dart';

class CartManagementScreen extends StatefulWidget {
  const CartManagementScreen({super.key});

  @override
  State<CartManagementScreen> createState() => _CartManagementScreenState();
}

class _CartManagementScreenState extends State<CartManagementScreen> {
  List<Cart> _carts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCarts();
  }

  Future<void> _loadCarts() async {
    setState(() => _isLoading = true);
    try {
      final carts = await CartService.getAllCarts();
      setState(() => _carts = carts);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Cart> get _filteredCarts {
    if (_searchQuery.isEmpty) return _carts;
    return _carts
        .where((cart) =>
            cart.userId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            cart.items.any((item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCarts,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by User ID or Product...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCarts.isEmpty
                    ? const Center(child: Text('No carts found'))
                    : ListView.builder(
                        itemCount: _filteredCarts.length,
                        itemBuilder: (context, index) {
                          final cart = _filteredCarts[index];
                          return _buildCartCard(cart);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartCard(Cart cart) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCartDetails(cart),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User ID: ${cart.userId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  // Chip(
                  //   label: Text(
                  //     'Details',
                  //     style: const TextStyle(color: Colors.white),
                  //   ),
                  //   backgroundColor: Colors.blue,
                  // ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${formatter.format(cart.totalPrice)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (cart.items.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text('First item: ${cart.items.first.name}',
                        style: TextStyle(color: Colors.grey[600])),
                    Text(
                        'Qty: ${cart.items.first.quantity} ,${formatter.format(cart.items.first.price)}',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCartDetails(Cart cart) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cart Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                title: const Text('User ID'),
                subtitle: Text(cart.userId),
              ),
              ListTile(
                title: const Text('Total Price'),
                trailing: Text(
                  formatter.format(cart.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(),
              const Text(
                'Cart Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItemTile(item, formatter);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItemTile(CartItem item, NumberFormat formatter) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
          ),
        ),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: ${item.size} | Sugar: ${item.sugarLevel}'),
            if (item.toppings.isNotEmpty)
              Text('Toppings: ${item.toppings.join(', ')}'),
            Text('${item.quantity} × ${formatter.format(item.price)}'),
          ],
        ),
        trailing: Text(
          formatter.format(item.totalPrice),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
