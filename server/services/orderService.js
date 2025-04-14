// services/orderService.js
const OrderModel = require("./../model/orderSchema");

// thêm đơn hàng
const insertOrder = async (orderData) => {
  try {
    const newOrder = new OrderModel(orderData);
    const savedOrder = await newOrder.save();
    return savedOrder;
  } catch (error) {
    throw new Error("Failed to insert order: " + error.message);
  }
};

// lấy ds đơn hàng
const getAllOrder = async () => {
  try {
    const orders = await OrderModel.find()
      .populate("user_id", "email") // 👈 chỉ lấy email (vì schema chỉ có email/password)
      .populate("products.product_id", "name price"); // nếu cần
    return orders;
  } catch (error) {
    throw new Error("Failed to get orders: " + error.message);
  }
};

module.exports = {
  insertOrder,
  getAllOrder,
};
