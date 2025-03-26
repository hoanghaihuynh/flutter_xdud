const Cart = require("./../model/cartSchema");
const Product = require("./../model/productSchema");

// Xem giỏ hàng
exports.getAllCart = async (req, res) => {
  try {
    const carts = await Cart.find().populate("products.productId"); // Lấy tất cả giỏ hàng và populate thông tin sản phẩm

    res.status(200).json({
      status: 200,
      success: "Lấy danh sách giỏ hàng thành công",
      data: carts,
    });
  } catch (error) {
    res
      .status(500)
      .json({ status: 500, error: "Lỗi server", message: error.message });
  }
};

// Xem giỏ hàng theo id user
exports.getCartByUserId = async (req, res) => {
  try {
    const { userId } = req.params;
    const cart = await Cart.findOne({ userId }).populate("products.productId");
    if (!cart)
      return res.status(404).json({ error: "Không tìm thấy giỏ hàng" });

    res.status(200).json({ success: "Lấy giỏ hàng thành công", data: cart });
  } catch (error) {
    res.status(500).json({ error: "Lỗi server", message: error.message });
  }
};

// Thêm sản phẩm vào giỏ hàng
exports.insertCart = async (req, res) => {
  try {
    const { userId, productId, quantity } = req.body;

    // Kiểm tra xem sản phẩm có tồn tại không
    const product = await Product.findById(productId);
    if (!product) {
      return res
        .status(404)
        .json({ status: 404, error: "Sản phẩm không tồn tại" });
    }

    // Tìm giỏ hàng của người dùng
    let cart = await Cart.findOne({ userId });

    if (!cart) {
      // Nếu chưa có giỏ hàng, tạo mới
      cart = new Cart({
        userId,
        products: [{ productId, quantity, price: product.price }],
        totalPrice: product.price * quantity,
      });
    } else {
      // Kiểm tra xem sản phẩm đã có trong giỏ chưa
      const existingProductIndex = cart.products.findIndex(
        (item) => item.productId.toString() === productId
      );

      if (existingProductIndex > -1) {
        // Nếu sản phẩm đã có, cập nhật số lượng
        cart.products[existingProductIndex].quantity += quantity;
      } else {
        // Nếu chưa có, thêm vào giỏ hàng
        cart.products.push({ productId, quantity, price: product.price });
      }

      // Cập nhật tổng giá trị giỏ hàng
      cart.totalPrice = cart.products.reduce(
        (total, item) => total + item.quantity * item.price,
        0
      );
    }

    // Lưu giỏ hàng vào database
    await cart.save();

    res.status(201).json({
      status: 201,
      success: "Thêm sản phẩm vào giỏ hàng thành công",
      data: cart,
    });
  } catch (error) {
    res
      .status(500)
      .json({ status: 500, error: "Lỗi server", message: error.message });
  }
};

// Xóa sản phẩm khỏi giỏ hàng
exports.removeProductFromCart = async (req, res) => {
  try {
    const { userId, productId } = req.body;

    // Kiểm tra xem sản phẩm có tồn tại không
    const product = await Product.findById(productId);
    if (!product) {
      return res
        .status(404)
        .json({ status: 404, error: "Sản phẩm không tồn tại" });
    }

    // Tìm giỏ hàng của người dùng
    const cart = await Cart.findOne({ userId });
    if (!cart) {
      return res
        .status(404)
        .json({ status: 404, error: "Không tìm thấy giỏ hàng" });
    }

    // Tìm index của sản phẩm trong giỏ hàng
    const productIndex = cart.products.findIndex(
      (item) => item.productId.toString() === productId
    );

    if (productIndex === -1) {
      return res
        .status(404)
        .json({ status: 404, error: "Sản phẩm không có trong giỏ hàng" });
    }

    // Lưu giá của sản phẩm để cập nhật tổng giá
    const productPrice = cart.products[productIndex].price;
    const productQuantity = cart.products[productIndex].quantity;

    // Xóa sản phẩm khỏi mảng products
    cart.products.splice(productIndex, 1);

    // Cập nhật tổng giá trị giỏ hàng
    cart.totalPrice = Math.max(
      0,
      cart.totalPrice - productPrice * productQuantity
    );

    // Lưu giỏ hàng đã cập nhật
    await cart.save();

    res.status(200).json({
      status: 200,
      success: "Xóa sản phẩm khỏi giỏ hàng thành công",
      data: cart,
    });
  } catch (error) {
    res
      .status(500)
      .json({ status: 500, error: "Lỗi server", message: error.message });
  }
};

// Cập nhật số lượng sản phẩm trong giỏ hàng
exports.updateCartQuantity = async (req, res) => {
  try {
    const { userId, productId, newQuantity } = req.body;

    // Validate input
    if (!userId || !productId || newQuantity === undefined || newQuantity < 1) {
      return res.status(400).json({
        status: 400,
        error: "Thông tin không hợp lệ",
        message: "userId, productId và newQuantity (≥1) là bắt buộc"
      });
    }

    // Kiểm tra sản phẩm tồn tại
    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({
        status: 404,
        error: "Sản phẩm không tồn tại"
      });
    }

    // Kiểm tra số lượng tồn kho
    if (newQuantity > product.stock) {
      return res.status(400).json({
        status: 400,
        error: "Số lượng vượt quá tồn kho",
        availableStock: product.stock
      });
    }

    // Tìm giỏ hàng của người dùng
    const cart = await Cart.findOne({ userId }).populate("products.productId");
    if (!cart) {
      return res.status(404).json({
        status: 404,
        error: "Không tìm thấy giỏ hàng"
      });
    }

    // Tìm sản phẩm trong giỏ hàng
    const productItem = cart.products.find(
      item => item.productId._id.toString() === productId
    );

    if (!productItem) {
      return res.status(404).json({
        status: 404,
        error: "Sản phẩm không có trong giỏ hàng"
      });
    }

    // Lưu giá cũ để tính toán
    const oldTotalForProduct = productItem.quantity * productItem.price;
    
    // Cập nhật số lượng mới
    productItem.quantity = newQuantity;
    
    // Tính toán lại tổng giá
    const newTotalForProduct = productItem.quantity * productItem.price;
    cart.totalPrice = cart.totalPrice - oldTotalForProduct + newTotalForProduct;

    // Lưu giỏ hàng đã cập nhật
    await cart.save();

    res.status(200).json({
      status: 200,
      success: "Cập nhật số lượng sản phẩm thành công",
      data: {
        cart: cart,
        updatedProduct: {
          productId: productId,
          newQuantity: newQuantity,
          newPrice: newTotalForProduct
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 500,
      error: "Lỗi server",
      message: error.message
    });
  }
};
