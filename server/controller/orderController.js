const orderService = require("./../services/orderService");
const VNPayService = require("./../services/vnpayService");

// Thêm đơn hàng
exports.insertOrder = async (req, res) => {
  try {
    const orderData = req.body;
    const newOrder = await orderService.insertOrder(orderData);

    if (!orderData.payment_method) {
      return res.status(400).json({ error: "Thiếu phương thức thanh toán" });
    }

    // Tạo URL thanh toán VNPay
    const paymentUrl = VNPayService.createPaymentUrl(
      newOrder._id,
      newOrder.total,
      null,
      `Thanh toán đơn hàng #${newOrder._id}`
    );

    res.status(200).json({
      status: 200,
      success: "Tạo order thành công",
      data: {
        order: newOrder,
        paymentUrl: paymentUrl, // Trả về URL thanh toán cho client
      },
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

// Xử lý return URL từ VNPay
exports.vnpayReturn = async (req, res) => {
  try {
    const query = req.query;
    const result = VNPayService.verifyReturn(query);

    if (!result.isValid) {
      return res.redirect("/payment/failed?message=Invalid signature");
    }

    const orderId = result.vnp_TxnRef;
    const responseCode = result.vnp_ResponseCode;

    // Cập nhật trạng thái đơn hàng
    let updateData = {};
    if (responseCode === "00") {
      updateData.status = "paid";
      // Có thể thêm các thông tin thanh toán khác vào đơn hàng
      updateData.paymentInfo = {
        method: "VNPay",
        transactionId: result.vnp_TransactionNo,
        bankCode: result.vnp_BankCode,
        payDate: result.vnp_PayDate,
      };
    } else {
      updateData.status = "payment_failed";
    }

    await orderService.updateOrder(orderId, updateData);

    if (responseCode === "00") {
      // Thanh toán thành công
      return res.redirect("/payment/success");
    } else {
      // Thanh toán thất bại
      return res.redirect(`/payment/failed?code=${responseCode}`);
    }
  } catch (error) {
    console.error("VNPay return error:", error);
    return res.redirect("/payment/failed?message=Internal error");
  }
};
