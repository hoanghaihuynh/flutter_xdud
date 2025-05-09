const OrderModel = require("./../model/orderSchema");
const ToppingModel = require("./../model/toppingSchema");

class OrderService {
  // Thêm đơn hàng
  static async insertOrder(orderData) {
    try {
      let totalOrderPrice = 0; // Khởi tạo tổng giá của đơn hàng

      // Xử lý cho từng sản phẩm trong đơn hàng
      for (const product of orderData.products) {
        // Tính tổng giá của topping cho từng sản phẩm
        const toppingIds =
          product.note && product.note.topping ? product.note.topping : [];
        const toppings = await ToppingModel.find({ _id: { $in: toppingIds } });

        // Tính tổng giá của topping
        const toppingPrice = toppings.reduce(
          (total, topping) => total + topping.price,
          0
        );

        // Tính tổng giá của sản phẩm (bao gồm topping)
        const productTotalPrice =
          product.price * product.quantity + toppingPrice * product.quantity;

        // Cập nhật tổng giá của đơn hàng
        totalOrderPrice += productTotalPrice;

        // Nếu có topping dưới dạng ID, lấy tên topping
        product.note.topping = toppings.map((t) => t.name); // Gán lại topping thành mảng tên
      }

      // Tạo đơn hàng với tổng giá
      orderData.total = totalOrderPrice;

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

  // Sửa đơn hàng
  static async updateOrder(orderId, updateData) {
    try {
      const updatedOrder = await OrderModel.findByIdAndUpdate(
        orderId,
        updateData,
        {
          new: true,
        }
      );
      return updatedOrder;
    } catch (error) {
      throw error;
    }
  }

  // Xóa đơn hàng
  static async deleteOrder(orderId) {
    try {
      const deletedOrder = await OrderModel.findByIdAndDelete(orderId);

      if (!deletedOrder) {
        throw new Error("Không tìm thấy đơn hàng để xóa");
      }

      return deletedOrder;
    } catch (error) {
      throw new Error("Failed to delete order: " + error.message);
    }
  }
}

module.exports = OrderService;
