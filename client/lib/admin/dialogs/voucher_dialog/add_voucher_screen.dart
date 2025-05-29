import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import './../models/voucher_model.dart';
import '../../services/voucher_service.dart';

class AddVoucherScreen extends StatefulWidget {
  const AddVoucherScreen({super.key});

  @override
  State<AddVoucherScreen> createState() => _AddVoucherScreenState();
}

class _AddVoucherScreenState extends State<AddVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _voucherService = VoucherService();
  bool _isLoading = false;

  // Form fields
  final _codeController = TextEditingController();
  String _discountType = 'percent';
  final _discountValueController = TextEditingController();
  final _maxDiscountController = TextEditingController(text: '0');
  DateTime _startDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  final _quantityController = TextEditingController(text: '100');

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final voucher = await _voucherService.createVoucher(
        code: _codeController.text,
        discountType: _discountType,
        discountValue: double.parse(_discountValueController.text),
        maxDiscount: double.parse(_maxDiscountController.text),
        startDate: _startDate,
        expiryDate: _expiryDate,
        quantity: int.parse(_quantityController.text),
      );

      if (!mounted) return;

      if (voucher != null) {
        Navigator.pop(context, voucher);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo voucher: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _maxDiscountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Voucher Mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã Voucher',
                  hintText: 'VD: SUMMER20',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã voucher';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _discountType,
                items: const [
                  DropdownMenuItem(
                    value: 'percent',
                    child: Text('Phần trăm (%)'),
                  ),
                  DropdownMenuItem(
                    value: 'fixed',
                    child: Text('Giảm giá cố định (đ)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _discountType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Loại giảm giá',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountValueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _discountType == 'percent'
                      ? 'Giá trị giảm (%)'
                      : 'Giá trị giảm (đ)',
                  hintText: _discountType == 'percent' ? 'VD: 20' : 'VD: 50000',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá trị giảm';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Giá trị không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_discountType == 'percent')
                TextFormField(
                  controller: _maxDiscountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giảm tối đa (đ)',
                    hintText: '0 = không giới hạn',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập giá trị';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Giá trị không hợp lệ';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Ngày bắt đầu'),
                      subtitle:
                          Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Ngày kết thúc'),
                      subtitle:
                          Text(DateFormat('dd/MM/yyyy').format(_expiryDate)),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lượng',
                  hintText: 'VD: 100',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số lượng';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Số lượng không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Thêm Voucher'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
