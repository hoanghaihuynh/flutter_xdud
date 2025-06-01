const OrderModel = require("./../model/orderSchema");
const VoucherModel = require("./../model/voucherSchema");
const ToppingModel = require("./../model/toppingSchema");
const ProductModel = require("./../model/productSchema");
const ComboModel = require("./../model/comboSchema");

class OrderService {
  // Thêm đơn hàng
  static async insertOrder(orderData) {
    try {
      let calculatedSubtotal = 0;
      const processedItems = [];

      for (const item of orderData.items) {
        // ... (logic xử lý item như đã thảo luận) ...
        // (Giữ nguyên logic xử lý PRODUCT và COMBO của bạn ở đây)
        let itemPriceForOneUnit = 0;
        let itemToppingPriceForOneUnit = 0;
        let itemSubtotal = 0;
        const itemToSave = { ...item };

        if (item.itemType === "PRODUCT") {
          if (!item.product_id)
            throw new Error("product_id là bắt buộc cho item loại PRODUCT.");
          const productDetails = await ProductModel.findById(item.product_id);
          if (!productDetails)
            throw new Error(
              `Sản phẩm với ID ${item.product_id} không tồn tại.`
            );
          itemPriceForOneUnit = productDetails.price;
          itemToSave.name = productDetails.name;
          itemToSave.imageUrl = productDetails.imageUrl;
          const toppingIds = item.note?.toppings || [];
          const toppingsFromDb = await ToppingModel.find({
            _id: { $in: toppingIds },
          });
          itemToSave.note.toppings = toppingsFromDb.map((t) => ({
            name: t.name,
            price: t.price,
          }));
          itemToppingPriceForOneUnit = toppingsFromDb.reduce(
            (total, t) => total + t.price,
            0
          );
          itemToSave.toppingPrice = itemToppingPriceForOneUnit;
          if (!item.note?.size || !item.note?.sugarLevel) {
            throw new Error("Thiếu size hoặc sugarLevel cho sản phẩm đơn lẻ.");
          }
        } else if (item.itemType === "COMBO") {
          if (!item.combo_id)
            throw new Error("combo_id là bắt buộc cho item loại COMBO.");
          const comboDetails = await ComboModel.findById(
            item.combo_id
          ).populate("products.productId", "name price imageUrl");
          if (!comboDetails)
            throw new Error(`Combo với ID ${item.combo_id} không tồn tại.`);
          itemPriceForOneUnit = comboDetails.price;
          itemToSave.name = comboDetails.name;
          itemToSave.imageUrl = comboDetails.imageUrl;
          itemToSave.toppingPrice = 0;
          itemToSave.note = itemToSave.note || {};
          itemToSave.note.comboProductsSnapshot = comboDetails.products.map(
            (p) => ({
              productId: p.productId._id.toString(),
              name: p.productId.name,
              quantityInCombo: p.quantityInCombo,
              defaultSize: p.defaultSize,
              defaultSugarLevel: p.defaultSugarLevel,
            })
          );
          itemToSave.note.size = item.note?.size || "";
          itemToSave.note.sugarLevel = item.note?.sugarLevel || "";
        } else {
          throw new Error(`itemType không hợp lệ: ${item.itemType}`);
        }
        itemToSave.price = itemPriceForOneUnit;
        itemSubtotal =
          (itemPriceForOneUnit + itemToppingPriceForOneUnit) * item.quantity;
        calculatedSubtotal += itemSubtotal;
        processedItems.push(itemToSave);
      }

      orderData.items = processedItems;
      orderData.subtotal = calculatedSubtotal;

      let discountAmount = 0;
      if (orderData.voucher_code) {
        const voucher = await VoucherModel.findOne({
          code: orderData.voucher_code,
        });

        if (!voucher) throw new Error("Voucher không tồn tại");
        if (
          voucher.quantity_remaining !== undefined &&
          voucher.quantity_remaining <= 0
        ) {
          // Giả sử bạn có trường quantity_remaining
          throw new Error("Voucher đã hết lượt sử dụng.");
        } else if (
          voucher.quantity !== undefined &&
          voucher.used_count !== undefined &&
          voucher.quantity <= voucher.used_count
        ) {
          throw new Error(
            "Voucher đã hết lượt sử dụng (quantity <= used_count)."
          );
        }

        const now = new Date(); // <<<<<< THÊM DÒNG NÀY ĐỂ KHỞI TẠO 'now'

        if (voucher.start_date && now < voucher.start_date)
          throw new Error("Voucher chưa đến ngày áp dụng");
        if (voucher.expiry_date && now > voucher.expiry_date)
          throw new Error("Voucher đã hết hạn");

        if (
          voucher.min_order_value &&
          calculatedSubtotal < voucher.min_order_value
        ) {
          throw new Error(
            `Giá trị đơn hàng tối thiểu (${calculatedSubtotal}) chưa đạt ${voucher.min_order_value} để áp dụng voucher`
          );
        }

        if (voucher.discount_type === "percent") {
          discountAmount = (calculatedSubtotal * voucher.discount_value) / 100;
          if (voucher.max_discount && voucher.max_discount > 0) {
            // Sửa lại thành max_discount_value nếu đó là tên trường đúng
            discountAmount = Math.min(discountAmount, voucher.max_discount);
          }
        } else {
          // "fixed"
          discountAmount = voucher.discount_value;
        }

        voucher.used_count = (voucher.used_count || 0) + 1;
        // Nếu bạn dùng quantity_remaining:
        // if (voucher.quantity_remaining !== undefined) {
        //    voucher.quantity_remaining -=1;
        // }
        await voucher.save();
      }

      orderData.discount_amount = discountAmount;
      orderData.total = calculatedSubtotal - discountAmount;
      if (orderData.total < 0) orderData.total = 0;

      orderData.voucher_code = orderData.voucher_code || null;

      const newOrder = new OrderModel(orderData);
      return await newOrder.save();
    } catch (error) {
      console.error("OrderService insertOrder error:", error);
      // Ném lỗi với message gốc để controller có thể bắt và trả về client
      throw new Error(error.message); // Không cần thêm "OrderService - " nữa nếu message đã rõ ràng
    }
  }

