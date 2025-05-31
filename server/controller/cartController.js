const cartService = require("../services/cartService");

// Xem giỏ hàng (giữ nguyên, nhưng service populate có thể đã thay đổi)
exports.getAllCart = async (req, res) => {
  try {
    const carts = await cartService.getAllCart();
    res.status(200).json({ status: 200, message: "OK", data: carts }); // Đổi success thành message
  } catch (error) {
    console.error("Error in getAllCart controller:", error);
    res.status(500).json({ status: 500, error: error.message });
  }
};

// Xem giỏ hàng theo id user (giữ nguyên, nhưng service populate có thể đã thay đổi)
// Nên lấy userId từ req.user.id nếu đã có authentication middleware
exports.getCartByUserId = async (req, res) => {
  try {
    const { userId } = req.params; // Giả sử userId được lấy từ params
    if (!userId) {
      return res.status(400).json({ status: 400, error: "Thiếu userId." });
    }
    const cart = await cartService.getCartByUserId(userId);
    if (!cart) {
      return res.status(404).json({
        status: 404,
        error: "Không tìm thấy giỏ hàng cho người dùng này.",
      });
    }
    res.status(200).json({ message: "OK", data: cart }); // Đổi success thành message
  } catch (error) {
    console.error(
      `Error in getCartByUserId controller for userId ${req.params.userId}:`,
      error
    );
    res.status(500).json({ status: 500, error: error.message });
  }
};

// Thêm sản phẩm đơn lẻ vào giỏ hàng
exports.insertCart = async (req, res) => {
  try {
    const { userId, productId, quantity, size, sugarLevel, toppingIds } =
      req.body;

    if (!userId || !productId || !size || !sugarLevel) {
      return res.status(400).json({
        status: 400,
        error:
          "Thiếu thông tin bắt buộc: userId, productId, size, hoặc sugarLevel.",
      });
    }
    if (
      quantity !== undefined &&
      (typeof quantity !== "number" || quantity < 1)
    ) {
      return res
        .status(400)
        .json({ status: 400, error: "Số lượng không hợp lệ." });
    }

    const cart = await cartService.insertToCart(
      userId,
      productId,
      quantity, // service sẽ xử lý default nếu quantity là undefined
      size,
      sugarLevel,
      toppingIds || [] // Gửi mảng rỗng nếu không có toppingIds
    );

    res.status(201).json({
      status: 201,
      message: "Sản phẩm đã được thêm vào giỏ hàng.", // Nhất quán message
      data: cart,
    });
  } catch (error) {
    console.error("Error in insertCart controller:", error);
    if (error.message && error.message.includes("không tồn tại")) {
      // Ví dụ bắt lỗi cụ thể
      return res.status(404).json({ status: 404, error: error.message });
    }
    if (error.message && error.message.includes("tồn kho")) {
      return res.status(409).json({ status: 409, error: error.message }); // 409 Conflict
    }
    res.status(500).json({ status: 500, error: error.message });
  }
};

// addcombo controller
exports.addComboToCart = async (req, res) => {
  try {
    const { userId, comboId, quantity } = req.body;

    if (!userId || !comboId || !quantity) {
      return res.status(400).json({
        status: 400,
        error: "Thiếu thông tin bắt buộc: userId, comboId, hoặc quantity.",
      });
    }
    if (typeof quantity !== "number" || quantity < 1) {
      return res.status(400).json({
        status: 400,
        error: "Số lượng (quantity) phải là một số nguyên dương.",
      });
    }

    const cart = await cartService.addComboToCart(userId, comboId, quantity);

    res.status(201).json({
      status: 201,
      message: "Combo đã được thêm vào giỏ hàng.",
      data: cart,
    });
  } catch (error) {
    console.error("Error in addComboToCart controller:", error);
    if (
      error.name === "ComboNotFoundError" ||
      error.name === "ProductInComboNotFoundError"
    ) {
      return res.status(404).json({ status: 404, error: error.message });
    }
    if (
      error.name === "ComboNotActiveError" ||
      error.name === "ProductInComboOutOfStockError"
    ) {
      return res.status(409).json({ status: 409, error: error.message }); // 409 Conflict
    }
    res.status(500).json({
      status: 500,
      error: error.message || "Lỗi máy chủ khi thêm combo.",
    });
  }
};

