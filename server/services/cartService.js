const Cart = require("./../model/cartSchema");
const Product = require("./../model/productSchema");
const Topping = require("./../model/toppingSchema");

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
  static async insertToCart(
    userId,
    productId,
    quantity,
    size,
    sugarLevel,
    toppingIds
  ) {

    // Kiểm tra nếu size và sugarLevel không có, trả về lỗi
    if (!size || !sugarLevel) {
      throw new Error("Thiếu size hoặc sugarLevel cho sản phẩm");
    }

    // Tìm sản phẩm
    const product = await Product.findById(productId);
    if (!product) throw new Error("Sản phẩm không tồn tại");

    // Lấy các topping từ database nếu có toppingIds
    const toppings = toppingIds
      ? await Topping.find({ _id: { $in: toppingIds } })
      : [];

    // Chuyển đổi các topping thành tên topping và giá của chúng
    const toppingNames = toppings.map((topping) => topping.name); // Lấy tên topping
    const toppingPrices = toppings.map((topping) => topping.price); // Lấy giá topping

    // Tính tổng giá của topping
    const totalToppingPrice = toppingPrices.reduce(
      (total, price) => total + price,
      0
    );

    // Kiểm tra nếu giỏ hàng đã tồn tại
    let cart = await Cart.findOne({ userId });

    if (!cart) {
      // Nếu không có giỏ hàng, tạo mới giỏ hàng
      cart = new Cart({
        userId,
        products: [
          {
            productId,
            quantity,
            price: product.price,
            note: {
              size,
              sugarLevel,
              toppings: toppingNames, // Lưu tên topping vào trong note
            },
          },
        ],
        totalPrice: product.price * quantity + totalToppingPrice * quantity, // Tính tổng giá giỏ hàng, bao gồm giá topping
      });
    } else {
      // Nếu giỏ hàng đã có, kiểm tra xem sản phẩm đã có trong giỏ chưa
      const index = cart.products.findIndex(
        (item) => item.productId.toString() === productId
      );

      if (index > -1) {
        // Nếu có, cập nhật số lượng và các lựa chọn
        cart.products[index].quantity += quantity;
        cart.products[index].note = {
          size,
          sugarLevel,
          toppings: toppingNames,
        }; // Cập nhật topping names
      } else {
        // Nếu không có, thêm sản phẩm mới vào giỏ hàng
        cart.products.push({
          productId,
          quantity,
          price: product.price,
          note: {
            size,
            sugarLevel,
            toppings: toppingNames,
          },
        });
      }

      // Cập nhật lại tổng giá trị giỏ hàng
      cart.totalPrice = cart.products.reduce(
        (total, item) =>
          total +
          item.quantity * item.price +
          totalToppingPrice * item.quantity,
        0
      );
    }

    // Lưu lại giỏ hàng vào cơ sở dữ liệu
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
