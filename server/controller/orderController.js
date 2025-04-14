// controllers/orderController.js
const Order = require("./../model/orderSchema");
const orderService = require("./../services/orderService");

// Thêm đơn hàng
exports.insertOrder = async (req, res) => {
  try {
    const orderData = req.body;
    const newOrder = await orderService.insertOrder(orderData);
    res.status(200).json({
      status: 200,
      success: "Tạo order thành công",
      data: newOrder,
    });
  } catch (error) {
    res.status(500).json({
      status: 500,
      error: "Có lỗi khi tạo đơn hàng",
      message: error.message,
    });
  }
};

// Xem đơn hàng
exports.getAllOrder = async (req, res) => {
  try {
    const orders = await orderService.getAllOrder();
    res.status(200).json({
      status: 200,
      message: "Lấy danh sách đơn hàng thành công",
      data: orders,
    });
  } catch (error) {
    res.status(500).json({
      status: 500,
      error: "Có lỗi khi lấy danh sách đơn hàng",
      message: error.message,
    });
  }
};