// Xóa item khỏi giỏ hàng (sử dụng cartItemId)
exports.removeProductFromCart = async (req, res) => {
  try {
    // Nên lấy cartItemId từ req.params nếu route là /cart/item/:cartItemId
    // Hoặc từ req.body nếu client gửi trong body
    const { userId, cartItemId } = req.body; // Giả sử client gửi cartItemId trong body
    // Hoặc const { cartItemId } = req.params; và const { userId } = req.user; (nếu có auth)

    if (!userId || !cartItemId) {
      // Nếu dùng req.user.id thì chỉ cần !cartItemId
      return res
        .status(400)
        .json({ status: 400, error: "Thiếu userId hoặc cartItemId." });
    }

    const cart = await cartService.removeProduct(userId, cartItemId);
    res.status(200).json({
      status: 200,
      message: "Mục hàng đã được xóa khỏi giỏ.",
      data: cart,
    });
  } catch (error) {
    console.error("Error in removeProductFromCart controller:", error);
    if (
      error.message.includes("không có trong giỏ hàng") ||
      error.message.includes("Không tìm thấy giỏ hàng")
    ) {
      return res.status(404).json({ status: 404, error: error.message });
    }
    res.status(500).json({ status: 500, error: error.message });
  }
};

// Cập nhật số lượng sản phẩm/combo trong giỏ hàng (sử dụng cartItemId)
exports.updateCartQuantity = async (req, res) => {
  try {
    const { userId, cartItemId, newQuantity } = req.body;

    if (!userId || !cartItemId || newQuantity === undefined) {
      return res.status(400).json({
        status: 400,
        error: "Thiếu userId, cartItemId, hoặc newQuantity.",
      });
    }
    if (typeof newQuantity !== "number" || newQuantity < 0) {
      // newQuantity = 0 để xóa
      return res
        .status(400)
        .json({ status: 400, error: "Số lượng mới không hợp lệ." });
    }

    const result = await cartService.updateQuantity(
      userId,
      cartItemId,
      newQuantity
    );
    res.status(200).json({
      status: 200,
      message: "Số lượng mục hàng đã được cập nhật.",
      data: result.cart,
    }); // Trả về cart
  } catch (error) {
    console.error("Error in updateCartQuantity controller:", error);
    if (error.message.includes("không có trong giỏ hàng")) {
      return res.status(404).json({ status: 404, error: error.message });
    }
    if (error.message.includes("tồn kho")) {
      // Bắt lỗi tồn kho từ service
      return res.status(409).json({ status: 409, error: error.message });
    }
    res.status(500).json({ status: 500, error: error.message });
  }
};

// Xóa toàn bộ giỏ hàng của người dùng
// Nên lấy userId từ req.user.id nếu có auth, hoặc req.params/:userId
exports.clearCart = async (req, res) => {
  try {
    // Giả sử userId được lấy từ thông tin user đã xác thực, hoặc params
    const { userId } = req.body; // Hoặc req.params.userId hoặc req.user.id
    if (!userId) {
      return res.status(400).json({ status: 400, error: "Thiếu userId." });
    }
    const cart = await cartService.clearCart(userId);
    res
      .status(200)
      .json({ status: 200, message: "Đã xóa toàn bộ giỏ hàng.", data: cart });
  } catch (error) {
    console.error("Error in clearCart controller:", error);
    if (error.message.includes("Không tìm thấy giỏ hàng")) {
      return res.status(404).json({ status: 404, error: error.message });
    }
    res.status(500).json({ status: 500, error: error.message });
  }
};

// Áp dụng voucher vào giỏ hàng
exports.applyVoucher = async (req, res) => {
  try {
    const { userId, voucher_code } = req.body;

    if (!userId || !voucher_code) {
      return res
        .status(400)
        .json({ status: 400, error: "Thiếu userId hoặc voucher_code." });
    }

    const updatedCart = await cartService.applyVoucherToCart(
      userId,
      voucher_code
    );

    res.status(200).json({
      status: 200,
      message: "Áp dụng voucher thành công.",
      data: updatedCart,
    });
  } catch (error) {
    console.error("Error in applyVoucher controller:", error);
    // Các lỗi nghiệp vụ khi áp voucher thường là 400 hoặc 404
    if (
      error.message.includes("Voucher") ||
      error.message.includes("Giỏ hàng trống") ||
      error.message.includes("tối thiểu")
    ) {
      return res.status(400).json({ status: 400, error: error.message });
    }
    res.status(500).json({ status: 500, error: error.message }); // Lỗi không mong muốn
  }
};
