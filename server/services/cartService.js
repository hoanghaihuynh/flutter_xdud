// ./services/cartService.js
const Cart = require("./../model/cartSchema");
const Product = require("./../model/productSchema");
const Topping = require("./../model/toppingSchema");
const Voucher = require("./../model/voucherSchema");
const Combo = require("./../model/comboSchema"); // Đảm bảo import Combo model

class CartService {
  static async getAllCart() {
    return await Cart.find()
      .populate("userId", "fullName email") // Ví dụ populate thêm thông tin user
      .populate("items.productId", "name price imageUrl category stock") // Populate cho product items
      .populate("items.comboId", "name price imageUrl products"); // Populate cho combo items
  }

  static async getCartByUserId(userId) {
    return await Cart.findOne({ userId })
      .populate("userId", "fullName email")
      .populate("items.productId", "name price imageUrl category stock")
      .populate("items.comboId", "name price imageUrl products");
  }

  // Thêm sp vào giỏ hàng
  static async insertToCart(
    userId,
    productId,
    quantity = 1,
    size,
    sugarLevel,
    toppingIds
  ) {
    if (!userId || !productId || !size || !sugarLevel) {
      throw new Error(
        "Thiếu thông tin bắt buộc: userId, productId, size, hoặc sugarLevel."
      );
    }
    if (typeof quantity !== "number" || quantity < 1) {
      throw new Error("Số lượng không hợp lệ.");
    }

    const product = await Product.findById(productId);
    if (!product) {
      throw new Error(`Sản phẩm với ID ${productId} không tồn tại.`);
    }

    const selectedToppings =
      toppingIds && toppingIds.length > 0
        ? await Topping.find({ _id: { $in: toppingIds } })
        : [];

    const toppingNamesForNote = selectedToppings.map((t) => t.name);
    const singleItemToppingPrice = selectedToppings.reduce(
      (sum, t) => sum + t.price,
      0
    );

    let cart = await Cart.findOne({ userId });
    if (!cart) {
      cart = new Cart({
        userId,
        items: [],
        totalPrice: 0,
        voucher_code: null,
        discount_amount: 0,
      });
    }

    const existingItemIndex = cart.items.findIndex(
      (item) =>
        item.itemType === "PRODUCT" &&
        item.productId && // Đảm bảo productId tồn tại trước khi toString
        item.productId.toString() === productId &&
        item.note.size === size &&
        item.note.sugarLevel === sugarLevel &&
        JSON.stringify((item.note.toppings || []).slice().sort()) ===
          JSON.stringify(toppingNamesForNote.slice().sort())
    );

    if (existingItemIndex > -1) {
      const existingItem = cart.items[existingItemIndex];
      const newQuantityForExistingItem = existingItem.quantity + quantity;
      if (newQuantityForExistingItem > product.stock) {
        throw new Error(
          `Không đủ tồn kho cho sản phẩm "${product.name}". Yêu cầu ${newQuantityForExistingItem}, chỉ còn ${product.stock}.`
        );
      }
      existingItem.quantity = newQuantityForExistingItem;
      existingItem.subTotal =
        (existingItem.price + existingItem.itemToppingPrice) *
        existingItem.quantity;
    } else {
      if (quantity > product.stock) {
        throw new Error(
          `Không đủ tồn kho cho sản phẩm "${product.name}". Yêu cầu ${quantity}, chỉ còn ${product.stock}.`
        );
      }
      const newItem = {
        itemType: "PRODUCT",
        productId: product._id,
        name: product.name,
        imageUrl: product.imageUrl || "",
        quantity: quantity,
        price: product.price,
        note: {
          size,
          sugarLevel,
          toppings: toppingNamesForNote,
        },
        itemToppingPrice: singleItemToppingPrice,
        subTotal: (product.price + singleItemToppingPrice) * quantity,
      };
      cart.items.push(newItem);
    }

    cart.totalPrice = cart.items.reduce(
      (sum, item) => sum + (item.subTotal || 0),
      0
    );

    if (cart.voucher_code) {
      const voucher = await Voucher.findOne({ code: cart.voucher_code });
      if (
        voucher &&
        voucher.start_date <= new Date() &&
        voucher.expiry_date >= new Date() &&
        voucher.used_count < voucher.quantity &&
        cart.totalPrice >= voucher.min_order_value
      ) {
        let newDiscountAmount = 0;
        if (voucher.discount_type === "percent") {
          newDiscountAmount = (cart.totalPrice * voucher.discount_value) / 100;
          if (voucher.max_discount > 0) {
            newDiscountAmount = Math.min(
              newDiscountAmount,
              voucher.max_discount
            );
          }
        } else if (voucher.discount_type === "fixed") {
          newDiscountAmount = voucher.discount_value;
          if (newDiscountAmount > cart.totalPrice)
            newDiscountAmount = cart.totalPrice;
        }
        cart.discount_amount = newDiscountAmount;
      } else {
        cart.voucher_code = null;
        cart.discount_amount = 0;
      }
    } else {
      cart.discount_amount = 0;
    }

    await cart.save();
    return cart;
  }

