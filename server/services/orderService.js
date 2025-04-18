const OrderModel = require("./../model/orderSchema");

class OrderService {
  // Thêm đơn hàng
  static async insertOrder(orderData) {
    try {
      const newOrder = new OrderModel(orderData);
      const savedOrder = await newOrder.save();
      return savedOrder;
    } catch (error) {
      throw new Error("Failed to insert order: " + error.message);
    }
  }

  // Lấy danh sách tất cả đơn hàng
  static async getAllOrder() {
    try {
      const orders = await OrderModel.find()
        .populate("user_id", "email") // chỉ lấy email
        .populate("products.product_id", "name price"); // lấy tên và giá sản phẩm
      return orders;
    } catch (error) {
      throw new Error("Failed to get orders: " + error.message);
    }
  }

  // Lấy đơn hàng theo ID người dùng
  static async getOrdersByUserId(userId) {
    try {
      const orders = await OrderModel.find({ user_id: userId })
        .populate("user_id", "email")
        .populate("products.product_id", "name price");
      return orders;
    } catch (error) {
      throw new Error("Failed to get orders by user ID: " + error.message);
    }
  }
}

module.exports = OrderService;
