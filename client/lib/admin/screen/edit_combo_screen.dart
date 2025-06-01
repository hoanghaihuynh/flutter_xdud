// File: screens/admin/edit_combo_screen.dart
import 'package:flutter/material.dart';
import '../../models/combo_model.dart'; // Model Combo và ProductItem
import '../../models/inserted_combo_data.dart';
import '../../models/combo_product_config_item.dart';
import '../../models/products.dart';
import '../../services/product_service.dart';
import '../../services/combo_service.dart'; // Service của bạn

class EditComboScreen extends StatefulWidget {
  final Combo? initialCombo; // Combo hiện tại để sửa, null nếu là tạo mới

  const EditComboScreen({Key? key, this.initialCombo}) : super(key: key);

  @override
  State<EditComboScreen> createState() => _EditComboScreenState();
}

class _EditComboScreenState extends State<EditComboScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  List<String> _selectedProductIds =
      []; // Sẽ lưu ID các sản phẩm được chọn cho combo
  List<ComboProductConfigItem> _configuredProducts = [];

  bool _isLoading = false;
  final ComboService _comboService = ComboService();
  final ProductService _productService = ProductService();
  List<Product> _availableProducts = [];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialCombo?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialCombo?.description ?? '');
    _priceController = TextEditingController(
        text: widget.initialCombo?.price.toString() ?? '');
    _imageUrlController =
        TextEditingController(text: widget.initialCombo?.imageUrl ?? '');

    if (widget.initialCombo != null) {
      _configuredProducts = widget.initialCombo!.products.map((configItem) {
        // configItem ở đây đã là một đối tượng ComboProductConfigItem
        // Tạo một instance mới để _configuredProducts có danh sách riêng,
        // không ảnh hưởng đến widget.initialCombo.products.
        return ComboProductConfigItem(
          productId: configItem.productId,
          productName: configItem
              .productName, // Quan trọng: productName cần được populate đúng
          // từ ComboModel.fromJson -> ComboProductConfigItem.fromJson
          quantityInCombo: configItem.quantityInCombo,
          defaultSize: configItem.defaultSize,
          defaultSugarLevel: configItem.defaultSugarLevel,
          defaultToppings:
              List<String>.from(configItem.defaultToppings), // Tạo một List mới
        );
      }).toList();
    }
    _fetchAllProductsAndMapNames(); // Gọi để tải sản phẩm và cập nhật tên nếu cần
  }

  Future<void> _fetchAllProductsAndMapNames() async {
    await _fetchAllProducts();
    _mapProductNamesToConfiguredProducts(); // Cập nhật tên sau khi có _availableProducts
  }

  Future<void> _fetchAllProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true); // Có thể bật isLoading ở đây nếu muốn
    try {
      List<Product> products = await _productService.fetchAllProducts();
      if (mounted) {
        setState(() {
          _availableProducts = products;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách sản phẩm: $e')),
        );
      }
    } finally {
      if (mounted)
        setState(() => _isLoading = false); // Tắt isLoading sau khi tải xong
    }
  }

  void _mapProductNamesToConfiguredProducts() {
    if (_availableProducts.isEmpty) return;
    if (!mounted) return;

    setState(() {
      _configuredProducts = _configuredProducts.map((config) {
        if (config.productName == null ||
            config.productName!.isEmpty ||
            config.productName == "N/A") {
          try {
            final product =
                _availableProducts.firstWhere((p) => p.id == config.productId);
            return config.copyWith(productName: product.name);
          } catch (e) {
            // Không tìm thấy sản phẩm, giữ nguyên config cũ
            return config;
          }
        }
        return config;
      }).toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _showProductSelectionDialog(
      {ComboProductConfigItem? existingConfig,
      int? existingConfigIndex}) async {
    if (_availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Chưa có sản phẩm nào để chọn. Vui lòng thử lại.')),
      );
      await _fetchAllProducts(); // Thử tải lại nếu chưa có sản phẩm
      if (_availableProducts.isEmpty) return; // Nếu vẫn không có thì thoát
    }

    // Khởi tạo selectedProduct:
    // Nếu đang sửa (existingConfig != null), tìm product trong _availableProducts.
    // Nếu không tìm thấy (có thể do product đã bị xóa), hoặc nếu tạo mới, lấy product đầu tiên.
    Product selectedProduct = _availableProducts.first; // Mặc định
    if (existingConfig != null) {
      try {
        selectedProduct = _availableProducts
            .firstWhere((p) => p.id == existingConfig.productId);
      } catch (e) {
        print(
            "Không tìm thấy sản phẩm hiện tại của config trong danh sách available products. Dùng sản phẩm đầu tiên.");
        // selectedProduct đã được gán _availableProducts.first ở trên
      }
    }

    final quantityController = TextEditingController(
        text: existingConfig?.quantityInCombo.toString() ?? '1');

    // Lấy size và sugar từ selectedProduct (là List<String>) hoặc từ existingConfig
    // selectedProduct.size là List<String> các size mà sản phẩm đó hỗ trợ
    List<String> productAvailableSizes = selectedProduct.sizes;
    if (productAvailableSizes.isEmpty) {
      productAvailableSizes = [
        'M',
        'L'
      ]; // Giá trị mặc định nếu sản phẩm không có list size
    }
    String currentSize =
        existingConfig?.defaultSize ?? productAvailableSizes.first;
    if (!productAvailableSizes.contains(currentSize)) {
      // Đảm bảo currentSize hợp lệ
      currentSize = productAvailableSizes.first;
    }

    List<String> productAvailableSugarLevels = selectedProduct.sugarLevels;
    if (productAvailableSugarLevels.isEmpty) {
      productAvailableSugarLevels = [
        '0 SL',
        '50 SL',
        '75 SL'
      ]; // Giá trị mặc định
    }
    String currentSugarLevel =
        existingConfig?.defaultSugarLevel ?? productAvailableSugarLevels.first;
    if (!productAvailableSugarLevels.contains(currentSugarLevel)) {
      // Đảm bảo currentSugarLevel hợp lệ
      currentSugarLevel = productAvailableSugarLevels.first;
    }

    // List<String> currentToppingIds = List<String>.from(existingConfig?.defaultToppings ?? []); // Sẽ xử lý sau

    await showDialog<ComboProductConfigItem>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          // Lấy danh sách size và sugar options từ product hiện tại đang được chọn trong dialog
          List<String> currentProductSizesForDropdown = selectedProduct.sizes;
          if (currentProductSizesForDropdown.isEmpty) {
            currentProductSizesForDropdown = ['M', 'L']; // Fallback
          }

          List<String> currentProductSugarLevelsForDropdown =
              selectedProduct.sugarLevels;
          if (currentProductSugarLevelsForDropdown.isEmpty) {
            currentProductSugarLevelsForDropdown = [
              '0 SL',
              '50 SL',
              '75 SL'
            ]; // Fallback
          }

          // Đảm bảo giá trị đang chọn (currentSize, currentSugarLevel) nằm trong danh sách options
          if (!currentProductSizesForDropdown.contains(currentSize)) {
            currentSize = currentProductSizesForDropdown.first;
          }
          if (!currentProductSugarLevelsForDropdown
              .contains(currentSugarLevel)) {
            currentSugarLevel = currentProductSugarLevelsForDropdown.first;
          }

          return AlertDialog(
            title: Text(existingConfig == null
                ? 'Thêm Sản Phẩm Vào Combo'
                : 'Sửa Sản Phẩm Trong Combo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<Product>(
                    decoration:
                        const InputDecoration(labelText: 'Chọn sản phẩm'),
                    value: selectedProduct,
                    isExpanded: true,
                    items: _availableProducts.map((Product product) {
                      return DropdownMenuItem<Product>(
                        value: product,
                        child:
                            Text(product.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (Product? newValue) {
                      setDialogState(() {
                        selectedProduct = newValue!;
                        // Khi đổi sản phẩm, cập nhật lại currentSize và currentSugarLevel
                        // dựa trên danh sách size/sugar của sản phẩm mới
                        List<String> newProductSizes = selectedProduct.sizes;
                        if (newProductSizes.isEmpty)
                          newProductSizes = ['M', 'L'];
                        currentSize = newProductSizes.first;

                        List<String> newProductSugarLevels =
                            selectedProduct.sugarLevels;
                        if (newProductSugarLevels.isEmpty)
                          newProductSugarLevels = ['0 SL', '50 SL', '75 SL'];
                        currentSugarLevel = newProductSugarLevels.first;
                      });
                    },
                  ),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                        labelText: 'Số lượng trong combo'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          (int.tryParse(value) ?? 0) <= 0) {
                        return 'Số lượng phải lớn hơn 0';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Size mặc định'),
                    value: currentSize,
                    isExpanded: true,
                    // Sử dụng danh sách size của sản phẩm đang được chọn trong dialog
                    items: currentProductSizesForDropdown.map((String size) {
                      return DropdownMenuItem<String>(
                          value: size, child: Text(size));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() => currentSize = newValue!);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Mức đường mặc định'),
                    value: currentSugarLevel,
                    isExpanded: true,
                    // Sử dụng danh sách sugar level của sản phẩm đang được chọn trong dialog
                    items: currentProductSugarLevelsForDropdown
                        .map((String sugar) {
                      return DropdownMenuItem<String>(
                          value: sugar, child: Text(sugar));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() => currentSugarLevel = newValue!);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text("Topping mặc định: (Sẽ làm sau)",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Hủy'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: Text(existingConfig == null ? 'Thêm' : 'Cập nhật'),
                onPressed: () {
                  if (selectedProduct !=
                          null && // selectedProduct đã được gán ở trên, không thể null ở đây
                      (int.tryParse(quantityController.text) ?? 0) > 0) {
                    final newConfig = ComboProductConfigItem(
                      productId: selectedProduct
                          .id, // Đã sửa: selectedProduct không thể null
                      productName: selectedProduct.name, // Đã sửa
                      quantityInCombo: int.parse(quantityController.text),
                      defaultSize: currentSize,
                      defaultSugarLevel: currentSugarLevel,
                      defaultToppings: [], // Tạm thời để trống
                    );
                    Navigator.of(dialogContext).pop(newConfig);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Vui lòng chọn sản phẩm và nhập số lượng hợp lệ.')));
                  }
                },
              ),
            ],
          );
        });
      },
    ).then((configuredProduct) {
      if (configuredProduct != null) {
        setState(() {
          if (existingConfigIndex != null) {
            _configuredProducts[existingConfigIndex] = configuredProduct;
          } else {
            _configuredProducts.add(configuredProduct);
          }
        });
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_configuredProducts.isEmpty) {
        // Sử dụng _configuredProducts thay vì _selectedProductIds
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng thêm ít nhất một sản phẩm vào combo.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Lấy token xác thực từ một nơi an toàn, ví dụ: SharedPreferences hoặc một state manager
        String? userToken =
            "YOUR_ADMIN_AUTH_TOKEN"; // THAY THẾ BẰNG TOKEN THỰC TẾ

        final List<Map<String, dynamic>> productsConfigJson =
            _configuredProducts.map((config) => config.toJson()).toList();

        if (widget.initialCombo == null) {
          InsertedComboData newCombo = await _comboService.insertCombo(
            name: _nameController.text,
            description: _descriptionController.text,
            productsConfig: _configuredProducts, // << SỬA Ở ĐÂY
            imageUrl: _imageUrlController.text,
            price: double.tryParse(_priceController.text) ?? 0,
            authToken: userToken,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã tạo combo "${newCombo.name}" thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          InsertedComboData updatedCombo = await _comboService.updateCombo(
            comboId: widget.initialCombo!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            productsConfig: _configuredProducts, // << SỬA Ở ĐÂY
            imageUrl: _imageUrlController.text,
            price: double.tryParse(_priceController.text) ?? 0,
            authToken: userToken,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Đã cập nhật combo "${updatedCombo.name}"!')),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialCombo == null
            ? 'Thêm Combo Mới'
            : 'Sửa Combo "${widget.initialCombo?.name ?? ""}"'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
      ),
      body: _isLoading &&
              _availableProducts
                  .isEmpty // Chỉ hiển thị loading toàn màn hình khi đang fetch product lần đầu
          ? const Center(
              child: CircularProgressIndicator(
              semanticsLabel: "Đang tải sản phẩm...",
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: 'Tên Combo', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Vui lòng nhập tên combo';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Mô tả', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                          labelText: 'Giá Combo', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Vui lòng nhập giá';
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) return 'Giá không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                          labelText: 'URL Hình ảnh',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sản phẩm trong Combo:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : _showProductSelectionDialog, // Mở dialog để thêm mới
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Thêm SP'),
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_configuredProducts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Center(
                            child: Text('Chưa có sản phẩm nào trong combo.',
                                style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _configuredProducts.length,
                        itemBuilder: (context, index) {
                          final config = _configuredProducts[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                  child: Text((index + 1).toString())),
                              title: Text(config.productName ??
                                  "ID: ${config.productId}"),
                              subtitle: Text(
                                  'SL: ${config.quantityInCombo} - Size: ${config.defaultSize} - Đường: ${config.defaultSugarLevel.replaceAll(" SL", "%")}'
                                  // + (config.defaultToppings.isNotEmpty ? '\nToppings: ${config.defaultToppings.join(", ")}' : '') // Cần map ID sang tên
                                  ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_note_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    tooltip: 'Sửa cấu hình',
                                    onPressed: _isLoading
                                        ? null
                                        : () => _showProductSelectionDialog(
                                            existingConfig: config,
                                            existingConfigIndex: index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.redAccent),
                                    tooltip: 'Xóa khỏi combo',
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _configuredProducts
                                                  .removeAt(index);
                                            });
                                          },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: _isLoading ? null : _submitForm,
                        child: Text(widget.initialCombo == null
                            ? 'Tạo Combo'
                            : 'Lưu Thay Đổi'),
                      ),
                    ),
                    const SizedBox(height: 20), // Thêm khoảng trống ở cuối
                  ],
                ),
              ),
            ),
    );
  }
}
