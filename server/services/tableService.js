const Table = require("./../model/tableSchema");

class TableService {
  // api thêm bàn
  static async insertTable(tableData) {
    try {
      const newTable = new Table(tableData); // TableSchema ở đây là Mongoose Model
      const savedTable = await newTable.save();
      return savedTable;
    } catch (error) {
      console.error("Error in insertTable:", error);
      throw error; // Hoặc xử lý lỗi theo cách bạn muốn
    }
  }

  // api lấy danh sách bàn
  static async getAllTables() {
    try {
      // CHỈNH SỬA DÒNG SAU NẾU TÊN MODEL CỦA BẠN KHÁC
      const tables = await Table.find(); // TableSchema là Mongoose Model
      return tables;
    } catch (error) {
      console.error("Error in getAllTables:", error);
      throw error;
    }
  }

  // api lấy ds bàn theo id
  static async getTableById(tableId) {
    try {
      // CHỈNH SỬA DÒNG SAU NẾU TÊN MODEL CỦA BẠN KHÁC
      const table = await Table.findById(tableId); // TableSchema là Mongoose Model
      return table; // Sẽ là null nếu không tìm thấy ID
    } catch (error) {
      console.error("Error in getTableById:", error);
      throw error;
    }
  }

  // api cập nhật bàn
  static async updateTable(tableId, updateData) {
    try {
      const updatedTable = await Table.findByIdAndUpdate(
        tableId,
        updateData,
        { new: true, runValidators: true } // TableSchema là Mongoose Model
      );
      return updatedTable; // Sẽ là null nếu không tìm thấy ID
    } catch (error) {
      console.error("Error in updateTable:", error);
      throw error;
    }
  }

  // api xóa bàn
  static async deleteTable(tableId) {
    try {
      // CHỈNH SỬA DÒNG SAU NẾU TÊN MODEL CỦA BẠN KHÁC
      const deletedTable = await Table.findByIdAndDelete(tableId); // TableSchema là Mongoose Model
      return deletedTable; // Sẽ là null nếu không tìm thấy ID
    } catch (error) {
      console.error("Error in deleteTable:", error);
      throw error;
    }
  }

  // api lấy bàn còn trống
  static async getAvailableTables(minCapacity = 1) {
    try {
      const query = { status: "available" };
      if (minCapacity && typeof minCapacity === "number" && minCapacity > 0) {
        query.capacity = { $gte: minCapacity };
      }
      // CHỈNH SỬA DÒNG SAU NẾU TÊN MODEL CỦA BẠN KHÁC
      const availableTables = await Table.find(query); // TableSchema là Mongoose Model
      return availableTables;
    } catch (error) {
      console.error("Error in getCurrentlyAvailableTables:", error);
      throw error;
    }
  }
}

module.exports = TableService;