  // Lấy danh sách tất cả đơn hàng
  static async getAllOrder() {
    try {
      const orders = await OrderModel.find()
        .populate("user_id", "email name avatar") // Lấy thêm thông tin user nếu muốn
        .populate("items.product_id", "name price imageUrl category") // Cho sản phẩm
        .populate("items.combo_id", "name price imageUrl category"); // Cho combo
      return orders;
    } catch (error) {
      throw new Error("Failed to get orders: " + error.message);
    }
  }

  // Lấy đơn hàng theo ID người dùng
  static async getOrdersByUserId(userId) {
    try {
      const orders = await OrderModel.find({ user_id: userId })
        .populate("user_id", "email name avatar")
        .populate("items.product_id", "name price imageUrl category")
        .populate("items.combo_id", "name price imageUrl category");
      return orders;
    } catch (error) {
      throw new Error("Failed to get orders by user ID: " + error.message);
    }
  }

  // Sửa đơn hàng
  static async updateOrder(orderId, updateData) {
    try {
      const updatedOrder = await OrderModel.findByIdAndUpdate(
        orderId,
        updateData,
        {
          new: true,
        }
      );
      return updatedOrder;
    } catch (error) {
      throw error;
    }
  }

  // Xóa đơn hàng
  static async deleteOrder(orderId) {
    try {
      const deletedOrder = await OrderModel.findByIdAndDelete(orderId);

      if (!deletedOrder) {
        throw new Error("Không tìm thấy đơn hàng để xóa");
      }

      return deletedOrder;
    } catch (error) {
      throw new Error("Failed to delete order: " + error.message);
    }
  }
}

module.exports = OrderService;
