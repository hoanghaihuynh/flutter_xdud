import 'package:flutter/material.dart';
import 'package:myproject/widgets/table_card.dart';
import './../models/table.dart';
import './../services/table_service.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final TableService _tableService = TableService();
  late Future<List<TableModel>> _tablesFuture;
  final _formKey = GlobalKey<FormState>();
  final _tableNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedStatus = 'available';

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  void _loadTables() {
    setState(() {
      _tablesFuture = _tableService.getAllTables();
    });
  }

  Future<void> _handleTableTap(TableModel table) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        // Đổi tên context của builder
        List<Widget> actions = [];

        // Luôn có tùy chọn Sửa
        actions.add(
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blueAccent),
            title: const Text('Sửa thông tin bàn'),
            onTap: () {
              Navigator.pop(ctx); // Đóng bottom sheet
              _showEditTableDialog(table);
            },
          ),
        );

        // Tùy chọn dựa trên trạng thái
        switch (table.status) {
          case 'available':
            actions.add(ListTile(
                leading:
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Đặt bàn này'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAndBookTable(table);
                }));
            // actions.add(ListTile(
            //     leading: const Icon(Icons.bookmark_add_outlined,
            //         color: Colors.orangeAccent),
            //     title: const Text('Chuyển sang "Reserved"'),
            //     onTap: () {
            //       Navigator.pop(ctx);
            //       _changeTableStatus(
            //           table, 'reserved', 'Đã chuyển trạng thái bàn');
            //     }));
            // actions.add(ListTile(
            //     leading: const Icon(Icons.build_outlined, color: Colors.grey),
            //     title: const Text('Chuyển sang "Maintenance"'),
            //     onTap: () {
            //       Navigator.pop(ctx);
            //       _changeTableStatus(
            //           table, 'maintenance', 'Đã chuyển trạng thái bàn');
            //     }));
            break;
          case 'occupied':
            actions.add(ListTile(
                leading: const Icon(Icons.event_available_outlined,
                    color: Colors.green),
                title: const Text('Chuyển sang "Available"'),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeTableStatus(table, 'available', 'Đã giải phóng bàn');
                }));
            break;
          case 'reserved':
            actions.add(ListTile(
                leading: const Icon(Icons.no_meeting_room_outlined,
                    color: Colors.redAccent),
                title: const Text('Chuyển sang "Occupied"'),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeTableStatus(
                      table, 'occupied', 'Đã chuyển trạng thái bàn');
                }));
            actions.add(ListTile(
                leading: const Icon(Icons.cancel_outlined,
                    color: Colors.orangeAccent),
                title: const Text('Hủy đặt trước (Available)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeTableStatus(
                      table, 'available', 'Đã hủy đặt trước cho bàn');
                }));
            break;
          case 'maintenance':
            actions.add(ListTile(
                leading:
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Hoàn tất bảo trì (Available)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeTableStatus(table, 'available', 'Bàn');
                }));
            break;
          default:
            actions
                .add(ListTile(title: Text('Trạng thái bàn: ${table.status}')));
        }

        // Thêm tùy chọn Xóa bàn
        // Ví dụ: Chỉ cho phép xóa bàn nếu không phải là "occupied"
        // Bạn có thể thêm điều kiện về vai trò người dùng (admin) ở đây nếu cần
        if (table.status != 'occupied') {
          actions.add(
              const Divider(height: 1, thickness: 1)); // Ngăn cách trực quan
          actions.add(
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined,
                  color: Colors.redAccent),
              title: const Text('Xóa bàn này'),
              onTap: () {
                Navigator.pop(ctx); // Đóng bottom sheet
                _confirmAndDeleteTable(table); // Gọi hàm xác nhận và xóa
              },
            ),
          );
        }

        return SafeArea(
          child: Wrap(
            children: actions,
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDeleteTable(TableModel table) async {
    // Hiển thị dialog xác nhận
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa bàn'),
          content: Text(
              'Bạn có chắc chắn muốn xóa bàn số ${table.tableNumber}? Hành động này không thể hoàn tác.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop(false); // Trả về false khi hủy
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Colors.red), // Nút xóa màu đỏ cho nổi bật
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(context).pop(true); // Trả về true khi xác nhận xóa
              },
            ),
          ],
        );
      },
    );

    // Nếu người dùng xác nhận xóa
    if (confirmDelete == true) {
      try {
        // Gọi service để xóa bàn
        // Hàm deleteTable trong TableService của bạn trả về Map<String, dynamic>
        Map<String, dynamic> response =
            await _tableService.deleteTable(table.id);

        if (mounted) {
          // Kiểm tra widget còn tồn tại không
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ??
                  'Đã xóa bàn ${table.tableNumber} thành công!'), // Sử dụng message từ response
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadTables(); // Tải lại danh sách bàn để cập nhật UI
      } catch (e) {
        if (mounted) {
          // Kiểm tra widget còn tồn tại không
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa bàn: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCreateTableDialog() async {
    // Reset controllers và trạng thái cho mỗi lần mở dialog
    _tableNumberController.clear();
    _capacityController.clear();
    _descriptionController.clear();
    _selectedStatus = 'available'; // Reset về trạng thái mặc định

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Người dùng phải nhấn nút để đóng
      builder: (BuildContext context) {
        // Sử dụng StatefulBuilder để quản lý trạng thái của DropdownButtonFormField trong AlertDialog
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tạo bàn mới'),
            content: SingleChildScrollView(
              // Để có thể scroll nếu nội dung dài
              child: Form(
                key: _formKey, // Gán GlobalKey cho Form
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: _tableNumberController,
                      decoration:
                          const InputDecoration(labelText: 'Số bàn (vd: B001)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số bàn';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(labelText: 'Sức chứa'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập sức chứa';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Sức chứa phải là số dương';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Mô tả (vd: Bàn gần cửa sổ)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mô tả';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Trạng thái'),
                      value: _selectedStatus,
                      items: <String>[
                        'available',
                        'occupied',
                        'reserved',
                        'maintenance'
                      ] // Các trạng thái có thể có
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.replaceFirst(value[0],
                              value[0].toUpperCase())), // Viết hoa chữ cái đầu
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            // Cập nhật trạng thái của dialog
                            _selectedStatus = newValue;
                          });
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn trạng thái' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Hủy'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                // Sử dụng ElevatedButton cho hành động chính
                child: const Text('Tạo bàn'),
                onPressed: () async {
                  // Hàm async để đợi kết quả từ service
                  if (_formKey.currentState!.validate()) {
                    // Nếu form hợp lệ, lấy dữ liệu và gọi service
                    try {
                      // Hiện loading indicator (nếu muốn)
                      // Ví dụ: showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));

                      TableModel newTable = await _tableService.insertTable(
                        tableNumber: _tableNumberController.text,
                        capacity: int.parse(_capacityController.text),
                        description: _descriptionController.text,
                        status: _selectedStatus,
                      );

                      // Navigator.of(context).pop(); // Đóng loading indicator (nếu có)
                      Navigator.of(context).pop(); // Đóng dialog tạo bàn

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Đã tạo bàn ${newTable.tableNumber} thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadTables(); // Tải lại danh sách bàn để cập nhật UI
                    } catch (e) {
                      // Navigator.of(context).pop(); // Đóng loading indicator (nếu có)
                      // Không đóng dialog tạo bàn để người dùng có thể sửa lỗi
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi khi tạo bàn: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _changeTableStatus(
      TableModel table, String newStatus, String successMessagePrefix) async {
    try {
      Map<String, dynamic> updateData = {'status': newStatus};
      TableModel updatedTable =
          await _tableService.updateTable(table.id, updateData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$successMessagePrefix ${updatedTable.tableNumber} thành ${updatedTable.status}.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      _loadTables();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật trạng thái bàn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndBookTable(TableModel table) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận đặt bàn'),
          content:
              Text('Bạn có chắc chắn muốn đặt bàn số ${table.tableNumber}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Đặt bàn'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        Map<String, dynamic> updateData = {'status': 'occupied'};
        TableModel updatedTable =
            await _tableService.updateTable(table.id, updateData);

        if (mounted) {
          // Kiểm tra mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đã đặt bàn ${updatedTable.tableNumber} thành công! Trạng thái: ${updatedTable.status}.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadTables();
      } catch (e) {
        if (mounted) {
          // Kiểm tra mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi đặt bàn: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Dialog sửa bản
  Future<void> _showEditTableDialog(TableModel tableToEdit) async {
// Điền thông tin hiện tại của bàn vào controllers và _selectedStatus
    // Xử lý trường hợp các giá trị từ tableToEdit có thể là null
    _tableNumberController.text = tableToEdit.tableNumber ??
        ''; // Nếu tableNumber là null, dùng chuỗi rỗng
    _capacityController.text = tableToEdit.capacity.toString();
    _descriptionController.text = tableToEdit.description ??
        ''; // Nếu description là null, dùng chuỗi rỗng
    _selectedStatus = tableToEdit.status ?? 'available';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(// Để DropdownButtonFormField cập nhật đúng
            builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Sửa thông tin bàn: ${tableToEdit.tableNumber}'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: _tableNumberController,
                      decoration: const InputDecoration(labelText: 'Số bàn'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số bàn';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(labelText: 'Sức chứa'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập sức chứa';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Sức chứa phải là số dương';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mô tả';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Trạng thái'),
                      value: _selectedStatus,
                      items: <String>[
                        'available',
                        'occupied',
                        'reserved',
                        'maintenance'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.replaceFirst(
                              value[0], value[0].toUpperCase())),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            _selectedStatus = newValue;
                          });
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn trạng thái' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Hủy'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text('Lưu thay đổi'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    Map<String, dynamic> updatedData = {
                      'table_number': _tableNumberController.text,
                      'capacity': int.parse(_capacityController.text),
                      'description': _descriptionController.text,
                      'status': _selectedStatus,
                    };

                    try {
                      TableModel updatedTable = await _tableService.updateTable(
                        tableToEdit.id, // ID của bàn cần sửa
                        updatedData, // Dữ liệu mới
                      );

                      Navigator.of(context).pop(); // Đóng dialog sửa bàn

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Đã cập nhật bàn ${updatedTable.tableNumber} thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadTables(); // Tải lại danh sách bàn
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi khi cập nhật bàn: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      // Giữ dialog mở để người dùng có thể sửa lại nếu muốn
                    }
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý bàn ăn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTables,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: FutureBuilder<List<TableModel>>(
        future: _tablesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Đã sửa placeholder ở đây
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Không thể tải danh sách bàn.\nVui lòng thử lại.\nLỗi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Không có bàn nào. Nhấn + để thêm bàn mới.'));
          }

          final tables = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadTables(),
            child: GridView.builder(
              padding: const EdgeInsets.all(10.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.2, // Điều chỉnh tỷ lệ này nếu cần
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return TableCard(
                  // Đảm bảo bạn đã import TableCard
                  table: table,
                  // Giờ đây, _handleTableTap sẽ hiển thị menu với nhiều lựa chọn
                  onTap: () => _handleTableTap(table),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTableDialog,
        tooltip: 'Tạo bàn mới',
        child: const Icon(Icons.add),
      ),
    );
  }
}
