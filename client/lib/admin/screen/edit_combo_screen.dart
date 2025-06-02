// File: screens/admin/edit_combo_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/combo_model.dart'; // Model Combo và ProductItem
import '../../models/inserted_combo_data.dart';
import '../../models/combo_product_config_item.dart';
import '../../models/products.dart';
import '../../services/product_service.dart';
import '../../services/combo_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/config.dart';

// Service của bạn

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
  // late TextEditingController _imageUrlController; // Có thể không cần nữa nếu chỉ upload file

  List<ComboProductConfigItem> _configuredProducts = [];
  File? _selectedImageFile; // Lưu file ảnh đã chọn
  String?
      _currentImageUrl; // Lưu URL ảnh hiện tại (nếu đang sửa và chưa chọn ảnh mới)

  bool _isLoading = false;
  final ComboService _comboService = ComboService();
  final ProductService _productService = ProductService();
  List<Product> _availableProducts = [];
  final ImagePicker _picker = ImagePicker(); // Khởi tạo ImagePicker

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialCombo?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialCombo?.description ?? '');
    _priceController = TextEditingController(
        text: widget.initialCombo?.price.toString() ?? '');
    // _imageUrlController = // Bỏ hoặc xử lý khác nếu vẫn muốn nhập URL
    //     TextEditingController(text: widget.initialCombo?.imageUrl ?? '');
    _currentImageUrl = widget.initialCombo?.imageUrl;

    if (widget.initialCombo != null) {
      _configuredProducts = List<ComboProductConfigItem>.from(
          widget.initialCombo!.products.map((cp) {
        return ComboProductConfigItem(
          productId: cp.productId,
          productName: cp.productName,
          quantityInCombo: cp.quantityInCombo,
          defaultSize: cp.defaultSize,
          defaultSugarLevel: cp.defaultSugarLevel,
          defaultToppings: List<String>.from(cp.defaultToppings),
        );
      }));
    }
    _fetchAllProductsAndMapNames();
  }

  Future<void> _showImagePickerOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_currentImageUrl != null || _selectedImageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Xóa ảnh',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImageFile = null;
                      _currentImageUrl = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
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
    // _imageUrlController.dispose(); // Bỏ nếu không dùng
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Giảm chất lượng để giảm kích thước file
        maxWidth: 800, // Giảm kích thước ảnh
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _currentImageUrl = null; // Xóa URL ảnh cũ khi đã chọn file mới
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _showProductSelectionDialog(
      {ComboProductConfigItem? existingConfig,
      int? existingConfigIndex}) async {
    if (_availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Chưa có sản phẩm nào để chọn. Vui lòng thử lại.')),
      );
      await _fetchAllProducts();
      if (_availableProducts.isEmpty) return;
    }

    Product selectedProduct = _availableProducts.first;
    if (existingConfig != null) {
      try {
        selectedProduct = _availableProducts
            .firstWhere((p) => p.id == existingConfig.productId);
      } catch (e) {/* Dùng sản phẩm đầu tiên nếu không tìm thấy */}
    }

    final quantityController = TextEditingController(
        text: existingConfig?.quantityInCombo.toString() ?? '1');

    List<String> productAvailableSizes =
        selectedProduct.sizes.isNotEmpty ? selectedProduct.sizes : ['M', 'L'];
    String currentSize =
        existingConfig?.defaultSize ?? productAvailableSizes.first;
    if (!productAvailableSizes.contains(currentSize))
      currentSize = productAvailableSizes.first;

    List<String> productAvailableSugarLevels =
        selectedProduct.sugarLevels.isNotEmpty
            ? selectedProduct.sugarLevels
            : ['0 SL', '50 SL', '75 SL'];
    String currentSugarLevel =
        existingConfig?.defaultSugarLevel ?? productAvailableSugarLevels.first;
    if (!productAvailableSugarLevels.contains(currentSugarLevel))
      currentSugarLevel = productAvailableSugarLevels.first;

    await showDialog<ComboProductConfigItem>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          List<String> currentProductSizesForDropdown =
              selectedProduct.sizes.isNotEmpty
                  ? selectedProduct.sizes
                  : ['M', 'L'];
          List<String> currentProductSugarLevelsForDropdown =
              selectedProduct.sugarLevels.isNotEmpty
                  ? selectedProduct.sugarLevels
                  : ['0 SL', '50 SL', '75 SL'];

          if (!currentProductSizesForDropdown.contains(currentSize))
            currentSize = currentProductSizesForDropdown.first;
          if (!currentProductSugarLevelsForDropdown.contains(currentSugarLevel))
            currentSugarLevel = currentProductSugarLevelsForDropdown.first;

          return AlertDialog(
            title: Text(existingConfig == null
                ? 'Thêm Sản Phẩm Vào Combo'
                : 'Sửa Sản Phẩm Trong Combo'),
            content: SingleChildScrollView(
                child: Column(
              /* ... Nội dung dialog ... */
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(labelText: 'Chọn sản phẩm'),
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
                      List<String> newProductSizes =
                          selectedProduct.sizes.isNotEmpty
                              ? selectedProduct.sizes
                              : ['M', 'L'];
                      currentSize = newProductSizes.first;
                      List<String> newProductSugarLevels =
                          selectedProduct.sugarLevels.isNotEmpty
                              ? selectedProduct.sugarLevels
                              : ['0 SL', '50 SL', '75 SL'];
                      currentSugarLevel = newProductSugarLevels.first;
                    });
                  },
                ),
                TextFormField(
                  controller: quantityController,
                  decoration:
                      const InputDecoration(labelText: 'Số lượng trong combo'),
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
                  decoration: const InputDecoration(labelText: 'Size mặc định'),
                  value: currentSize,
                  isExpanded: true,
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
                  items:
                      currentProductSugarLevelsForDropdown.map((String sugar) {
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
            )),
            actions: <Widget>[
              TextButton(
                  child: const Text('Hủy'),
                  onPressed: () => Navigator.of(dialogContext).pop()),
              TextButton(
                child: Text(existingConfig == null ? 'Thêm' : 'Cập nhật'),
                onPressed: () {
                  if ((int.tryParse(quantityController.text) ?? 0) > 0) {
                    final newConfig = ComboProductConfigItem(
                      productId: selectedProduct.id,
                      productName: selectedProduct.name,
                      quantityInCombo: int.parse(quantityController.text),
                      defaultSize: currentSize,
                      defaultSugarLevel: currentSugarLevel,
                      defaultToppings: [],
                    );
                    Navigator.of(dialogContext).pop(newConfig);
                  } else {/* show error */}
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng thêm ít nhất một sản phẩm vào combo.')),
        );
        return;
      }
      // Nếu tạo mới mà không chọn ảnh, hoặc sửa mà không chọn ảnh mới và không có ảnh cũ
      if (widget.initialCombo == null && _selectedImageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ảnh cho combo.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        String? userToken = "YOUR_ADMIN_AUTH_TOKEN"; // THAY BẰNG TOKEN THỰC TẾ

        // Truyền _selectedImageFile vào service
        if (widget.initialCombo == null) {
          // Tạo mới
          InsertedComboData newCombo = await _comboService.insertCombo(
            name: _nameController.text,
            description: _descriptionController.text,
            productsConfig: _configuredProducts,
            price: double.tryParse(_priceController.text) ?? 0,
            authToken: userToken,
            imageFile: _selectedImageFile, // << TRUYỀN FILE ẢNH
            // imageUrl: _imageUrlController.text, // Bỏ nếu không dùng nhập URL
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Đã tạo combo "${newCombo.name}" thành công!')),
            );
            Navigator.pop(context, true);
          }
        } else {
          // Cập nhật
          InsertedComboData updatedCombo = await _comboService.updateCombo(
            comboId: widget.initialCombo!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            productsConfig: _configuredProducts,
            price: double.tryParse(_priceController.text) ?? 0,
            authToken: userToken,
            imageFile:
                _selectedImageFile, // << TRUYỀN FILE ẢNH (có thể null nếu không thay đổi)
            currentImageUrl: _selectedImageFile == null
                ? _currentImageUrl
                : null, // Gửi URL hiện tại nếu không có file mới
            // imageUrl: _imageUrlController.text, // Bỏ nếu không dùng nhập URL
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
                    // TextFormField(
                    //   controller: _imageUrlController,
                    //   decoration: const InputDecoration(
                    //       labelText: 'URL Hình ảnh',
                    //       border: OutlineInputBorder()),
                    //   keyboardType: TextInputType.url,
                    // ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ảnh Combo:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey
                                          .shade400), // Thêm shade cho đẹp hơn
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _selectedImageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            7), // Nhỏ hơn border 1 chút
                                        child: Image.file(
                                          _selectedImageFile!,
                                          fit: BoxFit.cover,
                                          width: double
                                              .infinity, // Cho ảnh file lấp đầy
                                          height: double.infinity,
                                        ),
                                      )
                                    : _currentImageUrl != null &&
                                            _currentImageUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(7),
                                            child: Builder(
                                                // Sử dụng Builder để có context mới nếu cần thiết cho AppConfig
                                                builder: (context) {
                                              String fullImageUrlToDisplay = '';
                                              if (_currentImageUrl!
                                                  .startsWith('http')) {
                                                fullImageUrlToDisplay =
                                                    _currentImageUrl!;
                                              } else {
                                                fullImageUrlToDisplay = AppConfig
                                                        .getBaseUrlForFiles() +
                                                    (_currentImageUrl!
                                                            .startsWith('/')
                                                        ? _currentImageUrl!
                                                        : '/${_currentImageUrl!}');
                                              }
                                              // print('EditComboScreen - Displaying image from URL: $fullImageUrlToDisplay'); // DEBUG
                                              return Image.network(
                                                  fullImageUrlToDisplay, // << SỬ DỤNG URL ĐẦY ĐỦ
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  loadingBuilder:
                                                      (BuildContext context,
                                                          Widget child,
                                                          ImageChunkEvent?
                                                              loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ));
                                              }, errorBuilder: (context, error,
                                                      stackTrace) {
                                                // print('EditComboScreen - Image.network error: $error for URL $fullImageUrlToDisplay'); // DEBUG
                                                return const Center(
                                                    child: Icon(
                                                        Icons.broken_image,
                                                        size: 50,
                                                        color: Colors.grey));
                                              });
                                            }),
                                          )
                                        : const Center(
                                            child: Icon(Icons.image_search,
                                                size: 50,
                                                color:
                                                    Colors.grey)), // Thay Icon
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: FloatingActionButton.small(
                                  // Sử dụng FAB small cho gọn
                                  heroTag:
                                      "editComboPickImageFab", // Thêm heroTag nếu có nhiều FAB trên màn hình
                                  onPressed:
                                      _showImagePickerOptions, // Gọi hàm bạn đã tạo
                                  tooltip: 'Chọn hoặc thay đổi ảnh',
                                  child: const Icon(
                                      Icons.edit_outlined), // Icon edit
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
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
