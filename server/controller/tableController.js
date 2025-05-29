const TableService = require("./../services/tableService");

// API tạo bàn
exports.createTable = async (req, res) => {
  try {
    const tableData = req.body;
    if (!tableData.table_number || !tableData.capacity) {
      return res.status(400).json({
        error: "Số hiệu bàn (table_number) và sức chứa (capacity) là bắt buộc.",
      });
    }

    const newTable = await TableService.insertTable(tableData);
    res.status(201).json({
      success: "TABLE ADDED SUCCESSFULLY",
      newTable,
    });
  } catch (error) {
    console.error("Lỗi tại TableController.createTable:", error);
    if (error.code === 11000) {
      // Lỗi trùng lặp key từ MongoDB (ví dụ: table_number đã tồn tại)
      return res.status(409).json({
        // 409 Conflict
        error: `Số hiệu bàn '${req.body.table_number}' đã tồn tại.`,
      });
    }
    if (error.name === "ValidationError") {
      // Lỗi từ Mongoose validation
      const messages = Object.values(error.errors).map((val) => val.message);
      return res.status(400).json({
        error: `Dữ liệu không hợp lệ: ${messages.join(", ")}`,
      });
    }
    res.status(500).json({
      error: error.message || "Đã có lỗi xảy ra ở phía máy chủ khi thêm bàn.",
    });
  }
};

// API lấy danh sách bàn
exports.getAllTables = async (req, res) => {
  try {
    const tables = await TableService.getAllTables();
    res.status(200).json(tables);
  } catch (error) {
    console.error("Lỗi tại TableController.getAllTables:", error);
    res.status(500).json({
      error:
        error.message ||
        "Đã có lỗi xảy ra ở phía máy chủ khi lấy danh sách bàn.",
    });
  }
};

// APi lấy bàn theo id
exports.getTableById = async (req, res) => {
  try {
    const tableId = req.params.id;
    const table = await TableService.getTableById(tableId);

    if (!table) {
      return res.status(404).json({
        error: "Không tìm thấy bàn với ID đã cung cấp.",
      });
    }
    res.status(200).json(table);
  } catch (error) {
    console.error("Lỗi tại TableController.getTableById:", error);
    if (error.name === "CastError" && error.kind === "ObjectId") {
      return res.status(400).json({
        error: "ID bàn không hợp lệ.",
      });
    }
    res.status(500).json({
      error:
        error.message ||
        "Đã có lỗi xảy ra ở phía máy chủ khi lấy thông tin bàn.",
    });
  }
};

// API cập nhật bàn
exports.updateTable = async (req, res) => {
  try {
    const tableId = req.params.id;
    const updateData = req.body;

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({
        error: "Không có dữ liệu cập nhật được cung cấp.",
      });
    }

    const updatedTable = await TableService.updateTable(tableId, updateData);

    if (!updatedTable) {
      return res.status(404).json({
        error: "Không tìm thấy bàn để cập nhật.",
      });
    }
    res.status(200).json(updatedTable);
  } catch (error) {
    console.error("Lỗi tại TableController.updateTable:", error);
    if (error.name === "CastError" && error.kind === "ObjectId") {
      return res.status(400).json({ error: "ID bàn không hợp lệ." });
    }
    if (error.code === 11000) {
      return res
        .status(409)
        .json({ error: "Xung đột dữ liệu, có thể số hiệu bàn đã tồn tại." });
    }
    if (error.name === "ValidationError") {
      const messages = Object.values(error.errors).map((val) => val.message);
      return res.status(400).json({
        error: `Dữ liệu cập nhật không hợp lệ: ${messages.join(", ")}`,
      });
    }
    res.status(500).json({
      error:
        error.message || "Đã có lỗi xảy ra ở phía máy chủ khi cập nhật bàn.",
    });
  }
};

// API xóa bàn
exports.deleteTable = async (req, res) => {
  try {
    const tableId = req.params.id;
    const deletedTable = await TableService.deleteTable(tableId);

    if (!deletedTable) {
      return res.status(404).json({
        error: "Không tìm thấy bàn để xóa.",
      });
    }
    // Theo ví dụ của bạn, trả về đối tượng đã xóa hoặc một thông báo.
    // res.status(200).json(deletedTable); // Lựa chọn 1: trả về đối tượng đã xóa
    res
      .status(200)
      .json({ message: "Xóa bàn thành công.", data: deletedTable }); // Lựa chọn 2: thông báo và đối tượng
    // res.status(204).send(); // Lựa chọn 3: không trả về nội dung (phổ biến cho DELETE)
  } catch (error) {
    console.error("Lỗi tại TableController.deleteTable:", error);
    if (error.name === "CastError" && error.kind === "ObjectId") {
      return res.status(400).json({ error: "ID bàn không hợp lệ." });
    }
    res.status(500).json({
      error: error.message || "Đã có lỗi xảy ra ở phía máy chủ khi xóa bàn.",
    });
  }
};

exports.getAvailableTable = async (req, res) => {
  try {
    const minCapacityQuery = req.query.minCapacity;
    let minCapacity = 1; // Giá trị mặc định

    if (minCapacityQuery) {
      minCapacity = parseInt(minCapacityQuery, 10);
      if (isNaN(minCapacity) || minCapacity < 1) {
        return res.status(400).json({
          error:
            "Giá trị minCapacity không hợp lệ. Phải là một số nguyên dương.",
        });
      }
    }

    const availableTables = await TableService.getAvailableTables(minCapacity);
    res.status(200).json(availableTables);
  } catch (error) {
    console.error("Lỗi tại TableController.getAvailableTablesNow:", error);
    res.status(500).json({
      error:
        error.message ||
        "Đã có lỗi xảy ra ở phía máy chủ khi lấy danh sách bàn trống.",
    });
  }
};
