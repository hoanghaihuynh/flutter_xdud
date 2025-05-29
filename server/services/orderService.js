const OrderModel = require("./../model/orderSchema");
const VoucherModel = require("./../model/voucherSchema");
const ToppingModel = require("./../model/toppingSchema");

class OrderService {
  // Thêm đơn hàng
  static async insertOrder(orderData) {
    try {
      let totalOrderPrice = 0;

      for (const product of orderData.products) {
        const toppingIds = product.note?.topping || [];
        const toppings = await ToppingModel.find({ _id: { $in: toppingIds } });

        const toppingPrice = toppings.reduce((total, t) => total + t.price, 0);
        // console.log(toppingPrice);
        const productTotal =
          product.price * product.quantity + toppingPrice * product.quantity;

        totalOrderPrice += productTotal;
        console.log("productTotal: " + productTotal);
        product.note.topping = toppings.map((t) => t.name);
      }

      // Áp dụng voucher nếu có
      let discountAmount = 0;
      // Áp dụng voucher nếu có
      if (orderData.voucher_code) {
        const voucher = await VoucherModel.findOne({
          code: orderData.voucher_code,
        });

        if (!voucher) throw new Error("Voucher không tồn tại");
        if (voucher.quantity <= voucher.used_count)
          throw new Error("Voucher đã hết lượt dùng");

        const now = new Date();
        if (now < voucher.start_date || now > voucher.expiry_date)
          throw new Error("Voucher không còn hiệu lực");

        if (voucher.discount_type === "percent") {
          discountAmount = (totalOrderPrice * voucher.discount_value) / 100;
          if (voucher.max_discount > 0) {
            discountAmount = Math.min(discountAmount, voucher.max_discount);
          }
        } else {
          discountAmount = voucher.discount_value;
        }

        console.log("Discount amount:", discountAmount);

        totalOrderPrice -= discountAmount;
        if (totalOrderPrice < 0) totalOrderPrice = 0;

        voucher.used_count += 1;
        await voucher.save();
      }

      orderData.total = totalOrderPrice;
      orderData.voucher_code = orderData.voucher_code || null;
      console.log("order data: " + orderData.total);
      const newOrder = new OrderModel(orderData);
      return await newOrder.save();
    } catch (error) {
      throw new Error(
        "Failed to insert order (order service): " + error.message
      );
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
