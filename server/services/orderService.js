// services/orderService.js
const OrderModel = require("./../model/orderSchema");
// const UserModel = require("./../model/userSchema");

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

// lấy ds đơn hàng theo user id
const getOrdersByUserId = async (userId) => {
  try {
    const orders = await OrderModel.find({ user_id: userId })
      .populate("user_id", "email")
      .populate("products.product_id", "name price");
    return orders;
  } catch (error) {
    throw new Error("Failed to get orders by user ID: " + error.message);
  }
};

module.exports = {
  insertOrder,
  getAllOrder,
  getOrdersByUserId,
};
