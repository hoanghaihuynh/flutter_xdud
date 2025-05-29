import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/voucher_model.dart';
import '../../services/voucher_service.dart';

class EditVoucherScreen extends StatefulWidget {
  final Voucher voucherToEdit;

  const EditVoucherScreen({super.key, required this.voucherToEdit});

  @override
  State<EditVoucherScreen> createState() => _EditVoucherScreenState();
}

class _EditVoucherScreenState extends State<EditVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final VoucherService _voucherService = VoucherService();

  // Controllers for form fields
  late TextEditingController _codeController;
  late TextEditingController _discountValueController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _quantityController;

  String? _selectedDiscountType;
  DateTime? _startDate;
  DateTime? _expiryDate;

  // Example list of discount types
  final List<String> _discountTypes = [
    'percent',
    'fixed_amount'
  ]; // Adjust as needed

  @override
  void initState() {
    super.initState();
    // Initialize controllers and state with existing voucher data
    _codeController = TextEditingController(text: widget.voucherToEdit.code);
    _selectedDiscountType = widget.voucherToEdit.discountType;
    _discountValueController = TextEditingController(
        text: widget.voucherToEdit.discountValue.toString());
    _maxDiscountController = TextEditingController(
        text: widget.voucherToEdit.maxDiscount.toString());
    _startDate = widget.voucherToEdit.startDate;
    _expiryDate = widget.voucherToEdit.expiryDate;
    _quantityController =
        TextEditingController(text: widget.voucherToEdit.quantity.toString());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _maxDiscountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate =
        (isStartDate ? _startDate : _expiryDate) ?? DateTime.now();
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2101);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _expiryDate = pickedDate;
        }
      });
    }
  }

  Future<void> _submitUpdateVoucher() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Map<String, dynamic> updateData = {
        'code': _codeController.text,
        'discount_type': _selectedDiscountType,
        'discount_value': double.tryParse(_discountValueController.text) ?? 0.0,
        'max_discount': double.tryParse(_maxDiscountController.text) ?? 0.0,
        'start_date': _startDate?.toIso8601String(),
        'expiry_date': _expiryDate?.toIso8601String(),
        'quantity': int.tryParse(_quantityController.text) ?? 0,
      };

      try {
        final updatedVoucher = await _voucherService.updateVoucher(
            widget.voucherToEdit.id, updateData);
        if (updatedVoucher != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CẬP NHẬT VOUCHER THÀNH CÔNG!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, updatedVoucher); // Return the updated voucher
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Cập nhật voucher không thành công: Phản hồi null từ server')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật voucher: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chỉnh sửa Voucher: ${widget.voucherToEdit.code}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Mã Voucher'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã voucher';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDiscountType,
                decoration: const InputDecoration(labelText: 'Loại giảm giá'),
                items: _discountTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type == 'percent'
                        ? 'Phần trăm (%)'
                        : 'Số tiền cố định (đ)'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDiscountType = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Vui lòng chọn loại giảm giá' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountValueController,
                decoration:
                    const InputDecoration(labelText: 'Giá trị giảm giá'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá trị giảm giá';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Vui lòng nhập một số hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxDiscountController,
                decoration: const InputDecoration(
                    labelText: 'Giảm giá tối đa (0 nếu không giới hạn)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Vui lòng nhập một số hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số lượng';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Vui lòng nhập một số nguyên dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _startDate == null
                          ? 'Chưa chọn ngày bắt đầu'
                          : 'Ngày bắt đầu: ${DateFormat('dd/MM/yyyy').format(_startDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(context, true),
                    child: const Text('Chọn ngày'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expiryDate == null
                          ? 'Chưa chọn ngày kết thúc'
                          : 'Ngày kết thúc: ${DateFormat('dd/MM/yyyy').format(_expiryDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDate(context, false),
                    child: const Text('Chọn ngày'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitUpdateVoucher,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0)),
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
