const orderService = require("./../services/orderService");
const VNPayService = require("./../services/vnpayService");

// Thêm đơn hàng
exports.insertOrder = async (req, res) => {
  try {
    const orderData = req.body;

    if (!orderData.payment_method) {
      return res.status(400).json({ error: "Thiếu phương thức thanh toán" });
    }

    // Validate items
    if (
      !orderData.items || // << THAY ĐỔI: products -> items
      !Array.isArray(orderData.items) ||
      orderData.items.length === 0
    ) {
      return res.status(400).json({ error: "Danh sách items không hợp lệ" });
    }

    // Validate từng item trong items (có thể làm sâu hơn trong service)
    for (const item of orderData.items) {
      if (
        !item.itemType ||
        (item.itemType !== "PRODUCT" && item.itemType !== "COMBO")
      ) {
        return res.status(400).json({
          error: `itemType không hợp lệ cho item: ${item.name || "Không tên"}`,
        });
      }
      if (item.itemType === "PRODUCT") {
        if (!item.product_id) {
          return res
            .status(400)
            .json({ error: "Thiếu product_id cho item loại PRODUCT" });
        }
        // Validate size và sugarLevel cho product vẫn giữ như cũ nếu frontend gửi lên
        if (!item.note?.size || !item.note?.sugarLevel) {
          return res
            .status(400)
            .json({ error: "Thiếu size hoặc sugarLevel cho sản phẩm đơn lẻ" });
        }
      } else if (item.itemType === "COMBO") {
        if (!item.combo_id) {
          return res
            .status(400)
            .json({ error: "Thiếu combo_id cho item loại COMBO" });
        }
        // Combo có thể không yêu cầu size/sugarLevel ở cấp độ item chính của combo
      }
      if (!item.quantity || item.quantity < 1) {
        return res.status(400).json({
          error: `Số lượng không hợp lệ cho item: ${item.name || "Không tên"}`,
        });
      }
    }

    const newOrder = await orderService.insertOrder(orderData);

    // Tạo URL thanh toán VNPay (nếu phương thức là VNPay)
    let paymentUrl = null;
    if (
      orderData.payment_method.toUpperCase() === "VNPAY" &&
      newOrder.total > 0
    ) {
      // Chỉ tạo URL nếu có tổng tiền
      paymentUrl = VNPayService.createPaymentUrl(
        newOrder._id.toString(), // Đảm bảo _id là string
        newOrder.total,
        req.ip, // Lấy IP từ request nếu VNPayService cần
        `Thanh toan don hang #${newOrder._id}`
      );
    }

    res.status(200).json({
      // Sử dụng 201 cho tạo mới thành công sẽ đúng chuẩn REST hơn
      status: 200, // Hoặc 201
      message: "Tạo đơn hàng thành công", // Sửa success thành message
      data: {
        order: newOrder,
        paymentUrl: paymentUrl, // Có thể là null nếu không phải VNPay hoặc total=0
      },
    });
  } catch (error) {
    console.error("insertOrder Controller Error:", error.message);
    res.status(500).json({
      status: 500,
      error: "Lỗi khi tạo đơn hàng: " + error.message, // Trả về message lỗi rõ ràng hơn
      // message: error.message, // Dòng này có thể dư thừa nếu error đã có message
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

// Xóa đơn hàng
exports.deleteOrder = async (req, res) => {
  try {
    const { orderId } = req.params;

    const deletedOrder = await orderService.deleteOrder(orderId);

    res.status(200).json({
      status: 200,
      success: "Xóa đơn hàng thành công",
      data: deletedOrder,
    });
  } catch (error) {
    res.status(500).json({
      status: 500,
      error: "Có lỗi khi xóa đơn hàng",
      message: error.message,
    });
  }
};
