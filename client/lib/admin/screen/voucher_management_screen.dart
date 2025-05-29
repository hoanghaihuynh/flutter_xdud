import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dialogs/voucher_dialog/add_voucher_screen.dart';
import '../dialogs/voucher_dialog/edit_voucher_screen.dart'; // <--- THÊM IMPORT MỚI
import './../models/voucher_model.dart';
import './../services/voucher_service.dart';

class VoucherManagementScreen extends StatefulWidget {
  const VoucherManagementScreen({super.key});

  @override
  State<VoucherManagementScreen> createState() =>
      _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  final VoucherService _voucherService = VoucherService();
  late Future<List<Voucher>> _vouchersFuture;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _vouchersFuture = _voucherService.getAllVouchers();
    });
  }

  Future<void> _deleteVoucher(String voucherId, String voucherCode) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text('Bạn có chắc chắn muốn xóa voucher "$voucherCode"?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Hủy'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Xóa'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        final success = await _voucherService.deleteVoucher(voucherId);
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ĐÃ XÓA VOUCHER "$voucherCode"'),
              backgroundColor: Colors.green,
            ),
          );
          _loadVouchers(); // Làm mới danh sách
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Xóa voucher "$voucherCode" không thành công')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa voucher: $e')),
      );
    }
  }

  void _navigateToAddVoucher() async {
    final result = await Navigator.push<Voucher>(
      // Chú ý kiểu dữ liệu trả về
      context,
      MaterialPageRoute(builder: (context) => const AddVoucherScreen()),
    );

    if (result != null) {
      // result ở đây là Voucher mới được thêm
      _loadVouchers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ĐÃ THÊM VOUCHER "${result.code}" THÀNH CÔNG'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // HÀM MỚI ĐỂ ĐIỀU HƯỚNG ĐẾN MÀN HÌNH CHỈNH SỬA
  void _navigateToEditVoucher(Voucher voucher) async {
    final result = await Navigator.push<Voucher>(
      // Chú ý kiểu dữ liệu trả về
      context,
      MaterialPageRoute(
        builder: (context) => EditVoucherScreen(voucherToEdit: voucher),
      ),
    );

    if (result != null) {
      // result ở đây là Voucher đã được cập nhật
      _loadVouchers(); // Làm mới danh sách sau khi chỉnh sửa
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật voucher "${result.code}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVouchers,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddVoucher,
          ),
        ],
      ),
      body: FutureBuilder<List<Voucher>>(
        future: _vouchersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có voucher nào'));
          }

          return RefreshIndicator(
            onRefresh: _loadVouchers,
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final voucher = snapshot.data![index];
                return _buildVoucherCard(
                    context, voucher); // Sử dụng widget card mới
              },
            ),
          );
        },
      ),
    );
  }

  // SỬA ĐỔI _buildVoucherCard ĐỂ THÊM NÚT EDIT
  // Và loại bỏ Dismissible để sử dụng IconButton cho cả Edit và Delete
  Widget _buildVoucherCard(BuildContext context, Voucher voucher) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(Icons.discount, color: Colors.teal[700], size: 36),
        title: Text(voucher.code,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              voucher.discountType == 'percent'
                  ? 'Giảm ${voucher.discountValue}%'
                  : 'Giảm ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(voucher.discountValue)}',
            ),
            if (voucher.maxDiscount > 0 && voucher.discountType == 'percent')
              Text(
                'Tối đa: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(voucher.maxDiscount)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              'Ngày BĐ: ${DateFormat('dd/MM/yyyy').format(voucher.startDate)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Ngày KT: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${voucher.usedCount}/${voucher.quantity}',
              style: TextStyle(
                color: voucher.usedCount >= voucher.quantity
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              tooltip: 'Chỉnh sửa',
              onPressed: () =>
                  _navigateToEditVoucher(voucher), // <--- GỌI HÀM CHỈNH SỬA
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Xóa',
              onPressed: () => _deleteVoucher(voucher.id, voucher.code),
            ),
          ],
        ),
        onTap: () {
          // Có thể điều hướng đến màn hình chi tiết voucher nếu muốn
          _navigateToEditVoucher(voucher);
        },
        isThreeLine: true, // Cho phép subtitle có nhiều dòng hơn
      ),
    );
  }
}
