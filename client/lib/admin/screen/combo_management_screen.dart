import 'package:flutter/material.dart';
import '../../models/combo_model.dart'; // Đường dẫn tới file combo_model.dart của bạn
import '../../services/combo_service.dart'; // Đường dẫn tới file api_service.dart của bạn
import './edit_combo_screen.dart'; // Sẽ tạo màn hình này sau
import '../../config/config.dart';

class ComboManagementScreen extends StatefulWidget {
  const ComboManagementScreen({Key? key}) : super(key: key);

  @override
  State<ComboManagementScreen> createState() => _ComboManagementScreenState();
}

class _ComboManagementScreenState extends State<ComboManagementScreen> {
  late Future<List<Combo>> _futureCombos;
  final ComboService _apiService = ComboService();

  @override
  void initState() {
    super.initState();
    _loadCombos();
  }

  void _loadCombos() {
    setState(() {
      _futureCombos = _apiService.getAllCombos();
    });
  }

  Future<void> _refreshCombos() async {
    _loadCombos();
  }

  void _navigateToAddComboScreen() {
    Navigator.push<bool>(
      // Sử dụng <bool> để nhận kết quả trả về
      context,
      MaterialPageRoute(
        builder: (context) =>
            const EditComboScreen(), // Không truyền initialCombo để ở chế độ tạo mới
      ),
    ).then((result) {
      // Nếu EditComboScreen trả về true (nghĩa là đã tạo combo thành công),
      // thì tải lại danh sách combo.
      if (result == true) {
        _loadCombos();
      }
    });
  }

  void _navigateToEditComboScreen(Combo combo) {
    // Khi có màn hình EditComboScreen, bạn sẽ điều hướng tới đó và truyền combo hiện tại
    Navigator.push<bool>(
      // Thêm kiểu generic <bool> cho Navigator.push
      context,
      MaterialPageRoute(
          builder: (context) =>
              EditComboScreen(initialCombo: combo)), // Truyền combo hiện tại
    ).then((result) {
      if (result == true) {
        _loadCombos();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Chức năng Sửa Combo "${combo.name}" sẽ được phát triển!'),
        backgroundColor: Colors.green));
  }

  Future<void> _confirmDeleteCombo(String comboId, String comboName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa combo "$comboName" không?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Giả sử ApiService có hàm deleteCombo
        // await _apiService.deleteCombo(comboId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa combo "$comboName" ( giả lập )')),
        );
        _loadCombos(); // Tải lại danh sách sau khi xóa
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa combo: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Combo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Thêm Combo Mới',
            onPressed: _navigateToAddComboScreen,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCombos,
        child: FutureBuilder<List<Combo>>(
          future: _futureCombos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lỗi tải dữ liệu: ${snapshot.error}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _loadCombos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    )
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Không có combo nào.\Nhấn (+) để thêm combo mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            final combos = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(8.0),
              itemCount: combos.length,
              itemBuilder: (context, index) {
                final combo = combos[index];
                // Giả định combo.price là double, bạn có thể cần format nó
                // final formattedPrice = NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(combo.price);
                final formattedPrice =
                    "${combo.price.toStringAsFixed(0)}đ"; // Format đơn giản
                String fullImageUrl = '';
                if (combo.imageUrl.isNotEmpty) {
                  if (combo.imageUrl.startsWith('http')) {
                    // Nếu imageUrl đã là một URL đầy đủ (ví dụ: từ một nguồn bên ngoài)
                    fullImageUrl = combo.imageUrl;
                  } else {
                    // Nếu imageUrl là đường dẫn tương đối từ server của bạn
                    fullImageUrl = AppConfig.getBaseUrlForFiles() +
                        (combo.imageUrl.startsWith('/')
                            ? combo.imageUrl
                            : '/${combo.imageUrl}');
                  }
                } else {
                  // Ảnh placeholder nếu không có imageUrl hoặc imageUrl rỗng
                  // Bạn có thể dùng một URL placeholder thực sự hoặc để errorBuilder xử lý
                  fullImageUrl =
                      'https://via.placeholder.com/80x80?text=No+Image';
                }
                return Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Ảnh combo (nếu có)
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              fullImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.broken_image,
                                      color: Colors.grey[400]),
                                );
                              },
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Thông tin combo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                combo.name,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedPrice,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${combo.products.length} món', // Số lượng sản phẩm con
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600]),
                              ),
                              if (combo.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  combo.description,
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ]
                            ],
                          ),
                        ),
                        // Các nút hành động
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.blue),
                              tooltip: 'Sửa Combo',
                              onPressed: () =>
                                  _navigateToEditComboScreen(combo),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              tooltip: 'Xóa Combo',
                              onPressed: () =>
                                  _confirmDeleteCombo(combo.id, combo.name),
                            ),
                          ],
                        ),
                        // Tùy chọn: Switch để bật/tắt trạng thái active
                        //  Switch(
                        //    value: combo.isActive ?? true, // Giả sử có trường isActive
                        //    onChanged: (value) {
                        //      _toggleComboActiveStatus(combo, value);
                        //    },
                        //  ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 4),
            );
          },
        ),
      ),
    );
  }
}
