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

// Xem ds đơn hàng hoặc đơn hàng theo user id
exports.getAllOrder = async (req, res) => {
  try {
    const { user_id } = req.query;

    let orders;
    if (user_id) {
      orders = await orderService.getOrdersByUserId(user_id);
    } else {
      orders = await orderService.getAllOrder();
    }
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

// Cập nhật đơn hàng
exports.updateOrder = async (req, res) => {
  try {
    const { orderId, updateData } = req.body;

    if (!orderId || !updateData) {
      return res.status(400).json({
        status: 400,
        error: "Thiếu orderId hoặc dữ liệu cập nhật",
      });
    }

    const updatedOrder = await orderService.updateOrder(orderId, updateData);

    res.status(200).json({
      status: 200,
      message: "Cập nhật đơn hàng thành công",
      data: updatedOrder,
    });
  } catch (error) {
    res.status(500).json({
      status: 500,
      error: "Có lỗi khi cập nhật đơn hàng",
      message: error.message,
    });
  }
};
