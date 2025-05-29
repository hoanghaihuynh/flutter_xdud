import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './../models/voucher_model.dart';
import './../services/voucher_service.dart';

class VoucherManagementScreen extends StatefulWidget {
  const VoucherManagementScreen({super.key});

  @override
  State<VoucherManagementScreen> createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  final VoucherService _voucherService = VoucherService();
  late Future<List<Voucher>> _vouchersFuture;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _vouchersFuture = _fetchVouchers();
  }

  Future<List<Voucher>> _fetchVouchers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final vouchers = await _voucherService.getAllVouchers();
      setState(() {
        _isLoading = false;
      });
      return vouchers;
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Voucher'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : FutureBuilder<List<Voucher>>(
                  future: _vouchersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final vouchers = snapshot.data!;
                      return ListView.builder(
                        itemCount: vouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = vouchers[index];
                          return VoucherCard(voucher: voucher);
                        },
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchVouchers,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class VoucherCard extends StatelessWidget {
  final Voucher voucher;

  const VoucherCard({super.key, required this.voucher});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  voucher.code,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: voucher.isValid ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    voucher.isValid ? 'VALID' : 'INVALID',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              voucher.discountType == 'percent'
                  ? 'Giảm ${voucher.discountValue}%'
                  : 'Giảm ${voucher.discountValue.toInt()}đ',
              style: const TextStyle(fontSize: 16),
            ),
            if (voucher.maxDiscount > 0 && voucher.discountType == 'percent')
              Text(
                'Tối đa ${voucher.maxDiscount.toInt()}đ',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 8),
            Text(
              'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate)}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Đã dùng: ${voucher.usedCount}/${voucher.quantity}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
