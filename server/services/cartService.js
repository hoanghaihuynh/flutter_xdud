const Cart = require("./../model/cartSchema");
const Product = require("./../model/productSchema");

class CartService {
  // Lấy danh sách toàn bộ giỏ hàng
  static async getAllCart() {
    return await Cart.find().populate("products.productId");
  }

  // Lấy giỏ hàng theo userId
  static async getCartByUserId(userId) {
    return await Cart.findOne({ userId }).populate("products.productId");
  }

  // Thêm item vào giỏ hàng
  static async insertToCart(userId, productId, quantity) {
    const product = await Product.findById(productId);
    if (!product) throw new Error("Sản phẩm không tồn tại");

    let cart = await Cart.findOne({ userId });

    if (!cart) {
      cart = new Cart({
        userId,
        products: [{ productId, quantity, price: product.price }],
        totalPrice: product.price * quantity,
      });
    } else {
      const index = cart.products.findIndex(
        (item) => item.productId.toString() === productId
      );

      if (index > -1) {
        cart.products[index].quantity += quantity;
      } else {
        cart.products.push({ productId, quantity, price: product.price });
      }

      cart.totalPrice = cart.products.reduce(
        (total, item) => total + item.quantity * item.price,
        0
      );
    }

    await cart.save();
    return cart;
  }

  // Xóa 1 sản phẩm khỏi giỏ hàng
  static async removeProduct(userId, productId) {
    const product = await Product.findById(productId);
    if (!product) throw new Error("Sản phẩm không tồn tại");

    const cart = await Cart.findOne({ userId });
    if (!cart) throw new Error("Không tìm thấy giỏ hàng");

    const index = cart.products.findIndex(
      (item) => item.productId.toString() === productId
    );

    if (index === -1) throw new Error("Sản phẩm không có trong giỏ hàng");

    const removedItem = cart.products[index];
    cart.products.splice(index, 1);
    cart.totalPrice = Math.max(
      0,
      cart.totalPrice - removedItem.quantity * removedItem.price
    );

    await cart.save();
    return cart;
  }

  // Cập nhật số lượng sản phẩm trong giỏ
  static async updateQuantity(userId, productId, newQuantity) {
    if (newQuantity < 1) throw new Error("Số lượng phải lớn hơn 0");

    const product = await Product.findById(productId);
    if (!product) throw new Error("Sản phẩm không tồn tại");

    if (newQuantity > product.stock)
      throw new Error("Số lượng vượt quá tồn kho");

    const cart = await Cart.findOne({ userId }).populate("products.productId");
    if (!cart) throw new Error("Không tìm thấy giỏ hàng");

    const item = cart.products.find(
      (p) => p.productId._id.toString() === productId
    );
    if (!item) throw new Error("Sản phẩm không có trong giỏ hàng");

    const oldTotal = item.quantity * item.price;
    item.quantity = newQuantity;
    const newTotal = item.quantity * item.price;

    cart.totalPrice = cart.totalPrice - oldTotal + newTotal;
    await cart.save();

    return {
      cart,
      updatedProduct: {
        productId,
        newQuantity,
        newPrice: newTotal,
      },
    };
  }

  // Xóa toàn bộ sản phẩm trong giỏ hàng
  static async clearCart(userId) {
    const cart = await Cart.findOne({ userId });
    if (!cart) throw new Error("Không tìm thấy giỏ hàng");

    cart.products = [];
    cart.totalPrice = 0;
    await cart.save();
    return cart;
  }
}

module.exports = CartService;