  // HÀM MỚI ĐỂ THÊM COMBO VÀO GIỎ HÀNG
  static async addComboToCart(userId, comboId, comboQuantity = 1) {
    if (!userId || !comboId) {
      throw new Error("Thiếu thông tin bắt buộc: userId hoặc comboId.");
    }
    if (typeof comboQuantity !== "number" || comboQuantity < 1) {
      throw new Error("Số lượng combo không hợp lệ.");
    }

    // 1. Lấy thông tin chi tiết của Combo
    // Populate sâu để lấy thông tin sản phẩm con và topping mặc định của sản phẩm con
    const combo = await Combo.findById(comboId)
      .populate({
        path: "products.productId", // Populate Product object trong mảng products của Combo
        model: "products", // Tên model Product của bạn
        populate: {
          // Populate tiếp Topping nếu Product có trường ref đến Topping
          path: "toppings", // Giả sử Product có trường 'toppings' ref đến Topping model
          model: "toppings",
        },
      })
      .populate({
        path: "products.defaultToppings", // Populate Topping objects trong defaultToppings của ComboProductItemSchema
        model: "toppings", // Tên model Topping của bạn
      });

    if (!combo) {
      const err = new Error("Combo không tồn tại.");
      err.name = "ComboNotFoundError";
      throw err;
    }

    if (!combo.isActive) {
      const err = new Error("Combo này hiện không có sẵn để bán.");
      err.name = "ComboNotActiveError";
      throw err;
    }

    // 2. Kiểm tra tồn kho cho từng sản phẩm con trong combo
    for (const comboProductItem of combo.products) {
      if (!comboProductItem.productId) {
        const err = new Error(
          `Một sản phẩm tham chiếu trong combo (ID: ${comboId}) không hợp lệ hoặc không thể tải.`
        );
        err.name = "ProductInComboNotFoundError";
        throw err;
      }
      const productDetails = comboProductItem.productId;
      const requiredStockForThisItem =
        (comboProductItem.quantityInCombo || 1) * comboQuantity;

      if (productDetails.stock < requiredStockForThisItem) {
        const err = new Error(
          `Sản phẩm "${productDetails.name}" trong combo "${combo.name}" không đủ số lượng tồn kho (cần ${requiredStockForThisItem}, còn ${productDetails.stock}).`
        );
        err.name = "ProductInComboOutOfStockError";
        throw err;
      }
    }

    // 3. Tìm hoặc tạo giỏ hàng cho người dùng
    let cart = await Cart.findOne({ userId });
    if (!cart) {
      cart = new Cart({
        userId,
        items: [],
        totalPrice: 0,
        voucher_code: null,
        discount_amount: 0,
      });
    }

    // 4. Thêm hoặc cập nhật "mục combo" trong giỏ hàng
    const existingComboItemIndex = cart.items.findIndex(
      (item) =>
        item.itemType === "COMBO" &&
        item.comboId && // Đảm bảo comboId tồn tại
        item.comboId.toString() === comboId
    );

    if (existingComboItemIndex > -1) {
      // Combo đã tồn tại trong giỏ, cập nhật số lượng
      const existingItem = cart.items[existingComboItemIndex];
      existingItem.quantity += comboQuantity;
      existingItem.subTotal = existingItem.price * existingItem.quantity; // price ở đây là combo.price
    } else {
      // Combo chưa có trong giỏ, thêm mới
      const newComboItem = {
        itemType: "COMBO",
        comboId: combo._id,
        name: combo.name,
        imageUrl: combo.imageUrl || "",
        quantity: comboQuantity,
        price: combo.price, // Giá của MỘT đơn vị combo
        note: {
          // Note cho combo có thể khác với product, ví dụ mô tả ngắn
          size: "", // Không áp dụng trực tiếp cho cả combo
          sugarLevel: "", // Không áp dụng trực tiếp cho cả combo
          toppings: [], // Không áp dụng trực tiếp cho cả combo
          // description: combo.description // Có thể thêm mô tả combo vào note
        },
        itemToppingPrice: 0, // Combo thường có giá trọn gói, không tính topping riêng ở cấp độ này
        subTotal: combo.price * comboQuantity,
      };
      cart.items.push(newComboItem);
    }

    // 5. Tính lại tổng giá giỏ hàng (totalPrice)
    cart.totalPrice = cart.items.reduce(
      (sum, item) => sum + (item.subTotal || 0),
      0
    );

    // 6. Cập nhật lại discount nếu có voucher đang được áp dụng
    if (cart.voucher_code) {
      const voucher = await Voucher.findOne({ code: cart.voucher_code });
      if (
        voucher &&
        voucher.start_date <= new Date() &&
        voucher.expiry_date >= new Date() &&
        voucher.used_count < voucher.quantity &&
        cart.totalPrice >= voucher.min_order_value
      ) {
        let newDiscountAmount = 0;
        if (voucher.discount_type === "percent") {
          newDiscountAmount = (cart.totalPrice * voucher.discount_value) / 100;
          if (voucher.max_discount > 0) {
            newDiscountAmount = Math.min(
              newDiscountAmount,
              voucher.max_discount
            );
          }
        } else if (voucher.discount_type === "fixed") {
          newDiscountAmount = voucher.discount_value;
          if (newDiscountAmount > cart.totalPrice)
            newDiscountAmount = cart.totalPrice;
        }
        cart.discount_amount = newDiscountAmount;
      } else {
        cart.voucher_code = null;
        cart.discount_amount = 0;
      }
    } else {
      cart.discount_amount = 0;
    }

    // 7. Lưu giỏ hàng
    await cart.save();
    return cart;
  }

