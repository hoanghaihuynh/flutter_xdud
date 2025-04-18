const cartService = require("../services/cartService");

// Xem giỏ hàng
exports.getAllCart = async (req, res) => {
  try {
    const carts = await cartService.getAllCarts();
    res.status(200).json({ status: 200, success: "OK", data: carts });
  } catch (error) {
    res.status(500).json({ status: 500, error: error.message });
  }
};

// Xem giỏ hàng theo id user
exports.getCartByUserId = async (req, res) => {
  try {
    const { userId } = req.params;
    const cart = await cartService.getCartByUserId(userId);
    if (!cart)
      return res
        .status(404)
        .json({ status: 404, error: "Không tìm thấy giỏ hàng" });

    res.status(200).json({ success: "OK", data: cart });
  } catch (error) {
    res.status(500).json({ status: 500, error: error.message });
  }
};

// Thêm sản phẩm vào giỏ hàng
exports.insertCart = async (req, res) => {
  try {
    const { userId, productId, quantity } = req.body;
    const cart = await cartService.insertToCart(userId, productId, quantity);
    res
      .status(201)
      .json({ status: 201, success: "PRODUCT ADDED SUCCESSFULLY", data: cart });
  } catch (error) {
    res.status(500).json({ status: 500, error: error.message });
  }
};

// Xóa item khỏi giỏ hàng
exports.removeProductFromCart = async (req, res) => {
  try {
    const { userId, productId } = req.body;
    const cart = await cartService.removeProduct(userId, productId);
    res
      .status(200)
      .json({ status: 200, success: "REMOVE ITEMS SUCCESSFULLY", data: cart });
  } catch (error) {
    res.status(500).json({ status: 500, error: error.message });
  }
};

// Cập nhật số lượng sản phẩm trong giỏ hàng
exports.updateCartQuantity = async (req, res) => {
  try {
    const { userId, productId, newQuantity } = req.body;
    const result = await cartService.updateQuantity(
      userId,
      productId,
      newQuantity
    );
    res
      .status(200)
      .json({ status: 200, success: "UPDATED SUCCESSFULLY", data: result });
  } catch (error) {
    res.status(500).json({ status: 500, error: error.message });
  }
};

// Xóa toàn bộ giỏ hàng của người dùng
exports.clearCart = async (req, res) => {
  try {
    const { userId } = req.body;
    const cart = await cartService.clearCart(userId);
    res
      .status(200)
      .json({ status: 200, success: "Đã xóa toàn bộ giỏ hàng", data: cart });
  } catch (error) {
    res.status(500).json({ status: 500, error: error.message });
  }
};