  // Ví dụ cập nhật cho removeProduct (ưu tiên cartItemId)
  static async removeProduct(userId, cartItemId) {
    const cart = await Cart.findOne({ userId });
    if (!cart) throw new Error("Không tìm thấy giỏ hàng");

    const itemIndex = cart.items.findIndex(
      (item) => item._id.toString() === cartItemId
    );

    if (itemIndex === -1)
      throw new Error("Mục hàng không có trong giỏ hoặc cartItemId không đúng");

    cart.items.splice(itemIndex, 1); // Xóa mục hàng

    // Tính lại totalPrice và discount
    cart.totalPrice = cart.items.reduce(
      (sum, item) => sum + (item.subTotal || 0),
      0
    );
    if (cart.voucher_code) {
      const voucher = await Voucher.findOne({ code: cart.voucher_code });
      if (
        voucher &&
        voucher.start_date <= new Date() &&
        voucher.expiry_date >= new Date() &&
        voucher.used_count < voucher.quantity &&
        cart.totalPrice >= voucher.min_order_value
      ) {
        let newDiscountAmount = 0;
        if (voucher.discount_type === "percent") {
          newDiscountAmount = (cart.totalPrice * voucher.discount_value) / 100;
          if (voucher.max_discount > 0)
            newDiscountAmount = Math.min(
              newDiscountAmount,
              voucher.max_discount
            );
        } else if (voucher.discount_type === "fixed") {
          newDiscountAmount = voucher.discount_value;
          if (newDiscountAmount > cart.totalPrice)
            newDiscountAmount = cart.totalPrice;
        }
        cart.discount_amount = newDiscountAmount;
      } else {
        cart.voucher_code = null;
        cart.discount_amount = 0;
      }
    } else {
      cart.discount_amount = 0;
    }

    await cart.save();
    return cart;
  }

  // Ví dụ cập nhật cho updateQuantity (ưu tiên cartItemId)
  static async updateQuantity(userId, cartItemId, newQuantity) {
    if (typeof newQuantity !== "number" || newQuantity < 0) {
      // newQuantity = 0 để xóa
      throw new Error("Số lượng mới không hợp lệ.");
    }

    const cart = await Cart.findOne({ userId });
    if (!cart) throw new Error("Không tìm thấy giỏ hàng");

    const itemIndex = cart.items.findIndex(
      (p) => p._id.toString() === cartItemId
    );
    if (itemIndex === -1)
      throw new Error("Mục hàng không có trong giỏ hoặc cartItemId không đúng");

    const itemToUpdate = cart.items[itemIndex];

    if (newQuantity === 0) {
      cart.items.splice(itemIndex, 1); // Xóa nếu số lượng là 0
    } else {
      // Kiểm tra tồn kho trước khi cập nhật số lượng
      if (itemToUpdate.itemType === "PRODUCT") {
        const productDetails = await Product.findById(itemToUpdate.productId);
        if (!productDetails)
          throw new Error("Sản phẩm gốc của mục hàng không tồn tại.");
        if (newQuantity > productDetails.stock) {
          throw new Error(
            `Số lượng yêu cầu (${newQuantity}) cho "${itemToUpdate.name}" vượt quá tồn kho (còn ${productDetails.stock}).`
          );
        }
      } else if (itemToUpdate.itemType === "COMBO") {
        const comboDetails = await Combo.findById(
          itemToUpdate.comboId
        ).populate("products.productId");
        if (!comboDetails)
          throw new Error("Combo gốc của mục hàng không tồn tại.");
        for (const comboProductItem of comboDetails.products) {
          const productInCombo = comboProductItem.productId;
          const requiredStockForThisItem =
            (comboProductItem.quantityInCombo || 1) * newQuantity; // newQuantity ở đây là số lượng combo mới
          if (productInCombo.stock < requiredStockForThisItem) {
            throw new Error(
              `Không đủ tồn kho cho sản phẩm "${productInCombo.name}" trong combo "${comboDetails.name}" để cập nhật số lượng combo lên ${newQuantity}.`
            );
          }
        }
      }
      itemToUpdate.quantity = newQuantity;
      itemToUpdate.subTotal = itemToUpdate.price * itemToUpdate.quantity; // price là giá của 1 product hoặc 1 combo
    }

    // Tính lại totalPrice và discount
    cart.totalPrice = cart.items.reduce(
      (sum, item) => sum + (item.subTotal || 0),
      0
    );
    if (cart.voucher_code) {
      const voucher = await Voucher.findOne({ code: cart.voucher_code });
      if (
        voucher &&
        voucher.start_date <= new Date() &&
        voucher.expiry_date >= new Date() &&
        voucher.used_count < voucher.quantity &&
        cart.totalPrice >= voucher.min_order_value
      ) {
        let newDiscountAmount = 0;
        if (voucher.discount_type === "percent") {
          newDiscountAmount = (cart.totalPrice * voucher.discount_value) / 100;
          if (voucher.max_discount > 0)
            newDiscountAmount = Math.min(
              newDiscountAmount,
              voucher.max_discount
            );
        } else if (voucher.discount_type === "fixed") {
          newDiscountAmount = voucher.discount_value;
          if (newDiscountAmount > cart.totalPrice)
            newDiscountAmount = cart.totalPrice;
        }
        cart.discount_amount = newDiscountAmount;
      } else {
        cart.voucher_code = null;
        cart.discount_amount = 0;
      }
    } else {
      cart.discount_amount = 0;
    }

    await cart.save();
    return { cart };
  }

  static async clearCart(userId) {
    const cart = await Cart.findOne({ userId });
    if (!cart) throw new Error("Không tìm thấy giỏ hàng");

    cart.items = [];
    cart.totalPrice = 0;
    cart.voucher_code = null;
    cart.discount_amount = 0;
    await cart.save();
    return cart;
  }

  // áp dụng voucher
  static async applyVoucherToCart(userId, voucher_code) {
    const cart = await Cart.findOne({ userId });
    if (!cart) throw new Error("Giỏ hàng không tồn tại");
    if (cart.items.length === 0)
      throw new Error("Giỏ hàng trống, không thể áp dụng voucher.");

    const voucher = await Voucher.findOne({ code: voucher_code });
    if (!voucher) throw new Error("Voucher không tồn tại");

    const now = new Date();
    if (now < voucher.start_date || now > voucher.expiry_date) {
      throw new Error("Voucher không còn hiệu lực hoặc chưa đến ngày sử dụng");
    }
    if (voucher.used_count >= voucher.quantity) {
      throw new Error("Voucher đã được sử dụng hết");
    }
    if (cart.totalPrice < voucher.min_order_value) {
      throw new Error(
        `Tổng giá trị đơn hàng (${cart.totalPrice.toLocaleString()}đ) chưa đạt mức tối thiểu (${voucher.min_order_value.toLocaleString()}đ) để sử dụng voucher này.`
      );
    }

    let discountAmount = 0;
    if (voucher.discount_type === "percent") {
      discountAmount = (cart.totalPrice * voucher.discount_value) / 100;
      if (voucher.max_discount > 0) {
        discountAmount = Math.min(discountAmount, voucher.max_discount);
      }
    } else if (voucher.discount_type === "fixed") {
      discountAmount = voucher.discount_value;
      if (discountAmount > cart.totalPrice) discountAmount = cart.totalPrice;
    }

    cart.voucher_code = voucher_code;
    cart.discount_amount = discountAmount;

    await cart.save();
    return cart;
  }
}

module.exports = CartService;
